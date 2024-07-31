#!/bin/bash

gen_info(){
    readLine lineinfo "请输入介绍:"
    if [ -z "$(echo -e "$lineinfo" | tr -d '[:space:]')" ]; then
        cwarn "介绍为空，默认填入---- no info ----"
        lineinfo="---- no info ----"
    fi
cat << EOF >$TEMP/$1.sh
#!/bin/bash

# VERSION: 1

${1}_info(){
    echo "$lineinfo"
}
EOF
}

gen_deps(){
    if readReturn "是否有依赖的项/命令?"; then
        readLine deps "请输入依赖-允许输入不存在于注册文件的命令(自动检测)，或者为空"
        if [ -z "$(echo -e "$deps" | tr -d '[:space:]')" ]; then
            cwarn "依赖项为空，默认返回空"
            deps=""
        fi
cat << EOF >>$TEMP/$1.sh

${1}_deps(){
    echo "__predeps__ $deps"
}
EOF
    else
cat << EOF >>$TEMP/$1.sh

${1}_deps(){
    echo "__predeps__"
}
EOF
    fi
}

gen_check(){
    
    if readReturn "是否能用type命令检测"; then
cat << EOF >>$TEMP/$1.sh
${1}_check(){
cmdCheck "$1"
return \$?
}

EOF
    else
        cnote "如果是纯配置文件，使用configCheck "\$HOME/proxyrc";return \$?;即可"
        cnote "如果能在终端输入明确指令，检测函数cmdCheck "$1"; return \$?;可供使用"
        cnote "不要用~/.proxyrc，必须要用\$HOME环境变量"
        # cnote "如果是纯配置文件(无需检查是否安装)，可以保持空白ctrl-d直接跳过"
        readMultiLine checkWay "请输入检测是否安装的bash命令，默认以return 0代表已安装"
        if [ -z "$(echo -e "$checkWay" | tr -d '[:space:]')" ]; then
            cwarn "检测命令为空，默认任何情况下均视为已安装"
            checkWay="return 0"
        fi
cat << EOF >>$TEMP/$1.sh

${1}_check(){
$checkWay
return 1
}
EOF
    fi
}

gen_install(){
    cnote "此处可以填入从源码构建的指令，也可以填入包管理安装命令(最好加上-y)"
    cnote "若无安装操作 也可以保持空白ctrl-d直接跳过"
    readMultiLine installCmd "请输入安装命令"
    if [ -z "$(echo -e "$installCmd" | tr -d '[:space:]')" ]; then
        cwarn "安装命令为空，跳过"
cat << EOFF >>$TEMP/$1.sh

${1}_install(){
genSignS "$1" \$INSTALL
cat << 'EOF' >> \$INSTALL
minfo "......正在安装${1}......"
cinfo "${1}是无需安装的配置文件"
EOF
genSignE "$1" \$INSTALL
}
EOFF
    else
cat << EOFF >>$TEMP/$1.sh

${1}_install(){
genSignS "$1" \$INSTALL
cat << 'EOF' >> \$INSTALL
minfo "......正在安装${1}......"
if ${1}_check; then
    cwarn "${1}已经安装，不再执行安装操作"
else
$installCmd
fi
EOF
genSignE "$1" \$INSTALL
}
EOFF
    fi
}   

