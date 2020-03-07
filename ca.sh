source ./env.rc

INTERMEDIATE=intermediate
CURRENTDIR=`realpath \`dirname $0\``
OPENSSL=openssl.cnf
INTERMEDIATESSL=intermediateopenssl.cnf
CACHAIN=$DIRCA/$INTERMEDIATE/certs/ca-chain.cert.pem
INDEXATTR=$DIRCA/$INTERMEDIATE/index.txt.attr 
INDEXDB=$DIRCA/$INTERMEDIATE/index.txt

ROOTNAME=ca
INTERMEDIATENAME=intermediate

log() {
    local -r MESS="$1"
    echo $MESS
}

logfail() {
    log "$1"
    exit 4
}

createcadir() {
    local -r DIR=$1
    rm -rf $DIR
    mkdir $DIR
}

xchmod() {
    local -r MOD=$1
    local -r FILE=$2
    chmod $MOD $FILE
    [ $? -eq 0 ] || logfail "Error while chmod $MOD $FILE"
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

required_var() {
  local -r VARIABLE=$1
  [ -z "${!VARIABLE}" ] && logfail "Need to set environment variable $VARIABLE"
}

required_listofvars() {
  local -r listv=$1
  for value in $listv; do required_var $value; done
}

movecertificate() {
    local -r CERTNAME=$1
    local -r TKEY=$2
    local -r TCSR=$3
    local -r TCERT=$4
    local -r LASTNUM=`tail -n 1 /home/sbartkowski/ca/intermediate/index.txt | cut -f 4`

    local -r  CERTDIR=$DIR/private/$LASTNUM
    mkdir -p  $CERTDIR

    mv $TKEY  $CERTDIR/$CERTNAME.key.pem
    mv $TCSR  $CERTDIR/$CERTNAME.csr.pem
    mv $TCERT $CERTDIR/$CERTNAME.cert.pem    
}

genp12() {
    local -r FILENAME="$1"
    local -r NUM=$2
    local -r PASS="$3"
    local -r DIRC=$DIRCA/$INTERMEDIATE/private/$NUM

    openssl pkcs12 -export -in $DIRC/$FILENAME.cert.pem  -inkey $DIRC/$FILENAME.key.pem -out /tmp/$FILENAME.p12 -password pass:$PASS
    [ $? -eq 0 ] || logfail "Failed to create $FILENAME.p12 file"
}

createcertificate() {
    local -r CERTNAME=$1
    local -r CERTSUBJ="$2"
    local -r DIR=$DIRCA/$INTERMEDIATE
    local -r CERTKEY=`mktemp`
    local -r CSRFILE=`mktemp`
    local -r CERTFILE=`mktemp`
    rm -f $CERTKEY
    openssl genrsa -out $CERTKEY 2048
    [ $? -eq 0 ] || logfail "Failed to create a key $CERTKEY"
    xchmod 400 $CERTKEY
    openssl req -config $DIR/$OPENSSL -key $CERTKEY -new -sha256 -out $CSRFILE -subj "$CERTSUBJ"
    [ $? -eq 0 ] || logfail "Failed to create a CSR $CSRNAME for $CERTSUBJ"
    rm -f $CERTFILE
    openssl ca -config $DIR/$OPENSSL -passin pass:$INTERMEDIATEKEYPASSWD -extensions server_cert -days 375 -notext -md sha256 -in $CSRFILE -out $CERTFILE -batch
    [ $? -eq 0 ] || logfail "Failed to create a CERT $CERTFILE"
    xchmod 444 $CERTFILE
    # verify the certificate
    openssl verify -CAfile $CACHAIN $CERTFILE
    [ $? -eq 0 ] || logfail "$CACHAIN, the verification of $CERTFILE failed"
    movecertificate $CERTNAME $CERTKEY $CSRFILE $CERTFILE
}

printhelp() {
    echo "Incorrect parameters"
    echo
    echo "./ca.sh create safe"
    echo "  Creates new certificate center using verbose output. Requires confirmation before proceeding"
    echo "./ca.sh create force"
    echo "  Creates new certificate center without warning. Previous certificate center is remove without confirmation"
    echo
    echo "./ca.sh makecert certname certsub"
    echo "  Produces certificate having the specified name and the subject provided"
    echo "    certname : certificate filename"
    echo "    certsub : certificate subject"
    echo "  Example:"
    echo "./ca.sh makecert www.example.com /C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com"
    echo
    echo "./ca.sh makep12 certname num password"
    echo "  Produce p12 file from existing key and certificate"
    echo "  The p12 file is generated to /tmp/certname.p12 file"
    echo "    certname : certficate file name"
    echo "    num : number of the certificate"
    echo "    password : password to encrypt p12 file"
    echo "  Example:"
    echo "./ca.sh makep12 www.example.com 1003 secret"

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
        [ -z "$par2" ] || [ -z "$par3" ] && printhelp
        createcertificate "$par2" "$par3"
        ;;
    makep12) 
        [ -z "$par2" ] || [ -z "$par3" ] || [ -z "$par4" ] && printhelp
        genp12 $par2 $par3 "$par4"
        ;;          
    *) printhelp;;
    esac
}

main "$1" "$2" "$3" "$4"