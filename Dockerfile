FROM openjdk:8
MAINTAINER "sb" <stanislawbartkowski@gmail.com>

RUN apt-get update && apt-get install -y zip
COPY ca.sh .
COPY env.rc .
COPY openssl.cnf .
COPY intermediateopenssl.cnf .
RUN ./ca.sh create force

COPY CARestApi/target/CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY restrun.sh .
ENTRYPOINT ["./restrun.sh"]
