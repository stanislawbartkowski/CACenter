. ./env.rc
source CARestApi/env.rc
echo $PORT

$DOCKER build --build-arg RESTPORT=$PORT -t cacenter . 
