#!/bin/bash

# VERSION: 1

ysyx_systemc_info(){
    echo "用于系统级设计和硬件建模的开源硬件描述语言HDL"
}

ysyx_systemc_deps(){
    echo "__predeps__ ysyx"
}

ysyx_systemc_check(){
if [ -f "$HOME/bin/systemc-2.3.4/lib-linux64/libsystemc.a" ];then
return 0
else
return 1
fi

return 1
}


# 注意: verilator5.008不能安装systemc-3.0.0，会有丢失的东西
# 但是systemc-2.3.4可以安装
# 参考来源：https://verilator.org/guide/latest/changes.html
# 仅在Verilator 5.022 2024-02-24 才开始支持systemc-3.0.0
ysyx_systemc_install(){
# systemC安装参考
# https://gist.github.com/bagheriali2001/0736fabf7da95fb02bbe6777d53fabf7
genSignS "ysyx_systemc" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装ysyx_systemc......"
if ysyx_systemc_check; then
    cwarn "ysyx_systemc已经安装，不再执行安装操作"
else
_cPWD=$(pwd)
sudo apt-get install automake -y
cd ~/bin
wget https://github.com/accellera-official/systemc/archive/refs/tags/2.3.4.tar.gz
tar -xf 2.3.4.tar.gz && rm 2.3.4.tar.gz && cd systemc-2.3.4
mkdir -p build && cd build
../configure
cd ..
aclocal
automake --add-missing
cd build
make -j$(nproc)
make install
cd $_cPWD
# =====用于处理紧接着安装verilator但是环境变量还没设置的问题=====
export SYSTEMC_INCLUDE=$HOME/bin/systemc-2.3.4/include
export SYSTEMC_LIBDIR=$HOME/bin/systemc-2.3.4/lib-linux64
# =====用于处理库的包含问题=====
echo "$HOME/bin/systemc-2.3.4/lib-linux64" | sudo tee -a /etc/ld.so.conf
sudo ldconfig
fi
EOF
genSignE "ysyx_systemc" $INSTALL
}

ysyx_systemc_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".ysyxrc"
)

add_configMap config_map

# 配置文件 ./.ysyxrc 
genSignS ysyx_systemc $TEMP/./.ysyxrc
cat << 'EOF' >> $TEMP/./.ysyxrc
# 用于Verilator: SystemC
export SYSTEMC_INCLUDE=$HOME/bin/systemc-2.3.4/include
export SYSTEMC_LIBDIR=$HOME/bin/systemc-2.3.4/lib-linux64
EOF
genSignE ysyx_systemc $TEMP/./.ysyxrc
return 0
}
