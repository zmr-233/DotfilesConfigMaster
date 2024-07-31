#!/bin/bash

autojump_info(){
    echo "autojump: A cd command that learns."
}

autojump_deps(){
    cmdCheck "python"
    return $?
}

autojump_check(){
    cmdCheck "autojump"
    return $?
}

autojump_install(){
cat << EOF >> $INSTALL
$(genSignS "autojump")
git clone https://github.com/wting/autojump.git ~/bin/autojump
cd ~/bin/autojump
./install.py #or ./uninstall.py
$(genSignE "autojump")

EOF
}

autojump_config(){
cat << EOF >> $ZSHRC
$(genSignS "autojump")
# autojump快速目录跳转
[[ -s /home/zmr466/.autojump/etc/profile.d/autojump.sh ]] && source /home/zmr466/.autojump/etc/profile.d/autojump.sh
autoload -U compinit && compinit -u

# 覆写的fo函数
source \$HOME/.autojumprc
$(genSignE "autojump")

EOF

OTHERRC+=(".autojumprc")
cat << EOFEND >> $TEMP/.autojumprc
jo () {
    if [[ \${1} == -* ]] && [[ \${1} != "--" ]]
    then
        autojump \${@}
        return
    fi
    setopt localoptions noautonamedirs
    local output="\$(autojump \${@})"
    if [[ -d "\${output}" ]]
    then
        case \${OSTYPE} in
            (linux*)
                if [[ \$WSLTYPE == "WSL2" ]]; then
                    local wsl_path=\$(wslpath -w "\${output}")
                    explorer.exe "\${wsl_path}"
                else
                    xdg-open "\${output}"
                fi
                ;;
            (darwin*) open "\${output}" ;;
            (cygwin) cygstart "" \$(cygpath -w -a \${output}) ;;
            (*) echo "Unknown operating system: \${OSTYPE}" >&2 ;;
        esac
    else
        echo "autojump: directory '\${@}' not found"
        echo "\${output}"
        echo "Try autojump --help for more information."
        false
    fi
}

EOFEND
}

autojump_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "autojump")
echo "autojump uninstalling does not support yet."
$(genSignE "autojump")

EOF
}

# ----