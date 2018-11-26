FROM alpine AS base

RUN apk add --no-cache curl

# we get these from the docker-compose.yml
ARG JAR_URL
ARG JAR_HASH

RUN curl -o /cookie.jar $JAR_URL
RUN if [ `sha1sum /cookie.jar|cut -f1 -d\ ` != $JAR_HASH ]; then exit 1; fi
RUN sha1sum /cookie.jar # just checking on stdout

FROM java:alpine
COPY --from=base /cookie.jar /service.jar
ENTRYPOINT ["java","-jar","/service.jar"]
