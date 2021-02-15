[Snort](https://www.snort.org/snort3) is a open source Network Intrusion Detection & Prevention system,
checkout the resources section on their page!

[Installation Guide for Snort 3.1.0.0](https://snort-org-site.s3.amazonaws.com/production/document_files/files/000/003/979/original/Snort3_3.1.0.0_on_Ubuntu_18___20.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXACIED2SPMSC7GA%2F20210215%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210215T132857Z&X-Amz-Expires=172800&X-Amz-SignedHeaders=host&X-Amz-Signature=b89786f8d04c6b5270176ad658bd6627a525427e05041d6cc819d0fb585817bd)

## Installation
```shell
sudo apt-get install -y build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev libpcap-dev \
zlib1g-dev pkg-config libhwloc-dev cmake liblzma-dev openssl libssl-dev cpputest libsqlite3-dev \
libtool uuid-dev git autoconf bison flex libcmocka-dev libnetfilter-queue-dev libunwind-dev \
libmnl-dev ethtool

mkdir snort_src
cd snort_src

wget -O- https://github.com/rurban/safeclib/releases/download/v02092020/libsafec-02092020.tar.gz | tar xz
cd libsafec-02092020.0-g6d921f
./configure
make
sudo make install
cd ..

wget -O- https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz | tar xz
cd pcre-8.44
./configure
make
sudo make install
cd ..

wget -O- https://github.com/gperftools/gperftools/releases/download/gperftools-2.8/gperftools-2.8.tar.gz | tar xz
cd gperftools-2.8
./configure
make
sudo make install
cd ..

wget -O- http://www.colm.net/files/ragel/ragel-6.10.tar.gz | tar xz
cd ragel-6.10
./configure
make
sudo make install
cd ..

wget -O- https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz | tar xz

wget https://github.com/intel/hyperscan/archive/v5.3.0.tar.gz | tar xz
mkdir hyperscan-5.3.0-build
cd hyperscan-5.3.0-build/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=../boost_1_74_0/ ../hyperscan-5.3.0
make
sudo make install
cd ..


wget -O- https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz | tar xz
mkdir flatbuffers-1.12.0/build
cd flatbuffers-1.12.0/build
cmake ..
make
sudo make install
cd ../..

wget -O- https://www.snort.org/downloads/snortplus/libdaq-3.0.0.tar.gz | tar xz
cd libdaq-3.0.0
./bootstrap
./configure
make
sudo make install
cd ..

sudo ldconfig

wget -O- https://www.snort.org/downloads/snortplus/snort3-3.1.0.0.tar.gz | tar xz
cd snort3-3.1.0.0
# installation guide does not enable: shell / large-pcap
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc --enable-shell --enable-large-pcap
cd build
make
sudo make install
cd ../..

cd ..
# due to the fact that the snort_src folder has arround 6 gb you may would like to delete it
#rm -r snort_src

/usr/local/bin/snort -V
if [ $? -eq 0 ]; then
  snort -c /usr/local/etc/snort/snort.lua
fi
```

!!! warning "Remove unused tools"
    I suggest you to remove all unnessesary tools, after compilation.
    If you have all bunch of compilers, language interpreters, and so on installed on your system,
    you might help a potential hacker who has access to your system to gain higher privileges.

## Configuration

### Network interfaces
The guide explains why you probally want to disable GRO (generic-receive-offload) and LRO (large-receive-offload)
on the network interfaces that are being monitored by snort.

You can disable them with the ethtool command, but you need to create a systemd job to do this after every boot:
1. Create the job `/lib/systemd/system/ethtool.service`
(don't forget to adjust the name of the network interface)
```ini
[Unit]
Description=ethtool configration for monitored network interfaces

[Service]
Requires=network.target
Type=oneshot
ExecStart=/sbin/ethtool -K eth0 gro off
ExecStart=/sbin/ethtool -K eth0 lro off

[Install]
WantedBy=multi-user.target
```
2. Enable to systemd job:
```
sudo systemctl enable --now ethtool
```

### Snort Ruleset
Next you need to get some rules, I'm going to use the registered ruleset.
Therefore you need to [create an account](https://www.snort.org/users/sign_up),
afterwards you can [download the rules](https://www.snort.org/downloads#rules).

!!! warning ""
    In the past, I simply downloaded the rule once, but there is a great tool for updating.

    I didn't really get the idea from the author of the installation guide,
    to put the rules directly in the etc directory. So I first tried to put them inside the snort directory.

    This resulted in an error so I tried to do it like he did, but i keep getting the same error.
    I created an [issue](https://github.com/shirkdog/pulledpork/issues/359) and will finish this entry when my snort instance is working correcly. Feel free to simply follow the installation guide, maybe I made a mistake somewhere.

#### Install
```shell
mkdir rules
cd rules
sudo apt-get install -y libcrypt-ssleay-perl liblwp-useragent-determined-perl
wget -O- https://github.com/shirkdog/pulledpork/archive/master.tar.gz | tar xz
sudo cp pulledpork-master/pulledpork.pl /usr/local/bin
sudo chmod +x /usr/local/bin/pulledpork.pl
sudo mkdir /usr/local/etc/pulledpork
sudo cp pulledpork-master/etc/*.conf /usr/local/etc/pulledpork

/usr/local/bin/pulledpork.pl -V
if [ $? -ne 0 ]; then
  read -p "Something went wrong [CTRL+C to exit; ENTER to continue]: "
fi

sudo mkdir /usr/local/etc/rules
sudo mkdir /usr/local/etc/so_rules/
sudo mkdir /usr/local/etc/lists/
sudo touch /usr/local/etc/rules/snort.rules
sudo touch /usr/local/etc/rules/local.rules
sudo touch /usr/local/etc/lists/default.blocklist
sudo mkdir /var/log/snort
```

#### Configure
Modify `/usr/local/etc/pulledpork/pulledpork.conf`:

* Replace `oinkcode` with your oinkcode (Snort Account -> Settings -> Oinkcode)
* Put `#` before community rules
* Set `rule_path` to `/usr/local/etc/rules/snort.rules`
* Set `local_rules` to `/usr/local/etc/rules/local.rules`
* Set `sid_msg_version` to `2`
* Set `sorule_path` to `/usr/local/etc/so_rules/`
* Set `distro` to to your matching distro (explained in the config) e.g. `Debian-10`
* Set `block_list` to `/usr/local/etc/lists/default.blocklist`
* Set `IPRVersion` to `/usr/local/etc/lists`
* Set `pid_path` to `/var/log/snort/snort.pid`
* Set `ips_policy` to `security`

#### Run
```shell
sudo /usr/local/bin/pulledpork.pl -c /usr/local/etc/pulledpork/pulledpork.conf -l -P -E -H SIGHUP
```

#### Create Cronjob
Create a root cronjob (sudo crontab -e) to update the rulesets:
```shell
# update snort ruleset at 2:30am
30 02 * * * /usr/local/bin/pulledpork.pl -c /usr/local/etc/pulledpork/pulledpork.conf -l -P -E -H SIGHUP
```

### Snort Plugins
Adjust your `HOME_NET` in `/usr/local/etc/snort/snort.lua`:
```sql
---------------------------------------------------------------------------
-- 1. configure defaults
---------------------------------------------------------------------------

-- HOME_NET and EXTERNAL_NET must be set now
-- setup the network addresses you are protecting
HOME_NET = 'any'

-- set up the external network addresses.
-- (leave as "any" in most situations)
EXTERNAL_NET = 'any'
```
