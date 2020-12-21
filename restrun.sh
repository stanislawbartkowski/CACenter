#!/bin/bash

source ./env.rc

[[ -d $DIRCA/private ]] || ./ca.sh create force


java -cp CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar com/ca/restapi/CARestApi 9080 ./ca.sh
