#!/bin/bash

rg_info(){
    echo "rg: ripgrep recursively searches directories for a regex pattern."
}

rg_deps(){
    return 1
}

rg_check(){
    cmdCheck "rg"
    return $?
}

rg_install(){
cat << EOF >> $INSTALL
$(genSignS "rg")
sudo apt-get install ripgrep -y
$(genSignE "rg")

EOF
}

rg_config(){
cat << EOF >> $ZSHRC
$(genSignS "rg")
# 指向~/.ripgreprc配置文件
export RIPGREP_CONFIG_PATH=~/.ripgreprc
$(genSignE "rg")

EOF

OTHERRC+=(".ripgreprc")
cat << EOF >> $TEMP/.ripgreprc
# 设置最大预览行数
# --max-columns=150
# --max-columns-preview

# 添加web的扩展名
--type-add
web:*.{html,css,js}*

# 寻找隐藏文件
--hidden

# 包含log目录
--glob
!log/*

# 设置颜色 通常没用，而且会导致终端颜色缺失
# --colors=line:none
# --colors=line:style:bold

# 智能大小写处理
# 特性: 如果搜索模式中有任何大写字母，搜索将是大小写敏感的
# 如果搜索模式中全是小写字母，搜索将是大小写不敏感的
--smart-case

EOF
}

rg_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "rg")
echo "rg uninstalling does not support yet."
$(genSignE "rg")

EOF
}

# ----