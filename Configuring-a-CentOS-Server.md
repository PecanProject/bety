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

###Site data installation

```
cd /usr/local/ebi

rm -rf sites
curl -o sites.tgz http://isda.ncsa.illinois.edu/~kooper/EBI/sites.tgz
tar zxf sites.tgz
sed -i -e "s#/home/kooper/projects/EBI#${PWD}#" sites/*/ED_MET_DRIVER_HEADER
rm sites.tgz

rm -rf inputs
wget http://isda.ncsa.illinois.edu/~kooper/EBI/inputs.tgz
tar zxf inputs.tgz
rm inputs.tgz
```

###Database Creation

```
#sets up the user for the bety database
mysql -u root -p -e "grant all on bety.* to bety@localhost identified by 'bety';"
wget -O /usr/local/ebi/updatedb.sh http://isda.ncsa.illinois.edu/~kooper/EBI/updatedb.sh
chmod 755 /usr/local/ebi/updatedb.sh
```

Open up updatedb.sh and remove the two lines

```
#change to home
cd
```

If these are left in, the script will attempt to put the site data in ~/sites instead of /usr/local/ebi/sites.

```
#fetch and updates the bety database
./updatedb.sh
```

###Ruby installation
The version of ruby available through yum is too low, so we have to install from source:
```
wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p330.tar.gz
tar -xzf ruby-1.8.7-p330.tar.gz
cd ruby-1.8.7-p330
./configure
make 
make install
#make install didn't take, also broke gem, etc. Trying RVM
```

Up next install required ruby-related packages.
```
yum install rubygems
```
Then all the ruby gems bety needs.
```
cd bety
gem install bundler
bundle install
```