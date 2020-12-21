# CACenter

A simple Certificate Authority centre issuing server and client SSL certificates. It is an automated version of the procedure described in this webpage.

https://jamielinux.com/docs/openssl-certificate-authority/index.html

The following tasks are implemented:
* Create root and intermediate Certificate Authority.
* Issue a pair key/cert certificate signed by the intermediate Certificate Authority
* Issue a certificate signed by CA from CSR file
* Produce on-demand .pk12 cert file containing key and certificate.

# Files description
 * ca.sh Bash script file implementation using OpenSSL tools.
 * openssl.cnf Template for root openssl.conf file
 * intermediateopenssl.cnf Template for intermediate openssl.conf file
 * template/env.rc Template configuration file
 
 openssl.conf and intermediateopenssl.conf contain XX-XX string, during the creation of CA it is replaced by CA directory.
 
# Installation and configuration

## Clone

>git clone https://github.com/stanislawbartkowski/CACenter.git<br>
>cd CACenter<br>
>cp template/env.rc .<br>

## Customize
Modify env.rc source file.
| Variable | Description | Sample 
|-----|------|------|
| DIRCA | Home directory for CA files | $HOME/ca
| ROOTKEYPASSWORD | Password for root key/cert credentials| secret
| ROOTSUB | Root authority subject | "/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=thinkde.sb.com"
| INTERMEDIATEKEYPASSWD | Password for intermediate key/cert credentials | secret
| INTERMEDIATESUB | Intermediate authority subject (CN for root and intemediate should be the same) | "/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=IntermediateRoom/CN=thinkde.sb.com"
| UNIQ | Possible values: yes/no | No: duplictated CN certificates are allowed

**UNIQ** variable is used to set value of *unique_subject* in the intermediate openssl.cnf file. If *yes*, only a single CN value in the certificates managed by this CA is allowed. Value *no* relax this constraint.<br>
<br>
All tasks are implemented in *ca.sh* bash script file. Exit code 0 means that the operation was completed successfully. Non-zero code means failure.

# Create a new CA centre

> ./ca.sh create safe/force<br>

Creates new CA using configuration parameters in *env.rc*. The previous content of *DIRCA* is removed. Parameter *safe* asks for yes/no permission before creating new CA, parameter *force* creates new CA and remove the old one without asking.<br>
Script exit code 0 means success, any other exit code means failure.

Example:<br>
>./ca.sh create safe
```
Creates certification center
Uniqe certificates no
 Directory for certificates: /home/sb/ca
   Warning: previous content of /home/sb/ca will be removed !
 Root subject: /C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=thinkde.sb.com
 Root password: XXXXXX
 Intermediate subject: /C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=IntermediateRoom/CN=thinkde.sb.com
 Intermediate password: XXXXXXX
Create new CA center (Yy) ?
```

The CA has the following directory structure under *DIRCA* root directory:<br>
* csr: (empty)
* crl: (empty)
* private (600): ca,key.pem, root certficate key
* certs: ca.cert.pem, root certficate
* newcerts : 1000.pem
* openssl.cnf Configuation file for root
* intermediate: intermediate authority directory
  * newcerts: (empty)
  * crl: (emmpty)
  * private (600): intermediate.key.pem. This directory also keeps all certificates generated.
  * csr: intermediate.csr.pem intermediate csr file
  * certs: 
    * intermediate.cert.pem intermediate certificate
    * ca-chain.cert.pem CA certficate chain, root and intermediate
  * openssl.cnf configuration file for intermediate CA
  * index.txt index of all certificates created.
  
The created certificates are stored in the *$DIRCA/intermediate/private* directory. <br>
After a new certificate is created, the *$DIRCA/intermediate/index.txt* is appended. The sequential *ID* is the subdirectory in the *$DIRCA/intermdiate/private* directory and all three file: csr, key and crt are stored there.<br>

Example:
Line in *index.txt* file:
```
V	210317182702Z		1000	unknown	/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com
```
> ls ..../ca/intermediate/private/1000/ -ltr
```
www.example.com.key.pem
www.example.com.csr.pem
www.example.com.cert.pem
```

