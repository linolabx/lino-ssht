#!/usr/bin/env bash

ssssh() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 3322 "$@"
}

# start http server
mkdir -p unit-test/web
echo -n "hello" > unit-test/web/index.html
screen -S ssht-server -d -m bash -c "cd unit-test/web && python3 -m http.server 3380"

# forward local 3380 to remote 3380
ssssh -N -R 3380:localhost:3380 -i unit-test/ssht ssht@localhost

# forward remote 3380 to local 3381
ssssh -N -L 3381:localhost:3380 -i unit-test/sshm sshm@localhost
