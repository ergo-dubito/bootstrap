# Bootstrap
Bootstraps MacOS and RedHat-based distros.

## Pre Bootstrap

### Linux
`sudo bash -c "echo '%wheel  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

### MacOS
`sudo bash -c "echo '%admin  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

## Bootstrap

`curl -fsSL https://bradleyfrank.github.io/bootstrap/bootstrap.sh | bash [-s -- -u]`

* `-u` user mode: skips any command that executes with sudo; i.e. should only affect user profile.

## Post Bootstrap

### MacOS
`curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash [-s -- -n [hostname]]`