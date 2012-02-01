#!/bin/bash
#################
#
# Script to setup an ininial KickStart server on top of a fresh
# installation of CentOS 6.x
#
# Author: Kirk Steffensen
# Version: 0.1
# Date: 10/23/2011
#
#################

# First do yum update to make sure it has the full repo list.
yum -y update

# Add EPEL to enable retrieving phpldapadmin
rpm -Uvh http://download.fedora.redhat.com/pub/epel/6/x86_64/epel-release-6-5.noarch.rpm

yum -y install vim tftp-server syslinux system-config-kickstart nfs-utils nfs-utils-lib openldap-servers openldap-clients httpd php php-mbstring php-pear phpldapadmin

rpm -Uvh http://rbel.frameos.org/rbel6

yum -y install ruby ruby-devel ruby-ri ruby-rdoc ruby-shadow gcc gcc-c++ automake autoconf make curl dmidecode

# Configure LDAP
sed -i 's/#SLAPD_LDAPI=no/SLAPD_LDAPI=yes/' /etc/sysconfig/ldap

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

PASSWORD_ENCRYPTED=$(slappasswd -s password)

echo "Encrypted Password: $PASSWORD_ENCRYPTED"

cat > /etc/openldap/slapd.conf << FILE_CONTENTS
pidfile     /var/run/openldap/slapd.pid
argsfile    /var/run/openldap/slapd.args
FILE_CONTENTS

rm -rf /etc/openldap/slapd.d/*
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
sed -i 's/olcAccess:.*/olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break/' /etc/openldap/slapd.d/cn=config/olcDatabase\={0}config.ldif

cat > /etc/openldap/slapd.d/cn=config/olcDatabase\={1}monitor.ldif << FILE_CONTENTS
dn: olcDatabase={1}monitor
objectClass: olcDatabaseConfig
olcDatabase: {1}monitor
olcAccess: {1}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAddContentAcl: FALSE
olcLastMod: TRUE
olcMaxDerefDepth: 15
olcReadOnly: FALSE
olcMonitoring: FALSE
structuralObjectClass: olcDatabaseConfig
creatorsName: cn=config
modifiersName: cn=config
FILE_CONTENTS

chown -R ldap. /etc/openldap/slapd.d 
chmod -R 700 /etc/openldap/slapd.d 
/etc/rc.d/init.d/slapd start 
chkconfig slapd on 

# Install RubyGems from source
cd /tmp
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
tar zxf rubygems-1.8.10.tgz
cd rubygems-1.8.10
ruby setup.rb --no-format-executable

# Install Chef Gem
gem install chef --no-ri --no-rdoc

mkdir /etc/chef/

cat > /etc/chef/solo.rb << FILE_CONTENTS
file_cache_path "/tmp/chef-solo"
cookbook_path "/tmp/chef-solo/cookbooks"
FILE_CONTENTS

cat > ~/chef.json << FILE_CONTENTS
{
    "chef_server": {
        "server_url": "http://localhost:4000",
        "webui_enabled": true,
        "init_style": "init"
    },
    "run_list": [ "recipe[chef-server::rubygems-install]" ]
}
FILE_CONTENTS

chef-solo -c /etc/chef/solo.rb -j ~/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz

# May have to run again due to couchdb bug with CentOS
# http://wiki.opscode.com/display/chef/Installing+Chef+Server+using+Chef+Solo#InstallingChefServerusingChefSolo-CentOS%2FRHELInstallationNotes
if [ $? -ne 0 ]
then
    chef-solo -c /etc/chef/solo.rb -j ~/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz
else
    echo "Did not need to run chef-solo a second time"
fi

# Fis issue on CentOS
# Ref: http://wiki.opscode.com/display/chef/Installing+Chef+Server+using+Chef+Solo#InstallingChefServerusingChefSolo-CentOS%2FRHELInstallationNotes
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

service chef-server start
service chef-server-webui start
