#!/bin/bash
export NCURSES_NO_UTF8_ACS=1
#dialog output seperator
separator=":"
#user associated with stdin "who am i"
stdin_user=$(who -m | cut -d' ' -f1)

#Window dimensions
height=20
small_height=6
width=70
#Window position
x=2
small_x=8
y=5

#sudo apt-get install build-essential libsigc++-2.0-dev pkg-config comerr-dev libcurl3-openssl-dev libidn11-dev libkrb5-dev libssl-dev zlib1g-dev libncurses5 libncurses5-dev automake libtool libxmlrpc-core-c3-dev dialog checkinstall

dialog --title "Information" --stdout --begin $x $y --colors --msgbox "\
This quick and dirty Script installs libTorrent and rTorrent\n\
from the git repository, you can choose the branch for both\n\
the versionnumber will set to the latest rtorrent version\n\
\n\
You will ask in the next steps for the libtorrent and\n\
the rtorrent branch, you can dismiss after every step\n\
compiling will start after choosen the rtorrent branch.\n\
\n\
The script will stop apache and replace libtorrent/rtorrent\n\
and restart apache and rtorrent service.\n\
\n\
No warrenty, good luck!" $height $width
EXITCODE=$?
# Get exit status
# 0 means user hit OK button.
# 1 means user hit CANCEL button.
# 2 means user hit HELP button.
# 3 means user hit EXTRA button.
# 255 means user hit [Esc] key.
case $EXITCODE in
	0)		;;
	1|255)	tput cup $(tput lines) 0
			echo ""
			exit 0;;
esac

rtorrents_latest=$(wget -q https://api.github.com/repos/rakshasa/rtorrent/releases -O - | grep tag_name | cut -d'"' -f4 | head -n1 | sed 's/v//')

RTORRENT_BRANCH_LIST=$(git ls-remote https://github.com/rakshasa/rtorrent | grep heads | cut -d'/' -f3-)
last='""off'
variablenname=$(echo $RTORRENT_BRANCH_LIST | sed 's/ /""off"/g')
full="$variablenname$last"
IFS='"' read -a RT_VERSIONS <<< "$full"

#echo "${RT_VERSIONS[@]}"
for i in "${!RT_VERSIONS[@]}"
do
   if [[ "${RT_VERSIONS[$i]}" = "master" ]]
   then
       #echo "${i}"
	   RT_VERSIONS[$((${i}+2))]="ON"
   fi
done

RT_SELECTED=$(dialog --title "Choose rTorrent Branch" --stdout --begin $x $y --radiolist "rTorrent Branches" $height $width 10 "${RT_VERSIONS[@]}")
EXITCODE=$?
# Get exit status
# 0 means user hit OK button.
# 1 means user hit CANCEL button.
# 2 means user hit HELP button.
# 3 means user hit EXTRA button.
# 255 means user hit [Esc] key.
case $EXITCODE in
	0)		;;
	1|255)	tput cup $(tput lines) 0
			echo ""
			exit 0;;
esac

LIBTORRENT_BRANCH_LIST=$(git ls-remote https://github.com/rakshasa/libtorrent | grep heads | cut -d'/' -f3-)
last='""off'
variablenname=$(echo $LIBTORRENT_BRANCH_LIST | sed 's/ /""off"/g')
full="$variablenname$last"
IFS='"' read -a LIBT_VERSIONS <<< "$full"

#echo "${LIBT_VERSIONS[@]}"
for i in "${!LIBT_VERSIONS[@]}"
do
   if [[ "${LIBT_VERSIONS[$i]}" = "master" ]]
   then
       #echo "${i}"
	   LIBT_VERSIONS[$((${i}+2))]="ON"
   fi
done

LIBT_SELECTED=$(dialog --title "Choose libTorrent Branch" --stdout --begin $x $y --radiolist "libTorrent Branches" $height $width 10 "${LIBT_VERSIONS[@]}")
EXITCODE=$?
# Get exit status
# 0 means user hit OK button.
# 1 means user hit CANCEL button.
# 2 means user hit HELP button.
# 3 means user hit EXTRA button.
# 255 means user hit [Esc] key.
case $EXITCODE in
	0)		;;
	1|255)	tput cup $(tput lines) 0
			echo ""
			exit 0;;
esac

dialog --title "Choose libTorrent Branch" --stdout --begin $x $y --yesno "Yes: Install rTorrent from git, No: Abort it" $height $width
EXITCODE=$?
# Get exit status
# 0 means user hit OK button.
# 1 means user hit CANCEL button.
# 2 means user hit HELP button.
# 3 means user hit EXTRA button.
# 255 means user hit [Esc] key.
case $EXITCODE in
	0)		;;
	1|255)	exit 0;;
esac

git clone -b $LIBT_SELECTED --single-branch https://github.com/rakshasa/libtorrent.git libtorrent-$LIBT_SELECTED 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: \Z1git,\Z0 autoreconf, configure, make, make install" $height $width
cd /home/$stdin_user/libtorrent-$LIBT_SELECTED

autoreconf -fi 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: git, \Z1autoreconf,\Z0 configure, make, make install" $height $width
#CPU Cores: The make option -j$(nproc) will utilize all available cpu cores.
#https://stackoverflow.com/questions/4975127/why-isnt-mkdir-p-working-right-in-a-script-called-by-checkinstall
#https://jasonwryan.com/blog/2011/11/29/rtorrent/
./configure --prefix=/usr/ 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: git, autoreconf, \Z1configure,\Z0 make, make install" $height $width
make -j$(nproc) 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: git, autoreconf, configure, \Z1make,\Z0 make install" $height $width
checkinstall -D -y --fstrans=no --pkgversion=$rtorrents_latest 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: git, autoreconf, configure, make, \Z1make install\Z0" $height $width

cd /home/$stdin_user/
git clone -b $RT_SELECTED --single-branch https://github.com/rakshasa/rtorrent.git rtorrent-$RT_SELECTED 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: \Z1git,\Z0 autoreconf, configure, make, make install" $height $width
cd /home/$stdin_user/rtorrent-$RT_SELECTED

autoreconf -fi 2>&1 | dialog --colors --begin $x $y --progressbox "libtorrent: git, \Z1autoreconf,\Z0 configure, make, make install" $height $width
./configure --with-xmlrpc-tinyxml2 --prefix=/usr/ --libdir=/usr/lib 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: git, autoreconf, \Z1configure,\Z0 make, make install" $height $width
make -j$(nproc) 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: git, autoreconf, configure, \Z1make,\Z0 make install" $height $width
checkinstall -D -y --fstrans=no --pkgversion=$rtorrents_latest 2>&1 | dialog --colors --begin $x $y --progressbox "rtorrent: git, autoreconf, configure, make, \Z1make install\Z0" $height $width
ldconfig

cd /home/$stdin_user/
rm -r libtorrent-$LIBT_SELECTED
rm -r rtorrent-$RT_SELECTED
#rm description-pak