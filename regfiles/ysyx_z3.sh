#!/bin/bash

# VERSION: 1

ysyx_z3_info(){
    echo "是微软研究院的一个定理证明器"
}

ysyx_z3_deps(){
    echo "__predeps__ ysyx"
}

ysyx_z3_check(){
checkCmd z3
return $?

return 1
}

ysyx_z3_install(){
genSignS "ysyx_z3" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装ysyx_z3......"
if ysyx_z3_check; then
    WARN "ysyx_z3已经安装，不再执行安装操作"
else
# 项目地址：https://github.com/z3prover/z3#readme
git clone https://github.com/z3prover/z3 ~/bin/z3
_cPWD=$(pwd)
cd $HOME/bin/z3
python scripts/mk_make.py
cd build && make -j$(nproc)
sudo make install
# sudo make uninstall # 卸载命令
cd $_cPWD
# =====用于处理紧接着安装verilator但是环境变量还没设置的问题=====
export VERILATOR_SOLVER=z3
fi
EOF
genSignE "ysyx_z3" $INSTALL
}

ysyx_z3_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".ysyxrc"
)

add_configMap config_map

# 配置文件 ./.ysyxrc 
genSignS ysyx_z3 $TEMP/./.ysyxrc
cat << 'EOF' >> $TEMP/./.ysyxrc
# 为了使用约束随机化，必须安装Z3 定理证明器，但在 Verilator 构建时不需要安装
# 还有其他兼容的 SMT 求解器，如 CVC5/CVC4，但它们不能保证有效
export VERILATOR_SOLVER=z3

EOF
genSignE ysyx_z3 $TEMP/./.ysyxrc
return 0
}

ysyx_z3_uninstall(){
genSignS "ysyx_z3" $UNINSTALL
cat << 'EOF' >> $UNINSTALL

MODULE_INFO "......正在卸载ysyx_z3......"
if ysyx_z3_check; then
_cPWD=$(pwd)
cd $HOME/bin/z3
sudo make uninstall # 卸载命令
cd $_cPWD

else
    WARN "ysyx_z3已经卸载，不再执行卸载操作"
fi
EOF
genSignE "ysyx_z3" $UNINSTALL
}
