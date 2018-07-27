# Bootstrap
Bootstraps MacOS and RedHat-based distros.

## Bootstrap

### AWS

The AWS script acts as a wrapper to create and grant `sudo` access to `[username]`. It then runs the regular bootstrap script as the new user.

`curl -fsSL https://bradleyfrank.github.io/bootstrap/aws.sh | sudo bash -s -- -u [username]`

### Linux & MacOS

`curl -fsSL https://bradleyfrank.github.io/bootstrap/bootstrap.sh | bash [-s -- [-t | -u | [-x acgprsuy] | -p]]`

* `-t` dumb terminal mode; implies `-x gprsu`
* `-u` user mode; implies `-x pru`
* `-x` except mode: skip the following actions(s):
  * `a`    granting nopasswd privileges [MacOS, Linux]
  * `c`    cloning utility repos (themes, etc) [MacOS, Linux]
  * `g`    adding ssh remote origin to dotfiles repo [MacOS, Linux]
  * `p`    installing system packages [Linux]
  * `r`    adding repos [Linux]
  * `s`    generating SSH keys [MacOS, Linux]
  * `u`    any sudo command [Linux]
  * `y`    installing python packages [MacOS, Linux]
* `-p` run post-bootstrap installs [MacOS]

## Post Bootstrap

### MacOS

The post-bootstrap script can be run separately:

`curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash`