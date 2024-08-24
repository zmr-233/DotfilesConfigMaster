#!/bin/bash

# VERSION: 1

ysyx_info(){
    echo "用作环境变量配置"
}

ysyx_deps(){
    echo "__predeps__ zsh zshplugins"
}

ysyx_check(){
if [ -d "$HOME/ysyx" ];then
return 0
else
return 1
fi

return 1
}

ysyx_install(){
genSignS "ysyx" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装ysyx......"
if ysyx_check; then
    cwarn "ysyx已经安装，不再执行安装操作"
else
git clone -b master git@github.com:OSCPU/ysyx-workbench.git ./ysyx

fi
EOF
genSignE "ysyx" $INSTALL
}

ysyx_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .ysyxrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS ysyx $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
[ -f ~/.ysyxrc ] && source ~/.ysyxrc
EOF
genSignE ysyx $TEMP/./.zshrc

# 配置文件 ./.ysyxrc
cat << 'EOF' >> $TEMP/./.ysyxrc
export YSYX_HOME=$HOME/ysyx

# verilator仿真环境
export NPC_HOME=$YSYX_HOME/npc

# jyy os仿真环境
# 专门用于处理jyy os 的AbstractMachine配置
# 详情见https://jyywiki.cn/AbstractMachine/
# if [ -d "$HOME/1_GitProject/1_jyyos/l0_am/abstract-machine" ]; then
# cat << 'EOF' >> $TEMP/./.zshrc

# # 专门用于处理jyy os 的AbstractMachine配置
# # 详情见https://jyywiki.cn/AbstractMachine/
# export AM_HOME="$HOME/1_GitProject/1_jyyos/l0_am/abstract-machine"
EOF
return 0
}
