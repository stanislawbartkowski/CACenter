#!/bin/bash
source `dirname $0`/env.rc

INTERMEDIATE=intermediate
CURRENTDIR=`realpath \`dirname $0\``
OPENSSL=openssl.cnf
INTERMEDIATESSL=intermediateopenssl.cnf
CACHAIN=$DIRCA/$INTERMEDIATE/certs/ca-chain.cert.pem
INDEXATTR=$DIRCA/$INTERMEDIATE/index.txt.attr 
INDEXDB=$DIRCA/$INTERMEDIATE/index.txt

ROOTNAME=ca
INTERMEDIATENAME=intermediate

# ======================
# logging utilities
# ======================

log() {
    local -r MESS="$1"
    echo $MESS
}

logfail() {
    log "$1"
    exit 4
}

# ========================
# misc script utilties
# ========================
required_var() {
  local -r VARIABLE=$1
  [ -z "${!VARIABLE}" ] && logfail "Need to set environment variable $VARIABLE"
}

required_listofvars() {
  local -r listv=$1
  for value in $listv; do required_var $value; done
}

xchmod() {
    local -r MOD=$1
    local -r FILE=$2
    chmod $MOD $FILE
    [ $? -eq 0 ] || logfail "Error while chmod $MOD $FILE"
}

existfile() {
    local -r FILENAME=$1
    [ -f $FILENAME ] || logfail "$FILENAME does not exist, cannot generate p12"
}

# ===========================
# Create CA centre
# ===========================

createcadir() {
    local -r DIR=$1
    rm -rf $DIR
    mkdir $DIR
}

createdirs() {
    local -r DIR=$1
    mkdir $DIR/certs $DIR/crl $DIR/newcerts $DIR/private $DIR/csr
    chmod 700 $DIR/private
    touch $DIR/index.txt
    echo 1000 > $DIR/serial
}

createopenssl() {
    local -r INFILE=$1
    local -r OUTDIR=$2
    sed "s+XX-XX+$OUTDIR+g" $INFILE >$OUTDIR/$OPENSSL
}

keyname() {
    local -r DIR=$1
    local -r PRE=$2
    echo "$DIR/private/$PRE.key.pem"
}

certname() {
    local -r DIR=$1
    local -r PRE=$2
    echo "$DIR/certs/$PRE.cert.pem"
}

csrname() {
    local -r DIR=$1
    local -r PRE=$2
    echo "$DIR/csr/$PRE.csr.pem"
}


createkey() {
    local -r DIR=$1
    local -r CAPREFIX=$2
    local -r KEYPASSWORD=$3
    local -r KEYFILE=`keyname $DIR $CAPREFIX`
    openssl genrsa -passout pass:$KEYPASSWORD -aes256 -out $KEYFILE 4096 
    [ $? -eq 0 ] || logfail "Error while creating keyfile $KEYFILE"
    xchmod 400 $KEYFILE
}

createcert() {
    local -r DIR=$1
    local -r CAPREFIX=$2
    local -r KEYPASSWORD=$3
    local -r SUBJ="$4"
    local -r KEYFILE=`keyname $DIR $CAPREFIX`
    local -r CERTFILE=`certname $DIR $CAPREFIX`
    openssl req -config $DIR/openssl.cnf -passin pass:$KEYPASSWORD  -key $KEYFILE -new -x509 -days 7300 -sha256 -extensions v3_ca -out $CERTFILE -subj "$SUBJ"
    [ $? -eq 0 ] || logfail "Error while creating certificate $CERTFILE"
    xchmod 444 $CERTFILE
}

createintermediatecert() {
    local -r DIR=$DIRCA/$INTERMEDIATE
    local -r KEYFILE=`keyname $DIR $INTERMEDIATENAME`
    local -r CSRNAME=`csrname $DIR $INTERMEDIATENAME`
    local -r CERTFILE=`certname $DIR $INTERMEDIATENAME`
    local -r ROOTCERT=`certname $DIRCA $ROOTNAME`
    openssl req -config $DIR/$OPENSSL -passin pass:$INTERMEDIATEKEYPASSWD -new -sha256 -key $KEYFILE -out $CSRNAME -subj "$INTERMEDIATESUB"
    [ $? -eq 0 ] || logfail "Error while creating intermediate CSR"
    openssl ca -config $DIRCA/$OPENSSL -passin pass:$INTERMEDIATEKEYPASSWD -extensions v3_intermediate_ca  -days 3650 -notext -md sha256 -in $CSRNAME -batch -out $CERTFILE -verbose
    [ $? -eq 0 ] || logfail "Error while creating intermediate CRT"
    xchmod 444 $CERTFILE
    # verify
    openssl verify -CAfile $ROOTCERT $CERTFILE
    [ $? -eq 0 ] || logfail "Certificate $ROOTCERT $CERTFILE validation failed"
    # create certificate chain
    cat $CERTFILE $ROOTCERT > $CACHAIN
    [ $? -eq 0 ] || logfail "Failed to create certficate chain $CERTFILE $ROOTCERT $CACHAIN"
    xchmod 444 $CACHAIN
}

