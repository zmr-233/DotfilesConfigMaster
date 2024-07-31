#!/bin/bash

# VERSION: 1

zsh_info(){
    echo "功能强大的命令行Shell"
}

zsh_deps(){
    echo "__predeps__"
}
zsh_check(){
    cmdCheck "zsh"
    return $?
}


zsh_install(){
genSignS "zsh" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装zsh......"
if zsh_check; then
    cwarn "zsh已经安装，不再执行安装操作"
else
sudo apt install zsh -y
chsh -s $(which zsh) # 设置默认终端
# 然后需要注销并重新登录，再次使用 source ~/.proxyrc 来获得代理
zsh
source ~/.zshrc

fi
EOF
genSignE "zsh" $INSTALL
}

zsh_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
)

add_configMap config_map

# 配置文件 ./.zshrc 
cat << 'EOF' >> $TEMP/./.zshrc
# 启用 Powerlevel10k 即时提示。应该保持在 ~/.zshrc 的顶部。
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# 设置powerlevel10k主题
ZSH_THEME="powerlevel10k/powerlevel10k"
# 加载配置文件p10k configure 或者 edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# 避免显示 p10k 的警告消息
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

plugins=(
  zsh-syntax-highlighting # 语法高亮显示
  zsh-autosuggestions # 灰色自动补全插件
  alias-finder # 别名提醒
  
)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# alias-finder别名提醒
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default


# oh-my-zsh加载
source $ZSH/oh-my-zsh.sh

# 判断是否是WSL2
if echo $(cat /proc/version) | grep -qi 'WSL2'; then 
    export WSLTYPE='WSL2'
    export WSLOSTYPE=$(lsb_release -r | awk '{print "Ubuntu-"$2}') # 设置Ubuntu-24.04
fi

# 从 Clash 加载代理配置
if [[ $WSLTYPE == "WSL2" ]]; then
    source ~/.proxyrc
    # 复制到windows剪贴板命令
    wclip() {
        if [ $# -eq 0 ]; then
            # 如果没有参数，使用管道输入的内容
            iconv -f utf-8 -t utf-16le | clip.exe
        else
            # 如果有参数，读取文件内容
            cat "$1" | iconv -f utf-8 -t utf-16le | clip.exe
        fi
    }
    # 获取 WSL2 IP 地址
    showip(){
        ip_address=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        echo "WSL2 IP Address: $ip_address"
    }
fi
EOF
return 0
}
