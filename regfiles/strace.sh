#!/bin/bash

# VERSION: 1

strace_info(){
    echo "用于追踪syscall的工具"
}

strace_deps(){
    echo "__predeps__"
}
strace_check(){
checkCmd "strace"
return $?
}


strace_install(){
genSignS "strace" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装strace......"
if strace_check; then
    WARN "strace已经安装，不再执行安装操作"
else
sudo apt install strace -y

fi
EOF
genSignE "strace" $INSTALL
}
