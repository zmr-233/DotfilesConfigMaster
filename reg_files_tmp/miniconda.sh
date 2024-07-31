#!/usr/bin/bash

miniconda_info(){
    echo "miniconda: A free minimal installer for conda."
}

miniconda_deps(){
    return 1
}

miniconda_check(){
    cmdCheck "conda"
    return $?
}

miniconda_install(){
cat << EOF >> $INSTALLSC
$(genSignS "miniconda")
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
$(genSignE "miniocnda")

EOF
}

miniconda_config(){
cat << EOF >> $ZSHRC
$(genSignS "miniconda")
__conda_setup="\$('\$HOME/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ \$? -eq 0 ]; then
    eval "\$__conda_setup"
else
    if [ -f "\$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "\$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="\$HOME/miniconda3/bin:\$PATH"
    fi
fi
unset __conda_setup
$(genSignE "miniocnda")

EOF
}

miniconda_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "miniconda")
conda activate
conda init --reverse --all
rm -rf ~/miniconda3
sudo rm -rf /opt/miniconda3
$(genSignE "miniocnda")

EOF
}