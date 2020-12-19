. ./env.rc
source CARestApi/env.rc
echo $PORT

cat << EOF | cat >restrun.sh
#!/bin/bash
java -cp CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar com/ca/restapi/CARestApi $PORT ./ca.sh
EOF

chmod 755 restrun.sh

$DOCKER build --build-arg RESTPORT=$PORT -t cacenter . 
