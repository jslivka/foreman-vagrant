#!/bin/sh

# Update system first
sudo yum update -y

sudo rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
sudo yum -y install puppet puppet-agent

if ps aux | grep "/usr/share/foreman" | grep -v grep 2> /dev/null
then
    echo "Foreman appears to all already be installed. Exiting..."
else
    sudo yum -y install epel-release http://yum.theforeman.org/releases/1.16/el7/x86_64/foreman-release.rpm && \
    sudo yum -y install foreman-installer && \
    sudo yum -y install nano nmap-ncat && \
    sudo foreman-installer

    # Set-up firewall
    # https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers
    sudo systemctl enable firewalld
    sudo systemctl start firewalld

    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --permanent --add-port=69/tcp
    sudo firewall-cmd --permanent --add-port=67-69/udp # DHCP
    sudo firewall-cmd --permanent --add-port=53/tcp
    sudo firewall-cmd --permanent --add-port=53/udp
    sudo firewall-cmd --permanent --add-port=8443/tcp
    sudo firewall-cmd --permanent --add-port=8140/tcp
    sudo firewall-cmd --permanent --add-port=21/tcp # TFTP

    sudo firewall-cmd --reload

    # First run the Puppet agent on the Foreman host which will send the first Puppet report to Foreman,
    # automatically creating the host in Foreman's database
    sudo /opt/puppetlabs/bin/puppet agent --test --waitforcert=60

    # Optional, install some optional puppet modules on Foreman server to get started...
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-ntp
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-git
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-vcsrepo
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules garethr-docker
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules jfryman-nginx
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-haproxy
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-apache
    sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppet/environments/production/modules puppetlabs-java
fi
