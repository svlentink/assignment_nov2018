FROM alpine AS base

RUN apk add --no-cache wget

COPY checksums.txt /
RUN cd /; for i in `cat checksums.txt`; do \
  (echo $i|grep jar; wget https://s3-eu-west-1.amazonaws.com/devops-assesment/$i) || true; done

RUN sha1sum -c /checksums.txt

FROM openjdk:jre-slim
# we get this from the docker-compose.yml
ARG JAR_FILE
COPY --from=base /$JAR_FILE /service.jar
ENTRYPOINT ["java","-jar","/service.jar"]
