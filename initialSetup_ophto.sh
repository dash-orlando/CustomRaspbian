#!/bin/bash
#
# Automate the configuration of the Raspbian image
# Ophto Version:
#	- Purges Wolfram Alpha & LibreOffice (~1GB gain)
#	- Updates/upgrades packages
#	- Sets Timezone
#	- Installs dependencies and packages required for OpenCV
#
# AUTHOR: Mohammad Odeh
# DATE	: Jul. 5th, 2017
#

################################################################################
# Terminal output helpers
################################################################################

# echo_equals() outputs a line with =
#   seq does not exist under OpenBSD
function echo_equals() {
	COUNTER=0
	while [  $COUNTER -lt "$1" ]; do
		printf '='
		let COUNTER=COUNTER+1 
	done
}

# echo_title() outputs a title padded by =, in yellow.
function echo_title() {
	TITLE=$1
	NCOLS=$(tput cols)
	NEQUALS=$(((NCOLS-${#TITLE})/2-1))
	tput setaf 3 0 0 # 3 = yellow
	echo_equals "$NEQUALS"
	printf " %s " "$TITLE"
	echo_equals "$NEQUALS"
	tput sgr0  # reset terminal
	echo
}

# echo_step() outputs a step collored in cyan, without outputing a newline.
function echo_step() {
	tput setaf 6 0 0 # 6 = cyan
	echo -n "$1"
	tput sgr0  # reset terminal
}

# echo_right() outputs a string at the rightmost side of the screen.
function echo_right() {
	TEXT=$1
	echo
	tput cuu1
	tput cuf "$(tput cols)"
	tput cub ${#TEXT}
	echo "$TEXT"
}

# echo_success() outputs [ OK ] in green, at the rightmost side of the screen.
function echo_success() {
	tput setaf 2 0 0 # 2 = green
	echo_right "[ OK ]"
	tput sgr0  # reset terminal
}

# echo_warning() outputs a message and [ WARNING ] in yellow, at the rightmost side of the screen.
function echo_warning() {
	tput setaf 3 0 0 # 3 = yellow
	echo_right "[ WARNING ]"
	tput sgr0  # reset terminal
	echo "    ($1)"
}

################################################################################
# Configure system-wide settings
################################################################################
echo_title 	"Configure System"
echo_step	"Configuring system-wide settings"; echo

# Timezone
echo_step	"	Setting Timezone"
TIMEZONE="US/Eastern"      
echo $TIMEZONE > /etc/timezone                     
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to set timezone"
else
	echo_success
fi

################################################################################
# Removing unnecessary packages
################################################################################

echo_title 	"Purge"
echo_step	"Preparing to purge unnecessary packages"; echo

echo_step	"	Wolfram Alpha"
sudo apt-get -qq purge wolfram*
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to purge. Package has been either purged earlier or doesn't exist"
else
	echo_success
fi

echo_step 	"	Libre Office Suite"
sudo apt-get -qq purge libreoffice*
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to purge. Package has been either purged earlier or doesn't exist"
else
	echo_success
fi

################################################################################
# Updating and upgrading
################################################################################
echo_title 	"Update/Upgrade System Packages"
echo_step	"Preparing to upgrade system packages"; echo

echo_step	"	Updating packages index"
sudo apt-get -qq update
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Upgrading packages"
sudo apt-get -qq dist-upgrade
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Removing unused dependencies/packages"
sudo apt-get -qq autoremove
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"  Updating Kernel"; echo
sudo rpi-update
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

################################################################################
# Installing OpenCV dependencies
################################################################################
echo_title 	"OpenCV Dependencies"
echo_step	"Installing Required packages for OpenCV"; echo

echo_step	"	Installing: Developer tools"
sudo apt-get -qq install build-essential cmake pkg-config
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: Image I/O packages"
sudo apt-get -qq install libjpeg8-dev libjasper-dev libpng12-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: GTK development library"
sudo apt-get -qq install libgtk2.0-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: Video processing packages (1)"
sudo apt-get -qq install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: Video processing packages (2)"
sudo apt-get -qq install libxvidcore-dev libx264-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: Optimization/Development libraries"
sudo apt-get -qq install libatlas-base-dev gfortran python2.7-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"	Installing: Text & string output on GUI" 
sudo apt-get -qq install libgtkglext1 libgtkglext1-dev
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

################################################################################
# Final Steps
################################################################################
echo_title 	"Clean Up"
echo_step	"Cleaning up"

echo_step	"  Cleaning caches"
sudo apt-get -qq autoclean
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

echo_step	"REBOOTING IN 15 SECONDS!!"; echo
sleep 10
echo_step	"REBOOTING IN 5 SECONDS!!"
sleep 5
sudo reboot