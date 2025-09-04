#!/usr/bin/env bash

set -e

failexit() {
    echo "Failed: $1"
    exit 1
}

failcleanup() {
    echo "============= Cleanup Start ============="
    docker rm -f ssht-test || true
    sudo rm -rf unit-test || true
    echo "============== Cleanup End =============="
}
trap failcleanup EXIT

docker build -t ssht .
mkdir unit-test

ssh-keygen -f unit-test/ssht -N "" -q
ssh-keygen -f unit-test/sshm -N "" -q

runssht() {
    docker run --name ssht-test --rm -d \
        -v "$PWD"/unit-test/host_keys:/etc/ssht/host_keys \
        -v "$PWD"/unit-test/ssht.pub:/ssht.pub \
        -v "$PWD"/unit-test/sshm.pub:/sshm.pub \
        -p 3322:22 \
        ssht
}

ssssh() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 3322 "$@"
}

echo "test host keys generation"
mkdir -p unit-test/host_keys
runssht

echo sleep 5
sleep 5
[[ $(docker inspect ssht-test --format '{{.State.Running}}') == "true" ]] || failexit "service should be running"

docker rm -f ssht-test
sleep 1
find unit-test | grep ssh_host_rsa_key || failexit "ssh_host_rsa_key should be generated"

runssht
sleep 1
[[ $(docker exec ssht-test md5sum /etc/ssh/ssh_host_rsa_key | cut -d ' ' -f 1) == $(sudo md5sum unit-test/host_keys/ssh_host_rsa_key | cut -d ' ' -f 1) ]] \
    || failexit "ssh_host_rsa_key should reload"

echo "ssht user should not exec command"
ssssh -i unit-test/ssht -l ssht localhost "true" && failexit "ssht user should not exec command"

echo "sshm user should exec command"
ssssh -i unit-test/sshm -l sshm localhost "true" || failexit "sshm user should exec command"

read -r -d '' _ </dev/tty
