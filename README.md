# Assignment nov 2018

In this 2h assignment, I show how to run multiple services behind a proxy
and how to switch to a new version of a service.
The implementation adheres to the minimum viable product philosophy.

## TLDR

Start by running (we assume you have docker-compose):
```
docker-compose up -d
```
after which we check the status by doing:
```
curl --silent \
  http://YOUR_HOST_NAME:8000/fitcheck/service[2,4,8]/health/live
```

## Intro

We have 3 services,
countries (country, service2),
airports old (rock, service4),
airports new (folk, service8).

We can update from old to new by using:
```shell
# update current service version
sed -i 's/4/8/g' nginx-include.conf

# reload proxy did not work, it did not point to the new proxy_pass
# docker exec -it `docker ps|grep proxy|cut -f1 -d\ ` nginx -s reload
# therefor we do
docker-compose restart proxy
```

## Motivation tech stack

Nginx as a reverse proxy.
With so little containers,
this is the easiest tool for the job.
With more containers, Traefik would be better or a container orchestrator.

## debug

```
docker exec -it laluna_rock_1 sh
/ # netstat -tulpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.11:33951        0.0.0.0:*               LISTEN      -
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      1/java
udp        0      0 127.0.0.11:36244        0.0.0.0:*                           -


# service2
curl --silent http://lent.ink:8000/fitcheck/service2/health/live
{"status":200,"state":"OK"}

curl --silent http://lent.ink:8000/fitcheck/service2/health/ready
{"status":503,"state":"INITIALIZING"}

# service4
curl --silent http://zing.vecht.huil.bid:8000/fitcheck/service4/health/ready
{"status":503,"state":"INITIALIZING"}

curl --silent lentink.consulting:8000/countries/AE
[{"id":302618,"code":"AE","name":"United Arab Emirates","continent":"AS","wikipedia_link":"http://en.wikipedia.org/wiki/United_Arab_Emirates","keywords":"UAE"},{"id":302633,"code":"IL","name":"Israel","continent":"AS","wikipedia_link":"http://en.wikipedia.org/wiki/Israel","keywords":""}]

curl --silent api.likes2.party:8000/airports/NL|cut -f10 -d\                                                    
Airport","latitude":50.91170120239258,"longitude":5.770140171051025,"elevation":375,"continent":"EU","iso_country":"NL","iso_region":"NL-LI","municipality":"Maastricht","scheduled_service":"yes","gps_code":"EHBK","iata_code":"MST","wikipedia_link":"http://en.wikipedia.org/wiki/Maastricht_Aachen_Airport","runways":[{"id":237921,"airport_ref":2515,"airport_ident":"EHBK","length_ft":8202,"width_ft":148,"surface":"ASP","lighted":1,"closed":0,"le_ident":"03","le_latitude_deg":50.901798248291016,"le_longitude_deg":5.760049819946289,"le_elevation_ft":365,"le_heading_degT":33,"le_displaced_threshold_ft":820,"he_ident":"21","he_latitude_deg":50.920799255371094,"he_longitude_deg":5.779230117797852,"he_elevation_ft":370,"he_heading_degT":213,"he_displaced_threshold_ft":820}]},{"id":2516,"ident":"EHDL","aType":"medium_airport","name":"Deelen
```

## What is missing

+ containers should be build after push to master and pushed to docker registry
+ automated test should be run
+ when the health check is positive, only then the switch should be made between containers (old -> new)
+ ideally you would roll it out to a small subset of the users (A/B testing) before deploying to all
+ a real orchistration tool with proper monitoring and log aggregation, not docker-compose
