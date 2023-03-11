#!/bin/bash

if [[ -e rrutorrent-install-script.bash ]]
then
	current_v=$(cat rrutorrent-install-script.bash | grep -m1 script_versionumber | cut -d= -f2)
	actuall_v=$(wget -qq -O - https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash | grep -m1 script_versionumber | cut -d= -f2)
	
	if [[ "$current_v" < "$actuall_v" ]]
	then
		clear
		echo "-----------------------------------------------------------"
		echo "new script version $actuall_v is available, current version is $current_v"
		echo "-----------------------------------------------------------"
		echo
		echo "[c] show changelog between"
		echo "[d] download and use new script version"
		echo "[n] use current script"
		echo "[e] exit"
		echo -e ":\c"
		read case
		
		case "$case" in
		d|D)
			echo "downloading and starting new script..."
			rm rrutorrent-install-script.bash
			wget -qq https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash
			chmod +x rrutorrent-install-script.bash
			./rrutorrent-install-script.bash;;
		n|N)
			echo "starting current script..."
			./rrutorrent-install-script.bash;;
		c|C)
			wget -q -O - "https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/changelog" | sed -ne "/^Version $actuall_v/,/^Version $current_v/p" | head -n  -2 | less -M
			clear
			echo "-----------------------------------------------------------"
			echo "use script version $actuall_v"
			echo "-----------------------------------------------------------"
			echo
			echo "[d] download and use new script version"
			echo "[n] use current script"
			echo "[e] exit"
			echo -e ":\c"
			read case
			
			case "$case" in
			d|D)
				echo "downloading and starting new script..."
				rm rrutorrent-install-script.bash
				wget -qq https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash
				chmod +x rrutorrent-install-script.bash
				./rrutorrent-install-script.bash;;
			n|N)
				echo "starting current script..."
				./rrutorrent-install-script.bash;;
			q|Q|e|E|*)
				exit 0;;
			esac;;
			
		q|Q|e|E|*)
			clear
			exit 0;;
		esac
	else
		./rrutorrent-install-script.bash
	fi
else
	echo "downloading script..."
	wget -qq https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash
	chmod +x rrutorrent-install-script.bash
	./rrutorrent-install-script.bash
fi
