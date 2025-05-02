#!/bin/bash
export NCURSES_NO_UTF8_ACS=1
#dialog output seperator
separator=":"
#user associated with stdin "who am i"
stdin_user=$(who -m | cut -d' ' -f1)
if [ -z "$stdin_user" ]
	then
	stdin_user=$(logname)
fi

#Install Logfile
logfile=/home/$stdin_user/install.log
#Remove Logfile
removelogfile=/home/$stdin_user/remove.log

#Output redirection /dev/null or logfile
LOG_REDIRECTION="/dev/null"
#LOG_REDIRECTION=$logfile

#rtorrent daemon user
the_user=rtorrent-daemon
the_group=rtorrent-common
change_on_script=true

#Script versionnumber
script_versionumber="V3.7"
#Fullmenu true,false
fullmenu=false

#Window dimensions
height=20
small_height=6
width=70
#Window position
x=2
small_x=8
y=5

#os-release
#ID:       | NAME               | VERSION_ID             | /etc/debian_version          | /etc/issue                        | /etc/rpi-issue | ->Distribution
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#linuxmint | LMDE               | release number         | (debian)point release number | NAME+VERSION \n \l                | -              | LMDE
#          | Linux Mint         | point release number   | (debian)VERSION_CODENAME/sid | PRETTYNAME+VERSION_CODENAME \n \l | -              | Linux Mint
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#debian    | Debian GNU/Linux   | release number         | point release number         | NAME+VERSION_ID \n \l             | -              | Debian
#          | Debian GNU/Linux   | release number         | point release number         | NAME+VERSION_ID \n \l             | yes            | Raspberry Pi OS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#ubuntu    | Ubuntu             | point release number   | (debian)VERSION_CODENAME/sid | PRETTY_NAME \n \l                 | -              | Ubuntu
#          | Ubuntu             | point release number   | (debian)VERSION_CODENAME/sid | PRETTY_NAME \n \l                 | -              | Ubuntu LTS 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#raspbian  | Raspbian GNU/Linux | (debian)release number | (debian)point release number | NAME+VERSION_ID \n \l             | yes            | Raspbian
#

#system
architecture=$(dpkg --print-architecture)
bits=$(getconf LONG_BIT)
distributor=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)
name=$(cat /etc/os-release | grep ^NAME | cut -d'"' -f2)
codename=$(cat /etc/os-release | grep ^VERSION= | cut -d'(' -f2 | cut -d')' -f1)

#https://stackoverflow.com/questions/16396146/using-the-operator-in-an-if-statement
if [[ -e "/etc/debian_version" && $name == "Debian GNU/Linux" ]]
then
	version=$(cat /etc/debian_version)
else
	version=$(cat /etc/os-release | grep ^VERSION_ID | cut -d'"' -f2)
fi

if [[ -e "/etc/rpi-issue" && $distributor != "raspbian" ]]
then
	distributor="$distributor (raspbian)"
fi

if [[ $distributor == "ubuntu" || $distributor == "linuxmint" ]]
then
	debian_version=$(cat /etc/debian_version | cut -d'/' -f1)
	codename="$codename ($debian_version)"
fi

#rtorrent
#rtorrent_version=$(apt-cache policy rtorrent | head -3 | tail -1 | cut -d' ' -f4)
#rtorrent_version=$(apt-cache policy rtorrent | tail -2 | head -1 | cut -d' ' -f6)
#rtorrent_version=$(apt-cache policy rtorrent | tail -3 | head -1 | cut -c 6- | cut -d' ' -f1)
#rtorrent_version=$(apt-cache policy rtorrent | grep -A1 "Version table:" | tail -1 | cut -c 6- | cut -d' ' -f1)
#rtorrent_version_micro=$(echo "$rtorrent_version" | cut -d'-' -f1 | cut -d'.' -f3)
rtorrent_version=$(apt-cache policy rtorrent | grep -m 1 "500" | tail -1 | cut -c 6- | cut -d' ' -f1 | cut -d'-' -f1)
libtorrent_version=$(apt-cache policy libtorrent?? | head -3 | tail -1 | cut -d' ' -f4)
RTORRENT_VERSIONS=$(wget -q https://api.github.com/repos/rakshasa/rtorrent/releases -O - | grep tag_name | grep -v '0.9.7\|0.15.2' | cut -d'"' -f4)

RTORRENT_LIST="v$rtorrent_version $RTORRENT_VERSIONS"
last='""off'
variablenname=$(echo $RTORRENT_LIST | sed 's/ /""off"/g')
full="$variablenname$last"
IFS='"' read -a RT_VERSIONS <<< "$full"
reposity_marker="from distro repository"

#python
python_path=$(ls -l /usr/bin/python? | tail -1 | rev | cut -d' ' -f3 | rev)
python_version=$($python_path -V | cut -d' ' -f2)
python_version_major=$(echo "$python_version" | cut -d'.' -f1)
python_version_minor=$(echo "$python_version" | cut -d'.' -f2)
python_pip=python$python_version_major-pip

#php
#php_version="$(apt-cache policy php | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1)"
php_version=$(apt-cache policy php | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1-3)

#apache2
apache2_version=$(apt-cache policy apache2 | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1)

## get mini UID limit ##
low=$(cat /etc/login.defs | grep "^UID_MIN" | grep -o '[[:digit:]]*')
## get max UID limit ##
high=$(cat /etc/login.defs | grep "^UID_MAX" | grep -o '[[:digit:]]*')

#system_low = 1 prevent root from using
system_low=1
let system_high=$((low - 1))

#ruTorrents
#ALL_VERSION=$(wget -q https://api.github.com/repos/Novik/ruTorrent/releases -O - | grep tag_name | cut -d'"' -f4)
ALL_VERSION=$(wget -q https://api.github.com/repos/Novik/ruTorrent/tags -O - | grep name | cut -d'"' -f4 | grep -v 'rutorrent\|plugins')
#remove v4.0 "All Linux Distributions should mark version 4 as "unstable" due to caching issues and use the v4.0.1 hot fix release instead"
#https://github.com/Novik/ruTorrent/releases/tag/v4.0.1-hotfix
STABLE_VERSION=$(echo "$ALL_VERSION" | grep -v 'beta\|v4.0-stable')
#set rutorrent list to all versions(ALL_VERSION) or stable versions(STABLE_VERSION) only
LIST=$STABLE_VERSION

#https://stackoverflow.com/questions/9293887/reading-a-space-delimited-string-into-an-array-in-bash
#https://unix.stackexchange.com/questions/412120/array-into-whiptail-checkbox-bash
last='""off'
variablenname=$(echo $LIST | sed 's/ /""off"/g')
full="$variablenname$last"
IFS='"' read -a VERSIONS <<< "$full"

function SCRIPT_BASE_INSTALL {
	DIALOG_CHECK="$(dpkg-query -W -f='${Status}\n' dialog 2>/dev/null | grep -c "ok installed")"
	WGET_CHECK="$(dpkg-query -W -f='${Status}\n' wget 2>/dev/null | grep -c "ok installed")"
	
	if [ "$DIALOG_CHECK" -ne 1 ] || [ "$WGET_CHECK" -ne 1 ];
	then
		if [ "$DIALOG_CHECK" -ne 1 ];
		then
			base0=dialog
		fi
		if [ "$WGET_CHECK" -ne 1 ];
		then
			base1=wget
		fi
		apt-get -y install $base0 $base1 
		#1> /dev/null
	fi
}

function MENU {
	LOG_REDIRECTION="/dev/null"
	menu_options=("0" "System Information"
	              "1" "Licence"
	              "2" "Changelog"
	              "I" "Scripted Installation"
	              "E" "Update/Change rtorrent"
	              "T" "Update/Change ruTorrent"
	              "V" "Change VHost"
	              "S" "Enable/Renew SSL for VHost"
	              "W" "Enable/Disable WebAuth"
	              "A" "Add User to WebAuth"
	              "U" "Remove User from WebAuth"
	              "R" "Move to unrar-nonfree variant"
	              "H" "Add/Remove Softlink to/from the rtorrent users homedir"
	              "G" "Edit rtorrent.rc/Move rtorrent basedir"
	              "C" "Change rtorrent user"
	              "X" "Remove complete rtorrent & ruTorrent installation")
	
	if [ -f $logfile ]
	then
		menu_options+=("L" "Show Installation log")
	fi
	
	if [ -f $removelogfile ]
	then
		menu_options+=("M" "Show Remove log")
	fi
	
	if $fullmenu
	then
		menu_options+=("9" "Add User"
		               "6" "Remove User"
		               "4" "Allow SSH"
		               "5" "Deny SSH"
		               "7" "Install webserver & php")
	fi
	
	#	               "Z" "Install Complete"
	#	               "N" "Script"
	
	SELECTED=$(dialog \
	--backtitle "rtorrent & ruTorrent Installation Script $script_versionumber" \
	--title "Menu" \
	--stdout \
	--begin $x $y \
	--colors \
	--cancel-label "Exit" \
	--menu "Options" $height $width 13 "${menu_options[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		MENU_OPTIONS $SELECTED;;
	1|255)	EXIT;;
	esac
}

function MENU_OPTIONS () {
	case $1 in
	0)	HEADER;;
	1)	LICENSE;;
	2)	CHANGELOG;;
	I)	SCRIPTED_INSTALL;;
	E)	MENU_RTORRENT;;
	T)	MENU_RUTORRENT;;
	V)	CHANGE_VHOST;;
	S)	SSL_FOR_WEBSERVER;;
	W)	WEBAUTH_TOGGLE;;
	A)	ADD_USER_TO_WEBAUTH;;
	U)	REMOVE_WEBAUTH_USER;;
	R)	USE_UNRAR_NONFREE;;
	H)	SOFTLINK_TO_HOMEDIR;;
	G)	MOVE_RTORRENT_BASEDIR;;
	X)	REMOVE_EVERYTHING;;
	L)	INSTALLLOG;;
	M)	REMOVELOG;;
	9)	ADD_USER;;
	6)	REMOVE_USER;;
	4)	ALLOW_SSH;;
	5)	DENY_SSH;;
	7)	APACHE2;;
	Z)	INSTALL_COMPLETE;;
	N)	SCRIPT;;
	C)	SELECT_USER;;
	esac
}

function EXIT {
	#https://stackoverflow.com/questions/49733211/bash-jump-to-bottom-of-terminal
	tput cup $(tput lines) 0
	echo ""
	echo "goodbye!"
	exit 0
}

function INSTALLLOG {
	dialog --title "Installation log" --stdout --begin $x $y --ok-label "Exit" --extra-button --extra-label "Remove \"Installation Log\"" --no-collapse --textbox $logfile $height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	3)			rm -f $logfile;;
	esac
	MENU
}

function REMOVELOG {
	dialog --title "Remove log" --stdout --begin $x $y --ok-label "Exit" --extra-button --extra-label "Remove \"Remove Log\"" --no-collapse --textbox $removelogfile $height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	3)			rm -f $removelogfile;;
	esac
	MENU
}

function HEADER {
	systemupdate=$(stat /var/cache/apt/ | head -6 | tail -1 | cut -d' ' -f2- | cut -d'.' -f1)
	dialog \
	--backtitle "last systemupdate on $systemupdate" \
	--title "System Information" \
	--stdout \
	--begin $x $y \
	--colors \
	--msgbox "\
System:\n\
   Architecture:           \Z4$architecture\Z0\n\
   Address Register:       \Z4$bits Bit\Z0\n\
\n\
Operation System:\n\
   OS:                     \Z4$name\Z0\n\
   Version:                \Z4$version\Z0\n\
   OS Codename:            \Z4$codename\Z0\n\
   Distributor:            \Z4$distributor\Z0\n\
\n\
   Active user:            \Z4$stdin_user\Z0\n\
\n\
Software Versions:\n\
   Python:                 \Z4$python_version\Z0\n\
   Apache2:                \Z4$apache2_version\Z0\n\
   PHP:                    \Z4$php_version\Z0"\
	$height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)   ;;
	esac
	MENU
}

#   rtorrent(distro):       \Z4$rtorrent_version\Z0\n\
#   libtorrent(distro):     \Z4$libtorrent_version\Z0\n\

function LICENSE {
	dialog \
	--title "Licence" \
	--stdout \
	--begin $x $y \
	--colors \
	--msgbox "\
\n\
 THE BEER-WARE LICENSE (Revision 42)©:\n\
\n\
 \Z2I\Z0 wrote this script. As long as you retain this notice you\n\
 can do whatever you want with this stuff. If we meet some day,\n\
 and you think this stuff is worth it, you can buy me a beer\n\
 in return.\n\
\n\
 Contact me? use Github\n\
\n\
 © Poul-Henning Kamp's beerware license."\
	$height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)   ;;
	esac
	MENU
}

function CHANGELOG {
	#https://superuser.com/questions/802650/make-a-web-request-cat-response-to-stdout
	# local homedir
	#link=$(cat $(getent passwd "$stdin_user" | cut -d':' -f6)/changelog)
	#link=$(cat /home/$stdin_user/changelog)
	# github
	link=$(wget -q -O - https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/changelog)
	
	dialog --title "Changelog" --stdout --begin $x $y --no-collapse \
	--backtitle "rtorrent & ruTorrent Installation Script $script_versionumber" \
	--msgbox "$link" $height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)   ;;
	esac
	MENU
}

function SELECT_USER () {
	## use awk to print if UID >= $MIN and UID <= $MAX ##
	#user=$(getent passwd {1000..2000} | cut -d':' -f1)
	user=$(awk -F':' -v "min=${low}" -v "max=${high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1 | sort)
	system_user=$(awk -F':' -v "min=${system_low}" -v "max=${system_high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1 | sort)
	
	end='""off'
	variablenname=$(echo $user | sed 's/ /""off"/g')
	full="$variablenname$end"
	IFS='"' read -a USERS <<< "$full"
	
	system_last='""off"add new system user""off'
	variablensystemname=$(echo $system_user | sed 's/ /""off"/g')
	systemfull="$variablensystemname$system_last"
	IFS='"' read -a SYSTEM_USERS <<< "$systemfull"
	
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	user_of_rtorrent_group=$(grep $rtorrent_user_group /etc/group | cut -d':' -f4)
	IFS=',' read -a list_of_rtorrent_group_user <<< "$user_of_rtorrent_group"
	
	rtorrentuser=${list_of_rtorrent_group_user[@]/"www-data"}
	rtorrentuser="${rtorrentuser[@]}"
	#remove space from String
	rtorrentuser=$(echo $rtorrentuser | sed 's/ //g')
	
	#https://stackoverflow.com/questions/15028567/get-the-index-of-a-value-in-a-bash-array
	for i in "${!USERS[@]}"
	do
		[[ "${USERS[$i]}" = "${rtorrentuser}" ]] && break
	done
	echo $i
		
	for each in "${USERS[@]}"
	do
		echo "$each"
	done
	
	USERS[$i+2]=on
	SELECTED=$(dialog \
	--title "Select rtorrent User" \
	--stdout \
	--begin $x $y \
	--extra-button \
	--extra-label "Add User"\
	--radiolist "current rtorrent User (*)" $height $width 13 "${USERS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		PRESENT_USER $SELECTED;;
	1|255)	;;
	3)		ADD_USER;;
	esac
	MENU
}

#rtorrent daemon user
#rtorrent_daemon_user=rtorrent-daemon
#rtorrent_daemon_group=rtorrent-common

function PRESENT_USER () {
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	user_of_rtorrent_group=$(grep $rtorrent_user_group /etc/group | cut -d':' -f4)
	IFS=',' read -a list_of_rtorrent_group_user <<< "$user_of_rtorrent_group"
	
	rtorrentuser=${list_of_rtorrent_group_user[@]/"www-data"}
	rtorrentuser="${rtorrentuser[@]}"
	#remove space from String
	rtorrentuser=$(echo $rtorrentuser | sed 's/ //g')
	
	location=$(cat /etc/systemd/system/rtorrent.service | grep "ExecStart" | cut -d'=' -f3 | cut -d'.' -f1)
	status=$(ls -lrt /home/$rtorrentuser | grep "rtorrent" | grep -c "^l")
	
	if [ $status == "1" ]
	then
		unlink /home/$rtorrentuser/rtorrent 2> /dev/null
	fi
	
	deluser $rtorrentuser $rtorrent_user_group 1> /dev/null
	usermod -a -G $rtorrent_user_group $1
	
	if [ $status == "1" ]
	then
		ln -s $location /home/$1/rtorrent
	fi
}

function ADD_USER () {
	unset OUTPUT
	OUTPUT=$(dialog \
	--title "New User" \
	--stdout \
	--begin $x $y \
	--insecure "$@" \
	--trim \
	--output-separator $separator \
	--mixedform "Create new User for rtorrent" \
	$height $width 0 \
	"Username          :" 1 1 ""    1 21 12 0 0 \
	"Password          :" 2 1 ""    2 21 10 0 1 \
	"Retype Password   :" 3 1 ""    3 21 10 0 1 \
	"Allow SSH (yes/no):" 4 1 "yes" 4 21  5 0 0 \
	)
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	#echo $OUTPUT
	#remove spaces from String
	OUTPUT=$(echo $OUTPUT | sed 's/ //g')
	IFS=$separator read -a SHOWN <<< "$OUTPUT"
	
	case $EXITCODE in
	0)		CREATE_USER "${SHOWN[@]}"
			PRESENT_USER "${SHOWN[0]}";;
	1|255)	;;
	esac
	MENU
}

function CREATE_USER () {
	arr=("$@")
	#https://acloudguru.com/blog/engineering/conditions-in-bash-scripting-if-statements
	unset state
	if [ -z "${arr[0]}" ]
	then
		answer1="No Username entered"
		state="error"
	else
		if [[ $(getent passwd | grep -c ^${arr[0]}:) -ne 0 ]]
		then
			answer1="User exist"
			state="error"
		else
			answer1=""
		fi
	fi
	
	if [ -z "${arr[1]}" ] || [ -z "${arr[2]}" ]
	then
		answer2="Password is empty"
		state="error"
	else
		if [ "${arr[1]}" != "${arr[2]}" ]
		then
			answer2="Passwords does not match"
			state="error"
		else
			answer2=""
		fi
	fi
	
	if [[ $state == "error" ]]
	then
		dialog --title "Error" \
		--stdout \
		--begin $small_x $y \
		--msgbox "\
$answer1\n\
$answer2\
		"\
		$small_height $width
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0|1|255)   ADD_USER;;
		esac
	else
		(echo ${arr[1]}; echo ${arr[1]}) | sudo adduser --force-badname --gecos "" ${arr[0]} --quiet 2> /dev/null
		#https://stackoverflow.com/questions/11392189/how-can-i-convert-a-string-from-uppercase-to-lowercase-in-bash
		if [ "${arr[3],,}" == "no" ];
		then
			#echo "Deny SSH"
			if grep -q '^DenyUsers' '/etc/ssh/sshd_config';
			then
				present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
				sudo sed -i 's/^DenyUsers.*/'"$present"' '"$1"'/g' /etc/ssh/sshd_config
			else
				sudo sed -i '$aDenyUsers\t'"$1"'' /etc/ssh/sshd_config
			fi
			systemctl restart ssh
		fi
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "\nNew User ${arr[0]} created" $small_height $width
	fi
}

function ALLOW_SSH () {
	if grep -q '^DenyUsers' '/etc/ssh/sshd_config';
	then
		present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
		#change tab to space
		present2=$(echo $present)
		
		IFS=' ' read -a DENYLIST <<< "$present2"
		
		DENYLIST_NAMES=${DENYLIST[@]/"DenyUsers"}
		
		last='""off'
		variablenname=$(echo $DENYLIST_NAMES | sed 's/ /""off"/g')
		full="$variablenname$last"
		IFS='"' read -a DENYLISTUSERS <<< "$full"
		
		SELECTED=$(dialog --title "Remove User from SSH DenyUsers List" --stdout --begin $x $y --radiolist "Select User" $height $width 13 "${DENYLISTUSERS[@]}")
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		#echo $EXITCODE
		#echo $SELECTED
		
		DENYLIST_NEW=${DENYLIST_NAMES[@]/$SELECTED}
		new_string="${DENYLIST_NEW[@]}"
		#remove double space from String 
		new_string=$(echo $new_string | sed 's/  / /g')
		#echo $new_string
		
		case $EXITCODE in
		0)		sudo sed -i 's/^DenyUsers.*/DenyUsers\t'"$new_string"'/g' /etc/ssh/sshd_config
				#https://serverfault.com/questions/477503/check-if-array-is-empty-in-bash
				if [ "$(echo -ne ${DENYLIST_NEW} | wc -m)" -eq 0 ]
				then
					#echo "Array is empty"
					sudo sed -i '/^DenyUsers/d' /etc/ssh/sshd_config
				fi
				systemctl restart ssh
				dialog --title "Done" --stdout --begin $small_x $y --msgbox "User $SELECTED removed from DenyUsers List" $small_height $width;;
		1|255)	;;
		esac
	else
		dialog --title "Error" --stdout --begin $small_x $y --msgbox "DenyUsers does not exist" $small_height $width
	fi
	MENU
}
#testfunction only
function DIFF_USERS () {
	user=$(awk -F':' -v "min=${low}" -v "max=${high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1)
	#echo $user
	present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
	present2=$(echo $present | cut -d' ' -f2-)
	#echo $present2
	
	#https://stackoverflow.com/questions/454427/string-difference-in-bash
	diff=$(comm -23 <(tr ' ' $'\n' <<< $user | sort) <(tr ' ' $'\n' <<< $present2 | sort))
	#echo $diff
}

function DENY_SSH () {
	user=$(awk -F':' -v "min=${low}" -v "max=${high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1)
	
	present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
	#change TAB to space and remove DenyUsers from String
	present2=$(echo $present | cut -d' ' -f2-)
	
	#https://stackoverflow.com/questions/454427/string-difference-in-bash
	diff=$(comm -23 <(tr ' ' $'\n' <<< $user | sort) <(tr ' ' $'\n' <<< $present2 | sort))
	
	end='""off'
	variablenname=$(echo $diff | sed 's/ /""off"/g')
	full="$variablenname$end"
	IFS='"' read -a USERS <<< "$full"
	
	SELECTED=$(dialog --title "Remove SSH from User" --stdout --begin $x $y --radiolist "Add User to SSH DenyUsers List" $height $width 13 "${USERS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		DENY_SSH_FORM_USER $SELECTED;;
	1|255)	;;
	esac
	MENU
}

function DENY_SSH_FORM_USER () {
	if grep -q '^DenyUsers' '/etc/ssh/sshd_config';
	then
		present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
		if grep -q $1 <<< "$present";
		then
			dialog --title "Error" --stdout --begin $small_x $y --msgbox "User $1 is allready denyed from SSH" $small_height $width
		else
			sudo sed -i 's/^DenyUsers.*/'"$present"' '"$1"'/g' /etc/ssh/sshd_config
			dialog --title "Done" --stdout --begin $small_x $y --msgbox "User $1 is now denyed from SSH" $small_height $width
		fi
	else
		sudo sed -i '$aDenyUsers\t'"$1"'' /etc/ssh/sshd_config
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "User $1 is now denyed from SSH" $small_height $width
	fi
	systemctl restart ssh
}

function REMOVE_USER () {
	user=$(awk -F':' -v "min=${low}" -v "max=${high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1 | sort)
	
	end='""off'
	variablenname=$(echo $user | sed 's/ /""off"/g')
	full="$variablenname$end"
	IFS='"' read -a USERS <<< "$full"
	
	SELECTED=$(dialog --title "Remove Linux User" --stdout --begin $x $y --radiolist "Select User" $height $width 13 "${USERS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		DEL_USER $SELECTED;;
	1|255)	;;
	esac
	MENU
}

function DEL_USER () {
	if [ $(id -u $1) == "$low" ]
	then
		#echo "first user"
		dialog --title "Error" --begin $small_x $y --stdout --msgbox "Won't delete first User" $small_height $width
	else
		#echo "someone else"
		userdel -f -r $1 >& /dev/null
		
		if grep -q '^DenyUsers' '/etc/ssh/sshd_config';
		then
			#echo "DenyUsers exist"
			present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
			if grep -q $1 <<< "$present";
			then
				#change tab to space
				present2=$(echo $present)
				IFS=' ' read -a DENYLIST <<< "$present2"
				
				DENYLIST_NAMES=${DENYLIST[@]/"DenyUsers"}
				
				DENYLIST_NEW=${DENYLIST_NAMES[@]/#%$1}
				new_string="${DENYLIST_NEW[@]}"
				#remove double space from String 
				new_string=$(echo $new_string | sed 's/  / /g')
				
				sudo sed -i 's/^DenyUsers.*/DenyUsers\t'"$new_string"'/g' /etc/ssh/sshd_config
				if [ "$(echo -ne ${DENYLIST_NEW} | wc -m)" -eq 0 ]
				then
					#echo "Array is empty"
					sudo sed -i '/^DenyUsers/d' /etc/ssh/sshd_config
				fi
				systemctl restart ssh
			fi
		else
			:
		fi
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "User $1 deleted" $small_heightheight $width
	fi
}

function SYSTEM_UPDATE {
	apt-get update 1>> $LOG_REDIRECTION
	apt-get -y dist-upgrade 1>> $LOG_REDIRECTION
}

function APACHE2 {
	apt-get -y install openssl apache2 apache2-utils php$PHP_VERSION php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-cli php$PHP_VERSION-xml libapache2-mod-php$PHP_VERSION unzip curl 2>/dev/null 1>> $LOG_REDIRECTION
	
	#https://www.digitalocean.com/community/tutorials/apache-configuration-error-ah00558-could-not-reliably-determine-the-server-s-fully-qualified-domain-name
	echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
	
	#https://www.inmotionhosting.com/support/server/apache/hide-apache-version-and-linux-os/
	#https://stackoverflow.com/questions/24889346/how-to-uncomment-a-line-that-contains-a-specific-string-using-sed
	sed -i '/ServerTokens OS/  s/^/#/' /etc/apache2/conf-enabled/security.conf
	sed -i '/#ServerTokens Full/a ServerTokens Prod' /etc/apache2/conf-enabled/security.conf
	
	sed -i '/ServerSignature On/  s/^/#/' /etc/apache2/conf-enabled/security.conf
	sed -i '/ServerSignature Off/  s/^#//' /etc/apache2/conf-enabled/security.conf
	
	systemctl reload apache2.service 1>> $LOG_REDIRECTION
	systemctl restart apache2.service 1>> $LOG_REDIRECTION
}

function MENU_RTORRENT () {
	installed_rtorrent=$(rtorrent -h | grep "client version" | cut -d' ' -f5 | rev | sed 's/\.//' | rev)
	#rtorrent_version=$(apt-cache policy rtorrent | tail -2 | head -1 | cut -d' ' -f6)
	RT_VERSIONS[0]="v$rtorrent_version $reposity_marker"
	RTORRENT_VERSION=$(dialog --title "Choose rTorrent Version" --stdout --begin $x $y --radiolist "rTorrent Versions installed is $installed_rtorrent" $height $width 10 "${RT_VERSIONS[@]}")
	EXITCODE=$?
	#echo $EXITCODE
	#echo $RUTORRENT_VERSION
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		UPDATE_RTORRENT;;
	1|255)	;;
	esac
	MENU
}

function UPDATE_RTORRENT () {
	systemctl stop apache2.service 1> /dev/null
	systemctl stop rtorrent.service 1> /dev/null
	
	apt-get purge -y rtorrent libtorrent* >> $LOG_REDIRECTION 2>&1
	
	INSTALL_RTORRENT
	
	rtorrent_rc_path=$(find / -not \( -path /proc/sys/fs/binfmt_misc -prune \) -name .rtorrent.rc)
	
	if (( $(echo $RTORRENT_VERSION | cut -d' ' -f1 | cut -d'-' -f1 | sed 's/\.//g' | sed 's/0//' | sed 's/v//') >= 100 ))
	then
		sed -i '/^#trackers.delay_scrape.*/ s/^#//' $rtorrent_rc_path
	fi
	
	if (( $(echo $RTORRENT_VERSION | cut -d' ' -f1 | cut -d'-' -f1 | sed 's/\.//g' | sed 's/0//' | sed 's/v//') < 100 ))
	then
		sed -i '/^trackers.delay_scrape.*/ s/^/#/' $rtorrent_rc_path
	fi
	
	systemctl start rtorrent.service 1> /dev/null
	systemctl start apache2.service 1> /dev/null
}

function INSTALL_RTORRENT () {
	if [[ $RTORRENT_VERSION == "v$rtorrent_version $reposity_marker" ]]
	then
		apt-get -y install rtorrent >> $LOG_REDIRECTION 2>&1
	else
		#apt-get install build-essential libsigc++-2.0-dev pkg-config comerr-dev libcurl3-openssl-dev libidn11-dev libkrb5-dev libssl-dev zlib1g-dev libncurses5 libncurses5-dev automake libtool libxmlrpc-core-c3-dev dialog checkinstall 1>> $LOG_REDIRECTION
		
		REPO_URL='https://api.github.com/repos/rakshasa/rtorrent/releases'
		RESPONSE_LIST=$(wget -q $REPO_URL -O - | grep browser_download | cut -d'"' -f4)
		#RESPONSE_LIST=$(wget -q --header='Accept: application/vnd.github+json' --header='X-GitHub-Api-Version: 2022-11-28' $REPO_URL -O -)
		#RESPONSE_LIST=$(curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" $REPO_URL)
		#curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/rakshasa/rtorrent/releases
		#wget -q https://api.github.com/repos/rakshasa/rtorrent/releases -O - | grep browser_download | cut -d'"' -f4
		
		#echo "$RESPONSE_LIST" | grep $RTORRENT_VERSION | grep browser_download | cut -d'"' -f4
		
		for f in $(echo "$RESPONSE_LIST" | grep $RTORRENT_VERSION)
		do
			#echo $f
			output=$(echo $f | cut -d'/' -f9 | cut -d'-' -f1)
			wget -q "$f" -O "$output".tar.gz
		done
		
		tar xzvf libtorrent.tar.gz | dialog --colors --begin $x $y --progressbox "libtorrent: \Z1tar,\Z0 configure, make, make install" $height $width
		cd /home/$stdin_user/libtorrent-*
		
		#CPU Cores: The make option -j$(nproc) will utilize all available cpu cores.
		#https://stackoverflow.com/questions/4975127/why-isnt-mkdir-p-working-right-in-a-script-called-by-checkinstall
		#https://jasonwryan.com/blog/2011/11/29/rtorrent/
		./configure --prefix=/usr/ 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: tar, \Z1configure,\Z0 make, make install" $height $width
		make -j$(nproc) 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: tar, configure, \Z1make,\Z0 make install" $height $width
		checkinstall -D -y --fstrans=no 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: tar, configure, make, \Z1make install\Z0" $height $width
		
		cd /home/$stdin_user/
		tar xzvf rtorrent.tar.gz | dialog --colors --begin $x $y --progressbox "rtorrent: \Z1tar,\Z0 configure, make, make install" $height $width
		cd /home/$stdin_user/rtorrent-*
		
		#echo $(echo $RTORRENT_VERSION | cut -d'.' -f2)
		if [[ "$(echo $RTORRENT_VERSION | cut -d'.' -f2)" -gt "10" ]]
		then
			#echo ">10"
			./configure --with-xmlrpc-tinyxml2 --prefix=/usr/ --libdir=/usr/lib 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: tar, \Z1configure,\Z0 make, make install" $height $width
		else
			#echo "<=10"
			./configure --with-xmlrpc-c --prefix=/usr/ --libdir=/usr/lib 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: tar, \Z1configure,\Z0 make, make install" $height $width
		fi
		
		make -j$(nproc) 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: tar, configure, \Z1make,\Z0 make install" $height $width
		checkinstall -D -y --fstrans=no 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: tar, configure, make, \Z1make install\Z0" $height $width
		ldconfig
		
		cd /home/$stdin_user/
		rm libtorrent.tar.gz
		rm -r libtorrent-*
		rm rtorrent.tar.gz
		rm -r rtorrent-*
		#rm description-pak
	fi
}

function RTORRENT () {
	arr=("$@")
	# USER[_] 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
	USER[0]=
	USER[1]=${arr[1]}
	USER[2]=
	USER[3]=${arr[3]}
	USER[4]=${arr[4]}
	USER[5]=
	
	#echo ${USER[1]}
	#echo ${USER[3]}
	#echo ${USER[4]}
	
	#https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template
	wget -q -O - "https://raw.githubusercontent.com/wiki/rakshasa/rtorrent/CONFIG-Template.md" | sed -ne "/^######/,/^### END/p" | sed -re "s:/home/USERNAME:/srv:" >${USER[4]}/.rtorrent.rc
	
	chown -R ${USER[1]}:${USER[3]} ${USER[4]}/.rtorrent.rc
	
	CREATE_TMPFILES "${USER[@]}"
	
	#https://github.com/rakshasa/rtorrent/issues/949#issuecomment-572528586
	sed -i '/^system.umask.*/a session.use_lock.set = no' ${USER[4]}/.rtorrent.rc
	#rpc enabled from local socket
	#https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC
	#https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
	sed -i '/(session.path),rpc.socket)/ s/^#//' ${USER[4]}/.rtorrent.rc
	
	#not usable links sessiondata also to run/torrent removes everything on reboot
	#sed -i 's:(cfg.basedir),".session/":"/run/rtorrent/":' ${USER[4]}/.rtorrent.rc
	
	#move socket to run
	sed -i 's:(cat,(session.path),rpc.socket):/run/rtorrent/rpc.socket:' ${USER[4]}/.rtorrent.rc
	#sed -i ':rtorrent.pid: s:(session.path):/run/rtorrent/:' ${USER[4]}/.rtorrent.rc ##not working correctly
	sed -i 's:    (session.path):    /run/rtorrent/:' ${USER[4]}/.rtorrent.rc
	##sed -i '/rtorrent.pid/ s/(session.path)/\/run\/rtorrent\//' ${USER[4]}/.rtorrent.rc
	
	#set rights to 770
	sed -i '27iexecute.throw = chmod, -R, 770, (cat, (cfg.basedir))' ${USER[4]}/.rtorrent.rc
	
	#echo "0.15.1" | sed 's/\.//g' | sed 's/0//' | sed 's/v//'
	#if (( $rtorrent_version_micro <= 6 ))
	if (( $(echo $RTORRENT_VERSION | cut -d' ' -f1 | cut -d'-' -f1 | sed 's/\.//g' | sed 's/0//' | sed 's/v//') <= 96 ))
	then
		echo "rtorrent Version is equal or lower than 0.9.6" 1>> $LOG_REDIRECTION
		apt-get install -y tmux >> $LOG_REDIRECTION 2>&1
		RTORRENT_TMUX_SERVICE "${USER[@]}"
	else
		echo "daemon mode enabled since 0.9.7+" 1>> $LOG_REDIRECTION
		sed -i '/system.daemon.set/ s/^#//' ${USER[4]}/.rtorrent.rc
		RTORRENT_SERVICE "${USER[@]}"
	fi
	
	sed -i '/^trackers.numwant.set.*/a #trackers.delay_scrape = yes' ${USER[4]}/.rtorrent.rc
	
	if (( $(echo $RTORRENT_VERSION | cut -d' ' -f1 | cut -d'-' -f1 | sed 's/\.//g' | sed 's/0//' | sed 's/v//') >= 100 ))
	then
		#sed -i '/^trackers.numwant.set.*/a trackers.delay_scrape = yes' ${USER[4]}/.rtorrent.rc
		sed -i '/^#trackers.delay_scrape.*/ s/^#//' ${USER[4]}/.rtorrent.rc
	fi
	
	echo "rtorrent.service" 1>> $LOG_REDIRECTION
	cat /etc/systemd/system/rtorrent.service >> $LOG_REDIRECTION
}

function CREATE_TMPFILES () {
	arr=("$@")
	#https://serverfault.com/questions/779634/create-a-directory-under-var-run-at-boot
	cat > "/usr/lib/tmpfiles.d/rtorrent.conf" <<-EOF
#Type Path            Mode UID      GID        Age Argument
d     /run/rtorrent   0770 ${arr[1]} ${arr[3]}   -   -
EOF
	
	# inital placement for the direct run
	mkdir -p /run/rtorrent
	chown -R ${arr[1]}:${arr[3]} /run/rtorrent
	#chmod -R 775 /run/rtorrent
}

#tmux session explanations
#http://man.openbsd.org/OpenBSD-current/man1/tmux.1
#https://coderwall.com/p/omqa2w/tmux-basics
#https://stackoverflow.com/questions/39523167/how-do-you-send-keys-to-a-specific-window-in-tmux

#tmux -2 new-session -d -s rtorrent-session /usr/bin/rtorrent
#
#     -2                                                      [Force tmux to assume the terminal supports 256 colours. This is equivalent to -T 256]
#        new-session    -s rtorrent-session                   [Creating named session which can be used we want the session to run the background]
#                    -d                                       [detach session from current terminal]
#                                           /usr/bin/rtorrent [Programm that startet inside the tmux session]
#
#tmux send-keys -t rtorrent-session C-q
#     send-keys -t                                            [Send a key or keys to a window or client, target panel {-t}]
#                  rtorrent-session                           [{session}]
#                                   C-q                       [Send keys]
#
#tmux kill-session -t rtorrent-session
#     kill-session -t                                         [Destroy the given session]

function RTORRENT_TMUX_SERVICE () {
	arr=("$@")
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
[Unit]
Description=rtorrent (in tmux)
Requires=network-online.target
After=apache2.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=${arr[1]}
Group=${arr[3]}
ExecStart=/usr/bin/tmux -2 new-session -d -s rtorrent-session /usr/bin/rtorrent -n -o import=${arr[4]}/.rtorrent.rc
ExecStop=/usr/bin/tmux send-keys -t rtorrent-session C-q

[Install]
WantedBy=default.target
EOF
}

#https://www.freedesktop.org/software/systemd/man/systemd.kill.html#KillSignal=
#https://github.com/rakshasa/rtorrent/wiki/User-Guide
function RTORRENT_SERVICE () {
	arr=("$@")
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
[Unit]
Description=rtorrent deamon
Requires=network-online.target
After=apache2.service

[Service]
Type=simple
RemainAfterExit=yes
User=${arr[1]}
Group=${arr[3]}
ExecStart=/usr/bin/rtorrent -n -o import=${arr[4]}/.rtorrent.rc
KillMode=mixed
KillSignal=SIGINT
#Stop -> SIGINT - 10s - SIGTERM (if not stopped)
#TimeoutStopSec=10
#SendSIGKILL=yes
#FinalKillSignal=SIGTERM

[Install]
WantedBy=default.target
EOF
}

function MOVE_RTORRENT_BASEDIR () {
	rtorrent_rc_path=$(cat /etc/systemd/system/rtorrent.service | grep "ExecStart" | cut -d'=' -f3)
	rtorrent_basedir=$(echo $rtorrent_rc_path | rev | cut -d'/' -f3- | rev)
	
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	
	rtorrentuser=${list_of_rtorrent_group_user[@]/"www-data"}
	rtorrentuser="${rtorrentuser[@]}"
	#remove space from String
	rtorrentuser=$(echo $rtorrentuser | sed 's/ //g')
	
	#location=$(cat /etc/systemd/system/rtorrent.service | grep "ExecStart" | cut -d'=' -f3 | cut -d'.' -f1)
	status=$(ls -lrt /home/$rtorrentuser | grep "rtorrent" | grep -c "^l")
	
	PORT_RANGE=$(grep 'port_range.set' $rtorrent_rc_path | cut -d' ' -f3)
	PORT_RANGE_MIN=$(echo $PORT_RANGE | cut -d'-' -f1)
	PORT_RANGE_MAX=$(echo $PORT_RANGE | cut -d'-' -f2)
	PORT_SET=$(grep 'port_random.set' $rtorrent_rc_path | cut -d' ' -f3)
	DLFOLDER=$rtorrent_basedir
	
	PRESENT_PORT_SET=$PORT_SET
	PRESENT_DLFOLDER=$DLFOLDER
	
	while :; do
		OUTPUT=$(dialog \
		--title "Edit rtorrent.rc" \
		--stdout \
		--begin $x $y \
		--trim \
		--extra-button \
		--colors \
		--extra-label "Change Basedir" \
		--output-separator $separator \
		--default-button "ok" \
		--mixedform "Port Range defines the usable Ports for rtorrent\n
Random Listening Port let rtorrent set the Port randomly\n
rtorrent folder stucture:\n
	\Z4$DLFOLDER\Zn \n
	 └── /rtorrent \n
	      ├── /.session \n
	      ├── /download \n
	      ├── /log \n
	      └── /watch \n
	           ├── /load \n
	           └── /start"\
		$height $width 0 \
		"Port Range                    :" 1 1  " $PORT_RANGE_MIN" 1 33  6 0 0 \
		"-"                               1 39 " $PORT_RANGE_MAX" 1 40  6 0 0 \
		"Random Listening Port (yes/no):" 2 1  "$PORT_SET"        2 33  5 0 0 \
		"rtorrent basedir              :" 3 1  "$DLFOLDER"        3 33 31 0 2 \
		)
		EXITCODE=$?
		#remove spaces from String
		OUTPUT=$(echo $OUTPUT | sed 's/ //g')
		IFS=$separator read -a SHOWN <<< "$OUTPUT"
		
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0)	
			EXITLOOP=0
			break;;
		1|255)
			EXITLOOP=1
			break;;
		3)
			RETURN=$(dialog --stdout --begin $x $y --dselect "$DLFOLDER" 10 $width)
			EXITCODE=$?
			#https://stackoverflow.com/questions/9018723/what-is-the-simplest-way-to-remove-a-trailing-slash-from-each-parameter
			RETURN=$(echo "$RETURN" | sed 's:/*$::')
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			case $EXITCODE in
			0)		PORT_RANGE_MIN=${SHOWN[0]}
					PORT_RANGE_MAX=${SHOWN[1]}
					PORT_SET=${SHOWN[2]}
					DLFOLDER=$RETURN;;
			1|255)	EXITLOOP=1
					break;;
			esac
		esac
	done
	
	case $EXITLOOP in
	0)	# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
		RC[0]="${SHOWN[0]}-${SHOWN[1]}"
		RC[1]="${SHOWN[2]}"
		RC[2]="${SHOWN[3]}"
		
		systemctl stop rtorrent.service 1> /dev/null
		
		sed -i '/port_range.set/ s/'"$PORT_RANGE"'/'"${RC[0]}"'/' $rtorrent_rc_path
		sed -i '/port_random.set/ s/'"$PRESENT_PORT_SET"'/'"${RC[1]}"'/' $rtorrent_rc_path
		
		if [[ "$PRESENT_DLFOLDER" != "${RC[2]}" ]]
		then
			#echo "differ"
			sed -i 's#'"$PRESENT_DLFOLDER"'#'"${RC[2]}"'#' $rtorrent_rc_path
			
			rm $PRESENT_DLFOLDER/rtorrent/.session/*.libtorrent_resume
			rm $PRESENT_DLFOLDER/rtorrent/.session/*.rtorrent
			#sed -i 's#'"$PRESENT_DLFOLDER"'#'"${RC[2]}"'#g' $PRESENT_DLFOLDER/rtorrent/.session/*.torrent.rtorrent
			
			sed -i 's#'"$PRESENT_DLFOLDER"'#'"${RC[2]}"'#' /etc/systemd/system/rtorrent.service
			systemctl daemon-reload 1> /dev/null
			
			if [ $status == "1" ]
			then
				unlink /home/$rtorrentuser/rtorrent 2>> /dev/null
			fi
			
			mv $PRESENT_DLFOLDER/rtorrent ${RC[2]}/rtorrent
			chown -R $rtorrent_user_name:$rtorrent_user_group ${RC[2]}/rtorrent/.rtorrent.rc
			
			#echo $rtorrentuser
			#echo ${RC[2]}
			if [ $status == "1" ]
			then
				ln -s ${RC[2]}/rtorrent /home/$rtorrentuser/rtorrent
			fi
		else
			:
			#echo "same"
		fi
		
		systemctl start rtorrent.service 1> /dev/null;;
	1)	;;
	esac
	MENU
}

function SSL_FOR_WEBSERVER () {
	dummy_hostname=$(wget -q -O - ipinfo.io/json | grep "hostname" | cut -d'"' -f4)
	OUTPUT=$(dialog \
	--title "Webadress" \
	--stdout \
	--begin $x $y \
	--trim \
	--ok-label "Self Signed" \
	--extra-button \
	--extra-label "Let's Encrypt" \
	--inputbox "Enter the Domain Name for the Webpage and choose the SSL Certificate" $height $width $dummy_hostname)
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)  	SELF_SIGNED $OUTPUT;;
	1|255)	;;
	3)  	LE_SIGNED $OUTPUT;;
	esac
	MENU
}

function SELF_SIGNED () {
	if [[ $(a2query -s | cut -d' ' -f1 | grep -v https_redirect | grep -c -i "SS-SSL") -ne 0 ]]
	then
		DNS=$(openssl x509 -text -noout -in /etc/ssl/certs/rutorrent-selfsigned.crt | grep "DNS" | cut -d':' -f2 | cut -d',' -f1)
		dialog \
		--title "Self Signed certification" \
		--stdout \
		--begin $small_x $y \
		--ok-label "Abort" --extra-button --extra-label "Renew cert" \
		--msgbox "Activ VHost used allready SSL, aborted" $small_height $width
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0|1|255)	;;
		3)			SELF_SIGNED_SSL $DNS
					systemctl restart apache2.service 1> /dev/null;;
		esac
	else
		SELF_SIGNED_SSL $1
		CONFIGURE_SSL_CONF
		HTTPS_CONF
		CONFIGURE_HTTPS_REDIRECT_CONF
	fi
}

function LE_SIGNED () {
	if [[ $(a2query -s | cut -d' ' -f1 | grep -v https_redirect | grep -c -i "LE-SSL") -ne 0 ]]
	then
		dialog \
		--title "Let's Encrypt certification" \
		--stdout \
		--begin $small_x $y \
		--ok-label "Abort" --extra-button --extra-label "Renew cert" \
		--msgbox "Activ VHost used allready SSL, aborted" $small_height $width
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0|1|255)	;;
		3)			certbot renew 2>&1 | dialog --stdout --begin $x $y --progressbox $height $width
					sleep 3;;
		esac
	else
		LET_ENCRYPT_FOR_SSL $1
		CONFIGURE_HTTPS_REDIRECT_CONF
	fi
}

function SELF_SIGNED_SSL () {
	host_information=$(wget -q -O - ipinfo.io/json)
	
	C=$(echo "$host_information" | grep "country" | cut -d'"' -f4)
	ST=$(echo "$host_information" | grep "region" | cut -d'"' -f4)
	L=$(echo "$host_information" | grep "city" | cut -d'"' -f4)
	O=$(echo "$host_information" | grep "org" | cut -d'"' -f4)
	CN=$1
	DNS=$(echo "$host_information" | grep "ip" -m 1 | cut -d'"' -f4)
	
	#https://9to5answer.com/err_ssl_key_usage_incompatible-solution
	#keyUsage = keyEncipherment, dataEncipherment
	
	cat > req.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = $C
ST = $ST
L = $L
O = $O
OU = -
CN = $CN
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $CN
DNS.2 = $DNS
EOF
	
	openssl req -x509 -config req.conf -extensions 'v3_req' -nodes -days 398 -newkey rsa:4096 -keyout /etc/ssl/private/rutorrent-selfsigned.key -out /etc/ssl/certs/rutorrent-selfsigned.crt 2>&1 | dialog --stdout --begin $x $y --progressbox $height $width
	
	rm -f req.conf
	#https://stackoverflow.com/questions/58712760/how-to-hide-the-cursor-in-a-terminal-during-a-script-and-restore-it-back-to-norm
	tput civis
	sleep 3
	tput cnorm 
}

function HTTPS_CONF () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	if (echo "$CURRENT_CONF" | grep -q -i "SSL")
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
		SET_NEW_VHOST $CURRENT_CONF $TARGET
	else
		TARGET=$CURRENT_CONF
	fi
	
	# recover Overridestatus for SSL Page
	status=$(grep "AllowOverride" /etc/apache2/sites-available/$TARGET.conf | rev | cut -d' ' -f1 | rev)
	
	a2enmod ssl 1> /dev/null
	a2enmod headers 1> /dev/null
	
	cat > /etc/apache2/sites-available/$TARGET-ss-ssl.conf << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/$TARGET
	<Directory "/var/www/$TARGET">
		AllowOverride $status
	</Directory>

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog \${APACHE_LOG_DIR}/rutorrent_error.log
	CustomLog \${APACHE_LOG_DIR}/rutorrent.log vhost_combined

	Include /etc/apache2/conf-available/options-ssl-apache.conf
	SSLEngine on
	SSLCertificateFile /etc/ssl/certs/rutorrent-selfsigned.crt
	SSLCertificateKeyFile /etc/ssl/private/rutorrent-selfsigned.key
	Header always set Strict-Transport-Security "max-age=63072000"
</VirtualHost>
</IfModule>
EOF
	
	a2dissite $TARGET.conf 1> /dev/null
	a2ensite $TARGET-ss-ssl.conf 1> /dev/null
	systemctl reload apache2.service 1> /dev/null
	systemctl restart apache2.service 1> /dev/null
}

function CONFIGURE_HTTPS_REDIRECT_CONF {
	a2enmod rewrite 1> /dev/null
	
	cat > /etc/apache2/sites-available/https_redirect.conf <<-EOF
<VirtualHost *:80>
	ServerAlias *
	RewriteEngine on
	RewriteRule ^/(.*) https://%{HTTP_HOST}/\$1 [NC,R=301,L]
</VirtualHost>
EOF
	
	a2ensite https_redirect.conf 1> /dev/null
	systemctl reload apache2.service 1> /dev/null
	systemctl restart apache2.service 1> /dev/null
}

function CONFIGURE_SSL_CONF {
	cat > /etc/apache2/conf-available/options-ssl-apache.conf <<-EOF
# This file contains important security parameters.
# Contents are based on https://ssl-config.mozilla.org

SSLEngine on

# Intermediate configuration, tweak to your needs
SSLProtocol             all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLOptions +StrictRequire

# Add vhost name to log entries:
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" vhost_combined
LogFormat "%v %h %l %u %t \"%r\" %>s %b" vhost_common
EOF
}

function LET_ENCRYPT_FOR_SSL () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	
	if (echo "$CURRENT_CONF" | grep -q -i "SSL")
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
		SET_NEW_VHOST $CURRENT_CONF $TARGET
	else
		TARGET=$CURRENT_CONF
	fi
	
	DOMAIN_NAME=$1
	
	a2enmod ssl 1> /dev/null
	a2enmod headers 1> /dev/null
	
	apt-get install -y python3-certbot-apache 1> /dev/null
	
	tput cup $(tput lines) 0
	echo ""
	
	certbot --apache --rsa-key-size 4096 --must-staple --hsts --uir --staple-ocsp --strict-permissions --register-unsafely-without-email --agree-tos --no-redirect -d "$DOMAIN_NAME" #2>&1 | dialog --stdout --begin $x $y --progressbox $height $width
	sed -i 's/31536000/63072000/g' /etc/apache2/sites-available/$TARGET-le-ssl.conf
	
	tput civis
	sleep 3
	tput cnorm
	
	a2dissite $TARGET.conf 1> /dev/null
	systemctl reload apache2.service 1> /dev/null
	systemctl restart apache2.service 1> /dev/null
}

function MENU_RUTORRENT () {
	#set rutorrent list to all versions(ALL_VERSION) or stable versions(STABLE_VERSION) only
	LIST=$ALL_VERSION
	
	last='""off'
	variablenname=$(echo $LIST | sed 's/ /""off"/g')
	full="$variablenname$last"
	IFS='"' read -a RU_VERSIONS <<< "$full"
	
	SELECTED=$(dialog --title "Choose ruTorrent Version" --stdout --begin $x $y --radiolist "ruTorrent Versions" 20 70 10 "${RU_VERSIONS[@]}")
	EXITCODE=$?
	#echo $EXITCODE
	#echo $SELECTED
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		INSTALL_RUTORRENT "$SELECTED";;
	1|255)	;;
	esac
	MENU
}

function INSTALL_RUTORRENT () {	
	if [ -z "$1" ]
	then
		#echo "\$1 is empty"
		dialog --title "Error" --stdout --begin $small_x $y --msgbox "No ruTorrent Version was choosen" $small_height $width
	else
		SELECTED=$1
		SELECTED_CUT="ruTorrent-${SELECTED:1}"
		
		############## install ruTorrent
		wget -q https://github.com/Novik/ruTorrent/archive/refs/tags/$SELECTED.zip -O /var/www/$SELECTED_CUT.zip
		unzip -qqo /var/www/$SELECTED_CUT.zip -d /var/www/
		rm /var/www/$SELECTED_CUT.zip	
		
		############## configure ruTorrent
		#https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC
		#https://stackoverflow.com/questions/20808095/why-do-alternate-delimiters-not-work-with-sed-e-pattern-s-a-b
		sed -i '/scgi_port/ s|5000|0|g' /var/www/$SELECTED_CUT/conf/config.php
		sed -i '/scgi_host/ s|127.0.0.1|unix:///run/rtorrent/rpc.socket|g' /var/www/$SELECTED_CUT/conf/config.php
		
		#move ruTorrent errorlog to a folder writeable by www-data
		sed -i '/log_file/ s|/tmp/errors.log|/var/log/apache2/rutorrent-errors.log|g' /var/www/$SELECTED_CUT/conf/config.php
		
		#use localHostedMode (rutorrent 4.0.1+)
		sed -i '/localHostedMode/ s/false/true/' /var/www/$SELECTED_CUT/conf/config.php
		
		############## install and configure plugins
		# deactivate php-geoip outdated since php7.4
		sed -i '$a[geoip]' /var/www/$SELECTED_CUT/conf/plugins.ini
		sed -i '$aenabled = no' /var/www/$SELECTED_CUT/conf/plugins.ini
		
		#httprpc vs rpc, only one is nessesary choose the better: https://github.com/Novik/ruTorrent/discussions/2439
		sed -i '$a[rpc]' /var/www/$SELECTED_CUT/conf/plugins.ini
		sed -i '$aenabled = no' /var/www/$SELECTED_CUT/conf/plugins.ini
		
		#dependencies for ruTorrent plugins
		#                  screenshots
		#                         mediainfo
		#                                   unpack
		#                                              spectrogram
		apt-get -y install ffmpeg mediainfo unrar-free sox libsox-fmt-mp3 >> $LOG_REDIRECTION 2>&1
		
		#_cloudflare
		#https://unix.stackexchange.com/questions/89913/sed-ignore-line-starting-whitespace-for-match
		#https://stackoverflow.com/questions/7517632/how-do-i-escape-slashes-and-double-and-single-quotes-in-sed
		sed -i '/^\s*$pathToExternals.*/a \		"python"=> '"'"''"$python_path"''"'"',' /var/www/$SELECTED_CUT/conf/config.php
		apt-get install -y $python_pip >> $LOG_REDIRECTION 2>&1
		
		if [[ -e /usr/lib/python$python_version_major.$python_version_minor/EXTERNALLY-MANAGED ]]
		then
			echo "EXTERNALLY-MANAGED Python" 1>> $LOG_REDIRECTION
			sudo python$python_version_major -m pip install cloudscraper --break-system-packages --quiet >> $LOG_REDIRECTION 2>&1
		else
			echo "No Python restrictions" 1>> $LOG_REDIRECTION
			sudo python$python_version_major -m pip install cloudscraper --quiet >> $LOG_REDIRECTION 2>&1
		fi
		
		# dumptorrent plugin
		if [ "${SELECTED:0:2}" == "v5" ]
		then
			apt-get install -y build-essential cmake ruby ruby-dev >> $LOG_REDIRECTION 2>&1
			# git only needed when cloning a repository
			gem install fpm >> $LOG_REDIRECTION 2>&1
			
			# Clone the repository
			#rm -rf /home/$stdin_user/dumptorrent/
			#git clone https://github.com/tomcdj71/dumptorrent.git >> $LOG_REDIRECTION 2>&1
			#cd dumptorrent
			
			# Download lastest Release
			rm -rf /home/$stdin_user/dumptorrent/
			latest_dumptorrent=$(wget -q https://api.github.com/repos/tomcdj71/dumptorrent/releases/latest -O - | grep tag_name | cut -d'"' -f4)
			wget -q https://github.com/tomcdj71/dumptorrent/archive/refs/tags/$latest_dumptorrent.tar.gz -O dumptorrent.tar.gz
			mkdir dumptorrent
			# https://wiki.ubuntuusers.de/tar/
			tar xzvf dumptorrent.tar.gz -C dumptorrent --strip-components=1 >> $LOG_REDIRECTION 2>&1
			rm -f dumptorrent.tar.gz
			cd dumptorrent
			
			# Build the binaries
			cmake -B build/ -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=Release -S . >> $LOG_REDIRECTION 2>&1
			cmake --build build/ --config Release --parallel $(nproc) >> $LOG_REDIRECTION 2>&1
			
			# Create necessary directories
			mkdir -p staging/usr/bin
			
			# Copy binaries to staging area
			cp build/dumptorrent build/scrapec staging/usr/bin/
			
			# Make binaries executable
			chmod +x staging/usr/bin/dumptorrent staging/usr/bin/scrapec
			
			# Get version from CMakeLists.txt
			dt_version=$(grep -oP '(?<=set\(DUMPTORRENT_VERSION ")[^"]*' CMakeLists.txt)
			
			# Create the package
			fpm -s dir -t deb -C staging \
			  --name dumptorrent \
			  --version $dt_version \
			  --architecture $architecture \
			  --description "DumpTorrent is a command-line utility that displays detailed information about .torrent files" \
			  --url "https://github.com/tomcdj71/dumptorrent" \
			  --maintainer "Thomas Chauveau <contact.tomc@yahoo.com>" \
			  --license "MIT" \
			  --depends "libc6" \
			  --deb-compression xz \
			  --deb-priority optional \
			  --category net \
			  usr/bin >> $LOG_REDIRECTION 2>&1
			
			# Install the package
			dpkg -i dumptorrent_*.deb >> $LOG_REDIRECTION 2>&1
			
			# Clean the repository
			cd /home/$stdin_user/
			rm -rf /home/$stdin_user/dumptorrent/
		fi
		
		# geoip2 plugin
		apt-get install -y git libapache2-mod-geoip php$PHP_VERSION-bcmath >> $LOG_REDIRECTION 2>&1
		git clone --depth=1 https://github.com/MarkusLange/geoip2-rutorrent.git /var/www/$SELECTED_CUT/plugins/geoip2 >> $LOG_REDIRECTION 2>&1
		rm -rf /var/www/$SELECTED_CUT/plugins/geoip2/.git
		
		chown -R www-data:www-data /var/www/$SELECTED_CUT
		chmod -R 775 /var/www/$SELECTED_CUT
		
		CREATE_AND_ACTIVATE_CONF $SELECTED_CUT
		
		#only for install log needed
		echo "rutorrent config.php" 1>> $LOG_REDIRECTION
		cat /var/www/$SELECTED_CUT/conf/config.php 1>> $LOG_REDIRECTION
		echo "Apache $SELECTED_CUT.conf vhost" 1>> $LOG_REDIRECTION
		cat /etc/apache2/sites-available/$SELECTED_CUT.conf 1>> $LOG_REDIRECTION
	fi
}

function CREATE_AND_ACTIVATE_CONF () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	
	cat > /etc/apache2/sites-available/$1.conf << EOF
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/$1
	<Directory "/var/www/$1">
		AllowOverride None
	</Directory>

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog \${APACHE_LOG_DIR}/rutorrent_error.log
	CustomLog \${APACHE_LOG_DIR}/rutorrent.log vhost_combined
</VirtualHost>
EOF
	
	a2dissite $CURRENT_CONF.conf 1>> $LOG_REDIRECTION
	a2ensite $1.conf 1>> $LOG_REDIRECTION
	if [[ $(a2query -s | cut -d' ' -f1 | grep -c https_redirect) -ne 0 ]]
	then
		a2dissite https_redirect.conf 1>> $LOG_REDIRECTION
	fi
	systemctl reload apache2.service 1>> $LOG_REDIRECTION
	systemctl restart apache2.service 1>> $LOG_REDIRECTION
}

function CHANGE_VHOST () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	ALL_VHOST=$(ls /etc/apache2/sites-available/ | grep -v 'https_redirect\|000-default\|default-ssl' | sed 's/.conf/""off"/g' | sed '/'"$CURRENT_CONF"'/ s/off/on/')
	ALL_VHOST_NO_SPACE=$(echo $ALL_VHOST | sed 's/ //g')
	IFS='"' read -a VHOSTS <<< "$ALL_VHOST_NO_SPACE"
	
	SELECTED=$(dialog --title "Change VHost" --stdout --begin $x $y --radiolist "current VHost (*)" $height $width 13 "${VHOSTS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		SET_NEW_VHOST $CURRENT_CONF $SELECTED;;
	1|255)	;;
	esac
	MENU
}

function SET_NEW_VHOST () {
	a2dissite $1.conf 1> /dev/null
	if echo "$1" | grep -q -i "SSL" && [ -e "/etc/apache2/sites-available/https_redirect.conf" ]
	then
		a2dissite https_redirect.conf 1> /dev/null
	fi
	
	a2ensite $2.conf 1> /dev/null
	if echo "$2" | grep -q -i "SSL" && [ -e "/etc/apache2/sites-available/https_redirect.conf" ]
	then
		a2ensite https_redirect.conf 1> /dev/null
	fi
	systemctl reload apache2.service 1> /dev/null
}

function WEBAUTH_TOGGLE {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	status=$(grep "AllowOverride" /etc/apache2/sites-available/$CURRENT_CONF.conf | rev | cut -d' ' -f1 | rev)
	
	#     <tag1><item1>                 <status1>
	AUTH=("off" "no Web Authentication" "OFF" "on" "with Web Authentication" "OFF")
	
	#All (Webauth on) or None (Webauth off)
	if [ $status == "All" ]
	then
		AUTH[5]="ON"
	else
		AUTH[2]="ON"
	fi
	
	SELECTED=$(dialog \
	--title "Web Authentication On/Off" \
	--stdout \
	--begin $x $y \
	--no-tags \
	--radiolist "current Webauth status (*) on VHost $CURRENT_CONF" $height $width 2 "${AUTH[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		TOGGLE_BASIC_AUTH $SELECTED;;
	1|255)	;;
	esac
	MENU
}

function TOGGLE_BASIC_AUTH () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	
	if [ $1 == "on" ]
	then
		sed -i 's/^\s*AllowOverride None/\		AllowOverride All/g' /etc/apache2/sites-available/$CURRENT_CONF.conf
	else
		sed -i 's/^\s*AllowOverride All/\		AllowOverride None/g' /etc/apache2/sites-available/$CURRENT_CONF.conf
	fi
	systemctl reload apache2.service 1> /dev/null
}

function ADD_USER_TO_WEBAUTH () {
	unset OUTPUT
	OUTPUT=$(dialog \
	--title "Webauth User" \
	--stdout \
	--begin $x $y \
	--insecure "$@" \
	--trim \
	--output-separator $separator \
	--mixedform "Add User to Webauth on VHost $CURRENT_CONF" \
	$height $width 0 \
	"Username          :" 1 1 ""    1 21 12 0 0 \
	"Password          :" 2 1 ""    2 21 10 0 1 \
	"Retype Password   :" 3 1 ""    3 21 10 0 1 \
	)
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	#remove spaces from String
	OUTPUT=$(echo $OUTPUT | sed 's/ //g')
	IFS=$separator read -a SHOWN <<< "$OUTPUT"
	
	case $EXITCODE in
	0)		CREATE_WEBAUTH_USER "${SHOWN[@]}";;
	1|255)	;;
	esac
	MENU
}

function CREATE_WEBAUTH_USER () {
	arr=("$@")
	
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	if (echo "$CURRENT_CONF" | grep -q -i "SSL")
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
	else
		TARGET=$CURRENT_CONF
	fi
	
	unset state
	if [ -z "${arr[0]}" ]
	then
		answer1="No Username entered"
		state="error"
	else
		if [ -f "/var/www/$TARGET/.htpasswd" ]
		then
			if [[ $(grep ":" /var/www/$TARGET/.htpasswd | cut -d':' -f1 | grep -c ${arr[0]}) -ne 0 ]]
			then
				answer1="User exist"
				state="error"
			else
				answer1=""
			fi
		fi
	fi
	
	if [ -z "${arr[1]}" ] || [ -z "${arr[2]}" ]
	then
		answer2="Password is empty"
		state="error"
	else
		if [ "${arr[1]}" != "${arr[2]}" ]
		then
			answer2="Passwords does not match"
			state="error"
		else
			answer2=""
		fi
	fi
	
	if [[ $state == "error" ]]
	then
		dialog --title "Error" \
		--stdout \
		--begin $small_x $y \
		--msgbox "\
$answer1\n\
$answer2
		"\
		$small_height $width
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0|1|255)	ADD_USER_TO_WEBAUTH;;
		esac
	else
		LINE=$(echo "${arr[1]}" | htpasswd -i -n "${arr[0]}")
		#echo $LINE
		
		if [ -f "/var/www/$TARGET/.htpasswd" ]
		then
			echo $LINE >> /var/www/$TARGET/.htpasswd
			# remove empty Lines
			sed -i '/^$/d' /var/www/$TARGET/.htpasswd
		else
			touch /var/www/$TARGET/.htpasswd
			echo $LINE >> /var/www/$TARGET/.htpasswd
		fi
		
		if [ -f "/var/www/$TARGET/.htaccess" ]
		then
			:
		else
			cat > /var/www/$TARGET/.htaccess << EOF
AuthType Basic
AuthName "Tits or GTFO"
Require valid-user
AuthUserFile /var/www/$TARGET/.htpasswd
EOF
		fi
		
		chown -R www-data:www-data /var/www/$TARGET/.ht*
		
		systemctl reload apache2.service
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "\nNew WebAuth User ${arr[0]} created" $small_height $width
	fi
}

function REMOVE_WEBAUTH_USER {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	if (echo "$CURRENT_CONF" | grep -q -i "SSL")
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
	else
		TARGET=$CURRENT_CONF
	fi
	
	present_web=$(grep ":" /var/www/$TARGET/.htpasswd | cut -d':' -f1 | sort)
	
	last='""off'
	actual_web_user=$(echo $present_web | sed 's/ /""off"/g')
	full="$actual_web_user$last"
	IFS='"' read -a ACTUAL_USERS <<< "$full"
	
	SELECTED=$(dialog --title "Remove User from Webauth" --stdout --begin $x $y --radiolist "Remove User from VHost $CURRENT_CONF" $height $width 13 "${ACTUAL_USERS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		REMOVE_USER_FROM_WEBAUTH_AUTH $SELECTED;;
	1|255)	;;
	esac
	MENU
}

function REMOVE_USER_FROM_WEBAUTH_AUTH () {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	if (echo "$CURRENT_CONF" | grep -q -i "SSL")
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
	else
		TARGET=$CURRENT_CONF
	fi
	
	if [ -z "$1" ]
	then
		dialog --title "Error" --stdout --begin $small_x $y --msgbox "No WebAuth User was choosen" $small_height $width
	else
		#https://stackoverflow.com/questions/10319745/redirecting-command-output-to-a-variable-in-bash-fails
		response=$(htpasswd -D /var/www/$TARGET/.htpasswd $1 2>&1)
		
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "$response" $small_height $width
	fi
}

function SOFTLINK_TO_HOMEDIR {
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	user_of_rtorrent_group=$(grep $rtorrent_user_group /etc/group | cut -d':' -f4)
	IFS=',' read -a list_of_rtorrent_group_user <<< "$user_of_rtorrent_group"
	
	rtorrentuser=${list_of_rtorrent_group_user[@]/"www-data"}
	status=$(ls -lrt /home/$rtorrentuser | grep "rtorrent" | grep -c "^l")
	
	#        <tag1><item1>                <status1><tag2><item2>                <status2>
	SOFTLINK=("on" "add softlink to homedir" "OFF" "off" "no softlink to homedir" "OFF")
	
	if [ $status == "0" ]
	then
		SOFTLINK[5]="ON"
		preselect="on"
	else
		SOFTLINK[2]="ON"
		preselect="off"
	fi
	
	SELECTED=$(dialog \
	--title "Add/Remove softlink to rtorrent user home" \
	--stdout \
	--begin $x $y \
	--no-tags \
	--colors \
	--default-item "$preselect" \
	--radiolist "Softlink to home of rtorrent user \Z4$rtorrentuser\Zn status (*)" $height $width 2 "${SOFTLINK[@]}")
	EXITCODE=$?
	#echo "$SELECTED"
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		TOGGLE_SOFTLINK "$SELECTED";;
	1|255)	;;
	esac
	MENU
}

function TOGGLE_SOFTLINK () {
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	user_of_rtorrent_group=$(grep $rtorrent_user_group /etc/group | cut -d':' -f4)
	IFS=',' read -a list_of_rtorrent_group_user <<< "$user_of_rtorrent_group"
	
	rtorrentuser=${list_of_rtorrent_group_user[@]/"www-data"}
	rtorrentuser="${rtorrentuser[@]}"
	#remove space from String
	rtorrentuser=$(echo $rtorrentuser | sed 's/ //g')
	
	status=$(ls -lrt /home/$rtorrentuser | grep "rtorrent" | grep -c "^l")
	location=$(cat /etc/systemd/system/rtorrent.service | grep "ExecStart" | cut -d'=' -f3 | cut -d'.' -f1)
	#echo "$rtorrentuser"
	#echo "$status"
	#echo "$location"
	
	if [ -d $location ]
	then
		if [ $1 == "on" ]
		then
			if [ $status == "0" ]
			then
				sudo -u $rtorrentuser ln -s $location /home/$rtorrentuser/rtorrent
			fi
		else
			unlink /home/$rtorrentuser/rtorrent 2>> /dev/null
		fi
	else
		dialog --title "Error" --stdout --begin $small_x $y --msgbox "rtorrent directory to link from not exist" $small_height $width
	fi
}

function SCRIPTED_INSTALL () {
	dialog --title "Scripted Installation" --stdout --begin $x $y --colors --yesno "\
The scripted installation ask you some questions about the\n\
user for rtorrent, the ruTorrent version and other stuff,\n\
after that you will see a list with all you have selected.\n\
\n\
You can shortcut everything with hitting \"\Zuenter\ZU\" to get a\n\
standard installation with the most common result, newest\n\
versions, and add all under the users home folder via softlink\n\
\n\
Until you choose install, nothing will happen to your system.\n\
To this point this installation only looks after \Z4dialog\Zn\n\
what makes this fancy menu and for \Z4wget\Zn for the downloads\n\
both should already part of an debian based linux system.\n\
\n\
So only these two are installed until now, the installation\n\
started with an update e.g. (apt update; apt dist-upgrade) to\n\
get this linux up-to-date before the installations starts.\n\
\n\
You can always update your ruTorrent to the next version and\n\
add SSL-Protocol or WebAuth to your ruTorrent Webpage\n\
\n\
There would a logfile created to show what happend\n\
"\
	$height $width
	EXITCODE=$?
	#echo $EXITCODE
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		SCRIPT;;
	1|255)	;;
	esac
	MENU
}

function SCRIPT () {
	user=$(awk -F':' -v "min=${low}" -v "max=${high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1)
	system_user=$(awk -F':' -v "min=${system_low}" -v "max=${system_high}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd | cut -d':' -f1)
	
	end='""off'
	variablenname=$(echo $user | sed 's/ /""off"/g')
	full="$variablenname$end"
	IFS='"' read -a USERS <<< "$full"
	
	system_last='""off"add new system user""off'
	variablensystemname=$(echo $system_user | sed 's/ /""off"/g')
	systemfull="$variablensystemname$system_last"
	IFS='"' read -a SYSTEM_USERS <<< "$systemfull"
	
	USERS[2]="ON"
	SELECTED=$(dialog \
	--title "Select rtorrent User" \
	--stdout \
	--begin $x $y \
	--extra-button \
	--extra-label "Add User" \
	--radiolist "Select User" $height $width 13 "${USERS[@]}")
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)
		# USER[_] 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
		USER[0]="existing"
		USER[1]=$SELECTED
		USER[2]=
		USER[3]=$(grep "$(id -u $SELECTED)" /etc/group | cut -d':' -f1)
		USER[4]=$(getent passwd "$SELECTED" | cut -d':' -f6)
		USER[5]=
		;;
	1|255)	MENU;;
	3)
		unset OUTPUT
		OUTPUT=$(dialog \
		--title "New User" \
		--stdout \
		--begin $x $y \
		--insecure "$@" \
		--trim \
		--output-separator $separator \
		--mixedform "Create new User for rtorrent" \
		$height $width 0 \
		"Username          :" 1 1 ""    1 21 12 0 0 \
		"Password          :" 2 1 ""    2 21 10 0 1 \
		"Retype Password   :" 3 1 ""    3 21 10 0 1 \
		"Allow SSH (yes/no):" 4 1 "yes" 4 21  5 0 0 \
		)
		EXITCODE=$?
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0)
			OUTPUT=$(echo $OUTPUT | sed 's/ //g')
			IFS=$separator read -a arr <<< "$OUTPUT"
			unset state
			if [ -z "${arr[0]}" ]
			then
				answer1="No Username entered"
				state="error"
			else
				if [[ $(getent passwd | grep -c ^${arr[0]}:) -ne 0 ]]
				then
					answer1="User exist"
					state="error"
				else
					answer1=""
				fi
			fi
			
			if [ -z "${arr[1]}" ] || [ -z "${arr[2]}" ]
			then
				answer2="Password is empty"
				state="error"
			else
				if [ "${arr[1]}" != "${arr[2]}" ]
				then
					answer2="Passwords does not match"
					state="error"
				else
					answer2=""
				fi
			fi
			
			if [[ $state == "error" ]]
			then
				dialog --title "Error" \
				--stdout \
				--begin $small_x $y \
				--msgbox "\
$answer1\n\
$answer2
				"\
				$small_height $width
				EXITCODE=$?
				# Get exit status
				# 0 means user hit OK button.
				# 1 means user hit CANCEL button.
				# 2 means user hit HELP button.
				# 3 means user hit EXTRA button.
				# 255 means user hit [Esc] key.
				case $EXITCODE in
				0|1|255)   SCRIPT;;
				esac
			else
				# USER[_] 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
				USER[0]="to_create"
				USER[1]=${arr[0]}
				USER[2]=${arr[1]}
				USER[3]=${arr[0]}
				USER[4]="/home/${arr[0]}"
				USER[5]=${arr[3]}
			fi
			;;
		1|255)	MENU;;
		esac
	esac
	
	PORT_RANGE_MIN="50000"
	PORT_RANGE_MAX="50000"
	PORT_SET="no"
	DLFOLDER="/srv"
	
	while :; do
		OUTPUT=$(dialog \
		--title "Edit rtorrent.rc" \
		--stdout \
		--begin $x $y \
		--trim \
		--extra-button \
		--colors \
		--extra-label "Change Basedir" \
		--output-separator $separator \
		--default-button "ok" \
		--mixedform "Port Range defines the usable Ports for rtorrent\n
Random Listening Port let rtorrent set the Port randomly\n
rtorrent folder stucture:\n
	\Z4$DLFOLDER\Zn \n
	 └── /rtorrent \n
	      ├── /.session \n
	      ├── /download \n
	      ├── /log \n
	      └── /watch \n
	           ├── /load \n
	           └── /start"\
		$height $width 0 \
		"Port Range                    :" 1 1  " $PORT_RANGE_MIN" 1 33  6 0 0 \
		"-"                               1 39 " $PORT_RANGE_MAX" 1 40  6 0 0 \
		"Random Listening Port (yes/no):" 2 1  "$PORT_SET"        2 33  5 0 0 \
		"rtorrent basedir              :" 3 1  "$DLFOLDER"        3 33 31 0 2 \
		)
		EXITCODE=$?
		#remove spaces from String
		OUTPUT=$(echo $OUTPUT | sed 's/ //g')
		IFS=$separator read -a SHOWN <<< "$OUTPUT"
		
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0)	
			EXITLOOP=0
			break;;
		1|255)
			EXITLOOP=1
			break;;
		3)
			RETURN=$(dialog --stdout --begin $x $y --dselect "$DLFOLDER" 10 $width)
			EXITCODE=$?
			#https://stackoverflow.com/questions/9018723/what-is-the-simplest-way-to-remove-a-trailing-slash-from-each-parameter
			RETURN=$(echo "$RETURN" | sed 's:/*$::')
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			case $EXITCODE in
			0)		PORT_RANGE_MIN=${SHOWN[0]}
					PORT_RANGE_MAX=${SHOWN[1]}
					PORT_SET=${SHOWN[2]}
					DLFOLDER=$RETURN;;
			1|255)	EXITLOOP=1
					break;;
			esac
		esac
	done
	
	case $EXITLOOP in
	0)	# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
		RC[0]="${SHOWN[0]}-${SHOWN[1]}"
		RC[1]="${SHOWN[2]}"
		RC[2]="${SHOWN[3]}";;
	1)	MENU;;
	esac
	
	if $change_on_script
	then
		while :; do
			OUTPUT=$(dialog \
			--title "Set rtorrent user" \
			--stdout \
			--begin $x $y \
			--insecure "$@" \
			--trim \
			--output-separator $separator \
			--colors \
			--default-button "ok" \
			--ok-label "Default" \
			--extra-button \
			--extra-label "Change" \
			--mixedform "Create User and Group for rtorrent deamon" \
			$height $width 0 \
			"Username :" 1 1 "$the_user"    1 12 20 0 0 \
			"Usergroup:" 2 1 "$the_group"   2 12 20 0 0 \
			)
			EXITCODE=$?
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			#remove spaces from String
			OUTPUT=$(echo $OUTPUT | sed 's/ //g')
			IFS=$separator read -a DAEMON <<< "$OUTPUT"
			case $EXITCODE in
			0)	
				EXITLOOP_DAEMON=0
				break;;
			1|255)	
				MENU
				;;
			3)	
				if [[ $(getent passwd | grep -c ^${DAEMON[0]}:) -ne 0 ]] || [[ ${USER[1]} == ${DAEMON[0]} ]]
				then
					dialog --title "Error" --stdout --begin $small_x $y --msgbox "\nUser ${DAEMON[0]} already exist, try again!" $small_height $width
				else
					EXITLOOP_DAEMON=1
					break
				fi
				;;
			esac
		done
		
		case $EXITLOOP_DAEMON in
		0)	rtorrent_daemon_user=$the_user
			rtorrent_daemon_group=$the_group
			;;
		1)	rtorrent_daemon_user=${DAEMON[0]}
			rtorrent_daemon_group=${DAEMON[1]}
			;;
		esac
	else
		rtorrent_daemon_user=$the_user
		rtorrent_daemon_group=$the_group
	fi
	
	RT_VERSIONS[0]="v$rtorrent_version $reposity_marker"
	RT_VERSIONS[2]="ON"
	RTORRENT_VERSION=$(dialog --title "Choose rTorrent Version" --stdout --begin $x $y --radiolist "rTorrent Versions" $height $width 10 "${RT_VERSIONS[@]}")
	#echo $EXITCODE
	#echo $RUTORRENT_VERSION
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		;;
	1|255)	MENU;;
	esac
	
	VERSIONS[2]="ON"
	RUTORRENT_VERSION=$(dialog --title "Choose ruTorrent Version" --stdout --begin $x $y --radiolist "ruTorrent Versions" $height $width 10 "${VERSIONS[@]}")
	EXITCODE=$?
	#echo $EXITCODE
	#echo $RUTORRENT_VERSION
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		SUM;;
	1|255)	;;
	esac
}

function SUM () {
	if [[ ${USER[0]} == "to_create" ]]
	then
		ssh_login=${USER[5]}
	else
		if (grep "^DenyUsers" /etc/ssh/sshd_config | grep -cq "${USER[1]}")
		then
			ssh_login=no
		else
			ssh_login=yes
		fi
	fi
	
	if [[ $RTORRENT_VERSION == "v$rtorrent_version $reposity_marker" ]]
	then
		RTORRENT_VERSION_CHOOSE=$rtorrent_version
		LIBTORRENT_VERSION_CHOOSE=$libtorrent_version
	else
		RTORRENT_VERSION_CHOOSE=${RTORRENT_VERSION:1}
		LIBTORRENT_VERSION_CHOOSE=$(wget -q https://api.github.com/repos/rakshasa/rtorrent/releases -O - | grep browser_download | cut -d'"' -f4 | grep $RTORRENT_VERSION | grep libtorrent | cut -d'-' -f2 | cut -d'.' -f-3)
	fi
	
	dialog --title "Scripted Installation" --stdout --begin $x $y --colors --yesno "\
Configuration:\n\
\n\
user:\n\
rtorrent user                      \Z4${USER[1]}\Z0\n\
SSH Login for rtorrent user        \Z4$ssh_login\Z0\n\
\n\
rtorrent daemon:\n\
rtorrent system user               \Z4$rtorrent_daemon_user\Z0\n\
rtorrent system group              \Z4$rtorrent_daemon_group\Z0\n\
\n\
rtorrent:\n\
rtorrent Version                   \Z4$RTORRENT_VERSION_CHOOSE\Z0\n\
libtorrent Version                 \Z4$LIBTORRENT_VERSION_CHOOSE\Z0\n\
rtorrent Basedir                   \Z4${RC[2]}\Z0\n\
rtorrent.rc placed in              \Z4${RC[2]}/rtorrent\Z0\n\
Portrange                          \Z4${RC[0]}\Z0\n\
Random Listening port              \Z4${RC[1]}\Z0\n\
\n\
ruTorrent:\n\
ruTorrent Version                  \Z4$RUTORRENT_VERSION\Z0\n\
\n\
This Script will install rtorrent and ruTorrent with this\n\
configuration, rtorrent set all folders within this installation.\n\
\n\
The permissons of the rtorrent Basedir will granted to user \Z4${USER[1]}\Z0\n\
"\
	$height $width
	EXITCODE=$?
	#echo $EXITCODE
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		INSTALLATION;;
	1|255)	;;
	esac
}

function INSTALLATION () {
	{
	if [ -f $logfile ]
	then
		rm -f $logfile
	fi
	LOG_REDIRECTION=$logfile
	
	echo "System update" 1>> $LOG_REDIRECTION
	echo -e "XXX\n0\nUpdate System!\nXXX"
	(time SYSTEM_UPDATE) >> $LOG_REDIRECTION 2>&1
	
	echo "Install Apache" 1>> $LOG_REDIRECTION
	echo -e "XXX\n30\nInstall Apache and PHP\nXXX"
	(time APACHE2) >> $LOG_REDIRECTION 2>&1
	
	# USER[_] 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
	if [[ ${USER[0]} == "to_create" ]]
	then
		(echo ${USER[2]}; echo ${USER[2]}) | sudo adduser --force-badname --gecos "" ${USER[1]} --quiet 2>> $LOG_REDIRECTION
		if [ "${USER[5],,}" == "no" ];
		then
			#echo "Deny SSH"
			if grep -q '^DenyUsers' '/etc/ssh/sshd_config';
			then
				present=$(grep "^DenyUsers" /etc/ssh/sshd_config)
				sudo sed -i 's/^DenyUsers.*/'"$present"' '"${USER[1]}"'/g' /etc/ssh/sshd_config
			else
				sudo sed -i '$aDenyUsers\t'"${USER[1]}"'' /etc/ssh/sshd_config
			fi
		systemctl restart ssh
		fi
	fi
	
	adduser --system --no-create-home $rtorrent_daemon_user
	
	#add rtorrent_daemon_group to rtorrent user
	sudo groupadd --system $rtorrent_daemon_group  >> $LOG_REDIRECTION 2>&1
	sudo usermod -a -G $rtorrent_daemon_group ${USER[1]}  >> $LOG_REDIRECTION 2>&1
	
	#create rtorrent_daemon_user as system user
	#adduser $rtorrent_daemon_user --system --force-badname
	#--allow-bad-names
	sudo usermod -g $rtorrent_daemon_group $rtorrent_daemon_user
	
	mkdir -p ${RC[2]}/rtorrent
	chown -R $rtorrent_daemon_user:$rtorrent_daemon_group ${RC[2]}/rtorrent
	
	RT_DAEMON[0]=""
	RT_DAEMON[1]=$rtorrent_daemon_user
	RT_DAEMON[2]=""
	RT_DAEMON[3]=$rtorrent_daemon_group
	RT_DAEMON[4]=${RC[2]}/rtorrent
	RT_DAEMON[5]=""
	
	echo "Install rtorrent" 1>> $LOG_REDIRECTION
	echo -e "XXX\n65\nInstall and configure rtorrent\nXXX"
	apt-get install -y apt-utils build-essential libsigc++-2.0-dev pkg-config comerr-dev libcurl3-openssl-dev libidn11-dev libkrb5-dev libssl-dev zlib1g-dev libncurses5-dev automake libtool libxmlrpc-core-c3-dev checkinstall 2>/dev/null 1>> $LOG_REDIRECTION
	#libncurses5
	#INSTALL_RTORRENT
	(time INSTALL_RTORRENT) >> $LOG_REDIRECTION 2>&1
	(time RTORRENT "${RT_DAEMON[@]}") >> $LOG_REDIRECTION 2>&1
	
	PORT_RANGE=$(grep 'port_range.set' ${RC[2]}/rtorrent/.rtorrent.rc | cut -d' ' -f3)
	PORT_SET=$(grep 'port_random.set' ${RC[2]}/rtorrent/.rtorrent.rc | cut -d' ' -f3)
	DLFOLDER=$(grep 'method.insert = cfg.basedir' ${RC[2]}/rtorrent/.rtorrent.rc | cut -d'"' -f2 | rev | cut -d'/' -f3- | rev)
	
	# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
	sed -i '/port_range.set/ s/'"$PORT_RANGE"'/'"${RC[0]}"'/' ${RC[2]}/rtorrent/.rtorrent.rc
	sed -i '/port_random.set/ s/'"$PORT_SET"'/'"${RC[1]}"'/' ${RC[2]}/rtorrent/.rtorrent.rc
	sed -i 's#'"$DLFOLDER"'#'"${RC[2]}"'#' ${RC[2]}/rtorrent/.rtorrent.rc
	
	echo "Enable rtorrent" 1>> $LOG_REDIRECTION
	systemctl enable rtorrent.service 2>> $LOG_REDIRECTION
	systemctl start rtorrent.service 1>> $LOG_REDIRECTION
	systemctl status rtorrent.service --no-pager 1>> $LOG_REDIRECTION
	
	#softlink to rtorrent users homedir
	#ln -s ${RC[2]}/rtorrent/ /home/${USER[1]}/rtorrent
	sudo -u ${USER[1]} ln -s ${RC[2]}/rtorrent/ /home/${USER[1]}/rtorrent
	
	echo "Install rutorrent" 1>> $LOG_REDIRECTION
	echo -e "XXX\n70\nInstall and configure rutorrent\nXXX"
	(time INSTALL_RUTORRENT $RUTORRENT_VERSION) >> $LOG_REDIRECTION 2>&1
	
	#add rtorrent_daemon_group to www-data
	sudo usermod -a -G $rtorrent_daemon_group www-data
	sudo systemctl restart apache2.service
	
	echo -e "XXX\n100\nInstallation complete\nXXX"
	} | dialog --begin $small_x $y --gauge "Please wait while installing" $small_height $width 0
	
	tput civis
	sleep 3
	tput cnorm
	
	#move installation logfile ownership to actual user
	chown -R $stdin_user:$stdin_user $logfile
	INSTALL_COMPLETE
}

function INSTALL_COMPLETE {
	external_ip=$(wget -O - -q ipv4.icanhazip.com)
	internal_ip=$(hostname -I | cut -d' ' -f1 | sed 's/ //g')
	BASEDIR=${RC[2]}
	
	dialog --title "Installation Completed" --stdout --begin $x $y --colors --msgbox "\
\Z2Installation is completed.\Zn\n\
\n\
The actual Apache2 vhost file has been disabled and replaced\n\
with a new one. If you were using it, enable the default again\n\
beside the ruTorrent vhost file.\n\
\n\
Your downloads folder is in \Z2$BASEDIR/rtorrent/download\Z0\n\
Sessions data is in \Z2$BASEDIR/rtorrent/.session\Zn\n\
rtorrent's configuration file is in \Z2$BASEDIR/rtorrent/.rtorrent.rc\Zn\n\
\n\
If you want to change settings for rtorrent, such as download\n\
folder, etc., you need to edit the '.rtorrent.rc' file.\n\
E.g. 'nano \Z2$BASEDIR/rtorrent/.rtorrent.rc\Zn'\n\
\n\
rtorrent can be started|stopped|restarted without rebooting\n\
with '\Z5sudo systemctl start|stop|restart rtorrent.service\Zn'.\n\
\n\
\Z2LOCAL IP:\Z0    http://$internal_ip/\Zn\n\
\Z2EXTERNAL IP:\Z0 http://$external_ip/\Zn\n\
"\
	$height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	esac
}

function REMOVE_EVERYTHING () {
	dialog --title "Remove Everything" --stdout --begin $x $y --yes-label "Clean up" --extra-button --extra-label "Keep" --no-label "Exit" --colors --yesno "\
\ZuClean up:\Zn\n\
Be carefull with this\n\
Everything that was installed with this script will be removed.\n\
\n\
If you start this all from the script installed packages will\n\
be removed, all packages from apache2, php, rtorrent and\n\
ruTorrent.\n\
\n\
All downloaded files will be deleted too, also all config files\n\
and everything under the apache2 document root /var/www.\n\
\n\
A system cleanup with apt autoremove will finalize this.\n\
There will nothing left behind, and nothing ask after this.\n\
\n\
\ZuKeep:\Zn\n\
Does the same as above but keep the basedir and the softlink\n\
to the rtorrent user homedir, so with all sessiondata an\n\
reinstallation will restore the previous torrents.\n\
"\
	$height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		REMOVE_ALL true;;
	3)		REMOVE_ALL false;;
	1|255)	;;
	esac
	MENU
}

function REMOVE_ALL () {
	dialog --begin $small_x $y --infobox "\nPlease wait while fetching data" $small_height $width
	
	activ_rutorrent=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect | cut -d'-' -f2)
	rtorrent_rc_path=$(find / -not \( -path /proc/sys/fs/binfmt_misc -prune \) -name .rtorrent.rc)
	rpc_socket_path=$(find / -not \( -path /proc/sys/fs/binfmt_misc -prune \) -name rpc.socket | rev | cut -d'/' -f2- | rev)
	rtorrent_basedir=$(find / -not \( -path /proc/sys/fs/binfmt_misc -prune \) -name rtorrent-*.log | rev | cut -d'/' -f3- | rev | head -n 1)
	softlink_link=$(find /home -type l | grep rtorrent)
	
	rtorrent_version_installed=$(rtorrent -h | grep "client version" | cut -d' ' -f5 | rev | sed 's/\.//' | rev)
	rtorrent_user_name=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
	rtorrent_user_group=$(groups $rtorrent_user_name | cut -d' ' -f3)
	user_of_rtorrent_group=$(grep $rtorrent_user_group /etc/group | cut -d':' -f4)
	IFS=',' read -a list_of_rtorrent_group_user <<< "$user_of_rtorrent_group"
	
	{
	if [ -f $removelogfile ]
	then
		rm -f $removelogfile
	fi
	echo -e "XXX\n0\nRemove installation of rtorrent & ruTorrent\nXXX"
	
	echo -e "XXX\n5\nStop systemd services\nXXX"
	systemctl stop rtorrent.service 1>> $removelogfile
	systemctl disable rtorrent.service 2>> $removelogfile
	rm /etc/systemd/system/rtorrent.service
	
	systemctl stop apache2.service 1>> $removelogfile
	systemctl disable apache2.service 2>> $removelogfile
	systemctl daemon-reload 1>> $removelogfile
	
	if $1
	then
		echo -e "XXX\n10\nRemove softlink\nXXX"
		if ( find /home -type l | grep -cq rtorrent )
		then
			unlink $(find /home -type l | grep rtorrent) >> $removelogfile 2>&1
		fi
	fi
	
	echo -e "XXX\n30\nRemove Apache and PHP\nXXX"
	apt-get purge -y apache2 apache2-utils apache2-bin php$PHP_VERSION php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-cli libapache2-mod-php$PHP_VERSION >> $removelogfile 2>&1
	rm -R /var/www $(whereis apache2 | cut -d':' -f2)
	
	echo -e "XXX\n50\nRemove rtorrent\nXXX"
	apt-get purge -y rtorrent libtorrent* >> $removelogfile 2>&1
	apt-get purge -y apt-utils build-essential libsigc++-2.0-dev pkg-config comerr-dev libcurl3-openssl-dev libidn11-dev libkrb5-dev libssl-dev zlib1g-dev libncurses5-dev automake libtool libxmlrpc-core-c3-dev checkinstall >> $removelogfile 2>&1
	#libncurses5
	
	echo -e "XXX\n60\nRemove ruTorrent plugins\nXXX"
	#remove deb non-free list if exist
	if [ -f /etc/apt/sources.list.d/non_free.list ]
	then
		rm -f /etc/apt/sources.list.d/non_free.list >> $removelogfile 2>&1
		apt-get update >> $removelogfile 2>&1
	fi
	
	#grep the installed unrar variant (unrar or unrar-free)
	unrar_variant=$(dpkg -l | grep ^ii | awk '{print $2}' | grep "unrar")
	
	apt-get purge -y ffmpeg libzen0v5 libmediainfo0v5 mediainfo $unrar_variant sox libsox-fmt-mp3 >> $removelogfile 2>&1
	
	if [[ -e /usr/lib/python$python_version_major.$python_version_minor/EXTERNALLY-MANAGED ]]
	then
		echo "EXTERNALLY-MANAGED Python" 1>> $removelogfile
		sudo python$python_version_major -m pip uninstall -y cloudscraper --break-system-packages --quiet >> $removelogfile 2>&1
	else
		echo "No Python restrictions" 1>> $removelogfile
		sudo python$python_version_major -m pip uninstall -y cloudscraper --quiet >> $removelogfile 2>&1
	fi
	
	if [[ -e /usr/bin/dumptorrent ]]
	then
		apt-get purge -y cmake ruby ruby-dev >> $removelogfile 2>&1
		if ( apt-cache show dumptorrent | grep -cq "installed" )
		then
			apt-get purge -y dumptorrent >> $removelogfile 2>&1
		else
			rm -f /usr/bin/dumptorrent /usr/bin/scrapec >> $removelogfile 2>&1
		fi
	fi
	
	apt-get purge -y git libapache2-mod-geoip php$PHP_VERSION-bcmath
	
	echo -e "XXX\n70\nClean system (apt autoremove)\nXXX"
	apt-get clean -y >> $removelogfile 2>&1
	apt-get autoclean -y >> $removelogfile 2>&1
	apt-get autoremove -y >> $removelogfile 2>&1
	
	echo -e "XXX\n90\nRemove config files\nXXX"
	rm $rtorrent_rc_path >> $removelogfile 2>&1
	rm -R $rpc_socket_path >> $removelogfile 2>&1
	rm /usr/lib/tmpfiles.d/rtorrent.conf >> $removelogfile 2>&1
	
	if $1
	then
		rm -R $rtorrent_basedir >> $removelogfile 2>&1
	fi
	
	#remove installation logfile if exist
	if [ -f $logfile ]
	then
		rm -f $logfile >> $removelogfile 2>&1
	fi
	
	echo -e "XXX\n100\nRemoving complete\nXXX"
	} | dialog --begin $small_x $y --gauge "Please wait while removing" $small_height $width 0
	
	tput civis
	sleep 3
	tput cnorm
	
	#remove rtorrent user and group
	sudo deluser $rtorrent_user_name >> $removelogfile 2>&1
	
	#sudo deluser www-data $rtorrent_user_group >> $removelogfile 2>&1
	for username in ${list_of_rtorrent_group_user[@]}
	do
        sudo deluser $username $rtorrent_user_group >> $removelogfile 2>&1
	done
	
	sudo groupdel $rtorrent_user_group >> $removelogfile 2>&1
	
	#move remove-logfile ownership to actual user
	chown -R $stdin_user:$stdin_user $removelogfile
	
	if $1
	then
		one=""
	else
		one="\n Keep files & folders:\n"
	fi
	
	dialog --title "Removing complete" --stdout --begin $x $y --extra-button --extra-label "Show" --ok-label "Exit" --colors --msgbox "\
Removed  packages:\n\
Apache2    (\Z4$apache2_version\Zn) + dependencies\n\
PHP        (\Z4$php_version\Zn) + dependencies\n\
rtorrent   (\Z4$rtorrent_version_installed\Zn) + dependencies\n\
ruTorrent  (\Z4v$activ_rutorrent\Zn) + dependencies\n\
\n\
Removed files & folders:\n\
.rtorrent.rc          \Z4$rtorrent_rc_path\Zn\n\
rpc.socket            \Z4$rpc_socket_path\Zn\n\
$one
softlink              \Z4$softlink_link\Zn\n\
rtorrent basedir      \Z4$rtorrent_basedir\Zn\n\
\n\
The uninstallation is logged in the remove.log"\
	$height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	3)			SHOW_REMOVELOG;;
	esac
}

function SHOW_REMOVELOG {
	dialog --title "Uninstallation log" --stdout --begin $x $y --ok-label "Exit" --extra-button --extra-label "Remove Log" --no-collapse --textbox $removelogfile $height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	3)			rm -f $removelogfile;;
	esac
}

#so far I can estimate only Debian and Raspbian has the non-free repository not included
#so only they needed the additional non-free repository to switch from unrar-free to unrar-nonfree
#
#unrar testet on actuall distributons
# Debian           missing  (included in non-free)
# Ubuntu           included (multiverse)
# Raspberry Pi OS  included (non-free)
# Raspbian         missing  (has to be build from apt source)
# Lmde             included (non-free)
# Ubuntu Mint      included (multiverse)
function USE_UNRAR_NONFREE {
	dialog --title "Use unrar nonfree version" --stdout --begin $x $y --colors --yesno "\
Use unrar non-free instead of unrar free\n\
\n\
Advanced features of version 3.0 archives are not supported\n\
with unrar-free. If you have problems with unpacking\n\
rar-archieves from the ruTorrent GUI switch to unrar-nonfree\n\
version.\n\
\n\
unrar-nonfree conflicts unrar-free so the free version will\n\
be remove first."\
	$height $width
	EXITCODE=$?
	#echo $EXITCODE
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		INSTALL_UNRAR_NONFREE;;
	1|255)	;;
	esac
	MENU
}

function INSTALL_UNRAR_NONFREE {
	if ( apt-cache -q0 show unrar* 2>&1 | grep -cq "Package: unrar$" )
	then
		#echo "nonfree"
		#FROM_UNRAR_FREE_TO_NONFREE
		dialog --title "Use unrar nonfree version" --stdout --begin $x $y --colors --yesno "\
\Z4$distributor\Zn supports the nonfree package from repository.\n\
\n\
The non-free version will be added and the free version will\n\
be removed. Choose < \Z1N\Zno  > if you don't want this."\
		$height $width
		EXITCODE=$?
		#echo $EXITCODE
		# Get exit status
		# 0 means user hit OK button.
		# 1 means user hit CANCEL button.
		# 2 means user hit HELP button.
		# 3 means user hit EXTRA button.
		# 255 means user hit [Esc] key.
		case $EXITCODE in
		0)		FROM_UNRAR_FREE_TO_NONFREE;;
		1|255)	;;
		esac
	else
		#echo "no nonfree"
		case $distributor in
		raspbian)
			dialog --title "Use unrar nonfree version" --stdout --begin $x $y --colors --yesno "\
\Z4$distributor\Zn supports the unrar package via build from source\n\
\n\
The source repository will be added to the sources in the\n\
progress. Choose < \Z1N\Zno  > if you don't want this."\
			$height $width
			EXITCODE=$?
			#echo $EXITCODE
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			case $EXITCODE in
			0)		BUILD_UNRAR;;
			1|255)	;;
			esac
			;;
		debian)
			dialog --title "Use unrar nonfree version" --stdout --begin $x $y --colors --yesno "\
\Z4$distributor\Zn supports the nonfree package via an additonal repository.\n\
\n\
The non-free repository will be added to the sources in the\n\
progress. Choose < \Z1N\Zno  > if you don't want this."\
			$height $width
			EXITCODE=$?
			#echo $EXITCODE
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			case $EXITCODE in
			0)		ADD_REPOSITORY
					FROM_UNRAR_FREE_TO_NONFREE;;
			1|255)	;;
			esac
			;;
		esac
	fi
}

function BUILD_UNRAR {
	dialog --begin $small_x $y --infobox "\nPlease wait while removing unrar-free and updating repository" $small_height $width
	
	#https://forums.raspberrypi.com/viewtopic.php?t=233405
	#https://raspberrypi.stackexchange.com/questions/103544/how-to-extract-mutipart-rar-files
	apt-get purge -y unrar-free >> $LOG_REDIRECTION 2>&1
	apt-get autoremove -y >> $LOG_REDIRECTION 2>&1
	
	sed -i '/deb-src/ s/^#//g' /etc/apt/sources.list
	cd $(mktemp -d)
	apt-get update 1>> $LOG_REDIRECTION
	apt-get build-dep -y unrar-nonfree >> $LOG_REDIRECTION 2>&1
	
	{
	apt-get source -b unrar-nonfree >> $LOG_REDIRECTION 2>&1
	dpkg -i unrar*.deb
	} | dialog --stdout --begin $x $y --progressbox $height $width
	
	tput civis
	sleep 3
	tput cnorm
}

function ADD_REPOSITORY {
	#https://linuxhint.com/debian_sources-list/
	#https://stackoverflow.com/questions/16956810/how-can-i-find-all-files-containing-specific-text-string-on-linux
	
	source="$(grep -rnw "^deb" /etc/apt/ | grep "main" -m 1 | cut -d':' -f3- | cut -d' ' -f1-3) non-free"
	
	cat > "/etc/apt/sources.list.d/non_free.list" <<-EOF
$source
EOF
	
	apt-get update >> $LOG_REDIRECTION 2>&1
}

function FROM_UNRAR_FREE_TO_NONFREE {
	apt-get purge -y unrar-free >> $LOG_REDIRECTION 2>&1
	apt-get autoremove -y >> $LOG_REDIRECTION 2>&1
	apt-get install -y unrar >> $LOG_REDIRECTION 2>&1
}

# https://github.com/pi-hole/pi-hole/blob/master/pihole
function ROOT_CHECK {
	# Must be root to use this tool
	if [[ ! $EUID -eq 0 ]];
	then
		if [[ -x "$(command -v sudo)" ]];
		then
			exec sudo bash "$0"
			exit 0
		else
			echo "sudo is needed to run commands. Please run this script as root or install sudo."
			exit 1
		fi
	fi
}

function START () {
	ROOT_CHECK
	echo "fetching system information..."
	echo "starting graphical user interface..."
	sleep 1
	SCRIPT_BASE_INSTALL
	MENU
}

START
