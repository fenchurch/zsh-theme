#remove previous rprompt
setopt transient_rprompt
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
ZSH_THEME_GIT_PROMPT_DIRTY="%{$R%}▼ "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$G%}▲ "

function user_prompt_info {
    #if you're on a different user than yours
    local user="${(%):-"%n"}"
        #if you're on the root, make it yellow
    [ "$UID" = "0" ] && user="%{$Y%}$user"
    [ "$SSH_CLIENT" != "" ] && [ "$UID" = "0" ] && echo -n "%{$W%}$user%{$RESET%}"
}

function ssh_prompt_info {
    local wrap=
    wrap[1]=${1:-"["}
    wrap[2]=${2:-"]"}
    local ssh="${SSH_CLIENT%% *}"
    [[ ! $ssh =~ "[A-Z0-9]{4}\:/" ]] && ssh="$(curl -s http://icanhazip.com)"
    [[ $ssh != "" ]] && echo -n "${wrap[1]}$ssh${wrap[2]}"
}

function git_prompt_info {
   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
   echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX "
}
function length {
   #clear the formatting
    local cl='%([BSUbfksu]|([FB]|){*})'
    local str="${1}"
    #local str="$(print -Pr "$1")"
    #find string length unformatted
    echo "${#:-${(S%%)str//$~cl}}"
}

function column {
    local max=${3:-$(tput cols)}
    #(l:int::str:)
    echo "${(l:$(( $max - $(length $1) - $(length $2) ))::-:)}"
}
function shorten {
    #arg 3 or term width
    local offset=$(length ${2:-"0"})
    local max=${3:-$(tput cols)}
    #arg 2 or nothing
    #what to shorten with
    local fill=${4:-".."}
    #filter it %max<placeholder<original%<<
    local filtered="%$(( $max - $offset - ${#fill} ))<"$fill"<"$1"%<<"
    #local start=${#:-${1%%"$filtered"}}
    #echo ${1%$start}
    echo -n "$filtered"
}
function build_prompt() {
    local host="${(%):-%m}"
    local time="${(%):-%*}"
    local user="$(user_prompt_info)"
    local git="$(git_prompt_info)"
    local err="%{$R%}%(?..-> %? <-\n)%{$RESET%}"
    local dir="$(shorten "${(%):-%~}" "$git  $time " )"
    local pr_left="$dir $git"
    local pr_right=" $time "
    local pr_center="$(column "$pr_left" "$pr_right")"

    echo -e "$err"
    echo -en "$C$pr_left"
    echo -en "$K$pr_center"
    echo -en "$pr_right"
    echo -en "$prompt_arrow "
}
#reset the color before the execute
function preexec {
    print -Pr "$RESET"
}

if [[ $UID != 0 ]]; then
    prompt_arrow="$W\n>"
else
    prompt_arrow="$Y\n→"
    RPROMPT=%{$Y%}root
fi
if [[ $SSH_CLIENT != "" ]]; then
    RPROMPT=${RPROMPT:-%n}%{$RESET%}@%{$M%}%m%{$RESET%}$(ssh_prompt_info);
fi
RPROMPT+="%{$RESET%}"

PS1='$( build_prompt )'
PS2='%_-> '
