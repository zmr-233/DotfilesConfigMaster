#!/bin/bash

tmux_info(){
    echo "tmux: A terminal multiplexer."
}

tmux_deps(){
    return 1
}

tmux_check(){
    cmdCheck "tmux"
    return $?
}

tmux_install(){
cat << EOF >> $INSTALL
$(genSignS "tmux")
sudo apt-get install tmux -y
$(genSignE "tmux")

EOF
}

tmux_config(){
# cat << EOF >> $ZSHRC
# $(genSignS "tmux")
# $(genSignE "tmux")

# EOF

OTHERRC+=(".tmux.conf")
cat << EOF >> $TEMP/.tmux.conf
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
}

tmux_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "tmux")
echo "tmux uninstalling does not support yet."
$(genSignE "tmux")

EOF
}

# ----