#!/bin/bash

# VERSION: 1

ssh_info(){
    echo "Secure Shell这里加载私钥的配置"
}

ssh_deps(){
    echo "__predeps__ zsh"
}
ssh_check(){
checkCmd "ssh"
return $?
}


ssh_install(){
genSignS "ssh" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装ssh......"
if ssh_check; then
    WARN "ssh已经安装，不再执行安装操作"
else
sudo apt-get install openssh-server -y # 下载ssh服务
sudo systemctl restart ssh # 启动ssh服务
eval "$(ssh-agent -s)" # 设置必要环境变量

fi
EOF
genSignE "ssh" $INSTALL
}

ssh_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS ssh $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
eval "$(ssh-agent -s)" > /dev/null # 启动 ssh-agent
if [ -d "$HOME/.ssh" ]; then # 如果存在，自动加载 SSH 私钥
    find $HOME/.ssh -maxdepth 1 -type f ! -name "*.pub" -exec ssh-add {} \; 2>/dev/null
fi

EOF
genSignE ssh $TEMP/./.zshrc
return 0
}


ssh_githubssh(){

MODULE_INFO "......为github生成ssh密钥对......"
NOTE "~/.ssh/main_rsa"
ssh-keygen -t rsa #生成密钥对
ssh-add ~/.ssh/main_rsa # 添加私钥到ssh代理
NOTE "或者复制到服务器 ssh-copy-id，这里直接打印出公钥"
cat ~/.ssh/main_rsa.pub # 打印公钥

return 0
}