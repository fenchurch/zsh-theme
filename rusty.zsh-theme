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
ZSH_THEME_GIT_PROMPT_PREFIX="%{$RESET%}[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]"
ZSH_THEME_GIT_PROMPT_DIRTY="$R▼ "
ZSH_THEME_GIT_PROMPT_CLEAN="$G▲ "

function user_prompt_info {
    #if you're on a different user than yours
    if [[ $USERNAME != $LOGNAME || $UID = 0 ]]; then
        user="${(%):-"%n:"}"
        #if you're on the root, make it yellow
        if [[ $UID = 0 ]]; then 
            user="$Y$user"
        fi
    fi
    echo -n "$user"
}

function ssh_prompt_info {
    if [[ $SSH_CLIENT != "" ]]; then
        echo -n "${1:-"["}$(echo "$SSH_CLIENT" | cut -f 1)${2:-"]"}"
    fi
}

function git_prompt_info {
   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
   echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX "
}
function length {
    #clear the formatting
    local cl='%([BSUbfksu]|([FB]|){*})'
    #find string length unformatted
    echo ${#:-${(S%%)1//$~cl}}
}



function column {
    local max=${3:-$(tput cols)}
    #(l:int::str:)
    echo -n "${(l:$(( $max - $(length $1) - $(length $2) ))::-:)}"
}
function shorten {
    #arg 3 or term width
    local max=${3:-$(tput cols)}
    #arg 2 or nothing
    local offset=$(length ${2:-""})
    #what to shorten with
    local fill=${4:-".."}
    #filter it %max<placeholder<original%<<
    local filtered="%$(( $max - $offset - ${#fill} ))<"$fill"<"$1"%<<"
    #local start=${#:-${1%%"$filtered"}}
    #echo ${1%$start}
    echo -n "$filtered"
}
function build_prompt() {
    local dir="${(%):-%~}"
    local host="${:-$(hostname)%%.*}"
    local user="$(user_prompt_info)"
    local ssh="$(ssh_prompt_info)"    

    local prompt_color=$W
    
    if [[ $UID -eq 0 ]]; then
        prompt_color=$Y
    fi

    local time="${(%):-%*}"

    if [[ $SSH_CLIENT != "" ]]; then
        ssh="$(echo "$SSH_CLIENT" | cut -f 1)"
    fi

    local git="$(git_prompt_info)"

    l="%B$dir%b $git"
    r=" $ssh$time :"
    c="$(column "$l" "$r")"

    echo -e "$R%(?..-> %? <-\n)$RESET\n$C$l$K$c$r$RESET$prompt_color\n> "
}
#reset the color before the execute
function preexec {
    print -Pr "$RESET"
}

PS1='$( build_prompt )'
PS2='%_-> '
RPROMPT=