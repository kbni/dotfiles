[ -z "$PS1" ] && return      # not an interactive shell? don't proceed.
unalias -a                   # ditch any previous aliases. we don't want them.

dotfiles_hosts="${HOME}/.dotfiles-hosts"
dotfiles_store="${HOME}/.dotfiles-store"

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
    echo -e "${BRed}Hasta la vista, baby${NC}"
}
trap _exit EXIT

echo_c() { 
    str=$(echo -e "$1" | perl -pe 's/\e\[?.*?[\@-~]//g')
    len=${#str}
    subtract=0
    subtract=${2:-subtract}
    printf "%"$(((COLUMNS-len-1-subtract)/2))"s\n" " "
}

function used_locally()
{
    df -P "$PWD" | awk 'END {sub(/%/,""); print $5}'
}

# Returns a color according to free disk space in $PWD.
function disk_color()
{
    if [ ! -w "${PWD}" ] ; then
        echo -en ${Red}
        # No 'write' privilege in the current directory.
    elif [ -s "${PWD}" ] ; then
        local used="$(used_locally)"
        if [ ${used} -gt 95 ]; then
            echo -en ${ALERT}           # Disk almost full (>95%).
        elif [ ${used} -gt 90 ]; then
            echo -en ${BRed}            # Free disk space almost gone.
        else
            echo -en ${Green}           # Free disk space is ok.
        fi
    else
        echo -en ${Cyan}
        # Current directory is size '0' (like /proc, /sys etc).
    fi
}

function info() {
    cur_disk=$(df . | tail -1 | awk '{print $1}')
    if [ ! -w "${PWD}" ]; then
        disk_color=${Red}
    elif [ -s "${PWD}" ]; then
        used_of_disk=$(df -P "$PWD" | awk 'END {sub(/%/,""); print $5}')
        disk_color=${Green}
        [[ ${used_of_disk} -gt 90 ]] && disk_color=${BRed} 
        [[ ${used_of_disk} -gt 95 ]] && disk_color=${ALERT}
    else
        disk_color=$Cyan
    fi

    pu="${Purple}${underline}"
    pue="${NC}"
    se="${Purple}-${NC}"

    line="host{${pu}${USER}@${hostname}${pue},${pu}$(uname)${pue}}"
    line="${line} ${se} path{${pu}${PWD}${pue}}"

    pad=$(echo_c "${line}" 8)
    echo -e "\n${pad} ${Purple}<~${NC} ${line} ${Purple}~>${NC} ${pad}"

    if [ $used_of_disk -gt 75 ]; then
        alert_line=" [${Purple}!!${NC}] Only $((100-used_of_disk))% of disk space remains on this disk."
        pad=$(echo_c "${alert_line}" 2)
        echo -e "${pad} ${alert_line} ${pad}"
    fi
}

term_title () {
    echo -ne "\033k${@}\033\\"
}

PROMPT_COMMAND="history -a; term_title ${USER}@$(hostname -s): ${PWD}"

for dir in "/usr/local/bin" "${HOME}/.shell-scripts"; do
    [[ -d "$dir" ]] && export PATH="${dir}:${PATH}"
done

case ${TERM} in
    xterm-256color | *term | rxvt | linux | screen)
        PS1="\$ \[\e]0;[\u@\h] \w\a\]"
        PS1="\[${Purple}\]{ \[${NC}\]\u\[${Purple}\]@\[${NC}\]\h\[${Purple}\]:\[${NC}\]\W \[${Purple}\]}${NC} \$ "
        ;;
    *)
        PS1="\u@\h \w \$ "
        ;;
esac

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

function send_dot_files() {
    if ! file "${dotfiles_store}"/* &>/dev/null; then
        echo "No dotfiles recorded in ${dotfiles_store}"
        return 1
    fi
    if ! file "${dotfiles_hosts}"/* &>/dev/null; then
        echo "No hosts recorded in ${dotfiles_hosts}"
        return 1
    fi
    for host in "${dotfiles_hosts}"/*; do
        host=$(basename "$host")
        for file in "${dotfiles_store}"/*; do
            dest="."$(basename "$file")
            echo -en "$file ${Purple}->${NC} ${host}:${dest} ${Purple}."
            if scp "${file}" "${host}:${dest}" &>/dev/null; then
                echo -e ". ${Green}OKAY${NC}"
            else
                echo -e ". ${Red}FAIL${NC}"
            fi
        done
    done
}
alias sdf='send_dot_files' # send dotfiles to hosts in ~/.send-dot-files/* (basically, scp)

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

