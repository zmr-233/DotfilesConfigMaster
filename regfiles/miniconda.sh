#!/bin/bash

# VERSION: 1

miniconda_info(){
    echo "轻量级的Python发行版和包管理系统"
}

miniconda_deps(){
    echo "__predeps__ zsh zshplugins"
}

miniconda_check(){
    cmdCheck "conda"
return $?

    return 1
}

miniconda_install(){
genSignS "miniconda" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装miniconda......"
if miniconda_check; then
    cwarn "miniconda已经安装，不再执行安装操作"
else
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh

fi
EOF
genSignE "miniconda" $INSTALL
}

miniconda_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS miniconda $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
__conda_setup="$('/home/zmr466/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/zmr466/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/zmr466/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/zmr466/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

EOF
genSignE miniconda $TEMP/./.zshrc
return 0
}

miniconda_uninstall(){
genSignS "miniconda" $UNINSTALL
cat << 'EOF' >> $UNINSTALL

minfo "......正在卸载miniconda......"
if miniconda_check; then
conda activate
conda init --reverse --all
rm -rf ~/miniconda3
sudo rm -rf /opt/miniconda3

else
    cwarn "miniconda已经卸载，不再执行卸载操作"
fi
EOF
genSignE "miniconda" $UNINSTALL
}
