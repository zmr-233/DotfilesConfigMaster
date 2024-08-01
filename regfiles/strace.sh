#!/bin/bash

# VERSION: 1

strace_info(){
    echo "用于追踪syscall的工具"
}

strace_deps(){
    echo "__predeps__"
}
strace_check(){
cmdCheck "strace"
return $?
}


strace_install(){
genSignS "strace" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装strace......"
if strace_check; then
    cwarn "strace已经安装，不再执行安装操作"
else
sudo apt install strace -y

fi
EOF
genSignE "strace" $INSTALL
}
