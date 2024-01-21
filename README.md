# Speedtest Visualisation Utiliy
![Sppedtest Visualisation](https://github.com/morganism/speedtest-viz/blob/master/images/page_speedtest-viz_app_mainpage.png?raw=true)

## Considerations


## TL/DR



### cron speedtest  & parser to run every 5 minutes : 

The following two scripts are show as crontab entries, 

'speedtest.simple' runs a simple speedtest with human readable output

'parse.speedtest.simple_to_csv' will take the output of the simple speedtest and creates a 'speedtest.csv' file that is read by 'app.rb' to plot data


- */5 * * * * /Users/morgan/bin/speedtest.simple

- */6 * * * * /Users/morgan/bin/parse.speedtest.simple_to_csv


## Charting

### Google Charts

The Google Charts library is used to provide the visualisation, and abillity to zoom into a selected subsection of the chart


## Docker

### Create the docker group.

sudo groupadd docker

### Add your user to the docker group.

sudo usermod -aG docker ${USER}

### You would need to log out and log back in so that your group membership is re-evaluated or type the following command:

su -s ${USER}

### Build the container

docker build --tag speedtest .

### Run the app : note the bindmount to make '/var/data/log/speedtest' directory available to the running container

docker run -p 4567:4567 --mount type=bind,source=/var/data/log/speedtest,target=/var/data/log/speedtest speedtest
