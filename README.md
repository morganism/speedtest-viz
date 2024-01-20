# Speedtest Visualisation Utiliy
![Sppedtest Visualisation](https://github.com/morganism/speedtest-viz/blob/master/images/page_speedtest-viz_app_mainpage.png?raw=true)

## Considerations

## TL/DR

- cron parser.rb to run every 5 minutes : 

- */5 * * * * /Users/morgan/bin/speedtest.simple

- */6 * * * * /Users/morgan/bin/parse.speedtest.simple_to_csv


## Devel


## Docker

docker build --tag speedtest .

docker run -p 4567:4567 speedtest
