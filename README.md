# rb-LiRuCounterRecognizer
A simple web api that allows you to get information from the li.ru counter about specified domain in a computer-readable format.

# Install dependecies

Install all gems without bundler
```
grep '^gem' ./Gemfile | cut -d\' -f2 | xargs -n1 sudo gem install
```


# Run

```
chmod +x ./LiRuCounterRecognizer.rb
./LiRuCounterRecognizer.rb
```
