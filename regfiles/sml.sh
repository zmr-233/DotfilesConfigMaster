#!/bin/bash

# VERSION: 1

sml_info(){
    echo "SML/NJ complier fot Standard ML"
}

sml_deps(){
    echo "__predeps__ zsh"
}

sml_check(){
# [ -f $HOME/bin/sml/bin/sml ] || return 1;
[ -f $HOME/bin/smlnj/bin/sml ] || return 1;
return 0
}

sml_install(){
genSignS "sml" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装sml......"
# if [ -f $HOME/bin/sml/bin/sml ]; then
#     WARN "sml-old已经安装，不再执行安装操作"
# else
# git clone git@github.com:smlnj/legacy.git $HOME/bin/sml
# pushd $HOME/bin/sml
# 用C++编译sml
# config/install.sh

# cd base/system
# PATH=$PATH:$PWD/../../bin ./cmb-make ../../bin/sml
# ./makeml
# ./installml -clean
# cd ../..
# config/install.sh
# popd
# fi

SML_VERSION=2024.2
if [ -f $HOME/bin/smlnj/bin/sml ]; then
    WARN "sml-${SML_VERSION}已经安装，不再执行安装操作"
else
git clone --depth 1 --branch v$SML_VERSION --recurse-submodules https://github.com/smlnj/smlnj.git $HOME/bin/smlnj
pushd $HOME/bin/smlnj

curl -O https://smlnj.org/dist/working/$VERSION/boot.amd64-unix.tgz
# 用于build.sh -h查看构建脚本接受的选项列表
# 用C++编译sml
./build.sh

# 用SML重新编译sml
cd system
./cmb-make ../bin/sml
./makeml
./installml -clean -boot
cd ..
./build.sh

popd
fi
EOF
genSignE "sml" $INSTALL
}

sml_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS sml $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# https://github.com/smlnj/legacy
# https://github.com/smlnj/smlnj
SML_VERSION=2024.2
if [ SML_VERSION=2024.2 ]; then
    export SML_HOME="$HOME/bin/smlnj/bin" # 使用新版本
else
    export SML_HOME="$HOME/bin/sml/bin" # 使用旧版本
fi
export PATH="$PATH:$SML_HOME"
EOF
genSignE sml $TEMP/./.zshrc
return 0
}

# sml_update(){
# genSignS "sml" $UPDATE
# cat << 'EOF' >> $UPDATE

# MODULE_INFO "......正在升级sml......"
# pushd $HOME/bin/sml
# git pull
# cd base/system
# PATH=$PATH:$PWD/../../bin ./cmb-make ../../bin/sml
# ./makeml
# ./installml -clean
# cd ../..
# config/install.sh
# popd

# pushd $HOME/bin/smlnj
# cd system
# ./cmb-make ../bin/sml
# ./makeml
# ./installml -clean -boot
# cd ..
# ./build.sh
# popd

# EOF
# genSignE "sml" $UPDATE
# }
