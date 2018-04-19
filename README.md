# Bootstrap
Bootstraps MacOS and RedHat-based distros.

## Pre Bootstrap

### Linux
`sudo bash -c "echo '%wheel  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

### MacOS
`sudo bash -c "echo '%admin  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

## Bootstrap

`curl -fsSL https://bradleyfrank.github.io/bootstrap/bootstrap.sh | bash [-s -- -u | [-x s]]`

* `-u` user mode: skips any command that executes with sudo; i.e. should only affect user profile.
* `-x` except mode: skips specific bootstrap sections:
	* `s` creating ssh keys

## Post Bootstrap

### MacOS
`curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash [-s -- -n [hostname]]`