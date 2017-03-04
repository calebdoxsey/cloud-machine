#!/bin/bash

# In User Data do:

# #!/bin/bash
# export NOMAD_VERSION=0.5.4
# curl https://raw.githubusercontent.com/calebdoxsey/cloud-machine/master/nomad-server.bash | sudo -E /bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

if [ -z "${NOMAD_VERSION}" ] ; then
  echo "NOMAD_VERSION is required"
  exit 1
fi

echo "[install] installing nomad"
cd /tmp
curl -O -L https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad_${NOMAD_VERSION}_linux_amd64.zip
mv nomad /usr/bin/nomad
rm nomad_${NOMAD_VERSION}_linux_amd64.zip

mkdir -p /etc/nomad
cat <<EOF > /etc/nomad/server.hcl
server {
  enabled          = true
  bootstrap_expect = 3
}
EOF

cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/

[Service]
ExecStart=/usr/bin/nomad agent -config /etc/nomad
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "[install] starting nomad"
systemctl daemon-reload 
systemctl enable nomad
systemctl start nomad

