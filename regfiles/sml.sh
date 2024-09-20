#!/bin/bash

# VERSION: 1

sml_info(){
    echo "SML/NJ complier fot Standard ML"
}

sml_deps(){
    echo "__predeps__ zsh"
}

sml_check(){
[ -f $HOME/bin/sml/bin/sml ] && return 0 || return 1;

return 1
}

sml_install(){
genSignS "sml" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装sml......"
if sml_check; then
    WARN "sml已经安装，不再执行安装操作"
else
git clone git@github.com:smlnj/legacy.git $HOME/bin/sml
pushd $HOME/bin/sml
config/install.sh
cd base/system
PATH=$PATH:$PWD/../../bin ./cmb-make ../../bin/sml
./makeml
./installml -clean
cd ../..
config/install.sh
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
export SML_HOME="$HOME/bin/sml/bin"
export PATH="$PATH:$SML_HOME"
EOF
genSignE sml $TEMP/./.zshrc
return 0
}

sml_update(){
genSignS "sml" $UPDATE
cat << 'EOF' >> $UPDATE

MODULE_INFO "......正在升级sml......"
pushd $HOME/bin/sml
git pull
cd base/system
PATH=$PATH:$PWD/../../bin ./cmb-make ../../bin/sml
./makeml
./installml -clean
cd ../..
config/install.sh
popd

EOF
genSignE "sml" $UPDATE
}
