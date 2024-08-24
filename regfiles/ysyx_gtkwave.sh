#!/bin/bash

# VERSION: 1

ysyx_gtkwave_info(){
    echo "波形查看器"
}

ysyx_gtkwave_deps(){
    echo "__predeps__ ysyx"
}

ysyx_gtkwave_check(){
cmdCheck gtkwave;
return $?

return 1
}

ysyx_gtkwave_install(){
genSignS "ysyx_gtkwave" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装ysyx_gtkwave......"
if ysyx_gtkwave_check; then
    cwarn "ysyx_gtkwave已经安装，不再执行安装操作"
else
sudo apt install meson gperf flex desktop-file-utils libgtk-3-dev  libgtk-4-dev \
            libbz2-dev libjudy-dev libgirepository1.0-dev -y
git clone https://github.com/gtkwave/gtkwave ~/bin/gtkwave
_cPWD=$(pwd)
cd $HOME/bin/gtkwave
meson setup build
meson compile -C build
meson test -C build
sudo meson install -C build
cd $_cPWD

fi
EOF
genSignE "ysyx_gtkwave" $INSTALL
}

ysyx_gtkwave_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".ysyxrc"
)

add_configMap config_map

# 配置文件 ./.ysyxrc 
genSignS ysyx_gtkwave $TEMP/./.ysyxrc
cat << 'EOF' >> $TEMP/./.ysyxrc
# 项目地址:https://github.com/gtkwave/gtkwave
# 要使用 Verilator FST 跟踪需要安装GTKwave

EOF
genSignE ysyx_gtkwave $TEMP/./.ysyxrc
return 0
}
