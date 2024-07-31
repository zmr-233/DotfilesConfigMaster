#!/bin/bash

git_info(){
    echo "git: A distributed version control system."
}

git_deps(){
    return 1
}

git_check(){
    cmdCheck "git"
    return $?
}

git_install(){
cat << EOF >> $INSTALL
$(genSignS "git")
sudo apt install git -y
$(genSignE "git")

EOF
}

git_config(){
# cat << EOF >> $ZSHRC
# $(genSignS "git")
# $(genSignE "git")

# EOF

OTHERRC+=(".gitconfig")
cat << EOF >> $TEMP/.gitconfig
[user]
  email = zmr_233@outlook.com
  name = zmr466
[core]
  editor = vim
[diff]
  tool = vimdiff
[alias]
  lg = log --decorate --oneline --graph --all --color=always
  ss = status -s
  lgg = !sh -c \\"git log --decorate --oneline --graph --all --color=always | cat\\"
[http]
  postBuffer = 524288000
[color]
  ui = true

EOF
}

git_uninstall(){
cat << EOF >> $UNINSTALLSC
$(genSignS "git")
echo "git uninstalling does not support yet."
$(genSignE "git")

EOF
}

# ----