createrootca() {
    local -r DIR=$DIRCA
    local -r KEYPASSWORD=$ROOTKEYPASSWORD
    local -r INSSLCNF=$OPENSSL
    local -r PREFIX=$ROOTNAME
    local -r SUB=$ROOTSUB
    createcadir $DIR
    createdirs $DIR
    createopenssl $CURRENTDIR/$INSSLCNF $DIR
    createkey $DIR $PREFIX $KEYPASSWORD
    createcert $DIR $PREFIX $KEYPASSWORD "$SUB"
}


createintermediateca() {
    local -r DIR=$DIRCA/$INTERMEDIATE
    local -r KEYPASSWORD=$INTERMEDIATEKEYPASSWD
    local -r INSSLCNF=$INTERMEDIATESSL
    local -r PREFIX=$INTERMEDIATENAME
    local -r SUB=$INTERMEDIATESUB
    createcadir $DIR
    createdirs $DIR
    createopenssl $CURRENTDIR/$INSSLCNF $DIR
    createkey $DIR $PREFIX $KEYPASSWORD
    createintermediatecert
}

correctuniq() {
    echo "unique_subject = $UNIQ" >$INDEXATTR
}

createca() {
    createrootca
    createintermediateca
    correctuniq
}

printdata() {
    echo "Creates certification center"
    echo "Uniqe certificates $UNIQ"
    echo " Directory for certificates: $DIRCA"
    echo "   Warning: previous content of $DIRCA will be removed !"
    echo " Root subject: $ROOTSUB"
    echo " Root password: XXXXXX"
    echo " Intermediate subject: $INTERMEDIATESUB"
    echo " Intermediate password: XXXXXXX"
}

# ==========================
# certficates routines
# ==========================

### --- FUNCTION -----------------------
### extractcertname
### Extract file/certficate name from index.txt file
### Parameters:
###   $1 : identifier
### Result:
###  Set to FILENAME variable
### -------------------------------------
extractcertname() {
    local -r NUM=$1
    FILENAME=`cat $INDEXDB | cut -f 4,6 | grep $NUM | sed -E 's/.*CN=(.*)/\1/' ` 
    [ -z "$FILENAME" ] && logfail "$NUM - cannot find the certficate number in $INDEXDB"
}

movecertificate() {
    local -r TKEY=$1
    local -r TCSR=$2
    local -r TCERT=$3
    local -r OUTFILE=$4
    local -r LASTNUM=`tail -n 1 $INDEXDB | cut -f 4`
    local -r CERTNAME=`tail -n 1 $INDEXDB | cut -f 6 | sed -E 's/.*CN=(.*)/\1/' `
    local -r DIR=$DIRCA/$INTERMEDIATE

    local -r  CERTDIR=$DIR/private/$LASTNUM
    mkdir -p  $CERTDIR

    [ -z "$TKEY" ] || mv $TKEY  $CERTDIR/$CERTNAME.key.pem
    mv $TCSR  $CERTDIR/$CERTNAME.csr.pem
    mv $TCERT $CERTDIR/$CERTNAME.cert.pem
    if [ -n "$OUTFILE" ]; then
       genzipfile $LASTNUM $OUTFILE
    fi
    log "NUM=$LASTNUM"
}

