#!/bin/bash

bat_info(){
    echo "bat: A cat(1) clone with wings."
}

bat_deps(){
    return 1
}

bat_check(){
    cmdCheck "bat"
    return $?
}

bat_install(){
cat << EOF >> $INSTALL
$(genSignS "bat")
sudo apt install bat -y # 由于命名冲突，默认是batcat,必须要设置一个符号别名
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat
$(genSignE "bat")

EOF
}

bat_config(){
    OTHERRC+=(".batrc")
cat << EOF >> $ZSHRC
$(genSignS "bat")
# bat配置文件目录
export BAT_CONFIG_PATH="\$HOME/.batrc"

# man彩色手册
export MANROFFOPT='-c' # 不设置会导致乱码
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# 彩色-h --help --zsh独有
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

# 使用help cp实现的代码高亮
alias bathelp='bat --plain --language=help'
help() {
    "\$@" --help 2>&1 | bathelp
}
$(genSignE "bat")

EOF

# 处理fzf bat交互
cat << EOF >> $ZSHRC
# 额外命令fzfp pre 使用别名-预览时色彩
alias fzfp="fzf --preview '[[ \\\$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || highlight -O ansi -l {} || coderay {} || rougify {} || cat {}) 2> /dev/null | head -500'"
alias pre="fzf --preview '[[ \\\$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || highlight -O ansi -l {} || coderay {} || rougify {} || cat {}) 2> /dev/null | head -500'"
EOF

cat << EOF >> $TEMP/.batrc
# 设置主题
--theme="Dracula"

# Show line numbers, Git modifications and file header (but no grid)
--style="numbers,changes,header"

# Use italic text on the terminal (not supported on all terminals)
--italic-text=always

# Use C++ syntax for Arduino .ino files
--map-syntax "*.ino:C++"

EOF
}

bat_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "bat")
echo "bat uninstalling does not support yet."
$(genSignE "bat")

EOF
}

# ----