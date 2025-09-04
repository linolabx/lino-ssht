FROM buildpack-deps:bookworm

RUN <<EORUN
#!/bin/bash -ex

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update
apt-get full-upgrade -y
apt-get install -y apt-transport-https

apt-get install -y curl wget git ca-certificates build-essential gnupg dirmngr sudo --no-install-recommends

# Install openssh-server
apt-get install -y openssh-server openssh-client
rm -f /etc/ssh/ssh_host_*

# Clean up
rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*
EORUN

RUN <<EORUN
#!/bin/bash -ex

sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config || true
sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config || true
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config || true

cat <<EOF >/etc/ssh/sshd_config.d/ssht.conf
PubkeyAuthentication yes
PermitRootLogin no
PasswordAuthentication yes
EOF

install -m 750 -o root -g root -d /var/run/sshd

rm -f /etc/update-motd.d/* || true

cat <<EOF >/etc/motd
_____ ______   __________ __  ________
/ ___// ____/  / ___/ ___// / / /_  __/
\__ \/ /_      \__ \\__ \/ /_/ / / /   
___/ / __/     ___/ /__/ / __  / / /    
/____/_/       /____/____/_/ /_/ /_/     
EOF

EORUN

VOLUME /etc/ssht/host_keys
ADD --chown=root:root --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
