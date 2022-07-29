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

```
curl http://localhost:4567/get/gazeta.ru | jq

{
  "error_code": 0,
  "error_message": null,
  "cached": true,
  "info": {
    "month": {
      "hits": 6043716,
      "hosts": 24060033
    },
    "week": {
      "hits": 20824746,
      "hosts": 5650076
    },
    "24_hours": {
      "hits": 3092057,
      "hosts": 983133
    },
    "12_hours": {
      "hits": 509786,
      "hosts": 168742
    },
    "online": {
      "hits": 64956,
      "hosts": 10795
    }
  }
}
```
