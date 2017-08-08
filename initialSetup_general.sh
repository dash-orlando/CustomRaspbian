#!/bin/bash
#
# Automate the configuration of the Raspbian image
# General Version:
#	- Sets Timezone and keyboard
#       - Disable blank screen forever
#	- Purges Wolfram Alpha & LibreOffice (~1GB gain)
#	- Updates/upgrades packages
#	- Post-setup cleanup
#
# AUTHOR	: Mohammad Odeh
# DATE		: Jul.  5th, 2017
# MODIFIED	: Aug.  7th, 2017
#

################################################################################
# Terminal output helpers
################################################################################

# check_if_root_or_die() verifies if the script is being run as root and exits
# otherwise (i.e. die).
function check_if_root_or_die() {
	echo_step "Checking installation privileges"
	echo -e "\nid -u" >>"$INSTALL_LOG"
	SCRIPT_UID=$(id -u)
	if [ "$OPERATING_SYSTEM" = "CYGWIN" ]; then
		# Administrator really isn't equivalent to POSIX root.
		echo_step_info "Under Cygwin, you do not have to be a root"
	elif [ "$SCRIPT_UID" != 0 ]; then
		exit_with_failure "Please run as root"
	fi
	echo_success
}

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

# echo_failure() outputs [ FAILED ] in red, at the rightmost side of the screen.
function echo_failure() {
	tput setaf 1 0 0 # 1 = red
	echo_right "[ FAILED ]"
	tput sgr0  # reset terminal
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

# use the given INSTALL_LOG or set it to a random file in /tmp
function set_install_log() {
	if [[ ! $INSTALL_LOG ]]; then
		export INSTALL_LOG="/home/pi/install_$DATETIME.log"
	fi
	if [ -e "$INSTALL_LOG" ]; then
		exit_with_failure "$INSTALL_LOG already exists"
	fi
}

# exit_with_message() outputs and logs a message before exiting the script.
function exit_with_message() {
	echo
	echo "$1"
	echo -e "\n$1" >>"$INSTALL_LOG"
	if [[ $INSTALL_LOG && "$2" -eq 1 ]]; then
		echo "For additional information, check the install log: $INSTALL_LOG"
	fi
	echo
	#debug_variables
	echo
	exit 1
}

# exit_with_failure() calls echo_failure() and exit_with_message().
function exit_with_failure() {
	echo_failure
	exit_with_message "FAILURE: $1" 1
}

################################################################################
# Script configuration
################################################################################
echo
echo

# Get current date and time
DATETIME=$(date "+%Y-%m-%d-%H-%M-%S")

# Create install log
set_install_log

# Check if the script is being run with root (sudo) privilages or not
check_if_root_or_die

################################################################################
# Configure system-wide settings
################################################################################
echo_title 	"Configure System"
echo_step	"Configuring system-wide settings"; echo

# Keyboard
echo_step	"  Setting keyboard to US layout"
sudo sed -i -e 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' /etc/default/keyboard
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to set keyboard"
else
	echo_success
fi

# Timezone
echo_step	"  Setting Timezone"
TIMEZONE="US/Eastern"      
echo $TIMEZONE > /etc/timezone                     
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to set timezone"
else
	echo_success
fi

# Disable blank screen (aka screensaver)
echo_step	"  Disabling blank screen"
sudo sed -i -e 's/#xserver-command=X/xserver-command=X -s 0 -dpms/g' /etc/lightdm/lightdm.conf
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to setup 10.1\" screen"
else
	echo_success
fi

################################################################################
# Removing unnecessary packages
################################################################################

echo_title 	"Purge"
echo_step	"Preparing to purge unnecessary packages"; echo

# Purge Wolfram Alpha
echo_step	"  Wolfram Alpha"
sudo apt-get -q -y purge wolfram* >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to purge. Package has been either purged earlier or doesn't exist"
else
	echo_success
fi

# Purge LibreOffice
echo_step 	"  Libre Office Suite"
sudo apt-get -q -y purge libreoffice* >>"$INSTALL_LOG"
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

# Update packages index
echo_step	"  Updating packages index"
sudo apt-get -q -y update >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

# Upgrade packages
echo_step	"  Upgrading packages"
sudo apt-get -q -y dist-upgrade >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

# Remove unused packages/dependencies
echo_step	"  Removing unused dependencies/packages"
sudo apt-get -q -y autoremove >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

# Update RPi kernel
echo_step	"  Updating Kernel"; echo
sudo rpi-update >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

################################################################################
# Installing pip and pip packages
################################################################################
echo_title 	"PIP"
echo_step	"Installing PIP + packages"; echo
cd /home/pi/

# Download/Install PIP
echo_step	"  Installing latest PIP release"
sudo wget https://bootstrap.pypa.io/get-pip.py -a "$INSTALL_LOG"
sudo python get-pip.py >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to install"
else
	echo_success
fi

# Upgrade Numpy
echo_step	"  Upgrading numpy (Please wait. This might take a while [ETA 10mins])"
sudo pip install --upgrade numpy >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to upgrade"
else
	echo_success
fi

# Upgrade pyserial
echo_step	"  Upgrading pyserial"
sudo pip install --upgrade pyserial >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to upgrade"
else
	echo_success
fi

# Install imutils
echo_step	"  Installing imutils"
sudo pip install imutils >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Failed to install"
else
	echo_success
fi

################################################################################
# Final Steps
################################################################################
echo_title 	"Clean Up"
echo_step	"Cleaning up"; echo

# Clean cache
echo_step	"  Cleaning caches"
sudo apt-get -q -y autoclean >>"$INSTALL_LOG"
if [ "$?" -ne 0 ]; then
	echo_warning "Something went wrong"
else
	echo_success
fi

# Reboot
echo_step	"Rebooting in 15 Seconds"; echo
sleep 5
echo_step	"Rebooting in 10 Seconds"; echo
sleep 5
echo_step	"Rebooting in 5"; sleep 1
echo_step	", 4"; sleep 1
echo_step	", 3"; sleep 1
echo_step   ", 2"; sleep 1
echo_step   ", 1"; sleep 1
sudo reboot