gen_config(){

    if readReturn "是否有配置文件"; then
        cnote "此处输入为~/.zshrc 或者 ./zshrc 或 bin/wclip.sh 或 ~/bin/wclip.sh"
        readArray configFiles "请输入配置文件路径(多个文件用空格分隔，且必须采用相对路径，默认工作目录为~):"
        if [[ ${#configFiles[@]} -eq 0 ]]; then
            cwarn "配置文件项全为空，跳过"
        else
cat << EOF >>$TEMP/$1.sh

${1}_config(){
# 加入配置文件更新映射
EOF
            declare -A config_map=()
            resolve_configFiles configFiles config_map
            {
                saveMap config_map
                echo "add_configMap config_map"
            } >> $TEMP/$1.sh

            for key in ${!config_map[@]}; do
                for file in ${config_map[$key]}; do
                    readMultiLine configCmd "请输入${key}/${file}配置命令:"
                    if [ -z "$(echo -e "$configCmd" | tr -d '[:space:]')" ]; then
                        cwarn "该文件配置为空，默认写入一个换行符"
cat << EOFF >> $TEMP/$1.sh
# 配置文件 $key/$file 为空--默认写入一个换行符
cat << 'EOF' >> \$TEMP/$key/$file

EOF
EOFF
                    else
                        echo "" >> $TEMP/$1.sh
                        echo "# 配置文件 $key/$file " >> $TEMP/$1.sh
                        readBool ifSign "是否需要用 >>>> $1 >>>> 标记"
                        if [[ $ifSign == y ]]; then
                            echo "genSignS $1 \$TEMP/$key/$file" >> $TEMP/$1.sh
                        fi
cat << EOFF >> $TEMP/$1.sh
cat << 'EOF' >> \$TEMP/$key/$file
$configCmd
EOF
EOFF
                        if [[ $ifSign == y ]]; then
                            echo "genSignE $1 \$TEMP/$key/$file" >> $TEMP/$1.sh
                        fi
                    fi
                done
            done
cat << EOFF >> $TEMP/$1.sh
return 0
}
EOFF
        fi
    fi
}

gen_update(){
    cnote "当尚不明确升级指令(或默认使用包管理升级) 可以保持空白ctrl-d直接跳过"
    readMultiLine updateCmd "请输入升级命令"
    if [ -z "$(echo -e "$updateCmd" | tr -d '[:space:]')" ]; then
        cwarn "升级命令为空，跳过"
    else
cat << EOFF >>$TEMP/$1.sh

${1}_update(){
genSignS "$1" \$UPDATE
cat << 'EOF' >> \$UPDATE

minfo "......正在升级${1}......"
$updateCmd
EOF
genSignE "$1" \$UPDATE
}
EOFF
    fi
}

gen_uninstall(){
    cnote "当尚不明确卸载指令(或默认使用包管理卸载) 可以保持空白ctrl-d直接跳过"
    readMultiLine uninstallCmd "请输入卸载命令"
    if [ -z "$(echo -e "$uninstallCmd" | tr -d '[:space:]')" ]; then
        cwarn "卸载命令为空，跳过"
    else
cat << EOFF >>$TEMP/$1.sh

${1}_uninstall(){
genSignS "$1" \$UNINSTALL
cat << 'EOF' >> \$UNINSTALL

minfo "......正在卸载${1}......"
if ${1}_check; then
$uninstallCmd
else
    cwarn "${1}已经卸载，不再执行卸载操作"
fi
EOF
genSignE "$1" \$UNINSTALL
}
EOFF
    fi
}

check_complete(){   
    local fileName=$TEMP/$1.sh
    bash -n "$fileName" && csuccess "==> ${1}注册文件检查 : [OK]" || cerror "==> ${1}注册文件检查 : [ERROR]"
}


gen_regFile(){ 
    minfo '#.生成注册文件'
    local fileName
    local ifOverwrite=y

    if [[ $# -eq 1 ]]; then
        fileName=$1
    else
        readNoSpace fileName "请输入注册名称/命令: "

        if [[ -f $TEMP/$fileName.sh ]]; then
            cinfo "检测到已存在的临时注册文件"
            readBool ifOverwrite "是否覆盖?"
        fi
    fi

    if [[ $ifOverwrite == y ]]; then
        cinfo "==> 当前注册文件: $fileName"
        gen_info $fileName 
        gen_deps $fileName
        gen_check $fileName
        gen_install $fileName
        gen_config $fileName
        gen_update $fileName
        gen_uninstall $fileName
    fi
    
    # 检查语法
    cinfo "临时注册文件生成完毕，文件路径: $TEMP/$fileName.sh"
    check_complete $fileName
    safeOverwrite $fileName.sh $TEMP $REGP
}