RESTSERVERPORT=thinkde:9080
CSR=db2.csr

#CERTCN=/C=PL/ST=MZ/L=Warsaw/O=TEST/OU=TEST/CN=john.sb.mail.com

ZIP=out.zip

curl -X POST -v http://$RESTSERVERPORT/csrcert --data-binary @$CSR -o $ZIP
echo $?
