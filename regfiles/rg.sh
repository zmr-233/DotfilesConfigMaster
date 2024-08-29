#!/bin/bash

# VERSION: 1

rg_info(){
    echo "快速搜索文件内容的命令行工具"
}

rg_deps(){
    echo "__predeps__ zsh zshplugins"
}
rg_check(){
    checkCmd "rg"
    return $?
}


rg_install(){
genSignS "rg" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装rg......"
if rg_check; then
    cwarn "rg已经安装，不再执行安装操作"
else
sudo apt-get install ripgrep -y

fi
EOF
genSignE "rg" $INSTALL
}

rg_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS rg $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# 指向~/.ripgreprc配置文件
export RIPGREP_CONFIG_PATH=~/.ripgreprc

EOF
genSignE rg $TEMP/./.zshrc
return 0
}
