#!/bin/bash

PUPPET_MASTER_HOSTNAME="master.puppet.local"

#vagrant@vagrant-ubuntu-trusty-64:~$ cp /vagrant/.vagrant/machines/master/virtualbox/private_key .ssh/
#vagrant@vagrant-ubuntu-trusty-64:~$ chmod 0600 .ssh/private_key
#vagrant@vagrant-ubuntu-trusty-64:~$ ssh -oStrictHostKeyChecking=no -i .ssh/private_key  vagrant@192.168.101.11
#!/bin/bash


# Create and add swap file
if [ ! -e "/swapfile" ]; then
    dd if=/dev/zero of=/swapfile bs=1MB count=4096
    mkswap /swapfile 
    swapon /swapfile 
fi

# copy the master private key from /vagrant
cp /vagrant/.vagrant/machines/master/virtualbox/private_key /home/vagrant/.ssh/
#  assign read only permission
chmod 0600 /home/vagrant/.ssh/private_key

grep -i master /etc/hosts 1>& /dev/null
if [ "$?" -ne "0" ]; then
    echo 'agent' > /etc/hostname
    echo '192.168.101.11    master.puppet.local    master' >> /etc/hosts
    echo '192.168.101.12    agent.puppet.local    agent' >> /etc/hosts
    hostname 'agent'

    ssh -oStrictHostKeyChecking=no -i /home/vagrant/.ssh/private_key  vagrant@master 'grep -i agent /etc/hosts 1>& /dev/null || sudo sh -c "echo \"192.168.101.12    agent.puppet.local       agent\" >> /etc/hosts "'

    # Remove already installed puppet agents
    apt-get -y remove puppet puppet-common chef chef-zero
fi


# Install Agent
curl -k https://$PUPPET_MASTER_HOSTNAME:8140/packages/current/install.bash 2> /dev/null | sudo bash


# Do the first puppet agent run
# This will exit because agent cert is not signed yet.
puppet agent -t 

# login to puppet master and sign the cert
ssh -oStrictHostKeyChecking=no -i /home/vagrant/.ssh/private_key  vagrant@master 'sudo puppet cert --sign agent.puppet.local'


# Run the puppet agent again
# This time it should work.
puppet agent -t 

# We don't want that Vagrant error print
# Puppet run output is enough to know if there is any error
exit 0
