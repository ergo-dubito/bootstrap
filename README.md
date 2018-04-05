# Bootstrap
Bootstraps MacOS and RedHat-based distros.

## Pre Bootstrap

### Linux
`sudo bash -c "echo '%wheel  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

## Bootstrap

`curl -fsSL https://bradleyfrank.github.io/bootstrap/bootstrap.sh | bash`

## Post Bootstrap

### MacOS
`curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash [-s -- -n [hostname]]`