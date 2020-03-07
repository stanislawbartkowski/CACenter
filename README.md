# CACenter

A simple Certificate Authority center issuing server and client SSL certificates. It is and automated version of the procedure described in this webpage.

https://jamielinux.com/docs/openssl-certificate-authority/index.html.

The following tasks are implemented:
* Create root and intermediate Certificate Authority.
* Issue a pair key/cert certificate signed by the Certificate Authority
* Produce on demand .pk12 cert file containing ket and certificate.

# Files description
 * ca.sh Bash script file implementation using OpenSSL tools.
 * openssl.cnf Template for root openssl.conf file
 * intermediateopenssl.cnf Template for intermediate openssl.conf file
 * template/env.rc Template configuration file
 
 # Configuration
 