genzipfile() {
    local -r NUM=$1
    local -r RESULTFILENAME=$2

    local -r TEMPDIR=`mktemp -d`
    local -r DIR=$DIRCA/$INTERMEDIATE
    local -r DIRC=$DIR/private/$NUM
    cp $DIRC/* $TEMPDIR
    # include root and intermediate
    cp $CACHAIN $TEMPDIR
    rm -f $RESULTFILENAME
    zip -j $RESULTFILENAME $TEMPDIR/*
    [ $? -eq 0 ] || logfail "zip command filed"
    rm -rf $TEMPDIR
    log "$RESULTFILENAME created."
}


genp12() {
    local -r NUM=$1
    local -r PASS="$2"
    local -r DIRC=$DIRCA/$INTERMEDIATE/private/$NUM

    # look for CN name
    extractcertname $NUM
    local -r KEYPEM=$DIRC/$FILENAME.key.pem
    local -r CERTPEM=$DIRC/$FILENAME.cert.pem
    existfile $KEYPEM
    existfile $CERTPEM

    local -r OUTP12=/tmp/$FILENAME.p12

    openssl pkcs12 -export -in $CERTPEM  -inkey $KEYPEM -out $OUTP12 -password pass:$PASS
    [ $? -eq 0 ] || logfail "Failed to create $FILENAME.p12 file"
    echo "OUT=$OUTP12"
}

createcertfromcsr() {
    local -r CSRFILE=$1
    local -r CERTFILE=$2
    local -r DIR=$DIRCA/$INTERMEDIATE
    openssl ca -config $DIR/$OPENSSL -passin pass:$INTERMEDIATEKEYPASSWD -extensions server_cert -days 375 -notext -md sha256 -in $CSRFILE -out $CERTFILE -batch
    [ $? -eq 0 ] || logfail "Failed to create a CERT $CERTFILE"
    xchmod 444 $CERTFILE
    # verify the certificate
    openssl verify -CAfile $CACHAIN $CERTFILE
    [ $? -eq 0 ] || logfail "$CACHAIN, the verification of $CERTFILE failed"
}

csrcreatecertficate() {
    local -r CSRFILE=`mktemp`
    local -r CERTFILE=`mktemp`
    cp $1 $CSRFILE
    local -r OUTFILE=$2
    createcertfromcsr $CSRFILE $CERTFILE
    movecertificate "" $CSRFILE $CERTFILE $OUTFILE
}

createcertificate() {
    local -r CERTSUBJ="$1"
    local -r OUTFILE=$2
    local -r DIR=$DIRCA/$INTERMEDIATE
    local -r CERTKEY=`mktemp`
    local -r CSRFILE=`mktemp`
    local -r CERTFILE=`mktemp`
    rm -f $CERTKEY
    openssl genrsa -out $CERTKEY 2048
    [ $? -eq 0 ] || logfail "Failed to create a key $CERTKEY"
    xchmod 400 $CERTKEY
    openssl req -config $DIR/$OPENSSL -key $CERTKEY -new -sha256 -out $CSRFILE -subj "$CERTSUBJ"
    [ $? -eq 0 ] || logfail "Failed to create a CSR and KEY $CSRNAME for $CERTSUBJ"
    createcertfromcsr $CSRFILE $CERTFILE
    movecertificate $CERTKEY $CSRFILE $CERTFILE $OUTFILE
}

# ==============================
# main
# ==============================

printhelp() {
    echo "Parameters"
    echo
    echo "./ca.sh create safe"
    echo "  Creates new certificate center using verbose output. Requires confirmation before proceeding"
    echo "./ca.sh create force"
    echo "  Creates new certificate center without warning. Previous certificate center is removed without confirmation"
    echo
    echo "./ca.sh makecert certsub /optional file name/"
    echo "  Produces signed certificate for the subject provided"
    echo "    certsub : certificate subject"
    echo "    /optional file name/ : if exist, the key, certificate and chain certfificate is compressed in the file name provided"
    echo "  Example:"
    echo "./ca.sh makecert /C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com"
    echo
    echo "./ca.sh makep12 num password"
    echo "  Produce p12 file from existing key and certificate"
    echo "  The p12 file is generated to /tmp/certname.p12 file"
    echo "    num : number of the certificate"
    echo "    password : password to encrypt p12 file"
    echo "  Example:"
    echo "./ca.sh makep12 1003 secret"
    echo
    echo "./ca.sh csrcert /csr file/ /optional file name/"
    echo "    /csr file/ CSR file"
    echo "    /optional file name/ : if exist, the certificate (without key) and chain certfificate is compressed in the file name provided"
    echo " Produces signed certficate from CSR file"
    echo " Example:"
    echo "./ca.sh csrcert ./bigsql.csr"
    echo "./ca.sh csrcert ./bigsql.csr /tmp/cert.zip"

    exit 4
}

main() {

    required_listofvars "DIRCA ROOTKEYPASSWORD ROOTSUB INTERMEDIATESUB INTERMEDIATEKEYPASSWD UNIQ"

    local -r par1=$1
    local -r par2=$2
    local -r par3="$3"
    local -r par4="$4"

    case $par1 in
    create) 
        case $par2 in
            safe|force) 
                printdata
                if [ $2 == "safe" ]; then 
                    read -p "Create new CA center (Yy) ?" -n 1 -r
                    echo    # (optional) move to a new line
                    if ! [[ $REPLY =~ [Yy] ]] ; then exit 4; fi
                fi
                createca;;
            *)  printhelp;;
        esac
        ;;
    makecert) 
        [ -z "$par2" ] && printhelp
        createcertificate "$par2" $par3
        ;;
    makep12) 
        [ -z "$par2" ] || [ -z "$par3" ] && printhelp
        genp12 $par2 $par3 
        ;;
    csrcert)
        [ -z "$par2" ] && printhelp
        csrcreatecertficate $par2 $par3
        ;;
    *) printhelp;;
    esac
}

 main "$1" "$2" "$3" "$4"

