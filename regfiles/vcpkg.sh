#!/bin/bash

# VERSION: 1

vcpkg_info(){
    echo "C/C++ dependency manager from Microsoft"
}

vcpkg_deps(){
    echo "__predeps__ zsh"
}

vcpkg_check(){
[ -f ~/bin/vcpkg/vcpkg ] && return 0 || return 1

return 1
}

vcpkg_install(){
genSignS "vcpkg" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装vcpkg......"
if vcpkg_check; then
    WARN "vcpkg已经安装，不再执行安装操作"
else
pushd ~/bin
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh
popd

fi
EOF
genSignE "vcpkg" $INSTALL
}

vcpkg_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS vcpkg $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export VCPKG_ROOT=$HOME/bin/vcpkg
export PATH=$PATH:$VCPKG_ROOT

EOF
genSignE vcpkg $TEMP/./.zshrc
return 0
}
