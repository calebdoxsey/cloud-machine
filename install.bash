#!/bin/bash

# In User Data do: 

# #!/bin/bash
# export CF_TOKEN=...
# curl https://raw.githubusercontent.com/calebdoxsey/cloud-machine/master/install.bash | /bin/bash

apt-get update
apt-get install -y curl git gcc

# ==========
# update DNS
# ==========
CF_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")
CF_EMAIL=caleb@doxsey.net
CF_ZONE=030188de42fc070c97e66dbed6277be3
CF_ID=dbb50b76fb8cfa1d55ccc43326385a2e

curl -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records/$CF_ID" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
      "id": "'$CF_ID'",
      "type": "A",
      "name": "www.badgerodon.com",
      "content": "'$CF_IP'",
      "proxiable": true,
      "proxied": false,
      "ttl": 1,
      "locked": false,
      "zone_id": "'$CF_ZONE'",
      "zone_name": "badgerodon.com"
    }'

# ==========
# install Go
# ==========
export GOPATH=/usr/local
go version
if [ "$?" -ne 0 ] ; then
	export PATH=$PATH:/usr/local/go/bin
fi
if [ "$(go version)" != "go version go1.6 linux/amd64" ] ; then
	pushd /usr/local

	rm -rf go
	curl -L https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz | tar -xz

	popd
fi

# ======================
# install badgerodon/www
# ======================
go get -x -u -d github.com/badgerodon/www
go build -x -i -o /usr/local/bin/badgerodon-www github.com/badgerodon/www
cat << EOF > /etc/systemd/system/badgerodon-www.service
[Unit]
Description=badgerodon-www

[Service]
ExecStart=/usr/local/bin/badgerodon-www
WorkingDirectory=/usr/local/src/github.com/badgerodon/www
Restart=always
Environment=PORT=9001

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badgerodon-www
systemctl start badgerodon-www

#==============
# install caddy
#==============
if [ "$(caddy -version)" != "Caddy 0.8.2" ] ; then
	pushd /usr/local/bin

	curl -L 'https://github.com/mholt/caddy/releases/download/v0.8.2/caddy_linux_amd64.tar.gz' | tar -xz

	popd
fi
mkdir -p /etc/caddy
cat << EOF > /etc/caddy/caddy.conf
www.badgerodon.com {
	proxy / localhost:9001
}
EOF
cat << EOF > /etc/systemd/system/caddy.service 
[Unit]
Description=caddy 

[Service]
ExecStart=/usr/local/bin/caddy -agree -conf /etc/caddy/caddy.conf -email 'caleb@doxsey.net'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable caddy
systemctl start caddy
