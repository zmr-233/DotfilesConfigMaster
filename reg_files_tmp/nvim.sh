#!/bin/bash

nvim_info(){
    echo "nvim: A hyperextensible Vim-based text editor."
}

nvim_deps(){
    return 1
}

nvim_check(){
    cmdCheck "nvim"
    return $?
}

nvim_install(){
cat << EOF >> $INSTALL
$(genSignS "nvim")
# 直接使用小彭老师自用 NeoVim 整合包
# https://github.com/archibate/vimrc
curl -sSLf https://142857.red/files/nvimrc-install.sh | bash
# 运行 :checkhealth 来检查 NeoVim 是否工作正常
# 运行 :Mason 来检查安装了哪些语言支持
$(genSignE "nvim")

EOF
}

nvim_config(){
# cat << EOF >> $ZSHRC
# $(genSignS "nvim")
# $(genSignE "nvim")

# EOF

# OTHERRC+=(".nvimrc")
# cat << EOF >> $TEMP/.nvimrc


# EOF
echo "nvim config does not support yet."
}

nvim_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "nvim")
echo "nvim uninstalling does not support yet."
$(genSignE "nvim")

EOF
}

# ----