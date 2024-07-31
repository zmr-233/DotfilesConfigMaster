#!/bin/bash

# VERSION: 1

git_info(){
    echo "分布式版本控制系统"
}

git_deps(){
    echo "__predeps__"
}
git_check(){
cmdCheck "git"
return $?
}


git_install(){
genSignS "git" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装git......"
if git_check; then
    cwarn "git已经安装，不再执行安装操作"
else
sudo apt install git -y

fi
EOF
genSignE "git" $INSTALL
}

git_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".gitconfig"
)

add_configMap config_map

# 配置文件 ./.gitconfig 
cat << 'EOF' >> $TEMP/./.gitconfig
[user]
  email = zmr_233@outlook.com
  name = zmr233
[core]
  editor = vim
[diff]
  tool = vimdiff
[alias]
  lg = log --decorate --oneline --graph --all --color=always
  ss = status -s
  lgg = !sh -c \"git log --decorate --oneline --graph --all --color=always | cat\"
[http]
  postBuffer = 524288000
[color]
  ui = true

EOF
return 0
}
