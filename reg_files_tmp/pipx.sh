#!/usr/bin/bash

pipx_info(){
    echo "pipx: Install and run Python applications in isolated environments."
}

pipx_deps(){
    return 1
}

pipx_check(){
    cmdCheck "pipx"
    return $?
}

pipx_install(){
cat << EOF >> $INSTALLSC
$(genSignS "pipx")
sudo apt install pipx -y
$(genSignE "pipx")

EOF
}

pipx_config(){
cat << EOF >> $ZSHRC
$(genSignS "pipx")
export PATH="$PATH:$HOME/.local/bin"
pipx ensurepath # pipx加入环境变量

$(genSignE "pipx")

EOF
}

pipx_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "pipx")
echo "Pipx uninstalling does not support yet."
$(genSignE "pipx")

EOF
}