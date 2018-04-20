# Bootstrap
Bootstraps MacOS and RedHat-based distros.

## Pre Bootstrap

### Linux
`sudo bash -c "echo '%wheel  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

### MacOS
`sudo bash -c "echo '%admin  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"`

## Bootstrap

`curl -fsSL https://bradleyfrank.github.io/bootstrap/bootstrap.sh | bash [-s -- -u | [-x s]]`

* `-t` dumb terminal mode; implies `-x gprsu`
* `-u` user mode; implies `-x pru`
* `-x` except mode: skip the following actions(s):
  * `g`    adding ssh remote origin to dotfiles repo [MacOS, Linux]
  * `p`    installing system packages [Linux]
  * `r`    adding repos [Linux]
  * `s`    generating SSH keys [MacOS, Linux]
  * `u`    any sudo command [Linux]
  * `y`    installing python packages [MacOS, Linux]

## Post Bootstrap

### MacOS
`curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash [-s -- -n [hostname]]`