#!/bin/bash
export NCURSES_NO_UTF8_ACS=1
separator=":"
#Fullmenu true,false
fullmenu=false
#Output Redirection /dev/null or logfile
logfile=install.log
LOG_REDIRECTION="/dev/null"
#LOG_REDIRECTION=$logfile
# Script versionnumber
script_versionumber=1.2
# Window dimensions
height=20
small_height=6
width=70
# Window position
x=2
small_x=8
y=5

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

if [[ $distributor == "ubuntu" ]]
then
	debian_version=$(cat /etc/debian_version | cut -d"/" -f1)
	codename="$codename ($debian_version)"
fi

#rtorrent
rtorrent_version=$(apt-cache policy rtorrent | head -3 | tail -1 | cut -d' ' -f4)
rtorrent_version_micro=${rtorrent_version:4:1}
libtorrent_version=$(apt-cache policy libtorrent?? | head -3 | tail -1 | cut -d' ' -f4)

#python
python_path=$(ls -l /usr/bin/python? | tail -1 | rev | cut -d' ' -f3 | rev)
python_version="$($python_path -V | cut -d' ' -f2)"
python_version_major=${python_version:0:1}
python_pip=python$python_version_major-pip

#php
php_version="$(apt-cache policy php | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1)"

#apache2
apache2_version="$(apt-cache policy apache2 | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1)"

## get mini UID limit ##
low=$(grep "^UID_MIN" /etc/login.defs | cut -d' ' -f2)
## get max UID limit ##
#high=$(grep "^UID_MAX" /etc/login.defs | cut -d' ' -f2)
let high=$((2 * low))

#system_low = 1 prevent root from using
system_low=1
let system_high=$((low - 1))

#rutorrents
ALL_VERSION=$(wget -q https://api.github.com/repos/Novik/ruTorrent/releases -O - | grep tag_name | cut -d'"' -f4)
# remove v4.0 "All Linux Distributions should mark version 4 as "unstable" due to caching issues and use the v4.0.1 hot fix release instead"
# https://github.com/Novik/ruTorrent/releases/tag/v4.0.1-hotfix
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
		apt-get -y install $base0 $base1 1> /dev/null
	fi
}

function MENU {
	LOG_REDIRECTION="/dev/null"
	menu_options=("0" "System Information"
	              "1" "Licence"
	              "2" "Changelog"
	              "I" "Scripted Installation"
	              "R" "Update/Change ruTorrent"
	              "V" "Change VHost"
	              "S" "Enable/Renew SSL for VHost"
	              "W" "Enable/Disable WebAuth"
	              "A" "Add User to WebAuth"
	              "U" "Remove User from WebAuth")
	
	if [ -f $logfile ]
	then
		menu_options+=("L" "Show Installation log")
	fi
	
	if $fullmenu
	then
		menu_options+=("9" "Add User"
		               "6" "Remove User"
		               "4" "Allow SSH"
		               "5" "Deny SSH"
		               "7" "Install webserver & php"
		               "8" "Install rtorrent on User \Z4$(who am i | cut -d" " -f1)\Zn"
		               "E" "Edit rtorrent.rc on User \Z4$(who am i | cut -d" " -f1)\Zn")
	fi
	
	#	               "Z" "Install Complete"
	#	               "N" "Script")
	
	SELECTED=$(dialog \
	--backtitle "rtorrent & ruTorrent Installation Script V$script_versionumber" \
	--title "Menu" \
	--stdout \
	--begin $x $y \
	--colors \
	--cancel-label "Exit" \
	--menu "Options" $height $width 12 "${menu_options[@]}")
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

function EXIT {
	echo ""
	echo "goodbye!"
	exit 0
}

function INSTALLLOG {
	dialog --title "Installation log" --stdout --begin $x $y --ok-label "Exit" --extra-button --extra-label "Remove Log" --no-collapse --textbox $logfile $height $width
	EXITCODE=$?
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0|1|255)	;;
	3)			rm -f install.log;;
	esac
	MENU
}

