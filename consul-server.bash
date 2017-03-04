#!/bin/bash

# In User Data do:

# #!/bin/bash
# export ATLAS_USERNAME=...
# export ATLAS_TOKEN=...
# export CONSUL_VERSION=0.7.5
# curl https://raw.githubusercontent.com/calebdoxsey/cloud-machine/master/consul-server.bash | sudo -E /bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

if [ -z "${ATLAS_USERNAME}" ] ; then
  echo "ATLAS_USERNAME is required"
  exit 1
fi

if [ -z "${ATLAS_TOKEN}" ] ; then
  echo "ATLAS_TOKEN is required"
  exit 1
fi

if [ -z "${CONSUL_VERSION}" ] ; then
  echo "CONSUL_VERSION is required"
  exit 1
fi

apt-get install -y curl unzip

echo "[install] installing consul"
cd /tmp
curl -O -L https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
mv consul /usr/bin/consul
rm consul_${CONSUL_VERSION}_linux_amd64.zip

cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=consul

[Service]
ExecStart=/usr/bin/consul agent -server \
  -data-dir="/tmp/consul" \
  -bootstrap-expect 3 \
  -atlas=${ATLAS_USERNAME}/infrastructure \
  -atlas-join \
  -atlas-token="${ATLAS_TOKEN}"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[install] starting consul"
systemctl daemon-reload 
systemctl enable consul
systemctl start consul

