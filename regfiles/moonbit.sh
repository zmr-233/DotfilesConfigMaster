#!/bin/bash

# VERSION: 1

moonbit_info(){
    echo "MoonBit  Cloud and Edge using WASM."
}

moonbit_deps(){
    echo "__predeps__ zsh"
}

moonbit_check(){
return 0;

return 1
}

moonbit_install(){
genSignS "moonbit" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装moonbit......"
INFO "moonbit是无需安装的配置文件"
EOF
genSignE "moonbit" $INSTALL
}

moonbit_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS moonbit $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export PATH="$HOME/.moon/bin:$PATH"

EOF
genSignE moonbit $TEMP/./.zshrc
return 0
}
