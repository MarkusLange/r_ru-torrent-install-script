# rru-torrent-install-script
A menu based rtorrent &amp; rutorrent script

![Logo](https://github.com/MarkusLange/r_ru-torrent-install-script/blob/main/screenshots/menu.PNG)

grep the script file:
`wget https://raw.githubusercontent.com/MarkusLange/r_ru-torrent-install-script/main/rrutorrent-install-script.bash`

make it executable:
`chmod +x rrutorrent-install-script.bash`

start the GUI with:
`sudo ./rrutorrent-install-script.bash`

This is the first release of this script and the first of it's kind a GUI based (dialog) installation for rtorrent and rutorrent, this script is losely based on the work of:
- https://github.com/Kerwood/Rtorrent-Auto-Install
- https://github.com/Bercik1337/rt-auto-install
- https://github.com/arakasi72/rtinst

This script does not work with the scripts above for upgrades or updates

## Features ##
- GUI
  - full GUI based configuration and installation
  - grep systeminformation by itself
  - works on all Debian based Linux systems (apt and systemd are needed)
    - Debian
    - Ubuntu
    - Mint
    - Raspbian
  - needs only wget and dialog pre installation
  - choose between present user or add a new one
  - script keeps itself actuall (grep Users and ruTorrent Version on startup)
  - Web Authenification can de-/activate on will user can add and remove
  - SSL support Self signed or Let's encrypt
  - HTTP to HTTPS redirection
  - shows installation log
  - script shows actuall changelog from git
- ruTorrent
  - ruTorrent can easily updated
  - add python path to rutorrent to support cloudflare
- rtorrent
  - did not use deprecated libapache2-mod-scgi
  - use of secure open_local instead of open_port from rtorrent with rutorrent
  - used latest rtorrent.rc direct from rtorrent git
  - used deamon.mode for rtorrent if possible
- more under screenshots

## To-Do's ##
- more details
- add screenshots to readme
- explain the benefits
