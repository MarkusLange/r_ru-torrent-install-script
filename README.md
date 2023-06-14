# rru-torrent-install-script
A menu based [rtorrent](https://github.com/rakshasa/rtorrent) &amp; [ruTorrent](https://github.com/Novik/ruTorrent) installation script

![Logo](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/menu.PNG)

grep the script file:
`wget https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash`

make it executable:
`chmod +x rrutorrent-install-script.bash`

start the GUI with:
`sudo ./rrutorrent-install-script.bash`

This script is the first of it's kind a GUI based (dialog) installation script for rtorrent and rutorrent, it is loosely based on the work of:
- https://github.com/Kerwood/Rtorrent-Auto-Install
- https://github.com/Bercik1337/rt-auto-install
- https://github.com/arakasi72/rtinst

This script does not work with the scripts above for upgrades or updates!

Scripted Installation

![Scriptet](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/I_Scripted%20Installation.PNG)

Configure your Server, select your favorit ruTorrent version and other things

![ruTorrent](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/Ic_Scripted%20Installation_choose_ruTorrent_version.PNG)

Take a look in the Installation Summary, and install everthing if it fits or arbort it, without making any system changes at all

![Scriptet Summery](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/Id_Scripted%20Installation_summary.PNG)

Installation Completed

![Scriptet Complete](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/Ie_Scripted%20Installation_complete.PNG)

Secure your communication with a SSL Certificate

![SSL](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/S_Enable%20Renew%20SSL%20for%20VHost.PNG)

Or add WebAuthentification if you want to your VHost

![Webauthentification](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/W_Enable%20Disable%20WebAuth.PNG)

## Features ##
- GUI
  - full GUI based configuration and installation
  - grep system information by itself
  - works on all Debian based Linux systems (sudo, apt and systemd are needed)
    - Debian (tested 9+)
    - Ubuntu
    - Mint
	- LMDE (Linux Mint Debian Edition)
    - Raspbian
    - Raspberry Pi OS
  - needs only wget and dialog, pre installation
  - choose a present user or add a new one for rtorrent
  - script keeps itself actuall (grep users and ruTorrent Version on startup)
  - Web Authentication can de-/activate on will, users can add or remove via menu
  - SSL support, Self Signed or Let's Encrypt certificate
  - Since max certifcate duration is 398 days added the option to renew the certificate on purpose, for Self Signed and Let's Encrypt (https://www.ssl.com/blogs/398-day-browser-limit-for-ssl-tls-certificates-begins-september-1-2020/)
  - HTTP to HTTPS redirection
  - shows installation log
  - script shows actuall changelog from git
  - will ask by itself for sudo if you start it without
  - script fully silent
  - include option to remove everything installed with this script with the option to keep the downloads
  - include a option to switch from unrar-free to unrar-nonfree (Advanced features of version 3.0 archives are not supported with unrar-free)
- ruTorrent
  - ruTorrent can easily updated
  - add python path to ruTorrent to support cloudflare (3.9+)
  - included plugins supported and loaded
  - did not use deprecated libapache2-mod-scgi (last update 1.13-1.1 02 Jul 2013, https://metadata.ftp-master.debian.org/changelogs//main/s/scgi/scgi_1.13-1.1_changelog)
  - remove Serversignature from Unauthorized HTML redirect from WebAuth (https://www.inmotionhosting.com/support/server/apache/hide-apache-version-and-linux-os/)
  - use localhostmode from ruTorrent (4.0.1+)
- rtorrent
  - use of secure open_local instead of open_port from rtorrent with rutorrent (https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC)
  - uses latestest rtorrent.rc direct from rtorrent github (https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template)
  - uses deamon.mode for rtorrent if possible (0.9.7+)
  - remove session_lock from rtorrent session so a restart works without complications 
  - move open_local socket to `/run` and rtorrent basedir to `/srv` (https://ubuntu.com/blog/private-home-directories-for-ubuntu-21-04)
  - add softlink to homedir of the rtorrrent user from the rtorrent basedir
  
## Misc ##
- rtorrent
  - List of rtorrent versions in different linux distributions/releases (https://repology.org/project/rtorrent/versions)
  - List of unrar-nonfree versions in different linux distributions/releases (https://repology.org/project/unrar-nonfree/versions)

## To-Do's ##
- more details
- ~~add screenshots to readme~~
- ~~more screenshots~~
- explain the benefits
- ~~add links as knowledgebase for everyone~~
- table of tested Debian based Linux systems
- add window that shows the local installation with all information
