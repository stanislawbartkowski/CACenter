FROM openjdk:8-jdk-alpine
MAINTAINER "sb" <stanislawbartkowski@gmail.com>
ARG RESTPORT
ENV DIR=/var/cacenter
ENV WORKDIR=/usr/local/cacenter

RUN apk add zip bash openssl && \
    mkdir -p ${WORKDIR} && chmod 755 ${WORKDIR}

WORKDIR ${WORKDIR}

COPY ca.sh .
COPY env.rc .
RUN echo "DIRCA=${DIR}" >>env.rc
RUN echo "RESTPORT=${RESTPORT}" >> env.rc
COPY openssl.cnf .
COPY intermediateopenssl.cnf .
# RUN ./ca.sh create force

COPY CARestApi/target/CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY restrun.sh .
EXPOSE ${RESTPORT}
VOLUME ${DIR}
#ENTRYPOINT ["./restrun.sh"]
CMD ["sleep","60m"]
