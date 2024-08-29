#!/bin/bash

# VERSION: 1

fd_info(){
    echo "更好的find"
}

fd_deps(){
    echo "__predeps__ zsh zshplugins"
}
fd_check(){
checkCmd "fd"
return $?
}


fd_install(){
genSignS "fd" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装fd......"
if fd_check; then
    WARN "fd已经安装，不再执行安装操作"
else
sudo apt install fd-find
# 由于包名冲突，需要创建符号链接
ln -s $(which fdfind) ~/.local/bin/fd # 确保$HOME/.local/bin is in your $PATH.

fi
EOF
genSignE "fd" $INSTALL
}
