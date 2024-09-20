#!/bin/bash

# VERSION: 1

sdkman_info(){
    echo "Switch different Java-SDK"
}

sdkman_deps(){
    echo "__predeps__ zsh"
}

sdkman_check(){

[[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]] && return 0 || return 1

return 1
}

sdkman_install(){
genSignS "sdkman" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装sdkman......"
if sdkman_check; then
    WARN "sdkman已经安装，不再执行安装操作"
else
curl -s "https://get.sdkman.io" | bash

fi
EOF
genSignE "sdkman" $INSTALL
}

sdkman_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS sdkman $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

EOF
genSignE sdkman $TEMP/./.zshrc
return 0
}
