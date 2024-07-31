#!/bin/bash

# VERSION: 1

__predeps___info(){
    echo "预先安装的软件，例如stow"
}

__predeps___deps(){
    echo ""
}

__predeps___check(){
cmdCheck stow
return $?

    return 1
}

__predeps___install(){
genSignS "__predeps__" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装__predeps__......"
if __predeps___check; then
    cwarn "__predeps__已经安装，不再执行安装操作"
else
sudo apt install stow -y

fi
EOF
genSignE "__predeps__" $INSTALL
}

# 更换清华源
__predeps___change_repository(){
# 检查是否是 Ubuntu
if [[ $(lsb_release -is) = "Ubuntu" ]]; then

    VERSION=$(lsb_release -rs) # 获取 Ubuntu 版本

    case $VERSION in # 根据不同版本执行不同的逻辑
        "22.04")
cat << 'EOF' >> $INSTALL

minfo "......更换清华源......"
sudo tee /etc/apt/sources.list > /dev/null << 'EL'
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
EL
EOF
            ;;
        "24.04")
cat << 'EOF' >> $INSTALL

minfo "......更换清华源......"
sudo tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null << 'EL'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: noble noble-updates noble-backports
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Types: deb-src
# URIs: http://security.ubuntu.com/ubuntu/
# Suites: noble-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 预发布软件源，不建议启用

# Types: deb
# URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: noble-proposed
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# # Suites: noble-proposed
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EL
EOF
            ;;
        *)
cerror "未知的 Ubuntu 版本，请手动操作"
cat << 'EOF' >> $INSTALL

minfo "......更换清华源......"
cwran "未知的 Ubuntu 版本，请手动操作"
cnote "https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/"
EOF
            ;;
    esac
else
    cerror "请手动操作"
cat << 'EOF' >> $INSTALL

minfo "......更换清华源......"
cwran "请手动操作"
cnote "https://mirrors.tuna.tsinghua.edu.cn/help/"
EOF
    return 1
fi
}




