#!/bin/bash

# VERSION: 1

GLFW_info(){
    echo "Open Source, multi-platform library for OpenGL"
}

GLFW_deps(){
    echo "__predeps__ zsh"
}

GLFW_check(){
[ -d ~/bin/GLFW ] && return 0 || return 1

return 1
}

GLFW_install(){
genSignS "GLFW" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装GLFW......"
if GLFW_check; then
    WARN "GLFW已经安装，不再执行安装操作"
else

sudo add-apt-repository ppa:oibaf/graphics-drivers
sudo apt update
sudo apt upgrade -y

sudo apt install libwayland-dev libxkbcommon-dev xorg-dev # Wayland & X11依赖项
mkdir -p ~/2_Repository/ && mkdir -p ~/bin/GLFW/3.4/
git clone https://github.com/glfw/glfw ~/2_Repository/glfw
pushd ~/2_Repository/glfw
# 静态库
cmake -S ~/2_Repository/glfw -B ~/bin/GLFW/3.4/ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=~/bin/GLFW/3.4/ -DBUILD_SHARED_LIBS=OFF 
pushd ~/bin/GLFW/3.4/ && make -j$(nproc) && make install && popd
# 动态库
cmake -S ~/2_Repository/glfw -B ~/bin/GLFW/3.4/ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=~/bin/GLFW/3.4/ -DBUILD_SHARED_LIBS=ON
pushd ~/bin/GLFW/3.4/ && make -j$(nproc) && make install && popd
popd

# 设置动态包含路径
echo -e "# GLFW library path\n# This file was generated to include the GLFW library into the system's library path\n$HOME/bin/GLFW/3.4/lib" | sudo tee /etc/ld.so.conf.d/glfw.conf
sudo ldconfig

fi
EOF
genSignE "GLFW" $INSTALL
}

GLFW_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS GLFW $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export GLFW_VERSION=3.4
export GLFW_HOME=~/bin/GLFW/$GLFW_VERSION

EOF
genSignE GLFW $TEMP/./.zshrc
return 0
}
