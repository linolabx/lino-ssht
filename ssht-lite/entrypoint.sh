#!/usr/bin/env bash

set -ex

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

random_pass() { openssl rand -hex 16; }

SSHT_USER_NAME=${SSHT_USER_NAME:-"ssht"}
SSHT_USER_PASS=${SSHT_USER_PASS:-$(random_pass)}
SSHT_PUB_KEY_FILE=${SSHT_PUB_KEY_FILE:-"/ssht.pub"}
SSHT_PUB_KEY=${SSHT_PUB_KEY:-$(cat "${SSHT_PUB_KEY_FILE}" 2>/dev/null || true)}

SSHM_USER_NAME=${SSHM_USER_NAME:-"sshm"}
SSHM_USER_PASS=${SSHM_USER_PASS:-$(random_pass)}
SSHM_PUB_KEY_FILE=${SSHM_PUB_KEY_FILE:-"/sshm.pub"}
SSHM_PUB_KEY=${SSHM_PUB_KEY:-$(cat "${SSHM_PUB_KEY_FILE}" 2>/dev/null || true)}

if [[ -z "${SSHT_PUB_KEY}" ]]; then
    echo "SSHT_PUB_KEY is not set"
    exit 1
fi

if [[ -z "${SSHM_PUB_KEY}" ]]; then
    echo "SSHM_PUB_KEY is not set"
    exit 1
fi

# create mgmt user sshm
if ! id -u "${SSHM_USER_NAME}" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "${SSHM_USER_NAME}"
    echo "${SSHM_USER_NAME}:${SSHM_USER_PASS}" | chpasswd
    mkdir -p "/home/${SSHM_USER_NAME}/.ssh"
    echo "${SSHM_PUB_KEY}" >"/home/${SSHM_USER_NAME}/.ssh/authorized_keys"
    chmod 600 "/home/${SSHM_USER_NAME}/.ssh/authorized_keys"
    chown -R "${SSHM_USER_NAME}:${SSHM_USER_NAME}" "/home/${SSHM_USER_NAME}/.ssh"
fi

# create port forward only user ssht
if ! id -u "${SSHT_USER_NAME}" >/dev/null 2>&1; then
    useradd -m -s /usr/sbin/nologin "${SSHT_USER_NAME}"
    echo "${SSHT_USER_NAME}:${SSHT_USER_PASS}" | chpasswd
    mkdir -p "/home/${SSHT_USER_NAME}/.ssh"
    echo "${SSHT_PUB_KEY}" >"/home/${SSHT_USER_NAME}/.ssh/authorized_keys"
    chmod 600 "/home/${SSHT_USER_NAME}/.ssh/authorized_keys"
    chown -R "${SSHT_USER_NAME}:${SSHT_USER_NAME}" "/home/${SSHT_USER_NAME}/.ssh"
fi

if [[ ! -f "/etc/ssh/ssh_host_rsa_key" ]]; then
    if [[ -f "/etc/ssht/host_keys/ssh_host_rsa_key" ]]; then
        cp /etc/ssht/host_keys/ssh_host_* /etc/ssh/
    else
        dpkg-reconfigure openssh-server
        cp /etc/ssh/ssh_host_* /etc/ssht/host_keys/
    fi
    chmod 600 /etc/ssh/ssh_host_*
    chown root:root /etc/ssh/ssh_host_*
fi

cat <<EOF >/etc/ssh/sshd_config.d/ssht-user.conf
Match User ${SSHT_USER_NAME}
    AllowTcpForwarding yes
    X11Forwarding no
    AllowAgentForwarding no
    ForceCommand /bin/false
EOF

echo "ssht: ${SSHT_USER_PASS}"
echo "sshm: ${SSHM_USER_PASS}"

exec /usr/sbin/sshd -D -e
