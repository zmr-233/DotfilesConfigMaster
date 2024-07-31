#!/bin/bash

zsh_info(){
    echo "zsh: A shell designed for interactive use, although it is also a powerful scripting language."
}

zsh_deps(){
    return 1
}

zsh_check(){
    cmdCheck "zsh"
    return $?
}

zsh_install(){
cat << EOF >> $INSTALL
$(genSignS "zsh")
sudo apt install zsh -y
chsh -s \$(which zsh) # 设置默认终端
# 然后需要注销并重新登录，再次使用 source ~/.proxyrc 来获得代理
zsh
source ~/.zshrc
$(genSignE "zsh")

EOF
}

zsh_config(){
# cat << EOF >> $ZSHRC
# $(genSignS "zsh")

# $(genSignE "zsh")

# EOF
echo "zsh config does not support yet."
}

zsh_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "zsh")
echo "Why you need uninstall zsh?"
$(genSignE "zsh")

EOF
}

# ----