#!/bin/bash
# Redmine Install on Debian Wheezy
# Author: John McCarthy
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
# Date: 10th of September, 2014
# Version 1.1
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## VARIABLES ########
redmine_version=2.5.2
######## FUNCTIONS ########
function getRedmine()
{
	# Downloads the latest Redmine installation files
		echo -e '\e[34;01m+++ Getting repositories...\e[0m'
		wget http://www.redmine.org/releases/redmine-2.5.2.tar.gz
	# Untars the Redmine installation files
		tar xzf redmine-$redmine_version.tar.gz
		echo -e '\e[01;37;42mThe latest version of Redmine have been acquired!\e[0m'
}

function installMysql()
{
	# Request root user's database password
		echo
		echo -e '\e[33mPlease type in the root user password for the mysql database:\e[0m'
		read mysql_passwd

	# Downloads the MySQL packages from the Debian repos
		echo -e '\e[34;01m+++ Installing MySQL...\e[0m'
		apt-get install mysql-server mysql-client mysql-common -y
		echo -e '\e[01;37;42mMySQL has been successfully installed!\e[0m'
}

function createDB()
{
	# Checks if the $mysql_passwd variable is set
		if [[ -z "$mysql_passwd" ]]; then
			echo -e '\e[33mPlease type in the root user password for the mysql database:\e[0m'
			read mysql_passwd
		fi

	# Request the redmine database user password
		echo
		echo -e '\e[33mPlease type in a password for the redmine user on your mysql database:\e[0m'
		echo -e '       \e[31;1mIf your password has special characters, please remember to escape\e[0m'
		echo -e "                \e[31;1mthe special character by placing a backslash '\'\e[0m"
		echo -e '                       \e[31;1min front of the special character\e[0m'
		echo
		read redmine_db_passwd

	# Variable to check if the Redmine database exits
		redmine_db=$(mysql -u root --password="$mysql_passwd" -e 'SHOW DATABASES LIKE "redmine";')
	# Checks if redmine database exists
		if [ -z "$redmine_db" ];then
		# Creates the redmine database
			echo -e '\e[34;01m+++ Creating the redmine database...\e[0m'
			mysql -u root --password="$mysql_passwd" -e 'CREATE DATABASE redmine CHARACTER SET utf8;'
			echo
			echo -e "\e[01;37;42mThe redmine database has been successfully created!\e[0m"
		# Creates the redmine database user
			echo -e '\e[34;01m+++ Creating the redmine database user...\e[0m'
			mysql -u root --password="$mysql_passwd" -e "CREATE USER 'redmine'@'localhost' IDENTIFIED BY '$redmine_db_passwd';"
			echo
			echo -e "\e[01;37;42mThe redmine database user has been successfully created!\e[0m"
		# Grants permissions to the redmine database to the redmine database user
			echo -e '\e[34;01m+++ Granting permissions to the redmine user on the redmine database...\e[0m'
			mysql -u root --password="$mysql_passwd" -e 'GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';'
			echo
			echo -e "\e[01;37;42mPermissions have been successfully granted to the redmine user!\e[0m"
		fi
}

function redmineConfigs()
{
	# Change to the redmine directory
		echo -e '\e[34;01m+++ Editing the redmine database.yml file...\e[0m'
		cd ~/redmine-$redmine_version
	# Creates a copy of the database.yml.example file to be used in production
		cp config/database.yml.example config/database.yml
	# Edit the database.yml file
		sed -i '10s/  username: root/  username: redmine/' config/database.yml
		sed -i '11s/  password: ""/  password: "'"$redmine_db_passwd"'"/' config/database.yml
		echo
		echo -e "\e[01;37;42mSuccessfully edited the redmine database.yml file!\e[0m"
}

