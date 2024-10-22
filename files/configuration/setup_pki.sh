if [ ! -f "$PKI_DIR/issued/server.crt" ] || [ "$REGENERATE_CERTS" == 'true' ]; then
 echo "easyrsa: creating server certs"
 sed -i 's/^RANDFILE/#RANDFILE/g' /opt/easyrsa/openssl-easyrsa.cnf
 EASYCMD="/opt/easyrsa/easyrsa"
 . /opt/easyrsa/pki_vars
 
 export EASYRSA_REQ_CN="$OVPN_SERVER_CN"
 
 $EASYCMD init-pki
 $EASYCMD build-ca nopass
 $EASYCMD gen-dh
 openvpn --genkey secret $PKI_DIR/ta.key
 $EASYCMD build-server-full server nopass
fi
