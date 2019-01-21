#!/bin/bash

# variables
appPrefix=arqonia

keyStore=${appPrefix}_https.jks
alias=${appPrefix}_https
password=pass123
csrFile=ca/${appPrefix}_https.csr

caCertificate=ca/${appPrefix}_ca_certificate.pem
caKey=ca/private/${appPrefix}_ca_key.pem

certificateName=ca/${appPrefix}_https_certificate.cer

# to be sure, that all previous files are removed from working directory
rm ${appPrefix}* ca/private/${appPrefix}*

# generate JKS keystore with appropriate name and alias and secured with password
keytool -keystore ${keyStore} -genkey -dname "CN=arqonia.pl, OU=Arqonia, O=Arqonia, L=Poznan, ST=Wielkopolska, C=PL" \
    -alias ${alias} -storepass ${password} -keypass ${password}

# generate the Certificate Signing Request (.csr)
keytool -keystore ${keyStore} -certreq -alias ${alias} -keyalg rsa -storepass ${password} -keypass ${password} -file ${csrFile}

# create directory for CA private key
mkdir ca/private

# create a CA certificate
openssl req -new -x509 -days 3650 -extensions v3_ca \
    -subj "/C=PL/ST=Wielkopolska/L=Poznan/O=Arqonia/OU=Arqonia/CN=arqonia.pl" \
    -passout pass:${password} -keyout ${caKey} -out ${caCertificate}

# generate a signed certificate for the associated Certificate Signing Request (.csr)
openssl x509 -req -CA ${caCertificate} -CAkey ${caKey} \
    -passin pass:${password} -in ${csrFile} -out ${certificateName} -days 3650 -CAcreateserial

# import the CA certificate into the client keystore
keytool -noprompt -import -keystore ${keyStore} -file ${caCertificate} -alias theCARoot \
    -storepass ${password} -keypass ${password}

# import the signed certificate for the associated alias in the keystore
keytool -import -keystore ${keyStore} -file ${certificateName} -alias ${alias} \
    -storepass ${password} -keypass ${password}