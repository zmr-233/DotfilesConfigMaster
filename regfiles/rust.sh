#!/bin/bash

# VERSION: 1

rust_info(){
    echo "Rust Programming Language"
}

rust_deps(){
    echo "__predeps__ zsh zshplugins"
}

rust_check(){
rustc_path="$HOME/.cargo/bin/rustc"
if [ -f "$rustc_path" ]; then
    return 0
else
    return 1
fi
return 1
}

rust_install(){
genSignS "rust" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装rust......"
if rust_check; then
    cwarn "rust已经安装，不再执行安装操作"
else
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

fi
EOF
genSignE "rust" $INSTALL
}

rust_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS rust $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
. "$HOME/.cargo/env"

EOF
genSignE rust $TEMP/./.zshrc
return 0
}