function MENU_OPTIONS () {
	case $1 in
	0)	HEADER;;
	1)	LICENSE;;
	2)	CHANGELOG;;
	I)	SCRIPTED_INSTALL;;
	R)	UPDATE_RUTORRENT;;
	V)	CHANGE_VHOST;;
	S)	SSL_FOR_WEBSERVER;;
	W)	WEBAUTH_TOGGLE;;
	A)	ADD_USER_TO_WEBAUTH;;
	U)	REMOVE_WEBAUTH_USER;;
	L)	INSTALLLOG;;
	9)	ADD_USER;;
	6)	REMOVE_USER;;
	4)	ALLOW_SSH;;
	5)	DENY_SSH;;
	7)	APACHE2;;
	8)	RTORRENT_LOCAL "$(who am i | cut -d" " -f1)";;
	E)	EDIT_RTORRENTRC "$(who am i | cut -d" " -f1)";;
	Z)	INSTALL_COMPLETE;;
	N)	SCRIPT;;
	3)	SELECT_USER;;
	esac
}

function HEADER {
	systemupdate=$(stat  /var/cache/apt/ | head -6 | tail -1 | cut -d' ' -f2- | cut -d. -f1)
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
Software Versions:\n\
   rtorrent:               \Z4$rtorrent_version\Z0\n\
   libtorrent:             \Z4$libtorrent_version\Z0\n\
   Python:                 \Z4$python_version\Z0\n\
   Apache2:                \Z4$apache2_version\Z0\n\
   PHP                     \Z4$php_version\Z0"\
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
	link=$(wget -q -O - https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/changelog)
	dialog --title "Changelog" --stdout --begin $x $y --no-collapse --msgbox "$link" $height $width
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
	
	USERS[2]=on
	SELECTED=$(dialog \
	--title "Select rtorrent User" \
	--stdout \
	--begin $x $y \
	--extra-button \
	--extra-label "Add User"\
	--radiolist "Select User" $height $width 13 "${USERS[@]}")
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

function PRESENT_USER () {
	echo "Username:"
	echo "$1"
	echo "Group:"
	echo "$(grep "$(id -u $1)" /etc/group | cut -d":" -f1)"
	echo "home:"
	echo "$(getent passwd "$1" | cut -d: -f6)"
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
	0)		CREATE_USER "${SHOWN[@]}";;
	1|255)	;;
	esac
	MENU
}

function CREATE_USER () {
	arr=("$@")
	
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
	apt-get -y install openssl git apache2 apache2-utils build-essential libsigc++-2.0-dev libcurl4-openssl-dev automake libtool libcppunit-dev libncurses5-dev php$PHP_VERSION php$PHP_VERSION-curl php$PHP_VERSION-cli libapache2-mod-php$PHP_VERSION unzip libssl-dev curl 2>/dev/null 1>> $LOG_REDIRECTION
	
	#https://www.digitalocean.com/community/tutorials/apache-configuration-error-ah00558-could-not-reliably-determine-the-server-s-fully-qualified-domain-name
	echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
	systemctl reload apache2.service 1>> $LOG_REDIRECTION
}

function RTORRENT_LOCAL () {
	RTORRENT $1
	EDIT_RTORRENTRC $1
	
	systemctl enable rtorrent.service 1> /dev/null
	systemctl start rtorrent.service 1> /dev/null
	systemctl status rtorrent.service --no-pager 1> /dev/null
	MENU
}

