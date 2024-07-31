#!/bin/bash

ssh_info(){
    echo "ssh: Secure Shell Protocol."
}

ssh_deps(){
    return 1
}

ssh_check(){
    cmdCheck "ssh"
    return $?
}

ssh_install(){
cat << EOF >> $INSTALL
$(genSignS "ssh")
sudo apt-get install openssh-server -y # 下载ssh服务
sudo systemctl restart ssh # 启动ssh服务
eval "\$(ssh-agent -s)" # 设置必要环境变量
$(genSignE "ssh")

EOF
}

ssh_config(){
cat << EOF >> $ZSHRC
$(genSignS "ssh")
eval "\$(ssh-agent -s)" > /dev/null # 启动 ssh-agent
if [ -d "\$HOME/.ssh" ]; then # 如果存在，自动加载 SSH 私钥
    find \$HOME/.ssh -maxdepth 1 -type f ! -name "*.pub" -exec ssh-add {} \; 2>/dev/null
fi
$(genSignE "ssh")

EOF
}

ssh_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "ssh")
echo "Pipx uninstalling does not support yet."
$(genSignE "ssh")

EOF
}

# ----

ssh_method_gitssh(){
cat << EOF >> $INSTALL
$(genSignS "ssh")
echo "ssh_method_gitssh(): 生成gihub密钥对"
echo "生成密钥对/home/zmr466/.ssh/main_rsa"
ssh-keygen -t rsa #生成密钥对
ssh-add ~/.ssh/main_rsa # 添加私钥到ssh代理
echo "或者复制到服务器 ssh-copy-id"
cat ~/.ssh/main_rsa.pub # 打印公钥
$(genSignE "ssh")

EOF
}