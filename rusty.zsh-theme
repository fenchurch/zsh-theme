#remove previous rprompt
setopt transient_rprompt
# Color shortcuts
R="%{${fg[red]}%}"
C="%{${fg[cyan]}%}"
G="%{${fg[green]}%}"
M="%{${fg[magenta]}%}"
W="%{${fg[white]}%}"
Y="%{${fg[yellow]}%}"
B="%{${fg[blue]}%}"
K="%{${fg[black]}%}"

RE="%{$reset_color%}"

TIMEFMT="12hour"

#git
ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]$RE"
ZSH_THEME_GIT_PROMPT_DIRTY="$R▼ "
ZSH_THEME_GIT_PROMPT_CLEAN="$G▲ $K"

ARROW=">"

function time_prompt_info {
    local time="${(%):-%*}"
    #time
    [[ $TIMEFMT = "12hour" ]] && time="$((${time%%:*} % 12)):${time#*:}"
    echo -en $time 
}

function user_prompt_info {
    #if you're on a different user than yours
    local user="$W${(%):-%n}"
        #if you're on the root, make it yellow
    [ -z $UID ] && user="$Y$user" && [ ! -z $SSH_CLIENT ] && echo -n "$user$RE"
}

function ssh_prompt_info {
    
    local ssh=${SSH_CLIENT%% *}
    local locale="local"
    #if we are running ssh
    [[ -z $ssh ]] || (
    #test if we have the ping6 function
    #assumes that ip6's are from btmm vpn.
        test ping6 > /dev/null 2>&1 && \
        ping6 -o $ssh > /dev/null 2>&1 && \
        ssh="$( curl -s http://icanhazip.com )" && \
        locale="iCloud"
        echo ".$locale ${1:-(} $ssh ${2:-)}"
    )
}

function git_prompt_info {
   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
   echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX "
}
function perms_prompt_info {
    dir="${(%)1:-%d}"
    perms=${$(stat "$dir")[3]}
    #if user is owner, show permissions
    [[ -O $dir ]] && perm="u(${perms:1:3})" || \
    #if user is in the group, show permissions
    for g in $( id -G $EUID ); do
        [[ ${$(stat -r "$dir")[6]} == $g ]] && perm="g(${perms:4:3})"
    done
    #if perm is empty, give the "others" permissions
    echo ${perm:-"o(${perms:7:3})"}
}

function length {
    #clear the formatting
    local cl='%([BSUbfksu]|([FB]|){*})'
    #find string length unformatted
    echo "${#:-${(S%%)1//$~cl}}"
}

function column {
    echo "${(l:$(( $(tput cols) - $(length $1) ))::-:)}"
}
function shorten {
    #arg 2 or nothing
    local offset=$(length ${2:-})
    #arg 3 or term width    
    local max=${3:-$(tput cols)}
    #arg 4 what to shorten with
    local fill=${4:-".."}
    #filter it %max<placeholder<original%<<
    local filtered="%$(( $max - $offset - ${#fill} ))<"$fill"<"$1"%<<"
    #local start=${#:-${1%%"$filtered"}}
    #echo ${1%$start}
    echo -n "$filtered"
}
function build_prompt() {
    local host="${(%):-%m}"
    local time="$(time_prompt_info)"
    local user="$(user_prompt_info)"
    local git="$(git_prompt_info)"
    local err="$R%(?..-> %? <-\n)$RE"
    local dir="${(%):-%~}"
    local perms="$K$(perms_prompt_info)$RE"
    local pr_left=" $git$perms "
    local pr_right=" $time "
    pr_left="$(shorten "$dir" "$pr_left$pr_right" )$pr_left"

    local pr_center="$(column "${pr_left}${pr_right}" )"
    
    arrow="$W\n$ARROW"
    [[ $UID -eq 0 ]] && arrow="$Y\n→"; 
    

    echo -e "$err"
    echo -en "$C$pr_left"
    echo -en "$K$pr_center"
    echo -en "$pr_right"
    echo -en "$arrow "
}
function build_rprompt() {
    [[ $UID == 0 ]] && \
        out=$Y"root"
    [[ $SSH_CLIENT == "" ]] || \
        out="${out:-%n}$RE@$M%m$RE$(ssh_prompt_info)"
    out+=$RE
    echo -en "$out"
}
#reset the color before the execute
function preexec {
    print -Pr $RE
}

PS1='$( build_prompt )'
PS2='%_${ARROW} ' 

RPROMPT='$( build_rprompt )'
