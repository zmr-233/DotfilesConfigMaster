#!/bin/bash

zshplugins_info(){
    echo "zshplugins: A collection of zsh plugins."
}

zshplugins_deps(){
    cmdCheck "zsh"
    return $?
}

zshplugins_check(){
    cmdCheck "p10k"
    return $?
}

zshplugins_install(){
cat << EOF >> $INSTALL
$(genSignS "zshplugins")
# 安装oh my zsh
sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# 安装zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# 安装zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# 安装zsh-completions
git clone https://github.com/zsh-users/zsh-completions \${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
# 安装powerlevel10k主题
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
$(genSignE "zshplugins")

EOF
}

zshplugins_config(){
cat << EOF >> $ZSHRC
$(genSignS "zshplugins")
# 启用 Powerlevel10k 即时提示。应该保持在 ~/.zshrc 的顶部。
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

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
fpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# alias-finder别名提醒
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default

# 判断是否是WSL2
if echo \$(cat /proc/version) | grep -qi 'WSL2'; then 
    export WSLTYPE='WSL2'
    export WSLOSTYPE=\$(lsb_release -r | awk '{print "Ubuntu-"\$2}') # 设置Ubuntu-24.04
fi

# 从 Clash 加载代理配置
if [[ \$WSLTYPE == "WSL2" ]]; then
    source ~/.proxyrc
    # 复制到windows剪贴板命令
    wclip() {
        if [ \$# -eq 0 ]; then
            # 如果没有参数，使用管道输入的内容
            iconv -f utf-8 -t utf-16le | clip.exe
        else
            # 如果有参数，读取文件内容
            cat "\$1" | iconv -f utf-8 -t utf-16le | clip.exe
        fi
    }
    # 获取 WSL2 IP 地址
    showip(){
        ip_address=\$(ip addr show eth0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}')
        echo "WSL2 IP Address: \$ip_address"
    }
fi
$(genSignE "zshplugins")

EOF

# p10k配置文件
OTHERRC+=(".p10k.zsh")
cp $SRC/zsh/.p10k.zsh $TEMP/.p10k.zsh

}

zshplugins_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "zshplugins")
echo "zshplugins uninstalling does not support yet."
$(genSignE "zshplugins")

EOF

}

# ----