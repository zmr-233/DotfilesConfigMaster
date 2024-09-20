#!/bin/bash

# VERSION: 1

Emscripten_info(){
    echo "编译 C/C++ 为 WebAssembly"
}

Emscripten_deps(){
    echo "__predeps__ zsh"
}

Emscripten_check(){
[ -f "$HOME/bin/emsdk/upstream/emscripten/emcc" ] && return 0 || return 1

return 1
}

Emscripten_install(){
genSignS "Emscripten" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装Emscripten......"
if Emscripten_check; then
    WARN "Emscripten已经安装，不再执行安装操作"
else
mkdir ~/bin
pushd ~/bin
git clone https://github.com/juj/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
popd

fi
EOF
genSignE "Emscripten" $INSTALL
}

Emscripten_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS Emscripten $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
 source "$HOME/bin/emsdk/emsdk_env.sh" > /dev/null 2>&1

EOF
genSignE Emscripten $TEMP/./.zshrc
return 0
}