# Issue a private key/certificate signed by this CA
> ./ca.sh makecert certsub /optional file name/
* certsub, the subject of the new certificate. The CN (Common Name) mustn't be the same as CN of root and intermediate CA certificate.
* /optional output file name/ if not provided, the generated certifcate and root certificate are stored in /tmp directory. 

Example:<br>
> ./ca.sh makecert /C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com<br>
```
          X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
Certificate is to be certified until Mar 17 18:27:02 2021 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
/tmp/tmp.TqrQoFdLE7: OK
```
Exit code 0 means that certificate was created succesfully, other code is returned in case of any failure. The *$DIRCA/intermediate/index.txt* file is appended and the newly created certificated are stored in the *$DIRCA/intermediate/private/NUMBER* directory.
# Generate .p12 
Create openssl pkcs12 file containing private key and certficate. The certficates should be alredy create by *./ca.sh makecert* command.
>  ./ca.sh makep12 /number/ /password/<br>
* number : the subdirectory in *private* directory
* password : encryption password for pkcs12 file generated.

The pkcs12 file is generated in /tmp directory as *CN.p12* file.<br>
Example:<br>
>  ./ca.sh makep12 1000 secret
```
 ls /tmp/www.example.com.p12 
/tmp/www.example.com.p12
```
# Issue a certificate using CSR file 
>./ca.sh csrcert /CSR file/ /optional file name/<br>

Produces a certificate signed by the CA using CSR file. 
* /optional file name/ if provided, the certificate and CA chain is zipped in this file. Important: it is the responsibility of the requester to remove the file if not needed any longer. Leaving the file create a potential security threat.

Example:
>  ./ca.sh csrcert ./bigsql.csr 
```
..............
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
Certificate is to be certified until Mar 18 22:04:40 2021 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
/tmp/tmp.2YuqHAgV1F: OK
NUM=1016
```
> ./ca.sh csrcert ./bigsql.csr bigsql.zip
```
.............. 
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
Certificate is to be certified until Oct 15 18:57:19 2021 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
/tmp/tmp.bsjpG1j5I9: OK
  adding: ca-chain.cert.pem (deflated 32%)
  adding: hdm1.sb.com.cert.pem (deflated 27%)
  adding: hdm1.sb.com.csr.pem (deflated 25%)
c.zip created.
NUM=1004
```

# CACenter REST/API
The certificate can be generated using Rest/API. Two options are supported: generate certficate through subject or CSR (Certificate Signing Request) file.
## Installation
Download and install RestService jar file https://github.com/stanislawbartkowski/RestService. It is the only dependency. Then prepare CARestAPI solution.
> cd CARestApi<br>
> mvn clean package -Dmaven.test.skip=true<br>

Verify<br>
>ll target
```
drwxrwxr-x. 2 sb sb     6 Mar 18 20:58 archive-tmp
-rw-rw-r--. 1 sb sb 12799 Mar 18 20:58 CARestApi-1.0-SNAPSHOT.jar
-rw-rw-r--. 1 sb sb 33472 Mar 18 20:58 CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar
drwxrwxr-x. 3 sb sb    48 Mar 18 20:58 classes
drwxrwxr-x. 3 sb sb    25 Mar 18 20:58 generated-sources
drwxrwxr-x. 2 sb sb    84 Mar 18 20:58 lib
drwxrwxr-x. 2 sb sb    28 Mar 18 20:58 maven-archiver
drwxrwxr-x. 3 sb sb    35 Mar 18 20:58 maven-status

```
## Customize
>cp template/env.rc .<br>

env.rc contains a single parameter, a port number to use. default is 9080<br>
## Run
>./run.sh<br>
```
Mar 18, 2020 9:48:30 PM com.rest.restservice.RestLogger info
INFO: ../ca.sh
Mar 18, 2020 9:48:30 PM com.rest.restservice.RestLogger info
INFO: Start HTTP Server, listening on port 9080
Mar 18, 2020 9:48:30 PM com.rest.restservice.RestLogger info
INFO: Register service: subcert
Mar 18, 2020 9:48:30 PM com.rest.restservice.RestLogger info
INFO: Register service: csrcert

```
### Rest/API 
Generate certficate from subject
| API | Description
| --- | --- |
| URL | /subcert
| Method | POST
| Query parameter | *subject*, a subject name. Example: C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com
| HTTP response code | 200: success, any other code: failure
| Response body | zip file containing key/certificate pair and CA certificate chain

