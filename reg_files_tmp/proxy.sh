#!/bin/bash

proxy_info(){
    echo "proxy: Set proxy for terminal."
}

proxy_deps(){
    return 1
}

proxy_check(){
    cmdCheck "sudop"
    return $?
}

proxy_install(){
# cat << EOF >> $INSTALL
# $(genSignS "proxy")
# $(genSignE "proxy")

# EOF
echo "proxy install does not support yet."
}

proxy_config(){

cat << EOF >> $ZSHRC
$(genSignS "proxy")
$(genSignE "proxy")

EOF

OTHERRC+=(".proxyrc")

cat << EOF > $TEMP/.proxyrc
$(genSignS "proxy")
# proxy operation
proxy() {
    if [[ \$@ == 'enable' ]]; then
        # Get host ip
        export HOST_IP=\$(ip route | grep default | awk '{print \$3}');
        export PROXY_PORT=1080;
        export {all_proxy,ALL_PROXY}="socks5://\${HOST_IP}:\${PROXY_PORT}";
        export {ftp_proxy,FTP_PROXY}="http://\${HOST_IP}:\${PROXY_PORT}";
        export {http_proxy,HTTP_PROXY}="http://\${HOST_IP}:\${PROXY_PORT}";
        export {https_proxy,HTTPS_PROXY}="http://\${HOST_IP}:\${PROXY_PORT}";
    elif [[ \$@ == 'disable' ]]; then
        unset {all_proxy,ALL_PROXY};
        unset {ftp_proxy,FTP_PROXY};
        unset {http_proxy,HTTP_PROXY};
        unset {https_proxy,HTTPS_PROXY};
    else
        echo 'all_proxy,   ALL_PROXY   =' \${all_proxy:-'none'};
        echo 'ftp_proxy,   FTP_PROXY   =' \${ftp_proxy:-'none'};
        echo 'http_proxy,  HTTP_PROXY  =' \${http_proxy:-'none'};
        echo 'https_proxy, HTTPS_PROXY =' \${https_proxy:-'none'};
    fi
}

# enable proxy
proxy enable

# add sudop alias
alias sudop='sudo --preserve-env=all_proxy,ALL_PROXY,ftp_proxy,FTP_PROXY,http_proxy,HTTP_PROXY,https_proxy,HTTPS_PROXY'
$(genSignE "proxy")
EOF
}

proxy_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "pipx")
echo "proxy uninstalling does not support yet."
$(genSignE "pipx")

EOF
}

# ----
