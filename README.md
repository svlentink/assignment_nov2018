# Assignment nov 2018

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

I've used one container with build arguments, less code to read/maintain for reviewer.

Infrastructure as a code; just run `docker-compose up`.

Builder pattern in Dockerfile for smaller images.

I've explained the most 'difficult' part with comments in the code, see the fitcheck location in nginx.conf.
For the remaining things, I try to using sensible variable names (except for my cookie jar)
and use default everywhere, resulting in less code.


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

## points after review
+ container isolation, not only from outside, but also across containers
+ terraform rollout, e.g. on scaleway
+ `sha1sum -c /file_with_hashes_and_filepaths`
+ container java:alpine is deprecated

Pseudo code we discussed on the spot, to check if healty and switch to new version
```python
for i in range(1,100):
  if curl /ready && curl live:
    change to new container
    break
  else
    sleep 1
```

## Terraform

[Download](https://www.terraform.io/downloads.html) and install terrafrom
```
wget URL
unzip terraform*.zip
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
terraform -v
```

Set your organization and token
```
export SCALEWAY_ORGANIZATION=
export SCALEWAY_TOKEN=
```

Prepare:
```
terraform init
terraform validate
terraform plan
```


Make sure that the machine you run the apply on,
has an ssh key that is inserted in the scaleway ui,
so it can ssh into the new machine.


Roll out:
```
terraform apply
scaleway_security_group.testendpoint: Refreshing state... (ID: 8d8644df-f8da-486b-b39b-838b3f25b2ba)
data.scaleway_image.ubuntux: Refreshing state...
data.scaleway_image.ubuntu: Refreshing state...
scaleway_security_group_rule.testendpoint_http_accept: Refreshing state... (ID: b3715565-14df-4ba3-8643-65ab1aa9fac6)
scaleway_server.tf1: Refreshing state... (ID: b8ed5406-a3fe-40fb-93d6-cc6526097a8e)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + scaleway_ip.tf1
      id:                      <computed>
      ip:                      <computed>
      reverse:                 <computed>
      server:                  "${scaleway_server.tf1.id}"

  + scaleway_security_group.testendpoint
      id:                      <computed>
      description:             "allow testendpoint"
      enable_default_security: "true"
      inbound_default_policy:  "accept"
      name:                    "testendpoint"
      outbound_default_policy: "accept"

  + scaleway_security_group_rule.testendpoint_http_accept
      id:                      <computed>
      action:                  "accept"
      direction:               "inbound"
      ip_range:                "0.0.0.0/0"
      port:                    "8000"
      protocol:                "TCP"
      security_group:          "${scaleway_security_group.testendpoint.id}"

  + scaleway_server.tf1
      id:                      <computed>
      boot_type:               <computed>
      cloudinit:               <computed>
      dynamic_ip_required:     "true"
      enable_ipv6:             "false"
      image:                   "4035ca92-5292-4c6e-aa17-759fbc32765e"
      name:                    "tf1"
      private_ip:              <computed>
      public_ip:               <computed>
      public_ipv6:             <computed>
      state:                   <computed>
      state_detail:            <computed>
      type:                    "START1-S"


Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

scaleway_security_group.testendpoint: Creating...
  description:             "" => "allow testendpoint"
  enable_default_security: "" => "true"
  inbound_default_policy:  "" => "accept"
  name:                    "" => "testendpoint"
  outbound_default_policy: "" => "accept"
scaleway_server.tf1: Creating...
  boot_type:           "" => "<computed>"
  cloudinit:           "" => "<computed>"
  dynamic_ip_required: "" => "true"
  enable_ipv6:         "" => "false"
  image:               "" => "4035ca92-5292-4c6e-aa17-759fbc32765e"
  name:                "" => "tf1"
  private_ip:          "" => "<computed>"
  public_ip:           "" => "<computed>"
  public_ipv6:         "" => "<computed>"
  state:               "" => "<computed>"
  state_detail:        "" => "<computed>"
  type:                "" => "START1-S"
scaleway_security_group.testendpoint: Creation complete after 6s (ID: e3921352-a187-46f2-a4e9-394e9266b6f3)
scaleway_security_group_rule.testendpoint_http_accept: Creating...
  action:         "" => "accept"
  direction:      "" => "inbound"
  ip_range:       "" => "0.0.0.0/0"
  port:           "" => "8000"
  protocol:       "" => "TCP"
  security_group: "" => "e3921352-a187-46f2-a4e9-394e9266b6f3"
scaleway_server.tf1: Still creating... (10s elapsed)
scaleway_security_group_rule.testendpoint_http_accept: Creation complete after 5s (ID: a5f7f97a-7311-46ee-b302-6afa196506fa)
scaleway_server.tf1: Still creating... (20s elapsed)
scaleway_server.tf1: Still creating... (30s elapsed)
scaleway_server.tf1: Still creating... (40s elapsed)
scaleway_server.tf1: Provisioning with 'local-exec'...
scaleway_server.tf1 (local-exec): Executing: ["/bin/sh" "-c" "date > /test_file.txt"]
scaleway_server.tf1: Creation complete after 49s (ID: 716a7040-7677-43d9-b159-a52d7d25b55c)
scaleway_ip.tf1: Creating...
  ip:      "" => "<computed>"
  reverse: "" => "<computed>"
  server:  "" => "716a7040-7677-43d9-b159-a52d7d25b55c"
scaleway_ip.tf1: Creation complete after 7s (ID: b2087076-29ec-459d-bc1d-56b961e859e5)

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

public_ip = 51.15.119.175
```

The installation of the terraform node itself is not completed,
we just indicate that you want to run commands or a script on the instance to initiate it.
We initiate the container orchistration, making it a master or worker.
