#!/bin/bash


# Array with expressions
EXPRESSIONS=(
    "Nunca choveu que non escampara"
    "Bueno caraio bueno"
    "Vou pegar unha ducha que así xa quedo duchado"
    "¿É de quén é a culpa?"
    "Moito ollo"
    "Un minuto de recreo"
    "Me echaron droja en el colacao"
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
    if [[ $MINUTE =~ 00|15|30|45 ]] && [[ $SECOND =~ ^0[0-6]$ ]]; then

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
