#!/bin/bash

fzf_info(){
    echo "fzf: A command-line fuzzy finder."
}

fzf_deps(){
    return 1
}

fzf_check(){
    cmdCheck "fzf"
    return $?
}

fzf_install(){
cat << EOF >> $INSTALL
$(genSignS "fzf")
# https://github.com/junegunn/fzf
# sudo apt install fzf -y # 版本过低
git clone --depth 1 https://github.com/junegunn/fzf.git ~/bin/fzf
./install # ./uninstall进行卸载
$(genSignE "fzf")

EOF
}

fzf_config(){
cat << EOF >> $ZSHRC
$(genSignS "fzf")
# fzf相关脚本
# 加载启动文件 -- 从clone的版本中安装，自动获得
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 
# 加载配置文件
[ -f ~/.fzfrc ] && source ~/.fzfrc
 
# 额外命令fzfc con
[ -f ~/.fzf.rg.sh ] && chmod +x ~/.fzf.rg.sh && alias fzfc='~/.fzf.rg.sh'
[ -f ~/.fzf.rg.sh ] && chmod +x ~/.fzf.rg.sh && alias con='~/.fzf.rg.sh'
$(genSignE "fzf")

EOF

OTHERRC+=(".fzfrc")

# 基础配置
cat << EOF >> $TEMP/.fzfrc
# 使用~~而不是**来启动
# export FZF_COMPLETION_TRIGGER='~~'

# 使用fd作为搜索工具
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "\$1"
}

# 使用fd作为搜索工具
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "\$1"
}

# 指定不同命令的**扩充内容
_fzf_comprun() {
  local command=\$1
  shift

  case "\$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "\$@" ;;
    export|unset) fzf --preview "eval 'echo \\\$'{}"         "\$@" ;;
    ssh)          fzf --preview 'dig {}'                   "\$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "\$@" ;;
  esac
}
EOF

# fd集成—使用fd作为查找器：
cat << EOF >> $TEMP/.fzfrc
# fd集成—使用fd作为查找器：
# (\$1) is the base path to start traversal
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "\$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "\$1"
}

EOF

# FZF_DEFAULT_OPTS_FILE配置文件位置：需要export在才能被识别
cat << EOF >> $TEMP/.fzfrc
# 设置配置文件位置
export FZF_DEFAULT_OPTS_FILE=~/.fzfrc

EOF

# FZF_CTRL_T_OPTS<C-T>传递附加选项
cat << EOF >> $TEMP/.fzfrc
# CTRL-T- 将选定的文件和目录粘贴到命令行上
# 使用bat彩色预览文件
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

EOF

# FZF_CTRL_R_OPTS<C-R>传递附加选项
cat << EOF >> $TEMP/.fzfrc
# CTRL-R- 将历史记录中选定的命令粘贴到命令行上
# 粘贴到剪切板:
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

EOF

# FZF_ALT_C_OPTS<Alt-C>传递附加选项
cat << EOF >> $TEMP/.fzfrc
# ALT-C- cd 进入选定的目录
# 以树形打印目录
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

EOF

# cat << EOF >> \$TEMP/.fzfrc
# EOF

# fzf rg集成
OTHERRC+=(".fzf.rg.shrc")
cat << EOF >> $TEMP/.fzf.rg.shrc
#!/usr/bin/env bash

# 绑定指令fzfc con 用于动态显示文件内容
# 1. 搜索并动态显示文件内容
# 2. 输入不同的字符，会刷新
# 3. 选中文件并在vim打开
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
INITIAL_QUERY="\${*:-}"
fzf --ansi --disabled --query "\$INITIAL_QUERY" \\
    --bind "start:reload:\$RG_PREFIX {q}" \\
    --bind "change:reload:sleep 0.1; \$RG_PREFIX {q} || true" \\
    --delimiter : \\
    --preview 'bat --color=always {1} --highlight-line {2}' \\
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \\
    --bind 'enter:become(vim {1} +{2})'

EOF

}

fzf_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "fzf")
echo "fzf uninstalling does not support yet."
$(genSignE "fzf")

EOF
}

# ----