function installRedmine()
{
	# Install the required packages
		echo -e '\e[34;01m+++ Installing required packages...\e[0m'
		apt-get install -y build-essential ruby1.9.1-dev libmysqlclient-dev libmagickwand-dev
		echo -e "\e[01;37;42mSuccessfully installed required packages!\e[0m"
		echo
	# Install the bundler gem
		echo -e '\e[34;01m+++ Installing the bundler gem...\e[0m'
		gem install bundler
		echo -e "\e[01;37;42mSuccessfully installed the bundler gem!\e[0m"
		echo
	# Install bundle
		echo -e '\e[34;01m+++ Installing the Redmine Gemfile...\e[0m'
		bundle install --without development test
		echo -e "\e[01;37;42mSuccessfully installed the Redmine Gemfile!\e[0m"
		echo
	# Generate the secret token in rake
		echo -e '\e[34;01m+++ Configuring the Redmine Production databse...\e[0m'
		rake generate_secret_token
	# Settings up the Redmine database
		RAILS_ENV=production rake db:migrate
		RAILS_ENV=production REDMINE_LANG=en rake redmine:load_default_data
		echo -e "\e[01;37;42mThe Redmine Production database has been successfully configured!\e[0m"
		echo
	# Create the redmine user and group on your Linux system
		echo -e '\e[34;01m+++ Creating the Redmine user and Group...\e[0m'
		useradd redmine
		addgroup redmine
		usermod -Gredmine redmine
		echo -e "\e[01;37;42mThe Redmine user and group has been successfully created!\e[0m"
		echo
	# Make some redmine directories
		echo -e '\e[34;01m+++ Creating required directories and setting permissions...\e[0m'
		mkdir -p tmp tmp/pdf public/plugin_assets
	# Make redmine the owner of these new files and directories
		chown -R redmine:redmine files log tmp public/plugin_assets
		chmod -R 755 files log tmp public/plugin_assets
		echo
		echo -e "\e[01;37;42mThe required directories and permissions http been successfully created and set!\e[0m"
}

function redmineWebrickTest()
{
		echo
		echo -e "             \e[37;1;42mGo to: http://$ipaddr:3000 to test if Redmine is working properly\e[0m"
		echo
		echo -e "                                 \e[37;1mUsername: admin\e[0m"
		echo -e "                                 \e[37;1mPassword: admin\e[0m"
		echo
		echo -e '           \e[30;01mPress Ctrl + C when you have successfully finished testing\e[0m'
	# Gets your IP Address and sets it as a variable
		hostip=`hostname -I`
	# Deleted the trailing whitespace
		ipaddr=$(echo "$ipaddr" | tr -d ' ')
	# Runs the webrick test of redmine
		ruby script/rails server webrick -e production
	# Announce the URL to browse to to test Redmine
}

function installPassenger()
{
	# Install the required packages to install passenger
		echo -e '\e[34;01m+++ Installing required packages...\e[0m'
		apt-get install -y build-essential apache2-prefork-dev apache2-mpm-worker libapr1-dev libssl-dev zlib1g-dev libcurl4-openssl-dev libssl-dev libapr1-dev libaprutil1-dev rubygems
		echo -e "\e[01;37;42mSuccessfully installed required packages!\e[0m"
		echo
	# Install the passenger gem
		echo -e '\e[34;01m+++ Installing the passenger gemfile...\e[0m'
		gem install passenger
		echo -e "\e[01;37;42mThe passenger gemfile has been successfully installed!\e[0m"
		echo
	# Install the passenger apache module
		echo -e '\e[34;01m+++ Installing the passenger-install-apache2-module...\e[0m'
		echo
		echo
		echo -e '                            \e[37;1m-- > \e[0;32mHit Enter twice \e[37;1m<--\e[0m'
		echo -e '                 \e[31;1mMake sure your machine has at least 1GB of RAM\e[0m'
		echo
		passenger-install-apache2-module
		echo -e "\e[01;37;42mThe passenger-install-apache2-module has been successfully installed!\e[0m"
	# Sets your versions of passenger to a variable
		passenger=$(gem list --local | grep passenger)
		vers=$(echo $passenger | awk -F "[()]" '{ for (i=2; i<NF; i+=2) print $i }')
	# Create the /etc/apache2/mods-available/passenger.load file
		cat <<EOA> /etc/apache2/mods-available/passenger.load
LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-$vers/buildout/apache2/mod_passenger.so
EOA
	# Create the /etc/apache2/mods-available/passenger.conf file
		cat <<EOB> /etc/apache2/mods-available/passenger.conf

PassengerRoot /var/lib/gems/1.9.1/gems/passenger-$vers
PassengerDefaultRuby /usr/bin/ruby1.9.1

EOB
}

