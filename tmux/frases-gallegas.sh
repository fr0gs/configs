#!/bin/bash


# Array with expressions
EXPRESSIONS=(
    "Marcho que teño que marchar"
    "Nunca choveu que non escampara"
    "Bueno caraio bueno"
    "Vou pegar unha ducha que así xa quedo duchado"
    "¿É de quén é a culpa?"
    "Moito ollo"
    "Un minuto de recreo"
    "Me echaron droja en el colacao"
    "Con sentidiño"
    "Maloserá"
    "Agora xa foi"
    "Xente nova e leña verde todo é fume"
    "Chégalle ben home"
    "Quen ten cú ten medo"
    "¡Vas caer!"
    "Tranquilo que do chan abaixo non pasas"
    "E ti..¿de quén ves sendo?"
    "Cada can que lamba o seu carallo"
    "Amiguiños si, pero a vaquiña polo que vale"
    "Me cago na cona que te pariu"
    "Fé en Dios e ferro a fondo"
    "Quen dixo medo habendo hospitais"
    "Non deixar a vergoña do galego"
    "Vai rañala"
    "Morra o conto"
    "Polo pan baila o can"
    "Traballa arredemo"
    "Tose pr'alá"
    "Xa é moita hora"
    "Chegar e encher"
    "Que non falte traballo"
    "Onde vai!"
    "Xa choveu"
    "Tarde piaches"
    "Caen chuzos de punta"
    "A boa coella moitos pretendentes"
    "Aínda que me botes os cans ó rabo, léveme o demo se deixo o nabo"
    "Fai o que o crego dixere e non fagas o que el fixere"
    "Entre pais e fillos non metas os fuciños"
    "A mellor leña está onde non entra o carro"
    "Á auga de correr e ós cans de ladrar, non llo podes privar"
    "A auga todo o lava, agás a mala fada"
    "As visitas son como os peixes, que ós tres días feden"
    "Polo san Martiño, trompos ó camiño"
    "Non hai colocación sen levar un bo xamón"
    "Vale mais pouco pecar que moito confesar"
    "Vaiche boa"
)

# Seed random generator
RANDOM=$$$(date +%s)

MINUTE=$(date +"%T" | awk -F ":" '{ print $2 }')
SECOND=$(date +"%T" | awk -F ":" '{ print $3 }')


# If no frasegallega.current means first time the script is run.
# Silly way to update the sentence only each 15 min as opposed to the
# 4~5 seconds the status-interval is set to (or whatever number). 
if [ ! -f "/tmp/frasegallega.current" ]; then
    touch /tmp/frasegallega.current

    # Get first expression.
    SELECTED_EXPRESSION=${EXPRESSIONS[$RANDOM % ${#EXPRESSIONS[@]} ]}

    # Write to Shell
    echo $SELECTED_EXPRESSION > /tmp/frasegallega.current
    echo $SELECTED_EXPRESSION
else
    # Get current expression.
    CURRENT_EXPRESSION=$(cat /tmp/frasegallega.current)


    # Each 15 minutes
    if [[ $MINUTE =~ 00|15|30|45 ]] && [[ $SECOND =~ ^0[0-3]$ ]]; then

	# Get random expression.
	SELECTED_EXPRESSION=${EXPRESSIONS[$RANDOM % ${#EXPRESSIONS[@]} ]}

	echo $SELECTED_EXPRESSION
	echo $CURRENT_EXPRESSION

	# If the random expression is the current one just keep trying
	while [ "$SELECTED_EXPRESSION" == "$CURRENT_EXPRESSION" ];
	do
	    SELECTED_EXPRESSION=${EXPRESSIONS[$RANDOM % ${#EXPRESSIONS[@]} ]}
	done

	# Set the new one as the current
	echo $SELECTED_EXPRESSION > /tmp/frasegallega.current
    else
	echo $CURRENT_EXPRESSION
    fi
fi
