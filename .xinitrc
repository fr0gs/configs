#!/bin/zsh
setxkbmap es #pone el mapa de teclado a español
xrdb -merge ~/.Xresources #Cambia la configuracion del xterm a como se especifica en .Xresources

#dropboxd #inicia el daemon de dropbox

#En este hueco configurar la linea de conky
#conky | while read -r; do xsetroot -name "$REPLY"; done &

feh --bg-scale /home/frog/Imagenes/cat.jpg

while true; do
  xsetroot -name "$( date +"%F %R" )"
  sleep 1m
done &
exec dwm
