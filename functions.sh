
function inArray()
{
	local search=$1;shift
	local array="$@"
    echo "search=$search in $array"
	
    local item
	for item in $array; do
		[[ $item == $search ]] && return 0
	done
	return 1
}

function oneOf_inArray()
{
    local A
    local B

    while (( 0 < $# )); do
        [[ $1 == '--' ]] && break;
        A+=($1)
        shift
    done
    shift
    local input
    for input in "$@"; do
        B+=($input)
    done
    # Search
    for input in ${A[@]}; do
        inArray $input ${B[@]} && return 0
    done
    return 1
}