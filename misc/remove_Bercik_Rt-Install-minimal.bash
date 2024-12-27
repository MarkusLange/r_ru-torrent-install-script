#!/bin/bash
export NCURSES_NO_UTF8_ACS=1
#dialog output seperator
separator=":"

#Window dimensions
height=20
small_height=6
width=70
#Window position
x=2
small_x=8
y=5

#get system_user
system_user=$(cat /etc/systemd/system/rtorrent.service | grep 'User' | cut -d'=' -f2)
system_user_homedir=$(getent passwd "$system_user" | cut -d':' -f6)

#get rtorrent folders
rtorrent_rc_path=$(find /home -name .rtorrent.rc)
rtorrent_session_path=$(cat $rtorrent_rc_path | grep "session = " | sed -re 's#~#'"$system_user_homedir"'#' | cut -d' ' -f3)
rtorrent_download_path=$(cat $rtorrent_rc_path | grep "directory = " | sed -re 's#~#'"$system_user_homedir"'#' | cut -d' ' -f3)

function SCRIPT_BASE_INSTALL {
	DIALOG_CHECK="$(dpkg-query -W -f='${Status}\n' dialog 2>/dev/null | grep -c "ok installed")"
	
	if [ "$DIALOG_CHECK" -ne 1 ];
	then
		apt-get -y install dialog
	fi
}

function REMOVE_RTORRENT () {
	systemctl stop rtorrent.service
	systemctl disable rtorrent.service
	systemctl daemon-reload
	rm /etc/systemd/system/rtorrent.service
	
	libtorrent_version=$(dpkg --get-selections | sed 's:install$::' | grep libtorrent | cut -d':' -f1)
	apt-get purge -y rtorrent libxmlrpc-core-c3 $libtorrent_version
	
	#apt-get purge -y rtorrent
	
	rm $rtorrent_rc_path
	
	mkdir -p $rtorrent_basedir/rtorrent 
	mv $rtorrent_session_path $rtorrent_basedir/rtorrent/.session
	mv $rtorrent_download_path $rtorrent_basedir/rtorrent/download
	
	#mkdir -p $rtorrent_download_path
	
	rm $rtorrent_basedir/rtorrent/.session/*.libtorrent_resume
	rm $rtorrent_basedir/rtorrent/.session/*.rtorrent
}

function REMOVE_APACHE () {
	systemctl stop apache2.service
	systemctl disable apache2.service
	systemctl daemon-reload
	
	apt-get purge -y git apache2 apache2-utils apache2-bin libapache2-mod-scgi unrar-free php php-curl php-cli libapache2-mod-php tmux unzip curl mediainfo unrar-free
	
	rm -f $system_user_homedir/libapache2-mod-scgi*
	rm -R /var/www $(whereis apache2 | cut -d':' -f2)
}

function CLEAN_REST () {
	apt-get clean -y
	apt-get autoclean -y
	apt-get autoremove -y
}

function START_REMOVE () {
	REMOVE_RTORRENT
	REMOVE_APACHE
	CLEAN_REST
	
	rm -r $system_user_homedir/Files
}

function SCRIPTED_REMOVE () {
	rtorrent_basedir="/srv"
	
	dialog --title "Scripted remove of Bercik Rt-Install-minimum" --stdout --begin $x $y --colors --yesno "\
The scripted remove of Bercik Rt-Install-minimum Script it will\n\
remove the complete installation done by Bercik's Script, except\n\
the downloaded torrents and session data so the torrents can be\n\
restored.\n\
\n\
The following infomations are collected:\n\
System user (rtorrent.service):\n\
         \Z4$system_user\Z0\n\
.rtorrent.rc path (with find):\n\
         \Z4$rtorrent_rc_path\Z0\n\
.rtorrent-session path (.rtorrent.rc):\n\
         \Z4$rtorrent_session_path\Z0\n\
Downloads path (.rtorrent.rc):\n\
         \Z4$rtorrent_download_path\Z0\n\
\n\
The Downloads and the session data will moved into a structure\n\
based on the latest .rtorrent.rc config from rtorrent stored\n\
inside \Z4$rtorrent_basedir\Z0, folder can be changed in the next step.\n\
\n\
Please make sure all torrents are completed.
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
	0)		MOVE_INTO;;
	1|255)	EXIT;;
	esac
}

function MOVE_INTO () {
	while :; do
		dialog --title "Change rtorrent Basedir/Remove Installation" --stdout --begin $x $y --colors --extra-button --extra-label "Change Basedir" --yes-label "Start" --no-label "Exit" --yesno "\
The folder Downloads and .rtorrent-session will be renamed\n\
and moved into this structure:\n
	\Z4$rtorrent_basedir\Zn \n
	 └── /rtorrent \n
	      ├── /.session (.rtorrent-session) \n
	      ├── /download (Downloads) \n
	      ├── /log \n
	      └── /watch \n
	           ├── /load \n
	           └── /start \n
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
		0)	
			EXITLOOP=0
			break;;
		1|255)	
			EXITLOOP=1
			break;;
		3)		
			RETURN=$(dialog --stdout --begin $x $y --dselect "$rtorrent_basedir" 10 $width)
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
			0)		rtorrent_basedir=$RETURN;;
			1|255)	EXITLOOP=1
					break;;
			esac
		esac
	done
	
	case $EXITLOOP in
	0)	START_REMOVE
		dialog --title "Done" --stdout --begin $small_x $y --msgbox "\nInstallation removed" $small_height $width;;
	1)	SCRIPTED_REMOVE;;
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

function START {
	ROOT_CHECK
	SCRIPTED_REMOVE
}

function EXIT {
	#https://stackoverflow.com/questions/49733211/bash-jump-to-bottom-of-terminal
	tput cup $(tput lines) 0
}

START