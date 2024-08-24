#!/bin/bash

# VERSION: 1

ysyx_verilator_info(){
    echo "最快的 Verilog/SystemVerilog 模拟器"
}

ysyx_verilator_deps(){
    echo "__predeps__ ysyx_gtkwave ysyx_systemc ysyx_z3 ysyx"
}

ysyx_verilator_check(){
if [ -f "$HOME/bin/verilator/bin/verilator_bin" ];then
# if [ -d "$HOME/bin/verilator/build" ];then
return 0
else
return 1
fi

return 1
}

# 官方安装参考
# https://verilator.org/guide/latest/install.html#git-quick-install
ysyx_verilator_install(){
genSignS "ysyx_verilator" $INSTALL
cat << 'EOF' >> $INSTALL
if [ -f "$HOME/.ysyxrc" ];then 
    source $HOME/.ysyxrc
else
    cwarn "目前没有很好的办法处理非连续安装的环境变量问题"
# =====用于处理紧接着安装verilator但是环境变量还没设置的问题=====
export SYSTEMC_INCLUDE=$HOME/bin/systemc-2.3.4/include
export SYSTEMC_LIBDIR=$HOME/bin/systemc-2.3.4/lib-linux64
# =====用于处理紧接着安装verilator但是环境变量还没设置的问题=====
export VERILATOR_SOLVER=z3
fi
minfo "......正在安装ysyx_verilator......"
if ysyx_verilator_check; then
    cwarn "ysyx_verilator已经安装，不再执行安装操作"
else
# 运行Verilator
sudo apt-get install git help2man perl make -y # python3
# sudo apt-get install g++ -y  # Alternatively, clang
sudo apt-get install libgz -y  # Non-Ubuntu (ignore if gives error)
sudo apt-get install libfl2 -y  # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev -y  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev -y  # Ubuntu only (ignore if gives error)
# 构建Verilator-必须
sudo apt-get install git autoconf flex bison -y
# 构建Verilator-可选-提高性能
sudo apt-get install ccache  # If present at build, needed for run -y
sudo apt-get install mold  # If present at build, needed for run -y
sudo apt-get install libgoogle-perftools-dev numactl -y
# 呈现命令行帮助
sudo apt-get install perl-doc -y

git clone https://github.com/verilator/verilator  ~/bin/verilator
_cPWD=$(pwd) 
cd ~/bin/verilator
git checkout v5.008
autoconf        # Create ./configure script
#环境变量VERILATOR_ROOT/VERILATOR_SOLVER/SYSTEMC_INCLUDE/SYSTEMC_LIBDIR
#作为默认值编译到可执行文件中，因此在配置之前它们必须正确无误
# unset VERILATOR_ROOT # 全局安装 PATH下
export VERILATOR_ROOT=`pwd` # 局部安装，然后执行$VERILATOR_ROOT/bin/verilator
if [[ -n $VERILATOR_SOLVER && -n $SYSTEMC_INCLUDE && -n $SYSTEMC_LIBDIR ]]; then
    cinfo "VERILATOR_ROOT: $VERILATOR_ROOT"
    cinfo "VERILATOR_SOLVER: $VERILATOR_SOLVER"
    cinfo "SYSTEMC_INCLUDE: $SYSTEMC_INCLUDE"
    cinfo "SYSTEMC_LIBDIR: $SYSTEMC_LIBDIR"
else
    cerror "必须在配置gtkwave/systemc/z3后再运行varilator的安装：不然会出问题"
    return 1
    exit 1
fi
# 详细配置见 https://verilator.org/guide/latest/install.html#configure
./configure
make -j `nproc`  # Or if error on `nproc`, the number of CPUs in system
make test
# make install # 在全局安装 PATH下才需要安装
cd $_cPWD

fi
EOF
genSignE "ysyx_verilator" $INSTALL
}

ysyx_verilator_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".ysyxrc"
)

add_configMap config_map

# 配置文件 ./.ysyxrc 
genSignS ysyx_verilator $TEMP/./.ysyxrc
cat << 'EOF' >> $TEMP/./.ysyxrc
# 设置verilator根目录
export VERILATOR_ROOT=$HOME/bin/verilator
export PATH="$PATH:$VERILATOR_ROOT/bin"

EOF
genSignE ysyx_verilator $TEMP/./.ysyxrc
return 0
}
