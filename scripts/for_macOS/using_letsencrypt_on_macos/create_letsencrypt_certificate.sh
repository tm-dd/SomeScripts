#!/bin/bash
#
# with commands from: https://community.letsencrypt.org/t/complete-guide-to-install-ssl-certificate-on-your-os-x-server-hosted-website/15005
#
# Copyright (c) 2022 tm-dd (Thomas Mueller) and maybe others
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

DOMAIN_DEFAULT='server1.example.org'
DOMAINS_CERT='server1.example.org server2.example.org'
WEBROOT_PATH='/Library/Server/Web/Data/Sites/Default/'
CONFIG_DIR='/Users/admin/letsencrypt'
PEM_DIR="/etc/letsencrypt/live/${DOMAIN_DEFAULT}"
RSA_SIZE='4096'
CONTACT_EMAIL='contact@example.org'

mkdir -p "$CONFIG_DIR" "$WEBROOT_PATH/.well-known/acme-challenge"
echo "Success" >> "$WEBROOT_PATH/.well-known/acme-challenge/test.html"

cat <<END >> "${CONFIG_DIR}/cert.ini"
rsa-key-size = $RSA_SIZE
email = $CONTACT_EMAIL
domains = $DOMAINS_CERT
authenticator = webroot
webroot-path = $WEBROOT_PATH
END

# try run
echo "TRY RUN: creating the certificate"
sudo rm /var/log/letsencrypt/letsencrypt.log
sudo certbot certonly -c "${CONFIG_DIR}/cert.ini" --dry-run
echo -n "Press ENTER to continue ..."; read; echo

# create certificate
echo "REAL RUN: creating the certificate"
sudo certbot certonly -c "${CONFIG_DIR}/cert.ini"
echo -n "Press ENTER to continue ..."; read; echo

# create a password
echo "CREATE RANDOM NUMBER"
PASS=$(openssl rand -base64 48 | tr -d /=+ | cut -c -30)
echo "CREATED PASS: $PASS"; echo

# convert pem to p12
echo "CREATE MORE SSL FILES"
sudo mkdir -p /usr/local/letsencrypt/live/${DOMAIN_DEFAULT}
sudo openssl pkcs12 -export -inkey "${PEM_DIR}/privkey.pem" -in "${PEM_DIR}/cert.pem" -certfile "${PEM_DIR}/fullchain.pem" -out "${PEM_DIR}/letsencrypt_sslcert.p12" -passout pass:$PASS
echo -n "Press ENTER to continue ..."; read; echo

# import p12 in keychain
echo "IMPORT CERTIFICATE"
sudo security import "${PEM_DIR}/letsencrypt_sslcert.p12" -f pkcs12 -k /Library/Keychains/System.keychain -P $PASS -T /Applications/Server.app/Contents/ServerRoot/System/Library/CoreServices/ServerManagerDaemon.bundle/Contents/MacOS/servermgrd

# change ownership
sudo chown -R admin:staff /etc/letsencrypt/archive

# some notes
echo -e "\nHOPEFULLY CREATED FILES in /etc/letsencrypt/live/${DOMAIN_DEFAULT}:\n"
sudo ls -l /etc/letsencrypt/live/${DOMAIN_DEFAULT}
echo -e "\nPLEASE CHANGE THE SERVICE PROFILEMANAGER TO USE THE NEW CERTIFICATE IN THE SERVER.APP NOW AND RESTART IT.\n"

exit 0
