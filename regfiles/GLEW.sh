#!/bin/bash

# VERSION: 1

GLEW_info(){
    echo "The OpenGL Extension Wrangler Library"
}

GLEW_deps(){
    echo "__predeps__ zsh"
}

GLEW_check(){
[ -d ~/bin/GLEW ] && return 0 || return 1

return 1
}

GLEW_install(){
genSignS "GLEW" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装GLEW......"
if GLEW_check; then
    WARN "GLEW已经安装，不再执行安装操作"
else
sudo apt-get install libxmu-dev libxi-dev libgl-dev # build-essential
# libgl-dev-OpenGL开发库 libxi-dev-输入设备库 libxmu-dev-X Window 系统实用工具库
mkdir -p ~/2_Repository/ && mkdir -p ~/bin/GLEW/
git clone https://github.com/nigels-com/glew ~/2_Repository/glew
# A.生成对应编译文件
pushd ~/2_Repository/glew/auto
make
popd
# B.正式执行编译
# 动态库
pushd ~/2_Repository/glew/build
cmake -DCMAKE_INSTALL_PREFIX=~/bin/GLEW -DBUILD_UTILS=ON -DBUILD_SHARED_LIBS=ON ./cmake
make -j$(nproc) && make install
popd
# 静态库
pushd ~/2_Repository/glew/build
cmake -DCMAKE_INSTALL_PREFIX=~/bin/GLEW -DBUILD_UTILS=ON -DBUILD_SHARED_LIBS=OFF ./cmake
make -j$(nproc) && make install
popd
# 设置动态包含路径
echo -e "# GLEW library path\n# This file was generated to include the GLEW library into the system's library path\n$HOME/bin/GLEW/lib" | sudo tee /etc/ld.so.conf.d/glew.conf
sudo ldconfig


fi
EOF
genSignE "GLEW" $INSTALL
}

GLEW_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS GLEW $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
export GLEW_HOME=~/bin/GLEW/
export PATH="$PATH:$GLEW_HOME/bin"

EOF
genSignE GLEW $TEMP/./.zshrc
return 0
}
