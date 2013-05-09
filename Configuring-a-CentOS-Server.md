### Overview

BETYdb runs on a Red Hat Enterprise Linux version 5.8 Server. To simulate this environment, we have set up a CentOS 5.8 server at pecandev.igb.illinois.edu for testing 

### Create an netinstall of the CentOS ISO 

### Boot from CD and Install 

* Following instructions here: http://www.if-not-true-then-false.com/2010/centos-netinstall-network-installation/
* Download this iso: http://vault.centos.org/5.8/isos/x86_64/CentOS-5.8-x86_64-netinstall.iso
 * it is the "netinstall" version, small enough to fit on a CD, but requires internet to install
 * burn to CD
 * boot from CD
* ftp server: `vault.centos.org`
* directory: `/centos/5.8/os/x86_64`

### Configuration

1. Add new user
 ```
adduser johndoe
 ```
2. add user to root
 ```
sudo su
emacs /etc/sudoers
 ```
3. add the line 
```
johndoe  ALL=(ALL)  ALL
```

### Add new repository

instructions here: http://www.rackspace.com/knowledge_center/article/installing-rhel-epel-repo-on-centos-5x-or-6x

```
wget http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
sudo rpm -Uvh epel-release-5*.rpm
```

... move to PEcAn wiki page for build environment https://github.com/PecanProject/pecan/wiki/Development-Environment-Setup-and-VM-Creation#install-build-environment
 
