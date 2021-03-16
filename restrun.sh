#!/bin/bash

source ./env.rc

[[ -d $DIRCA/private ]] || ./ca.sh create force

JAR=CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar

cat <<EOF >envr.rc
CADIR=.
EOF

java -cp $JAR RestMain -c carest.properties -p $RESTPORT
