#!/bin/bash

# VERSION: 1

zstree_info(){
    echo "是zmr233写的类似于pstree用于显示进程树的工具"
}

zstree_deps(){
    echo "__predeps__"
}
zstree_check(){
checkCmd "zstree"
return $?
}


zstree_install(){
genSignS "zstree" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装zstree......"
if zstree_check; then
    cwarn "zstree已经安装，不再执行安装操作"
else
git clone https://github.com/zmr-233/zstree.git ~/bin/zstree
cd ~/bin/zstree && make all

fi
EOF
genSignE "zstree" $INSTALL
}

zstree_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS zstree $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export PATH="$PATH:$HOME/bin/zstree/bin"

EOF
genSignE zstree $TEMP/./.zshrc
return 0
}

zstree_update(){
genSignS "zstree" $UPDATE
cat << 'EOF' >> $UPDATE

minfo "......正在升级zstree......"
cd ~/bin/zstree && git pull
make all

EOF
genSignE "zstree" $UPDATE
}
