#Create the VPN tunnel interface
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
  mknod /dev/net/tun c 10 200
fi

ovpn_net_net=$(echo ${OVPN_NETWORK} | awk '{ print $1 }')
ovpn_net_cidr=$(ipcalc -nb ${OVPN_NETWORK} | grep ^Netmask | awk '{ print $NF }')
ovpn_net="${ovpn_net_net}/${ovpn_net_cidr}"
export this_natdevice=$(route | grep '^default' | grep -o '[^ ]*$')

# Handle remote routes (push to clients)
if [ "${OVPN_REMOTE_ROUTES}x" != "x" ]; then
  IFS=","
  read -r -a remote_route_list <<<"$OVPN_REMOTE_ROUTES"
  echo "" >/tmp/routes_config.txt
  for this_route in ${remote_route_list[@]}; do
    echo "routes: adding remote route $this_route to server config"
    echo "push \"route $this_route\"" >>/tmp/routes_config.txt
  done
  IFS=" "
fi

# Handle local routes (server-side routes without push)
if [ "${OVPN_LOCAL_ROUTES}x" != "x" ]; then
  IFS=","
  read -r -a local_route_list <<<"$OVPN_LOCAL_ROUTES"
  for this_route in ${local_route_list[@]}; do
    echo "routes: adding local route $this_route to server config"
    echo "route $this_route" >>/tmp/routes_config.txt
  done
  IFS=" "
fi

# Add redirect-gateway if enabled
if [ "${OVPN_REDIRECT_GATEWAY}" == "true" ]; then
  echo "Adding redirect-gateway directive"
  echo "push \"redirect-gateway def1\"" >>/tmp/routes_config.txt
fi

if [ "$OVPN_NAT" == "true" ]; then
  echo "iptables: masquerade from $ovpn_net to everywhere via $this_natdevice"
  echo -n "iptables: "
  if iptables -t nat -C POSTROUTING -s "$ovpn_net" -o "$this_natdevice" -j MASQUERADE > /dev/null 2>&1; then
    echo "Rule already present. Skipping..."
  else
    echo "Rule missing. Creating rule..."
    iptables -t nat -A POSTROUTING -s "$ovpn_net" -o "$this_natdevice" -j MASQUERADE
  fi
fi

# Append extra iptables rules from a file if specified
if [ "${IPTABLES_EXTRA_FILE}x" != "x" ]; then
  if [ -f "$IPTABLES_EXTRA_FILE" ]; then
    echo "IPTABLES_EXTRA_FILE was set, appending iptables rules from $IPTABLES_EXTRA_FILE"
    iptables-restore -nv "$IPTABLES_EXTRA_FILE"
  else
    echo "IPTABLES_EXTRA_FILE was set but the specified file $IPTABLES_EXTRA_FILE cannot be found!"
  fi
fi