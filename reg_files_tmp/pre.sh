#!/bin/bash

pre_info(){
    echo "pre: Install some basic tools."
}

pre_deps(){
    return 1
}

pre_check(){
    return 1 # 在install/config中都检查
}

pre_install(){
cat << EOF >> $INSTALL
$(genSignS "pre")
cmdCheck "tree" || sudo apt-get install tree -y
cmdCheck "htop" || sudo apt install htop -y
cmdCheck "gcc" || sudo apt install build-essential -y
cmdCheck "stow" || sudo apt install stow -y
$(genSignE "pre")

EOF
}

pre_config(){
cat << EOF >> $ZSHRC
$(genSignS "pre")
cmdCheck "tree" || sudo apt-get install tree -y
cmdCheck "htop" || sudo apt install htop -y
cmdCheck "gcc" || sudo apt install build-essential -y
cmdCheck "stow" || sudo apt install stow -y
$(genSignE "pre")

EOF

# OTHERRC+=(".prerc")
# cat << EOF >> $TEMP/.prerc


# EOF
}

pre_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "pre")
echo "pre uninstalling does not support yet."
$(genSignE "pre")

EOF
}

# ----