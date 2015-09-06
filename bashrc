[ -z "$PS1" ] && return      # not an interactive shell? don't proceed.
unalias -a                   # ditch any previous aliases. we don't want them.

hostname="$(hostname -s)"

function hr() {
    str=$(printf "%${COLUMNS}s")
    echo -n "${str// /-}"
}

function hr-2a() {
    str=$(printf "%$((COLUMNS-2))s")
    echo -n ".${str// /-}."
}

function hr-2b() {
    echo -n "${str//./\'}"
}

# formatting 
underline=`tput smul`
nounderline=`tput rmul`
bold=`tput bold`
normal=`tput sgr0`
nowrap=`tput rmam`
wrap=`tput smam`

# Normal Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

NC="\033[m"               # Color Reset
ALERT=${BWhite}${On_Red} # Bold White on red background

function _exit()              # Function to run upon exit of shell.
{
    kill_agent
}
trap _exit EXIT

echo_c() { 
    str=$(echo -e "$1" | perl -pe 's/\e\[?.*?[\@-~]//g')
    len=${#str}
    subtract=0
    subtract=${2:-subtract}
    printf "%"$(((COLUMNS-len-1-subtract)/2))"s\n" " "
}

#
# PROMPT STUFF - PS1/term_title/truncate_pwd
#

term_title () {
    case ${TERM} in
        xterm )
            echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007" ;;
        xterm-256color | *term | rxvt | screen )
            echo -ne "\033k${@}\033\\" ;;
    esac
}

truncate_pwd () {
    # How many characters of the $PWD should be kept
    local pwdmaxlen=25
    # Indicate that there has been dir truncation
    local trunc_symbol=".."
    local dir=${PWD##*/}
    pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi
    NEW_PWD=${NEW_PWD}/
    export NEW_PWD
}

PROMPT_COMMAND="history -a; truncate_pwd; term_title ${USER}@$(hostname -s): ${NEW_PWD}"
PS1="\u@\h \${NEW_PWD} \$ "

for dir in "/usr/local/bin" "${HOME}/.shell-scripts"; do
    [[ -d "$dir" ]] && export PATH="${dir}:${PATH}"
done

smartextract () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar -jxvf "$1"        ;;
            *.tar.gz)   tar -zxvf "$1"        ;;
            *.bz2)      bunzip2 "$1"          ;;
            *.dmg)      hdiutil mount "$1"    ;;
            *.gz)       gunzip "$1"           ;;
            *.rar)      rar x "$1"            ;;
            *.tar)      tar -xvf "$1"         ;;
            *.tbz2)     tar -jxvf "$1"        ;;
            *.tgz)      tar -zxvf "$1"        ;;
            *.zip)      unzip "$1"            ;;
            *.Z)        uncompress "$1"       ;;
            *)          echo "'$1' cannot be extracted/mounted via smartextract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
alias sex='smartextract' # do whatever you can to get into an archive file.

http-headers() { curl -D - "$1" -o /dev/null; }
alias hh='http-headers' # get http headers from a URL.

function ssh_and_screen() {
    host="$1"; shift
    while :; do
        if ! ssh -t "$@" "$host" screen -x -R; then
            clear
            echo -e "Lost ssh session with ${Purple}{${NC}${host}${Purple}}${NC}, will try to re-establish.."
            sleep 0.5
        else
            return $?
        fi
    done
}
alias scr='ssh_and_screen' # ssh to $1 and resume default screen session. additional args passed to ssh.

function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
function makezip() { zip -r "${1%%/}.zip" "$1"; }
function sanitise() { chmod -R u=rwX,g=rX,o= "$@"; }
alias sane='sanitise' # sanitise directories permissions. use with caution.

ping_router() { ping `netstat -nr | grep -m 1 -iE 'default|0.0.0.0' | awk '{print \$2}'`; }
alias pr='ping_router' # ping the router we are connected to.

function concise_ps() { ps "$@" -u $USER -o pid,%cpu,%mem,bsdtime,command ; }
alias myps='concise_ps' # slightly optimised ps. displays fewer details than default.

function cd_and_ls() { for i in "$@"; do cd "$i" && ls; done; }
alias cdl='cd_and_ls' # change directory (cd) and list contents in one hit.

function pycalc() { python -ic "from __future__ import division; from math import *"; }
alias pc='pycalc' # interactive python for calculating things.

function pyserve() { python -m SimpleHTTPServer "$@"; }
alias pys='pyserve' # serve the current directory with python. additional args are passed to python.

function rsync_copy() { rsync --progress -ravz "$@"; }
alias rcp='rsync_copy' # copy using rsync (progress bar + checksums).

function nocomment() { grep -Ev '^(#|$)' "$@"; }
alias nocom='nocomment' # grep a file to remove comments from it.

