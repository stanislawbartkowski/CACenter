FROM openjdk:8
MAINTAINER "sb" <stanislawbartkowski@gmail.com>
ARG RESTPORT
ENV DIR=/var/cacenter

RUN apt-get update && apt-get install -y zip
COPY ca.sh .
COPY env.rc .
RUN echo "DIRCA=${DIR}" >>env.rc
COPY openssl.cnf .
COPY intermediateopenssl.cnf .
RUN ./ca.sh create force

COPY CARestApi/target/CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY restrun.sh .
EXPOSE ${RESTPORT}
VOLUME ${DIR}
ENTRYPOINT ["./restrun.sh"]
