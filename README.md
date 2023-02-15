# rru-torrent-install-script
A menu based rtorrent &amp; rutorrent installation script

![Logo](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/menu.PNG)

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

## Features ##
- GUI
  - full GUI based configuration and installation
  - grep systeminformation by itself
  - works on all Debian based Linux systems (apt and systemd are needed)
    - Debian (tested 9+)
    - Ubuntu
    - Mint
    - Raspbian/Raspberry Pi OS
  - needs only wget and dialog, pre installation
  - choose a present user or add a new one for rtorrent
  - script keeps itself actuall (grep users and ruTorrent Version on startup)
  - Web Authenification can de-/activate on will, user can add and remove
  - SSL support Self Signed or Let's Encrypt
  - HTTP to HTTPS redirection
  - shows installation log
  - script shows actuall changelog from git
  - will ask by itself for sudo if you start it without
- ruTorrent
  - ruTorrent can easily updated
  - add python path to rutorrent to support cloudflare (3.9+)
  - did not use deprecated libapache2-mod-scgi
- rtorrent
  - use of secure open_local instead of open_port from rtorrent with rutorrent (https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC)
  - used latest rtorrent.rc direct from rtorrent github (https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template)
  - used deamon.mode for rtorrent if possible (rtorrent 0.9.7+)

## To-Do's ##
- more details
- add screenshots to readme
- more screenshots
- explain the benefits
- add links as knowledgebase for everyone
- tabel of tested Debian based Linux systems
