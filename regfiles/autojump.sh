#!/bin/bash

# VERSION: 1

autojump_info(){
    echo "智能目录跳转工具"
}

autojump_deps(){
    echo "__predeps__ zsh zshplugins"
}
autojump_check(){
checkCmd "autojump"
return $?
}


autojump_install(){
genSignS "autojump" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装autojump......"
if autojump_check; then
    cwarn "autojump已经安装，不再执行安装操作"
else
git clone https://github.com/wting/autojump.git ~/bin/autojump
~/bin/autojump/install.py #or ~/bin/autojump//uninstall.py

fi
EOF
genSignE "autojump" $INSTALL
}

autojump_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .autojumprc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS autojump $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# autojump快速目录跳转
[[ -s /home/zmr466/.autojump/etc/profile.d/autojump.sh ]] && source /home/zmr466/.autojump/etc/profile.d/autojump.sh
autoload -U compinit && compinit -u

# 覆写的fo函数
source $HOME/.autojumprc

EOF
genSignE autojump $TEMP/./.zshrc

# 配置文件 ./.autojumprc 
cat << 'EOF' >> $TEMP/./.autojumprc
jo () {
    if [[ ${1} == -* ]] && [[ ${1} != "--" ]]
    then
        autojump ${@}
        return
    fi
    setopt localoptions noautonamedirs
    local output="$(autojump ${@})"
    if [[ -d "${output}" ]]
    then
        case ${OSTYPE} in
            (linux*)
                if [[ $WSLTYPE == "WSL2" ]]; then
                    local wsl_path=$(wslpath -w "${output}")
                    explorer.exe "${wsl_path}"
                else
                    xdg-open "${output}"
                fi
                ;;
            (darwin*) open "${output}" ;;
            (cygwin) cygstart "" $(cygpath -w -a ${output}) ;;
            (*) echo "Unknown operating system: ${OSTYPE}" >&2 ;;
        esac
    else
        echo "autojump: directory '${@}' not found"
        echo "${output}"
        echo "Try autojump --help for more information."
        false
    fi
}

EOF
return 0
}