Example:
> curl -X POST -v  http://localhost:9080/subcert?subject=/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com -o out.zip<br>
```
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* About to connect() to thinkde port 9080 (#0)
*   Trying 192.168.0.206...
* Connected to thinkde (192.168.0.206) port 9080 (#0)
> POST /subcert?subject=/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com HTTP/1.1
> User-Agent: curl/7.29.0
> Host: thinkde:9080
> Accept: */*
> 
< HTTP/1.1 200 OK
< Charset: utf8
< Date: Wed, 18 Mar 2020 20:54:40 GMT
< Access-control-allow-methods: OPTIONS, POST
< Content-type: application/zip
< Content-length: 6990
< 
{ [data not shown]
100  6990  100  6990    0     0  39526      0 --:--:-- --:--:-- --:--:-- 39715
* Connection #0 to host thinkde left intact

```
> unzip -l out.zip<br>
```
Archive:  out.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     4098  03-18-2020 21:54   ca-chain.cert.pem
     1972  03-18-2020 21:54   www.example.com.cert.pem
     1009  03-18-2020 21:54   www.example.com.csr.pem
     1675  03-18-2020 21:54   www.example.com.key.pem
---------                     -------
     8754                     4 files

```
Generate certificate from CST file<br>

| API | Description
| --- | --- |
| URL | /csrcert
| Method | POST
| Query parameter | no parameters
| Request body | CSR file
| HTTP response code | 200: success, any other code: failure
| Response body | zip file containing key/certificate pair and CA certificate chain

Example<br>
> curl -X POST -v  http://thinkde:9080/csrcert  --data-binary @/tmp/www.example.com.csr.pem -o out.zip
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* About to connect() to thinkde port 9080 (#0)
*   Trying 192.168.0.206...
* Connected to thinkde (192.168.0.206) port 9080 (#0)
> POST /csrcert HTTP/1.1
> User-Agent: curl/7.29.0
> Host: thinkde:9080
> Accept: */*
> Content-Length: 1009
> Content-Type: application/x-www-form-urlencoded
> 
} [data not shown]
* upload completely sent off: 1009 out of 1009 bytes
< HTTP/1.1 200 OK
< Charset: utf8
< Date: Wed, 18 Mar 2020 20:58:31 GMT
< Access-control-allow-methods: OPTIONS, POST
< Content-type: application/zip
< Content-length: 5533
< 
{ [data not shown]
100  6542  100  5533  100  1009  99904  18218 --:--:-- --:--:-- --:--:--  100k
* Connection #0 to host thinkde left intact

```
> unzip -l out.zip
```
Archive:  out.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     4098  03-18-2020 21:58   ca-chain.cert.pem
     1972  03-18-2020 21:58   www.example.com.cert.pem
     1009  03-18-2020 21:58   www.example.com.csr.pem
---------                     -------
     7079                     3 files
```
## Docker/Podman
### Create image
Configure CACenter (env.rc) and CARestAPI as described above. Create Docker image.
> ./createdocker.sh<br>
### Create container

*PORT* specified in *CARestApi/env.rc* resource file. Default is 9080. Use default port or customize port to different value. In this method of container creation,  a storage for generated certificates is epheremal and will be destroyed together with the container.

> podman run --name cacenter -d -p 9080:9080 cacenter

Use persistent storage. If SELinux enabled is enabled as recommended, configure SELinux context.

> mkdir $HOME/cacenter<br>
> sudo semanage fcontext -a -t container_file_t '$HOME/cacenter(/.*)?'<br>
> sudo restorecon -R $HOME/cacenter<br>

> podman run --name cacenter -d -p 9080:9080 -v $HOME/cacenter:/var/cacenter cacenter 


