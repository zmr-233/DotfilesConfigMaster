#!/bin/bash

# VERSION: 1

proxy_info(){
    echo "保留代理的sudop"
}

proxy_deps(){
    echo "__predeps__ zsh"
}

proxy_check(){
checkCfg "$HOME/.proxyrc"
return $?

return 1
}

proxy_install(){
genSignS "proxy" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装proxy......"
cinfo "proxy是无需安装的配置文件"
EOF
genSignE "proxy" $INSTALL
}

proxy_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .proxyrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS proxy $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# 代理设置
source ~/.proxyrc

EOF
genSignE proxy $TEMP/./.zshrc

# 配置文件 ./.proxyrc 
cat << 'EOF' >> $TEMP/./.proxyrc
# proxy operation
proxy() {
    if [[ $@ == 'enable' ]]; then
        # Get host ip
        export HOST_IP=$(ip route | grep default | awk '{print $3}');
        export PROXY_PORT=1080;
        export {all_proxy,ALL_PROXY}="socks5://${HOST_IP}:${PROXY_PORT}";
        export {ftp_proxy,FTP_PROXY}="http://${HOST_IP}:${PROXY_PORT}";
        export {http_proxy,HTTP_PROXY}="http://${HOST_IP}:${PROXY_PORT}";
        export {https_proxy,HTTPS_PROXY}="http://${HOST_IP}:${PROXY_PORT}";
    elif [[ $@ == 'disable' ]]; then
        unset {all_proxy,ALL_PROXY};
        unset {ftp_proxy,FTP_PROXY};
        unset {http_proxy,HTTP_PROXY};
        unset {https_proxy,HTTPS_PROXY};
    else
        echo 'all_proxy,   ALL_PROXY   =' ${all_proxy:-'none'};
        echo 'ftp_proxy,   FTP_PROXY   =' ${ftp_proxy:-'none'};
        echo 'http_proxy,  HTTP_PROXY  =' ${http_proxy:-'none'};
        echo 'https_proxy, HTTPS_PROXY =' ${https_proxy:-'none'};
    fi
}

# enable proxy
proxy enable

# add sudop alias
alias sudop='sudo --preserve-env=all_proxy,ALL_PROXY,ftp_proxy,FTP_PROXY,http_proxy,HTTP_PROXY,https_proxy,HTTPS_PROXY'

# add sudo alias
alias sudo='sudop'
EOF
return 0
}
