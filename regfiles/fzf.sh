#!/bin/bash

# VERSION: 1

fzf_info(){
    echo "命令行模糊查找工具"
}

fzf_deps(){
    echo "__predeps__ zsg bat rg fd"
}
fzf_check(){
checkCmd "fzf"
return $?
}


fzf_install(){
genSignS "fzf" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装fzf......"
if fzf_check; then
    cwarn "fzf已经安装，不再执行安装操作"
else
# https://github.com/junegunn/fzf
# sudo apt install fzf -y # 版本过低
git clone --depth 1 https://github.com/junegunn/fzf.git ~/bin/fzf
~/bin/fzf/install # ~/bin/fzf//uninstall进行卸载

fi
EOF
genSignE "fzf" $INSTALL
}

fzf_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .fzfrc .fzf.rg.sh"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS fzf $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# fzf相关脚本
# 加载启动文件 -- 从clone的版本中安装，自动获得
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 
# 加载配置文件
[ -f ~/.fzfrc ] && source ~/.fzfrc
 
# 额外命令fzfc con
[ -f ~/.fzf.rg.sh ] && chmod +x ~/.fzf.rg.sh && alias fzfc='~/.fzf.rg.sh'
[ -f ~/.fzf.rg.sh ] && chmod +x ~/.fzf.rg.sh && alias con='~/.fzf.rg.sh'

# 额外命令fzfp pre 使用别名-预览时色彩
alias fzfp="fzf --preview '[[ \$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || highlight -O ansi -l {} || coderay {} || rougify {} || cat {}) 2> /dev/null | head -500'"
alias pre="fzf --preview '[[ \$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || highlight -O ansi -l {} || coderay {} || rougify {} || cat {}) 2> /dev/null | head -500'"

EOF
genSignE fzf $TEMP/./.zshrc

# 配置文件 ./.fzfrc 
cat << 'EOF' >> $TEMP/./.fzfrc
# 使用~~而不是**来启动
# export FZF_COMPLETION_TRIGGER='~~'

# 使用fd作为搜索工具
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# 使用fd作为搜索工具
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# 指定不同命令的**扩充内容
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}

# fd集成—使用fd作为查找器：
# ($1) is the base path to start traversal
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# 设置配置文件位置
# export FZF_DEFAULT_OPTS_FILE=~/.fzfrc

# CTRL-T- 将选定的文件和目录粘贴到命令行上
# 使用bat彩色预览文件
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# CTRL-R- 将历史记录中选定的命令粘贴到命令行上
# 粘贴到剪切板:
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# ALT-C- cd 进入选定的目录
# 以树形打印目录
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"


EOF

# 配置文件 ./.fzf.rg.sh 
cat << 'EOF' >> $TEMP/./.fzf.rg.sh
#!/usr/bin/env bash

# 绑定指令fzfc con 用于动态显示文件内容
# 1. 搜索并动态显示文件内容
# 2. 输入不同的字符，会刷新
# 3. 选中文件并在vim打开
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
INITIAL_QUERY="${*:-}"
fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --delimiter : \
    --preview 'bat --color=always {1} --highlight-line {2}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    --bind 'enter:become(vim {1} +{2})'

EOF
return 0
}
