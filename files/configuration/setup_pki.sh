if [ ! -f "$PKI_DIR/issued/server.crt" ] || [ "$REGENERATE_CERTS" == 'true' ]; then
 echo "easyrsa: creating server certs"
 sed -i 's/^RANDFILE/#RANDFILE/g' /opt/easyrsa/openssl-easyrsa.cnf
 EASYCMD="/opt/easyrsa/easyrsa"
 . /opt/easyrsa/pki_vars
 
 $EASYCMD init-pki
 $EASYCMD --req-cn="$OVPN_SERVER_CN" build-ca nopass
 $EASYCMD gen-dh
 openvpn --genkey secret $PKI_DIR/ta.key
 $EASYCMD build-server-full server nopass
fi
$EASYCMD --req-cn="$OVPN_SERVER_CN" build-ca nopass