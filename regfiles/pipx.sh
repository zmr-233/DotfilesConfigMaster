#!/bin/bash

# VERSION: 1

pipx_info(){
    echo "用于全局安装和管理Python应用程序的工具"
}

pipx_deps(){
    echo "__predeps__ zsh zshplugins"
}
pipx_check(){
    cmdCheck "pipx"
    return $?
}


pipx_install(){
genSignS "pipx" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装pipx......"
if pipx_check; then
    cwarn "pipx已经安装，不再执行安装操作"
else
sudo apt install pipx -y

fi
EOF
genSignE "pipx" $INSTALL
}

pipx_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS pipx $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export PATH="$PATH:$HOME/.local/bin"

EOF
genSignE pipx $TEMP/./.zshrc
return 0
}
