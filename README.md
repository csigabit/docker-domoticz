[![domoticz](https://github.com/domoticz/domoticz/raw/master/www/images/logo.png)](https://www.domoticz.com)

```
docker run \
  --name=domoticz \
  --restart=unless-stopped \
  -d \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Budapest \
  -p 1180:8080 \
  -p 6144:6144 \
  -p 11443:1443 \
  -v /volume1/docker/domoticz:/config \
  csigabit/domoticz:2020.2
  
```
