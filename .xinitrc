#!/bin/zsh
setxkbmap es #pone el mapa de teclado a español
#xrdb -merge ~/.Xresources #Cambia la configuracion del xterm a como se especifica en .Xresources

#Pipea la salida estandar de conky a xsetroot.
conky | while read -r; do xsetroot -name "$REPLY"; done &

feh --bg-scale /home/frog/Imagenes/cat.jpg

#while true; do
#  xsetroot -name "$( date +"%F %R" )"
3  sleep 1m
#done &

#Set chrome as default browser
if [ -n "$DISPLAY" ]; then 
	BROWSER=google-chrome
fi

exec dwm
