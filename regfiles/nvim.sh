#!/bin/bash

# VERSION: 1

nvim_info(){
    echo "直接用的小彭老师开箱即用nvim配置"
}

nvim_deps(){
    echo "__predeps__"
}
nvim_check(){
checkCmd "nvim"
return $?
}


nvim_install(){
genSignS "nvim" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装nvim......"
if nvim_check; then
    cwarn "nvim已经安装，不再执行安装操作"
else
# 直接使用小彭老师自用 NeoVim 整合包
# https://github.com/archibate/vimrc
curl -sSLf https://142857.red/files/nvimrc-install.sh | bash
# 运行 :checkhealth 来检查 NeoVim 是否工作正常
# 运行 :Mason 来检查安装了哪些语言支持

fi
EOF
genSignE "nvim" $INSTALL
}
