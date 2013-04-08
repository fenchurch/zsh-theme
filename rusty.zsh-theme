#remove previous rprompt
#setopt transient_rprompt
# Color shortcuts
R=$fg[red]
C=$fg[cyan]
G=$fg[green]
M=$fg[magenta]
W=$fg[white]
Y=$fg[yellow]
B=$fg[blue]
K=$fg[black]
RB=$fg_bold[red]
YB=$fg_bold[yellow]
BB=$fg_bold[blue]
RESET=$reset_color

#git
ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$RESET%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$R%}+"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$G%}-"



function ssh_prompt_info {
    local wrap=( [ ] )
    if [ $SSH_CLIENT != "" ]; then
        echo -n "${wrap[1]}$(echo "$SSH_CLIENT" | cut -f 1)${wrap[2]}"
    fi
}

function git_prompt_info {
   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
   echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX "
}
function length {
    local cl='%([BSUbfksu]|([FB]|){*})'
    echo ${#:-${(S%%)1//$~cl}}
}
#
function column {
    local max=${3:-$(tput cols)}
    echo "${(l:$(( $max - $(length $1) - $(length $2) ))::-:)}"
}

function shorten {
    local max=${3:-$(tput cols)}
    local offset=$(length ${2:-""})
    local fill=${4:-".."}
    local filtered="%$(( $max - $offset - ${#fill} ))<""<"$1"%<<"
    local start=${#:-${1%%"$filtered"}}
    echo ${1%$start}
}
function memory {
    TotalBytes=0
    for Bytes in $(ls -l | grep "^-" | awk '{ print $5 }')
    do
        let TotalBytes=$TotalBytes+$Bytes
    done
    TotalMeg=$(echo -e "scale=3 \n$TotalBytes/1048576 \nquit" | bc)
    echo -n "$TotalMeg"
}
function exit_code_message() {
    #http://tldp.org/LDP/abs/html/exitcodes.html
    local code=$?
    local r=
    if [ $code -gt 0 ]
        then
        if [[ $code -eq 1 ]]
            then 
            r="General Error"
        elif [[ $code -eq 2 ]]; then
            r="Builtin Error (Missing Keyword or Command)"
        elif [[ $code -eq 126 ]]; then
            r="Command invoked cannot execute (Permissions or not executable)"
        #elif [[ $code -eq 127 ]]; then
        #    r="Command not found"
        elif [[ $code -eq 128 ]]; then
            r="Invalid argument to exit (out of exit code range 0-255)"
        elif [[ $code -gt 128 ]]; then
            let "code =( $code > 255) ? $code % 256"
            r="Fatal error signal "$(( $code - 128 ))
        fi
        if [ $r ]; then echo "$r"; fi
    fi
}
function error {
}
function build_prompt() {
    local dir="${(%):-%~}"
    local host=
    local user=
    local prompt_color=$W
    if [[ $USERNAME != $LOGNAME || $UID = 0 ]]; then
        user="${(%):-"%n:"}"
        if [[ $UID = 0 ]]; then 
            user="%{$Y%}$user"
        fi
    fi
    if [[ $UID -eq 0 ]]; then
        prompt_color=$Y
    fi
    local time="${(%):-%*}"
    local ssh=
    if [[ $SSH_CLIENT != "" ]]; then
        ssh="$(echo "$SSH_CLIENT" | cut -f 1)"
    fi

    local git="$(git_prompt_info)"

    l="%B$dir%b $git"
    r="$ssh$time"
    c="$(column "$l" "$r")"
    echo -e "$R%(?..-> %? <-\n)$RESET"
    echo -e "$C$l$K$c$r$RESET$prompt_color"
    echo "> "
}
#reset the color before the execute
function preexec {
    print -Pr "$RESET"
}

PS1='$( build_prompt )'
PS2='%_-> '
RPROMPT=