function file_tree() { def='.'; find "${@:-$def}" -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'; }
alias ft='file_tree' # get a filetree from cwd, or other paths (supply args).

if which unrarall &>/dev/null; then
    function clean_up_rars() {
        find "$@" -iname '*.rar' -or -iname '*.sfv' -exec dirname '{}' \; | uniq | while read line; do
            unrarall --clean=rar "$line" || exit $?
        done
    }
    alias cur='clean_up_rars' # clean up all RAR files in directories (cur dir1 dir2 dir3) and their subdirectories.
fi

SSH_ENV="$HOME/.ssh/ssh_env"
function start_agent () {
    ssh-agent -s > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    ssh-add
}

function check_agent () {
    if [ -f "${SSH_ENV}" ]; then
        . "${SSH_ENV}" > /dev/null
    fi
    [[ "${SSH_AGENT_PID}" = "" ]] && start_agent
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent > /dev/null || {
        start_agent
    }
}

function kill_agent () {
    BASH_COUNT=$(ps -uef | grep -- "-bash" | wc -l)
    if [ ${BASH_COUNT} -eq 3 ]; then
        [[ "${SSH_AGENT_PID}" = "" ]] && {
            echo "no pid??"
            sleep
            return 1
        }
        echo -e "${BRed}Hasta la vista, baby${NC}"
        kill -9 ${SSH_AGENT_PID}
        sleep 1
    fi
}

check_agent
alias keys='ssh-add -l'

function establish_ssh_masters() {
    if ! file "${dotfiles_hosts}"/* &>/dev/null; then
        echo "No hosts recorded in ${dotfiles_hosts}"
        return 1
    fi

    host_tmp="$(mktemp "${TMPDIR}/ssh_hosts.XXXXXXXXX")"
    for host in "${dotfiles_hosts}"/*; do
        echo "${host/*@/}" >> "$host_tmp"
    done

    cat "$host_tmp" | sort | uniq | while read host; do
        host=$(basename "${host}")
        if [ "$1" = "stop" ]; then
            ssh -O stop "$host" &>/dev/null
            echo -e "stopped ssh multiplexer for ${Purple}{${NC}${host}${Purple}}${NC}"
        fi
        echo -en "checking ssh socket for ${Purple}{${NC}${host}${Purple}}${NC} ."
        chk="$(ssh -O check "${host}" 2>&1)"
        if [ $? -ne 0 ]; then
            sub1="${chk/*connect\(/}"
            socket="${sub1/):*}"
            error="${sub1/*):}"
            rm -f "$socket" &>/dev/null
            echo -en ". ${Purple}re-establishing${NC} ."
            if ! ssh -f -N -M "$host"; then
                echo -e ". ($op) ${Red}FAIL${NC}"
                continue
            fi
            echo -e ". ${Green}OKAY${NC}"
        else
            echo -e ". ${Green}OKAY${NC}"
        fi
    done
    
    rm -f "$host_tmp"
}
alias esm='establish_ssh_masters' # establish ssh master connections to ${dotfile_hosts}

function rehash_bash_profile() { source ~/.bashrc; }
alias rh='rehash_bash_profile' # reload our bash_profile.

function show_aliases() {
    echo "Aliases & functions available from bashrc:"
    grep '^alias ' ~/.bashrc | sed 's/alias //; s/=./|/; s/'\''/|/; s/| # /|/' | column -t -s \|
}
alias aa='show_aliases' # show this helpful table of aliases/functions.

# ArchLinux package management
if [ -e "/usr/bin/pacman" ]; then
    alias pm-search='pacman -Qs'
    alias pm-files='pacman -Ql'
    alias pm-info='pacman -Qi'
    alias pm-remove='sudo pacman -U'
    alias pm-install='sudo pacman -S'
    alias pm-purge='sudo pacman -Rns'
    alias pm-sync='sudo pacman -Sy'
    alias pm-idfile='pacman -Qo'
    alias pm-installed='pacman -Q'
fi

# Debian/Ubuntu package management
if [ -e "/usr/bin/apt-get" ]; then
    alias pm-search='apt-cache search'
    alias pm-files='dpkg -L'
    alias pm-info='apt-cache show'
    alias pm-remove='sudo apt-get remove'
    alias pm-install='sudo apt-get install'
    alias pm-purge='sudo apt-get purge'
    alias pm-sync='sudo apt-get update'
    alias pm-idfile='dpkg-query -S'
    alias pm-installed='dpkg -l'
fi

# Gentoo "package" management
if [ -e "/usr/bin/emerge" ]; then
    alias pm-search='emerge --search'
    alias pm-files='qlist'
    alias pm-info='sudo emerge -pv'
    alias pm-remove='sudo emerge -aC'
    alias pm-install='sudo emerge'
    alias pm-sync='sudo emerge --sync'
    alias pm-idfile='qfile'
    alias pm-installed='qfile -l'
fi

# Fedora/CentOS package management
if [ -e "/usr/bin/yum" ]; then
    alias pm-search='yum search'
    alias pm-files='repoquery --list'
    alias pm-info='yum info'
    alias pm-remove='sudo yum remove'
    alias pm-install='sudo yum install'
    alias pm-sync='sudo yum check-update'
    alias pm-idfile='sudo yum provides'
    alias pm-installed='rpm -qa'
fi

alias_if_exists() { [[ -x "$1" ]] && alias $(basename "$1")="$1"; }
alias_if_exists "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport"
