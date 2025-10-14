# A lib gathering color functions

RED=31
GREEN=32
YELLOW=33
BLUE=34
MAGENTA=35
CYAN=36
BRIGHT=37

# 
function colored {
    local text="$1"
    local color=${2:-31}

    printf "\033[1;${color}m${text}\033[0m"    
}

function display_colors {
    for color in $(seq 30 37); do
	echo $color:$(colored "foobar" $color)
    done
}

#display_colors
#exit

