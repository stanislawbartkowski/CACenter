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
 



