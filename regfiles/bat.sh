#!/bin/bash

# VERSION: 1

bat_info(){
    echo "颜色高亮和分页显示的cat命令增强版"
}

bat_deps(){
    echo "__predeps__ zsh zshplugins"
}
bat_check(){
    checkCmd "bat"
    return $?
}


bat_install(){
genSignS "bat" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装bat......"
if bat_check; then
    WARN "bat已经安装，不再执行安装操作"
else
sudo apt install bat -y # 由于命名冲突，默认是batcat,必须要设置一个符号别名
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

fi
EOF
genSignE "bat" $INSTALL
}

bat_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .batrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS bat $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# bat配置文件目录
export BAT_CONFIG_PATH="$HOME/.batrc"

# man彩色手册
export MANROFFOPT='-c' # 不设置会导致乱码
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# 彩色-h --help --zsh独有
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

# 使用help cp实现的代码高亮
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

EOF
genSignE bat $TEMP/./.zshrc

# 配置文件 ./.batrc 
cat << 'EOF' >> $TEMP/./.batrc
# 设置主题
--theme="Dracula"

# Show line numbers, Git modifications and file header (but no grid)
--style="numbers,changes,header"

# Use italic text on the terminal (not supported on all terminals)
--italic-text=always

# Use C++ syntax for Arduino .ino files
--map-syntax "*.ino:C++"

EOF
return 0
}
