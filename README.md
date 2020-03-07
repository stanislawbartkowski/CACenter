# CACenter

A simple Certificate Authority center issuing server and client SSL certificates. It is and automated version of the procedure described in this webpage.

https://jamielinux.com/docs/openssl-certificate-authority/index.html.

The following tasks are implemented:
* Create root and intermediate Certificate Authority.
* Issue a pair key/cert certificate signed by the intemediate Certificate Authority
* Produce on demand .pk12 cert file containing key and certificate.

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
| INTERMEDIATESUB | Intermediate autority subject (CN for root and intemediate should be the same) | "/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=IntermediateRoom/CN=thinkde.sb.com"
| UNIQ | Possible values : yes/no | No: duplictated CN certificates are allowed

**UNIQ** variable is used to set value of *unique_subject* in the intermediate openssl.cnf file. If *yes*, only a single CN value in the certificates managed by this CA is allowed. Value *no* relax this contraint.

# Create new CA center

> ./ca.sh create safe/force<br>

Creates new CA using configuration parameters in *env.rc*. Previous content of *DIRCA* is removed. Parameter *safe* asks for yes/no permission before creating new CA, parameter *force* creates new CA and remove the old on without asking.<br>
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

# Issue a certificate signed by this CA
> 



