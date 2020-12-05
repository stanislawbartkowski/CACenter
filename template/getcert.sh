RESTSERVERPORT=localhost:9080
CERTCN=/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com
ZIP=out.zip

curl -X POST -v http://$RESTSERVERPORT/subcert?subject=$CERTCN -o $ZIP
