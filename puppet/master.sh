#!/bin/bash

PUPPET_MASTER_HOSTNAME="master.puppet.local"

# Create and add swap file
if [ ! -e "/swapfile" ]; then
    dd if=/dev/zero of=/swapfile bs=1MB count=4096
    mkswap /swapfile 
    swapon /swapfile 
fi

grep -i master /etc/hosts 1>& /dev/null
if [ "$?" -ne "0" ]; then
    echo 'master' > /etc/hostname
    hostname 'master'
    echo '192.168.101.11    master.puppet.local    master' >> /etc/hosts
fi


# Install Puppet Server
# For now we only support Ubuntu 14.04 on master
# TODO: Centos 7, RHEL 7 support
# Extract in /home/vagrant
tar -xzf /vagrant/software/puppet-enterprise-*-ubuntu-14.04-amd64.tar.gz -C /home/vagrant



# If answer file does not exist already
if [ ! -e "/home/vagrant/all-in-one.answers.txt" ]; then

    # Remove the puppet and chef packages that are already installed.
    apt-get remove puppet puppet-common chef chef-zero

    # Generate Random passwords for admin user and DB root user
    ADMINPASS="`tr -cd '[:alnum:]' < /dev/urandom | fold -w15 | head -n1`"
    DBPASS="`tr -cd '[:alnum:]' < /dev/urandom | fold -w15 | head -n1`"

    # Copy answer file and update admin and DB password
    sed -e "s/#ADMINPASS#/$ADMINPASS/" -e "s/#DBPASS#/$DBPASS/" /vagrant/puppet/answers/all-in-one.answers.txt > /home/vagrant/all-in-one.answers.txt
fi

# Currently only single all in one puppet master is supported
cd /home/vagrant/puppet-enterprise-*-ubuntu-14.04-amd64
./puppet-enterprise-installer -a /home/vagrant/all-in-one.answers.txt


echo ""
echo ""
echo "#####################################################################"
echo "# Puppet Master Installation is complete"
echo "#"
echo "# Answer file is located at: /home/vagrant/all-in-one.answers.txt"
echo "#"
echo "# Access Puppet Enterprise Console at: https://192.168.101.11"
echo "#"
echo "#    Console Admin Username: admin"
echo "#    Console Admin Password: $ADMINPASS"
echo "#"
echo "#    Please also note down DB password for your record." 
echo "#    DB root password: $DBPASS"
echo "#"
echo "####################################################################"
