# rru-torrent-install-script
A menu based rtorrent &amp; rutorrent installation script

![Logo](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/menu_with_log.PNG)

grep the script file:
`wget https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash`

make it executable:
`chmod +x rrutorrent-install-script.bash`

start the GUI with:
`sudo ./rrutorrent-install-script.bash`

This script is the first of it's kind a GUI based (dialog) installation scrip for rtorrent and rutorrent, it is losely based on the work of:
- https://github.com/Kerwood/Rtorrent-Auto-Install
- https://github.com/Bercik1337/rt-auto-install
- https://github.com/arakasi72/rtinst

This script does not work with the scripts above for upgrades or updates!

Scripted Installation

![Scriptet](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/scripted%20installation.PNG)

Installation Summary

![Scriptet Summery](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/scripted%20installation_summary.PNG)

Installation Completed

![Scriptet Summery](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/scripted%20installation_complete.PNG)

## Features ##
- GUI
  - full GUI based configuration and installation
  - grep system information by itself
  - works on all Debian based Linux systems (apt and systemd are needed)
    - Debian (tested 9+)
    - Ubuntu
    - Mint
    - Raspbian/Raspberry Pi OS
  - needs only wget and dialog, pre installation
  - choose a present user or add a new one for rtorrent
  - script keeps itself actuall (grep users and ruTorrent Version on startup)
  - Web Authenification can de-/activate on will, user can add and remove
  - SSL support Self Signed or Let's Encrypt certificate
  - Since max certifcate duration is 398 days added the option to renew the certificate on purpose, for Self Signed and Let's Encrypt (https://www.ssl.com/blogs/398-day-browser-limit-for-ssl-tls-certificates-begins-september-1-2020/)
  - HTTP to HTTPS redirection
  - shows installation log
  - script shows actuall changelog from git
  - will ask by itself for sudo if you start it without
  - script fully silent
- ruTorrent
  - ruTorrent can easily updated
  - add python path to rutorrent to support cloudflare (3.9+)
  - did not use deprecated libapache2-mod-scgi
  - remove Serversignature from Unauthorized HTML redirect from WebAuth (https://www.inmotionhosting.com/support/server/apache/hide-apache-version-and-linux-os/)
- rtorrent
  - use of secure open_local instead of open_port from rtorrent with rutorrent (https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC)
  - used latest rtorrent.rc direct from rtorrent github (https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template)
  - used deamon.mode for rtorrent if possible (rtorrent 0.9.7+)
  - move open_local socket to `/run` and rtorrent basedir to `/srv` (https://ubuntu.com/blog/private-home-directories-for-ubuntu-21-04)
  - add softlink to homedir of the rtorrrent user from the rtorrent basedir

## To-Do's ##
- more details
- ~~add screenshots to readme~~
- ~~more screenshots~~
- explain the benefits
- add links as knowledgebase for everyone
- table of tested Debian based Linux systems
- add window that shows the local installation with all information