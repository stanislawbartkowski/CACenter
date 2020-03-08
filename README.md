# CACenter

A simple Certificate Authority centre issuing server and client SSL certificates. It is an automated version of the procedure described in this webpage.

https://jamielinux.com/docs/openssl-certificate-authority/index.html.

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

**UNIQ** variable is used to set value of *unique_subject* in the intermediate openssl.cnf file. If *yes*, only a single CN value in the certificates managed by this CA is allowed. Value *no* relax this contraint.<br>
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

# Issue a certificate signed by this CA
> ./ca.sh makecert certsub
* certsub, the subject of the new certificate. The CN (Common Name) mustn't be the same CN of root and intermediate CA certificate.

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
> ././ca.sh makep12 /number/ /password/<br>
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
>./ca.sh csrcert /CSR file/<br>
Produces a certficate signed by the CA using CSR file. 

 ./ca.sh csrcert ./bigsql.csr 

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

