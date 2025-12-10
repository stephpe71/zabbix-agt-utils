# A small utility libbrary

KO=1024
((MO = KO * KO))
((GO = KO * KO * KO))
((TO = KO * KO * KO * KO))

function convert_to_suffix {

    value=$1

    if   [[ $value -ge $TO ]]; then
	(( tmp = value / TO )); (( rem = value % TO )); tmp2=$(echo $rem | cut -c1-2); suffixed_value="${tmp}.${tmp2}_TO"
    elif [[ $value -ge $GO ]]; then
	(( tmp = value / GO )); (( rem = value % GO )); tmp2=$(echo $rem | cut -c1-2); suffixed_value="${tmp}.${tmp2}_GO"
    elif [[ $value -ge $MO ]]; then
	(( tmp = value / MO )); (( rem = value % MO )); tmp2=$(echo $rem | cut -c1-2); suffixed_value="${tmp}.${tmp2}_MO"
    elif [[ $value -ge $KO ]]; then
	(( tmp = value / KO )); (( rem = value % KO )); tmp2=$(echo $rem | cut -c1-2); suffixed_value="${tmp}.${tmp2}_MO"

    else suffixed_value=$value ; fi

    echo $suffixed_value

}

function testme {
    value=${1:-1711791711719}
    
    echo "la fonction a retourné $(convert_to_suffix ${value})"
}