function RTORRENT () {
	# USER[_] 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
	USER[0]=
	USER[1]=$1
	USER[2]=
	USER[3]=$(grep "$(id -u $1)" /etc/group | cut -d":" -f1)
	USER[4]=$(getent passwd "$1" | cut -d: -f6)
	USER[5]=
	
	#echo ${USER[1]}
	#echo ${USER[3]}
	#echo ${USER[4]}
	
	apt-get -y install rtorrent 1>> $LOG_REDIRECTION
	
	#https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template
	wget -q -O - "https://raw.githubusercontent.com/wiki/rakshasa/rtorrent/CONFIG-Template.md" | sed -ne "/^######/,/^### END/p" | sed -re "s:/home/USERNAME:${USER[4]}:" >${USER[4]}/.rtorrent.rc
	
	chown -R ${USER[1]}:${USER[3]} ${USER[4]}/.rtorrent.rc
	chmod -R 775 ${USER[4]}/.rtorrent.rc
	
	#https://github.com/rakshasa/rtorrent/issues/949#issuecomment-572528586
	sed -i '/^system.umask.*/a session.use_lock.set = no' ${USER[4]}/.rtorrent.rc
	#rpc enabled from local socket
	#https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC
	#https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
	sed -i '/(session.path),rpc.socket)/ s/^#//' ${USER[4]}/.rtorrent.rc
	sed -i '/(session.path),rpc.socket)/ s/770/777/' ${USER[4]}/.rtorrent.rc
	
	if (( $rtorrent_version_micro <= 6 ))
	then
		echo "rtorrent Version is equal or lower than 0.9.6" 1>> $LOG_REDIRECTION
		apt-get install -y tmux 1>> $LOG_REDIRECTION
		RTORRENT_TMUX_SERVICE ${USER[1]}
	else
		echo "daemon mode enabled since 0.9.7+" 1>> $LOG_REDIRECTION
		sed -i '/system.daemon.set/ s/^#//' ${USER[4]}/.rtorrent.rc
		RTORRENT_SERVICE ${USER[1]}
	fi
	
	echo "rtorrent rtorrent.service" 1>> $LOG_REDIRECTION 
	cat /etc/systemd/system/rtorrent.service 1>> $LOG_REDIRECTION
}

function RTORRENT_TMUX_SERVICE () {
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
[Unit]
Description=rtorrent (in tmux)
Requires=network-online.target
After=apache2.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$1
ExecStart=/usr/bin/tmux -2 new-session -d -s rtorrent rtorrent
ExecStop=/usr/bin/tmux send-keys -t rtorrent:rtorrent C-q

[Install]
WantedBy=default.target
EOF
}

function RTORRENT_SERVICE () {
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
[Unit]
Description=rtorrent deamon
Requires=network-online.target
After=apache2.service

[Service]
Type=simple
RemainAfterExit=yes
User=$1
ExecStart=/usr/bin/rtorrent
KillMode=process

[Install]
WantedBy=default.target
EOF
}

function EDIT_RTORRENTRC () {
	# USER[_]
	# 0 User attribute, 1 Username, 2 User password, 3 Usergroup = Username, 4 User homedir, 5 User SSH status
	USER[0]=
	USER[1]=$1
	USER[2]=
	USER[3]=$(grep "$(id -u $1)" /etc/group | cut -d":" -f1)
	USER[4]=$(getent passwd "$1" | cut -d: -f6)
	USER[5]=
	# 6 Portrange, 7 Portrange min, 8 Portrange max, 9 Randomportset, 10 rtorrent basedir
	USER[6]=$(grep 'port_range.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	USER[7]=$(echo ${USER[6]} | cut -d'-' -f1)
	USER[8]=$(echo ${USER[6]} | cut -d'-' -f2)
	USER[9]=$(grep 'port_random.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	USER[10]=$(grep 'method.insert = cfg.basedir' ${USER[4]}/.rtorrent.rc | cut -d'"' -f2 | rev | cut -d'/' -f3- | rev)
	# 11 new Portrange, 12 new Portrange min, 13 new Portrange max, 14 new Randomportset, 15 new rtorrent basedir
	USER[11]=$(grep 'port_range.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	USER[12]=$(echo ${USER[6]} | cut -d'-' -f1)
	USER[13]=$(echo ${USER[6]} | cut -d'-' -f2)
	USER[14]=$(grep 'port_random.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	USER[15]=$(grep 'method.insert = cfg.basedir' ${USER[4]}/.rtorrent.rc | cut -d'"' -f2 | rev | cut -d'/' -f3- | rev)
	
	CHANGE_RTORRENTRC "${USER[@]}"
	systemctl restart rtorrent.service 1> /dev/null
	MENU
}

function CHANGE_RTORRENTRC () {
	arr=("$@")
	HOMEDIR=${arr[4]}
	PORT_RANGE=${arr[6]}
	PORT_RANGE_MIN=${arr[7]}
	PORT_RANGE_MAX=${arr[8]}
	PORT_SET=${arr[9]}
	DLFOLDER=${arr[10]}
	
	NEW_PORT_RANGE=${arr[11]}
	NEW_PORT_RANGE_MIN=${arr[12]}
	NEW_PORT_RANGE_MAX=${arr[13]}
	NEW_PORT_SET=${arr[14]}
	NEW_DLFOLDER=${arr[15]}
	
	OUTPUT=$(dialog \
	--title "Edit rtorrent.rc" \
	--stdout \
	--begin $x $y \
	--trim \
	--extra-button \
	--extra-label "Change Basedir" \
	--output-separator $separator \
	--mixedform " Port Range defines the usable Ports for rtorrent\n
	Random Listening Port let rtorrent set the Port randomly\n
	rtorrent basedir (needs to be writeable by rtorrent user): \n
	 └── rtorrent \n
	     ├── .session \n
	     │   └── rpc.socket \n
	     ├── download \n
	     ├── log \n
	     └── watch \n
	"\
	$height $width 0 \
	"Port Range                    :" 1 1  " $NEW_PORT_RANGE_MIN" 1 33  6 0 0 \
	"-"                               1 39 " $NEW_PORT_RANGE_MAX" 1 40  6 0 0 \
	"Random Listening Port (yes/no):" 2 1  "$NEW_PORT_SET"        2 33  5 0 0 \
	"rtorrent Basedir              :" 3 1  "$NEW_DLFOLDER"        3 33 31 0 2 \
	)
	EXITCODE=$?
	#echo $OUTPUT
	#remove spaces from String
	OUTPUT=$(echo $OUTPUT | sed 's/ //g')
	IFS=$separator read -a SHOWN <<< "$OUTPUT"
	
	NEW_PORT_RANGE="${SHOWN[0]}-${SHOWN[1]}"
	SELECTED="${SHOWN[2]}"
	NEW_DLFOLDER="${SHOWN[3]}"
	
	arr[11]=$NEW_PORT_RANGE
	arr[12]=${SHOWN[0]}
	arr[13]=${SHOWN[1]}
	arr[14]=${SHOWN[2]}
	
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)		sed -i '/port_range.set/ s/'"$PORT_RANGE"'/'"$NEW_PORT_RANGE"'/' $HOMEDIR/.rtorrent.rc
			sed -i '/port_random.set/ s/'"$PORT_SET"'/'"$SELECTED"'/' $HOMEDIR/.rtorrent.rc
			sed -i 's#'"$DLFOLDER"'#'"$NEW_DLFOLDER"'#' $HOMEDIR/.rtorrent.rc
			chown -R ${arr[1]}:${arr[3]} $NEW_DLFOLDER;;
	1|255)	;;
	3)		CHANGE_DLFOLDER "${arr[@]}";;
	esac
}

function CHANGE_DLFOLDER () {
	arr=("$@")
	
	RETURN=$(dialog --stdout --begin $x $y --dselect "${arr[15]}" $height $width)
	EXITCODE=$?
	RETURN=$(echo "$RETURN" | sed 's:/*$::')
	
	arr[15]=$RETURN
	# Get exit status
	# 0 means user hit OK button.
	# 1 means user hit CANCEL button.
	# 2 means user hit HELP button.
	# 3 means user hit EXTRA button.
	# 255 means user hit [Esc] key.
	case $EXITCODE in
	0)   	CHANGE_RTORRENTRC "${arr[@]}";;
	1|255)	;;
	esac
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
	0)   	SELF_SIGNED $OUTPUT;;
	1|255)	;;
	3)		LE_SIGNED $OUTPUT;;
	esac
	MENU
}

function SELF_SIGNED () {
	if [[ $(a2query -s | cut -d' ' -f1 | grep -v https_redirect | grep -c -i "SS-SSL") -ne 0 ]]
	then
		DNS=$(openssl x509 -text -noout -in /etc/ssl/certs/rutorrent-selfsigned.crt | grep "DNS" | cut -d: -f2 | cut -d, -f1)
		dialog --title "Self Signed certification" --stdout --begin $small_x $y --ok-label "Abort" --no-cancel --extra-button --extra-label "Renew cert" --yesno "Activ VHost used allready SSL, aborted" $small_height $width
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
		dialog --title "Let's Encrypt certification" --stdout --begin $small_x $y --ok-label "Abort" --no-cancel --extra-button --extra-label "Renew cert" --yesno "Activ VHost used allready SSL, aborted" $small_height $width
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
	# recover Overridestatus for SSL Page
	status=$(grep "AllowOverride" /etc/apache2/sites-available/$CURRENT_CONF.conf | rev | cut -d" " -f1 | rev)
	
	a2enmod ssl 1> /dev/null
	a2enmod headers 1> /dev/null
	
	cat > /etc/apache2/sites-available/$CURRENT_CONF-ss-ssl.conf << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/$CURRENT_CONF
	<Directory "/var/www/$CURRENT_CONF">
		AllowOverride $status
	</Directory>

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog ${APACHE_LOG_DIR}/rutorrent_error.log
	CustomLog ${APACHE_LOG_DIR}/rutorrent.log vhost_combined

	Include /etc/apache2/conf-available/options-ssl-apache.conf
	SSLEngine on
	SSLCertificateFile /etc/ssl/certs/rutorrent-selfsigned.crt
	SSLCertificateKeyFile /etc/ssl/private/rutorrent-selfsigned.key
	Header always set Strict-Transport-Security "max-age=63072000"
</VirtualHost>
</IfModule>
EOF
	
	a2dissite $CURRENT_CONF.conf 1> /dev/null
	a2ensite $CURRENT_CONF-ss-ssl.conf 1> /dev/null
	systemctl reload apache2.service 1> /dev/null
	systemctl restart apache2.service 1> /dev/null
}

function CONFIGURE_HTTPS_REDIRECT_CONF {
	a2enmod rewrite 1> /dev/null
	
	cat > /etc/apache2/sites-available/https_redirect.conf <<-EOF
<VirtualHost *:80>
	ServerAlias *
	RewriteEngine on
	RewriteRule ^/(.*) https://%{HTTP_HOST}/$1 [NC,R=301,L]
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
	DOMAIN_NAME=$1
	
	a2enmod ssl 1> /dev/null
	a2enmod headers 1> /dev/null
	
	apt-get install -y python3-certbot-apache 1> /dev/null
	
	certbot --apache --rsa-key-size 4096 --must-staple --hsts --uir --staple-ocsp --strict-permissions --register-unsafely-without-email --agree-tos --no-redirect -d "$DOMAIN_NAME" 2>&1 | dialog --stdout --begin $x $y --progressbox $height $width
	sed -i 's/31536000/63072000/g' /etc/apache2/sites-available/$CURRENT_CONF-le-ssl.conf
	
	tput civis
	sleep 3
	tput cnorm
	
	a2dissite $CURRENT_CONF.conf 1> /dev/null
	systemctl reload apache2.service 1> /dev/null
	systemctl restart apache2.service 1> /dev/null
}

function UPDATE_RUTORRENT () {
	dialog  --stdout --begin $small_x $y --infobox "searching for rtorrent (rpc.socket)..." $small_height $width
	file=rpc.socket
	GREP_RPCSOCKET=$(find / -name $file)
	LINES=$(find / -name $file | grep -c $file)
	
	if [ -z "$GREP_RPCSOCKET" ]
	then
		dialog --title "Error" --stdout --begin $x $y --msgbox "No rtorrent installed (no rpc.socket found)" $height $width
	else
		#echo "\$var is NOT empty"
		if [ $LINES -eq 1 ]
		then
			BASEDIR=$(echo $GREP_RPCSOCKET | rev | cut -d'/' -f4- | rev)
			#echo $HOMEDIR
			MENU_RUTORRENT "$BASEDIR"
		else
			last='""off'
			variablenname=$(echo $GREP_RPCSOCKET | sed 's/ /""off"/g')
			full="$variablenname$last"
			IFS='"' read -a RPCSOCKET <<< "$full"
			
			BASEDIR=$(dialog --title "Found RPC Socket" --stdout --begin $x $y --radiolist "found RPC Socket" 20 70 10 "${RPCSOCKET[@]}")
			EXITCODE=$?
			BASEDIR=$(echo $BASEDIR | rev | cut -d'/' -f4- | rev)
			#echo $EXITCODE
			#echo $BASEDIR
			# Get exit status
			# 0 means user hit OK button.
			# 1 means user hit CANCEL button.
			# 2 means user hit HELP button.
			# 3 means user hit EXTRA button.
			# 255 means user hit [Esc] key.
			case $EXITCODE in
			0)		MENU_RUTORRENT "$BASEDIR";;
			1|255)	;;
			esac
		fi
	fi
	MENU
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
	0)		INSTALL_RUTORRENT "$SELECTED" "$1";;
	1|255)	;;
	esac
}

function INSTALL_RUTORRENT () {
	HOMEDIR=$2
	#echo $HOMEDIR
	
	if [ -z "$1" ]
	then
		#echo "\$1 is empty"
		dialog --title "Error" --stdout --begin $small_x $y --msgbox "No ruTorrent Version was choosen" $small_height $width
	else
		SELECTED=$1
		#SELECTED_CUT=
		SELECTED_CUT="ruTorrent-${SELECTED:1}"
		
		cd /var/www
		wget -q https://github.com/Novik/ruTorrent/archive/$SELECTED.zip -O $SELECTED_CUT.zip
		unzip -qqo $SELECTED_CUT.zip
		rm $SELECTED_CUT.zip
		
		#https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC
		sed -i 's|scgi_port = 5000|scgi_port = 0|' /var/www/$SELECTED_CUT/conf/config.php
		sed -i 's|scgi_host = "127.0.0.1"|scgi_host = "unix://'"$HOMEDIR"'/rtorrent/.session/rpc.socket"|' /var/www/$SELECTED_CUT/conf/config.php
		
		chown -R www-data:www-data /var/www/$SELECTED_CUT
		chmod -R 775 /var/www/$SELECTED_CUT
		cd ~
		
		# dependencies for ruTorrent addons
		#                                                                        spectrogram Plugin
		apt-get -y install ffmpeg libzen0v5 libmediainfo0v5 mediainfo unrar-free sox libsox-fmt-mp3 2>/dev/null 1>> $LOG_REDIRECTION
		# php-geoip virtuelles Paket, bereitgestellt durch libapache2-mod-php7.3
		
		if [[ $codename == "stretch" || $debian_version == "stretch" ]]
		then
			echo "Debian 9" 1>> $LOG_REDIRECTION
			echo "cloudflare does not work atm" 1>> $LOG_REDIRECTION
			sed -i '$a[_cloudflare]' /var/www/$SELECTED_CUT/conf/plugins.ini
			sed -i '$aenabled = no' /var/www/$SELECTED_CUT/conf/plugins.ini
		else
			if [ "$SELECTED" != "v3.8" ]
			then
				echo "with _cloudflare" 1>> $LOG_REDIRECTION
				#https://unix.stackexchange.com/questions/89913/sed-ignore-line-starting-whitespace-for-match
				#https://stackoverflow.com/questions/7517632/how-do-i-escape-slashes-and-double-and-single-quotes-in-sed
				#sed -i '/^\s*$pathToExternals.*/a \                "python"=> '"'"''"$python_path"''"'"',' /var/www/$SELECTED_CUT/conf/config.php
				sed -i '/^\s*$pathToExternals.*/a \		"python"=> '"'"''"$python_path"''"'"',' /var/www/$SELECTED_CUT/conf/config.php
				apt-get install -y $python_pip 1>> $LOG_REDIRECTION
				sudo python$python_version_major -m pip install cloudscraper --quiet 1>> $LOG_REDIRECTION
			else
				#:
				echo "no _cloudflare" 1>> $LOG_REDIRECTION
			fi
		fi
		CREATE_AND_ACTIVATE_CONF $SELECTED_CUT
	fi
	
	# only for install log needed
	echo "rutorrent config.php"
	cat /var/www/$SELECTED_CUT/conf/config.php
	echo "Apache $SELECTED_CUT.conf vhost"
	cat /etc/apache2/sites-available/$SELECTED_CUT.conf
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

	ErrorLog ${APACHE_LOG_DIR}/rutorrent_error.log
	CustomLog ${APACHE_LOG_DIR}/rutorrent.log vhost_combined
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
	status=$(grep "AllowOverride" /etc/apache2/sites-available/$CURRENT_CONF.conf | rev | cut -d" " -f1 | rev)
	
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
	if echo "$CURRENT_CONF" | grep -q -i "SSL"
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
			if [[ $(grep ":" /var/www/$TARGET/.htpasswd | cut -d":" -f1 | grep -c ${arr[0]}) -ne 0 ]]
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
		
		chown -R www-data.www-data /var/www/$TARGET/.ht*
		
		systemctl reload apache2.service
		dialog --title "Done" --stdout --begin $x $y --msgbox "\nNew User ${arr[0]} created" $height $width
	fi
}