function redmineApacheSetup()
{
	# Move the redmine directory to the apache directory
		echo -e '\e[34;01m+++ Moving the redmine directory to the Apache DocumentRoot...\e[0m'
		cd
		mv redmine-$redmine_version /var/www/redmine
		echo
		echo -e "\e[01;37;42mThe Redmine directory has been moved to the Apache document root!\e[0m"
		echo
	# Edit the apache default sites-available file
		echo -e '\e[34;01m+++ Editing the default apache site file...\e[0m'
		echo
		echo -e '\e[33mPlease type in an admin email address for the default Apache site:\e[0m'
		read adminsmtp
	# Editting the /etc/apache2/sites-available/default file
	cat << EOC > /etc/apache2/sites-available/default
<VirtualHost *:80>
        ServerAdmin $adminsmtp

        DocumentRoot /var/www/redmine/public
        <Directory /var/www/redmine/public>
                AllowOverride all
                Options -MultiViews
        </Directory>
        RailsBaseURI /redmine
        <Directory /var/www/redmine/public>
                Options -MultiViews
        </Directory>
</VirtualHost>
EOC
		echo -e "\e[01;37;42mThe Apache default site file has been edited successfully!\e[0m"
		echo
	# Setup permissions on the apache files and directories
		echo -e '\e[34;01m+++ Setting permissions on the redmine directory...\e[0m'
		chown -R redmine:redmine /var/www/redmine
		chmod 755 /var/www/redmine
		echo
		echo -e "\e[01;37;42mSettings have been successfully set for the Redmine directory!\e[0m"
		echo
	# Enable the passenger module
		echo -e '\e[34;01m+++ Enabling the passenger mod for Apache...\e[0m'
		a2enmod passenger
		echo -e "\e[01;37;42mThe passenger mod has been successfully enabled!\e[0m"
		echo
	# Restart apache
		echo -e '\e[34;01m+++ Restarting the apache2 service...\e[0m'
		service apache2 restart
		echo -e "\e[01;37;42mApache has been successfully restarted!\e[0m"
}

function redmineTheme()
{
	# Install git to pull a git repo
		echo -e '\e[34;01m+++ Installing git to download Redmine themes...\e[0m'
		apt-get install -y git
		echo -e "\e[01;37;42mGit has been successfully installed!\e[0m"
		echo
	# Change to the redmine theme directory
		cd /var/www/redmine/public/themes
	# Clone the redmine theme git repo to your redmine theme directory
		echo -e '\e[34;01m+++ Installing your Redmine Theme...\e[0m'
		git clone https://github.com/AlphaNodes/bavarian_dawn
		echo
		echo -e '              \e[01;37;42mYour Redmine theme has been successfully installed!\e[0m'
		echo -e '                            \e[37;01mLog in as (admin / admin)\e[0m'
		echo -e '                \e[37;01mAdministration > Settings > Display tab > Themes\e[0m'
		echo -e '                         \e[37;01mChoose the theme you downloaded\e[0m'
}

function doAll()
{
	echo
	echo -e '\e[33m=== Download the latest version of Redmine ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		getRedmine
	fi

	echo
	echo -e '\e[33m=== Install MySQL for your Redmine database ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		installMysql
	fi

	echo
	echo -e '\e[33m=== Create your your Redmine database ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		createDB
	fi

	echo
	echo -e '\e[33m=== Configure Redmine before installation ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		redmineConfigs
	fi

	echo
	echo -e '\e[33m=== Install Redmine ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		installRedmine
	fi

	echo
	echo -e '\e[33m=== Test out Redmine with WEBrick ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		redmineWebrickTest
	fi

	echo
	echo -e '\e[33m=== Setup Apache Passenger for Redmine to use ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		installPassenger
	fi

	echo
	echo -e '\e[33m=== Configure Apache to use Redmine ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		redmineApacheSetup
	fi

	echo
	echo -e '\e[33m=== Install a custom Redmine theme ? [RECOMMENDED] (y/n)\e[0m'
	read yesno
	if [ "$yesno" = "y" ]; then
		redmineTheme
	fi
	echo
	echo
	echo -e '            \e[01;37;42mWell done! You have completed your Redmine Installation!\e[0m'
	echo
	echo -e '                  \e[01;37;42mProceed to your Redmine web UI, http://fqdn\e[0m'
	echo
	echo -e '\e[01;37mCheckout similar material at "midactstech.blogspot.com" and "github.com/Midacts" \e[0m'
	echo
	echo -e '                            \e[37m########################\e[0m'
	echo -e '                            \e[37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[37m#\e[0m'
	echo -e '                            \e[37m########################\e[0m'
	echo
	echo
	exit 0
}
# Check privileges
[ $(whoami) == "root" ] || die "You need to run this script as root."
# Welcome to the script
echo
echo
echo -e '             \e[01;37;42mWelcome to Midacts Mystery'\''s Redmine Installer!\e[0m'
echo
echo
case "$go" in
	* )
		doAll ;;
esac

exit 0
