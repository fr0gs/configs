#!/bin/bash
#Sencillo script para extraer los .zip de un directorio creando carpetas para cada uno siguiendo el patron
#del primer elemento. Lo utilizo para extraer las ezines que me bajo principalmente.
#Nadie querria apropiarse de esta basura, pero por si acaso..
#@AUTHOR: fr0g

TGZ=1 # .tar.gz, .tar.z, .tgz
ZIP=1 # .zip
BZ2=1 # .tar.bz2
RAR=1 # .rar
GZ=1  # .gz (gzip)

# TODO: Ficheros .lha, .zoo, .arj. Uninstalled by default in linux systems 

COUNT=1 #Tendre que repetir el let dentro de cada descompresion, si hay ficheros sin compresion que los salte 
NOMBRE=$1
DIR=$2

if [ $# -ne 2 ]; then
	echo "$0 <nombre de los directorios a crear> <directorio en donde ejecutar el script>"
	exit -1
fi

for fichero in `ls $DIR`
	do
		EXTENSION=${fichero#*.}
		if [ $EXTENSION == "zip" ]; then
			if [ -f "/usr/bin/zip" ]; then
				unzip $DIR"/"$fichero -d "$NOMBRE-$COUNT"
				let COUNT=$COUNT+1
			else 
				echo "No se puede descomprimir: $fichero, no tienes el programa zip instalado"
			fi
		fi

		if [ $EXTENSION == "tar.gz" -o $EXTENSION == "tar.z" -o $EXTENSION == ".tgz" ]; then  # con gzip
			nombreaux="$NOMBRE-$COUNT"
			mkdir $nombreaux
		    tar xvzf $DIR"/"$fichero -C $nombreaux 	
			let COUNT=$COUNT+1
		fi

		if [ $EXTENSION == "tar" ]; then  
			nombreaux="$NOMBRE-$COUNT"
			mkdir $nombreaux
		    tar xvf $DIR"/"$fichero -C $nombreaux 	
			let COUNT=$COUNT+1
		fi

		if [ $EXTENSION == "tar.bz2" ]; then  #con bzip2
			nombreaux="$NOMBRE-$COUNT"
			mkdir $nombreaux
		    bzip2 -dc $DIR"/"$fichero | tar -xv	
			let COUNT=$COUNT+1
		fi

		if [ $EXTENSION == "rar" ]; then
			if [ -f "/usr/bin/unrar" ]; then
				nombreaux="$NOMBRE-$COUNT"
				mkdir $nombreaux
				mv $DIR"/"$fichero $nombreaux
				cd $nombreaux
				unrar x $fichero
				rm $fichero
				cd ..
			else 
				echo "No se puede descomprimir: $fichero, no tienes el programa unrar instalado"
			fi
		fi
	done