function REMOVE_WEBAUTH_USER {
	CURRENT_CONF=$(a2query -s | cut -d' ' -f1 | grep -v https_redirect)
	if echo "$CURRENT_CONF" | grep -q -i "SSL"
	then
		TARGET=${CURRENT_CONF:0:(${#CURRENT_CONF}-7)}
	else
		TARGET=$CURRENT_CONF
	fi
	
	present_web=$(grep ":" /var/www/$TARGET/.htpasswd | cut -d":" -f1 | sort)
	
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
	if echo "$CURRENT_CONF" | grep -q -i "SSL"
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

function SCRIPTED_INSTALL () {
	dialog --title "Scripted Installation" --stdout --begin $x $y --colors --yesno "\
The scripted installation ask you some questions about the\n\
user for rtorrent, the ruTorrent version and other stuff,\n\
after that you will see a list with all you have selected.\n\
\n\
You can shortcut everything with hitting \Zu\"enter\"\ZU to get a\n\
standard installation with the most common result, newest\n\
versions, and all under the users home folder\n\
\n\
Until you choose install, nothing will happen to your system.\n\
To this point this installation only looks after \Z4dialog\Zn\n\
what makes this fancy menu and for \Z4wget\Zn for the downloads\n\
both should allready part of an debian based linux system.\n\
\n\
So only these two are installed until now, the installation\n\
started with an update e.g. (apt update; apt dist-upgrade) to\n\
get this linux up-to-date before the installations starts.\n\
\n\
You can allways update your ruTorrent to the next version and\n\
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
		USER[3]=$(grep "$(id -u $SELECTED)" /etc/group | cut -d":" -f1)
		USER[4]=$(getent passwd "$SELECTED" | cut -d: -f6)
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
				# 0 User attribute, 1 Username, 2 User password, 3 Usergroup=Username, 4 User homedir, 5 User SSH status
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
	DLFOLDER=${USER[4]}
	
	OUTPUT=$(dialog \
	--title "Edit rtorrent.rc" \
	--stdout \
	--begin $x $y \
	--trim \
	--extra-button \
	--extra-label "Change Basedir" \
	--output-separator $separator \
	--default-button "ok" \
	--mixedform " Port Range defines the usable Ports for rtorrent\n
	Random Listening Port let rtorrent set the Port randomly\n
	rtorrent basedir (script will grep permissions):\n
	 └── rtorrent \n
	     ├── .session \n
	     │   └── rpc.socket \n
	     ├── download \n
	     ├── log \n
	     └── watch \n
	"\
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
		# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
		RC[0]="${SHOWN[0]}-${SHOWN[1]}"
		RC[1]="${SHOWN[2]}"
		RC[2]="${SHOWN[3]}"
		;;
	1|255)	MENU;;
	3)
		RETURN=$(dialog --stdout --dselect "$DLFOLDER" $height $width)
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
		0)
			# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
			RC[0]="${SHOWN[0]}-${SHOWN[1]}"
			RC[1]="${SHOWN[2]}"
			RC[2]=$RETURN
			;;
		1|255)	MENU;;
		esac
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
	#MENU
}

function SUM () {
	if [[ ${USER[0]} == "to_create" ]]
	then
		Deny_line="SSH Login for rtorrent User        \Z4${USER[5]}\Z0"
	else
		if (grep "^DenyUsers" /etc/ssh/sshd_config | grep -cq "${USER[1]}")
		then
			Deny_line="SSH Login for rtorrent User        \Z4no\Z0"
		else
			Deny_line="SSH Login for rtorrent User        \Z4yes\Z0"
		fi
	fi
	
	dialog --title "Scripted Installation" --stdout --begin $x $y --colors --yesno "\
Configuration:\n\
\n\
rtorrent User                      \Z4${USER[1]}\Z0\n\
$Deny_line\n\
\n\
rtorrent version                   \Z4$rtorrent_version\Z0\n\
rtorrent.rc placed in              \Z4${USER[4]}\Z0\n\
Portrange                          \Z4${RC[0]}\Z0\n\
Random Listening port              \Z4${RC[1]}\Z0\n\
rtorrent Basedir                   \Z4${RC[2]}\Z0\n\
ruTorrent Version                  \Z4$RUTORRENT_VERSION\Z0\n\
\n\
This Script will install rtorrent and ruTorrent with this\n\
configuration, rtorrent set all folders within this installation.\n\
\n\
The permissons of the rtorrent Basedir will granted to \Z4${USER[1]}\Z0\n\
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
	(time SYSTEM_UPDATE) >> $logfile 2>&1
	
	echo "Install Apache" 1>> $LOG_REDIRECTION
	echo -e "XXX\n30\nInstall Apache and PHP\nXXX"
	(time APACHE2) >> $logfile 2>&1
	
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
	
	echo "Install rtorrent" 1>> $LOG_REDIRECTION
	echo -e "XXX\n65\nInstall and configure rtorrent\nXXX"
	(time RTORRENT ${USER[1]}) >> $logfile 2>&1
	
	PORT_RANGE=$(grep 'port_range.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	PORT_SET=$(grep 'port_random.set' ${USER[4]}/.rtorrent.rc | cut -d' ' -f3)
	DLFOLDER=$(grep 'method.insert = cfg.basedir' ${USER[4]}/.rtorrent.rc | cut -d'"' -f2 | rev | cut -d'/' -f3- | rev)
	
	# RC[_] 0 Portrange, 1 random port set, 2 rtorrent basedir
	sed -i '/port_range.set/ s/'"$PORT_RANGE"'/'"${RC[0]}"'/' ${USER[4]}/.rtorrent.rc
	sed -i '/port_random.set/ s/'"$PORT_SET"'/'"${RC[1]}"'/' ${USER[4]}/.rtorrent.rc
	sed -i 's#'"$DLFOLDER"'#'"${RC[2]}"'#' ${USER[4]}/.rtorrent.rc
	chown -R ${USER[1]}:${USER[3]} ${RC[2]}
	
	echo "Enable rtorrent" 1>> $LOG_REDIRECTION
	systemctl enable rtorrent.service 2>> $LOG_REDIRECTION
	systemctl start rtorrent.service 1>> $LOG_REDIRECTION
	systemctl status rtorrent.service --no-pager 1>> $LOG_REDIRECTION
	
	echo "Install rutorrent" 1>> $LOG_REDIRECTION
	echo -e "XXX\n70\nInstall and configure rutorrent\nXXX"
	(time INSTALL_RUTORRENT $RUTORRENT_VERSION ${RC[2]}) >> $logfile 2>&1
	
	echo -e "XXX\n100\nInstallation complete\nXXX"
	} | dialog --begin $small_x $y --gauge "Please wait while installing" $small_height $width 0
	sleep 2
	INSTALL_COMPLETE
}

function INSTALL_COMPLETE {
	external_ip=$(wget -O - -q ipv4.icanhazip.com)
	internal_ip=$(hostname -I | cut -d' ' -f1 | sed 's/ //g')
	HOMEDIR=${USER[4]}
	BASEDIR=${RC[2]}
	
	dialog --title "Installation Complete" --stdout --begin $x $y --colors --msgbox "\
 \Z2Installation is complete.\Z0\n\
\n\
 The actual Apache2 vhost file has been disabled and replaced\n\
 with a new one. If you were using it, combine the default and\n\
 the ruTorrent vhost file and enable it again.\n\
\n\
 Your downloads folder is in \Z2$BASEDIR/Downloads\Z0\n\
 Sessions data is in \Z2$BASEDIR/.rtorrent-session\Z0\n\
 rtorrent's configuration file is in \Z2$HOMEDIR/.rtorrent.rc\Z0\n\
\n\
 If you want to change settings for rtorrent, such as download\n\
 folder, etc., you need to edit the '.rtorrent.rc' file. E.g.\n\
 'nano \Z2$HOMEDIR/.rtorrent.rc\Z0'\n\
\n\
 rtorrent can be started|stopped|restarted without rebooting\n\
 with '\Z5sudo systemctl start|stop|restart rtorrent.service\Z0'.\n\
\n\
 \Z2LOCAL IP:\Z0    http://$internal_ip/\n\
 \Z2EXTERNAL IP:\Z0 http://$external_ip/\n\
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