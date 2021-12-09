#!/bin/bash

#Variables for functions default, or given with input.
INSTALL_DIR="${1}"
DATA_DIR="${INSTALL_DIR}"/"Logs_downloads_squid"
LOGFILE="${DATA_DIR}"/"Installation_and_commands.log"

#Variables that makes text appear just a little fancier.

RED='\033[0;31m'
NC='\033[0m'
LPURPLE='\033[1;35m'
YEL='\033[1;33m'
BLINKRED='\033[5;31m'
BLINKPURP='\033[5;35m'
NRML='\033[0;37m'

#Function to let text appear in a rolling-out fashion
roll() {
  msg="${1}"
    if [[ "${msg}" =~ ^=.*+$ ]]; then
      speed=".01"
    else
      speed=".03"
    fi
  let lnmsg=$(expr length "${msg}")-1
  for (( i=0; i <= "${lnmsg}"; i++ )); do
    echo -n "${msg:$i:1}"
    sleep "${speed}"
  done ; echo ""
}


#Function to declare an initial directory for environment.
start() {
echo -e "${BLINKPURP}###${NC} ${RED}Welcome to${NC} ${LPURPLE}Nick's${NC} ${RED}Mailserver roll-out script 2 out 2${NC}${BLINKPURP} ###${NC}"
echo -e "${CYAN}Please make sure you run this script as${NC}${RED} privileged user${NC}${CYAN}, are you?${NC}${YEL} [Y/N] ${NC}"
read -p "Input: " -n 1 -r
echo -e "${YEL}"
if [[ $REPLY =~ ^[Nn]$  ]]
then
	echo -e  "${RED}User acknowledged webpage failure; stopping...${NC}"
	exit 1
fi

}

install_postfix_and_reqs() {
dnf install postfix postfix-mysql httpd vim policycoreutils-python-utils epel-release -y
dnf -y install php php-common php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-gd php-mbstring php-xml php-json php-pecl-zip libzip php-intl

}



install_mysql_and_conf() {
dnf -y upgrade
curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
bash mariadb_repo_setup --mariadb-server-version=10.6
dnf install boost-program-options -y
dnf module reset mariadb -y
yum install MariaDB-server MariaDB-client MariaDB-backup -y
systemctl enable --now mariadb

mysql -e "UPDATE mysql.user SET Password = PASSWORD('Pa$$w0rd!') WHERE User = 'root'"
mysql -e "CREATE DATABASE postfix_accounts;"
mysql -e "grant all on postfix_accounts.* to postfix_admin@localhost identified by 'Pa$$w0rd!';"
mysql -e "CREATE TABLE `postfix_accounts`.`domains_table` ( `DomainId` INT NOT NULL AUTO_INCREMENT, `DomainName` VARCHAR(50) NOT NULL , PRIMARY KEY (`DomainId`)) ENGINE = InnoDB;"
mysql -e "CREATE TABLE `postfix_accounts`.`alias_table` ( `AliasId` INT NOT NULL AUTO_INCREMENT, `DomainId` INT NOT NULL, `Source` varchar(100) NOT NULL, `Destination` varchar(100) NOT NULL, PRIMARY KEY (`AliasId`), FOREIGN KEY (DomainId) REFERENCES domains_table(DomainId) ON DELETE CASCADE) ENGINE = InnoDB;"
mysql -e "CREATE TABLE `postfix_accounts`.`accounts_table` ( `AccountId` INT NOT NULL AUTO_INCREMENT, `DomainId` INT NOT NULL, `password` VARCHAR(300) NOT NULL, `Email` VARCHAR(100) NOT NULL, PRIMARY KEY (`AccountId`), UNIQUE KEY `Email` (`Email`), FOREIGN KEY (DomainId) REFERENCES domains_table(DomainId) ON DELETE CASCADE) ENGINE = InnoDB;"
mysql -e "INSERT INTO `postfix_accounts`.`domains_table` (DomainName) VALUES ('groep5.local');"
mysql -e "INSERT INTO `postfix_accounts`.`accounts_table` (DomainId, password, Email) VALUES (1, ENCRYPT('Pa$$w0rd!', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 'test@groep5.local');"

# mysql -e "FLUSH PRIVILEGES;"
}

install_RoundCube_and_conf() {
mysql -e "create database roundcube;"
mysql -e "grant all on roundcube.* to roundcube_admin@localhost identified by 'Pa$$w0rd!';"
}

flush_db_privs() {
mysql -e "flush privileges;"
}

move_pfmaster_config_file() {
#Make local config file replace /etc/postfix/master.cf and make sure the line for dovecot is at the bottom

}

move_pfmain_config_file() {
#Make local config file replace /etc/postfix/main.cf

}

move_db_users_config_file() {
#Make local config file replace /etc/postfix/database-users.cf
chmod 640 /etc/postfix/database-users.cf
chown root:postfix /etc/postfix/database-users.cf
}

move_db_domains_config_file() {
#Make local config file replace /etc/postfix/database-domains.cf
chmod 640 /etc/postfix/database-domains.cf
chown root:postfix /etc/postfix/database-domains.cf
}

move_db_alias_config_file() {
#Make local config file replace /etc/postfix/database-alias.cf
chmod 640 /etc/postfix/database-alias.cf
chown root:postfix /etc/postfix/database-alias.cf
}

restart_postfix() {
sudo systemctl restart postfix
sudo systemctl enable postfix
}

install_dovecot_and_configure() {
dnf install dovecot dovecot-mysql -y
groupadd -g 6000 vmail
useradd -g vmail -u 6000 vmail -d /home/vmail -m
}

move_dovecot_config_file() {
#make local config file replace /etc/dovecot/dovecot.conf
}

move_10auth_config_file() {
#make local config file replace /etc/dovecot/conf.d/10-auth.conf
}

move_authsql_config_file() {
#make local config file replace /etc/dovecot/conf.d/auth-sql.conf.ext
}

move_dovecotsql_config_file() {
mkdir /home/vmail/example.com
#make local config file replace /etc/dovecot/dovecot-sql.conf.ext
}

move_mailboxloc_config_file() {
#make local config file replace /etc/dovecot/conf.d/10-mail.conf

}

move_mailboxloc_config_file() {
#make local config file replace /etc/dovecot/conf.d/10-master.conf

}

vmail_dovecot_permissions() {
chown –R vmail:vmail /home/vmail
chown -R vmail:dovecot /etc/dovecot 
chmod -R o-rwx /etc/dovecot
}

download_install_roundcube() {
VER="1.5.0"
wget https://github.com/roundcube/roundcubemail/releases/download/$VER/roundcubemail-$VER-complete.tar.gz
tar xvzf roundcubemail-$VER-complete.tar.gz
mv roundecubemail-$VER roundcube
mv roundcube /var/www/html/
chown -R apache:apache /var/www/html/
systemctl restart httpd
systemctl enable httpd
}
start
change_hostname
end
