. ./env.rc
source CARest/envr.rc
echo $PORT
DOCKER=podman

$DOCKER build --build-arg RESTPORT=$PORT -t cacenter . 
