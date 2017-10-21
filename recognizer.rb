require 'pathname'
require 'chunky_png'
require 'digest/md5'

include ChunkyPNG::Color

class Recognizer
  @@numbers_fingerprints = [
    { number: 0, md5: 'be9f3ab617376c49d5c5b4d838fa3441' },
    { number: 1, md5: '3ce8936342ce4af36cd090004b678ebd' },
    { number: 2, md5: '8ec1d6a31ebef97949922c44d93267b2' },
    { number: 3, md5: '44b8eec27010735ab373345893fcb7e6' },
    { number: 4, md5: 'eaabecc0dd3e99f898c7af15ca2875b7' },
    { number: 5, md5: 'd1766a7c1929878e26488d0e088faecc' },
    { number: 6, md5: 'f0d6edcb08a82c625d6aae3167cf4248' },
    { number: 7, md5: '69d097bbd06b6ae518c4b1cdf030ad06' },
    { number: 8, md5: 'a6cb4804f36ca507d39eccefa849ba75' },
    { number: 9, md5: '0715d406dded3f7d6f67b7782ea41fe5' }
  ]

  # Получение структурированной информации со счётчика
  def get_info(counter)
    # Распознаём изображение
    recognized = recognize_all_counter(counter, @@numbers_fingerprints)

    {
      'month' => {
        'hits' => recognized[0].join('').to_i,
        'hosts' => recognized[1].join('').to_i
      },
      'week' => {
        'hits'  => recognized[2].join('').to_i,
        'hosts' => recognized[3].join('').to_i
      },
      '24_hours' => {
        'hits'  => recognized[4].join('').to_i,
        'hosts' => recognized[5].join('').to_i
      },
      '12_hours' => {
        'hits'  => recognized[6].join('').to_i,
        'hosts' => recognized[7].join('').to_i
      },
      'online' => {
        'hits'  => recognized[8].join('').to_i,
        'hosts' => recognized[9].join('').to_i
      }
    }
  end

  private

  # Процедура получения одной цифры как нового изображения
  def get_one_number_from_counter(counter, x, y)
    number = ChunkyPNG::Image.new(4, 5)

    (y..(y + 4)).each do |my_y|
      (x..(x + 3)).each do |my_x|
        pixel = counter[my_x, my_y]
        number[my_x - x, my_y - y] = pixel
      end
    end

    number
  end

  # Процедура определения пустого изображения
  def image_is_empty(image)
    image.height.times do |y|
      image.row(y).each_with_index do |pixel, _x|
        return false if (r(pixel) == 0) && (g(pixel) == 0) && (b(pixel) == 0)
      end
    end
    true
  end

  # Процедура получения строки как массива изображений цифр
  def get_line_from_counter(counter, y)
    result = []

    # Смещения цифр в строке
    offsets = [39, 44, 51, 56, 61, 68, 73, 78].reverse!

    offsets.each do |x|
      number = get_one_number_from_counter(counter, x, y)

      if image_is_empty(number)
        next
      else
        result.push(Digest::MD5.hexdigest(number.to_blob))
      end
    end

    result.reverse
  end

  # Процедура получения всех строк со счётчика в виде массива
  def get_all_lines_from_counter(counter)
    result = []

    # Смещение строк в счётчике
    offsets = [27, 34, 46, 53, 65, 72, 84, 91, 103, 110]

    offsets.each do |y|
      result.push(get_line_from_counter(counter, y))
    end

    result
  end

  # Процедура определения одного символа
  def recognize_one_symbol(img, patterns)
    patterns.each do |pattern|
      return pattern[:number] if pattern[:md5] == img
    end

    nil
  end

  # Процедура расшифровки данных с изображения в текстовое представление
  def recognize_all_counter(counter, patterns)
    all_counter_lines = get_all_lines_from_counter(counter)
    result_lines = []

    all_counter_lines.each_with_index do |line, line_index|
      line.each_with_index do |number, number_index|
        symbol = recognize_one_symbol(number, patterns)

        result_lines[line_index] = [] unless result_lines.size - 1 >= line_index
        result_lines[line_index][number_index] = symbol
      end
    end

    result_lines
  end
end
