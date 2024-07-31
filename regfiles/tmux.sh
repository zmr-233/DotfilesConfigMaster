#!/bin/bash

# VERSION: 1

tmux_info(){
    echo "终端多路复用"
}

tmux_deps(){
    echo "__predeps__"
}
tmux_check(){
cmdCheck "tmux"
return $?
}


tmux_install(){
genSignS "tmux" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装tmux......"
if tmux_check; then
    cwarn "tmux已经安装，不再执行安装操作"
else
sudo apt install tmux -y

fi
EOF
genSignE "tmux" $INSTALL
}

tmux_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".tmux.conf"
)

add_configMap config_map

# 配置文件 ./.tmux.conf 
cat << 'EOF' >> $TEMP/./.tmux.conf
# 设置鼠标支持
set -g mouse on

# 绑定按键Ctrl_b->Ctrl_a
set-option -g prefix C-a
bind-key C-a send-prefix

# ------------------------------------------
# 设置复制模式为 Vim 风格
setw -g mode-keys vi

# 使用 Ctrl-a 后跟 h/j/k/l 在窗格间切换（不在复制模式下）
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# 这样，你就可以在复制模式中使用 hjkl 进行光标导航，
# 而在非复制模式下使用 Ctrl-b + hjkl 在窗格间切换

EOF
return 0
}
