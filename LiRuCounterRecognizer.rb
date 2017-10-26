require 'json'
require 'digest/md5'
require 'chunky_png'
require 'httpclient'
require 'domain_name'
require 'mini_magick'

require 'sinatra'
require 'sinatra/config_file'

require File.dirname(__FILE__) + '/recognizer.rb'

config_file 'config.yml'

recognizer = Recognizer.new
ua = HTTPClient.new

ERRORS = {
  1 => 'Invalid domain name',
  2 => 'Counter downloading error',
  3 => 'Counter is empty'
}.freeze

get '/' do
  'Main page! '
end

def write_file(path, data, option = 'wb')
  gif_counter = File.new(path, option)
  gif_counter.write(data)
  gif_counter.close
end

# Процедура загрузки и конвертирования изображения
def download(ua, domain, empty_counter_md5, domain_md5, db_path)
  # Загружаем изображение
  begin
    current_counter_data = ua.get_content(
      URI.escape("http://counter.yadro.ru/logo;#{domain}?29.6")
    )
  rescue
    return { error_code: 2 }
  end

  # Проверяем контрольную сумму пустого счётчика
  if Digest::MD5.hexdigest(current_counter_data) == empty_counter_md5
    return { error_code: 3 }
  end

  # Сохраняем счётчик
  gif_file_path = db_path + '/' + domain_md5 + '.gif'
  write_file(gif_file_path, current_counter_data)

  # Конвертируем счётчик в PNG
  png_file_path = db_path + '/' + domain_md5 + '.png'
  image = MiniMagick::Image.open(gif_file_path)
  image.format 'png'
  image.write(png_file_path)

  png_counter = ChunkyPNG::Image.from_file(png_file_path)
  { error_code: 0, image: png_counter }
end

get '/get/:domain' do
  content_type :json

  # Проверяем корректность домена и возвращаем ошибку если необходимо
  if DomainName(params[:domain]).canonical?
    target_domain = params[:domain]
  else
    return { error_code: 1, error_message: ERRORS[1] }.to_json
  end

  target_domain_hash = Digest::MD5.hexdigest(target_domain).to_s
  db_file_path = settings.db[:path] + '/' + target_domain_hash + '.json'

  # Если запись в кеше присутствует
  if File.exist?(db_file_path)
    # Получаем текущее время и время последней модификации файла
    current_time = Time.now
    existing_file_mtime = File.mtime(db_file_path)

    # Рассчитываем время жизни файла
    file_lifetime = (current_time - existing_file_mtime).to_i

    # Если файл не устарел возвращаем информацию из кеша
    if file_lifetime <= settings.downloader[:time_to_live]
      # Читаем данные из кеша
      cache_data = File.new(db_file_path, 'r').read
      return cache_data
    end
  end

  # Загружаем и конвертируем изображение
  download_result = download(ua, target_domain,
                             settings.downloader[:empty_counter_md5],
                             target_domain_hash, settings.db[:path]
  )

  # Если загрузка неудалась возвращаем ошибку
  if download_result[:error_code].zero?
    counter_info = recognizer.get_info(download_result[:image])
  end

  # Создаём хеш описывающий результат обработки
  response = {
    error_code: download_result[:error_code],
    error_message: ERRORS[download_result[:error_code]],
    cached: true,
    info: counter_info
  }

  # Сохраняем ответ в кеш
  write_file(db_file_path, response.to_json, 'w')

  # Модифицируем ответ перед выдачей
  response[:cached] = false

  response.to_json
end
