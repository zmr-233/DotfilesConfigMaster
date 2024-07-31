#!/bin/bash

gen_info(){
    readLine lineinfo "请输入介绍:"
cat << EOF >$TEMP/$1.sh
#!/bin/bash

${1}_info(){
    echo "$lineinfo"
}
EOF
}

gen_deps(){
    if readReturn "是否有依赖?"; then
        readLine deps "请输入依赖-允许输入不存在于注册文件的命令"
cat << EOF >>$TEMP/$1.sh

${1}_deps(){
    echo "__prepkgs__ $deps"
}
EOF
    else
cat << EOF >>$TEMP/$1.sh

${1}_deps(){
    echo ""
}
EOF
    fi
}

gen_check(){
    if readReturn "是否能用type检测"; then
cat << EOF >>$TEMP/$1.sh
${1}_check(){
    cmdCheck "$1"
    return \$?
}

EOF
    else
        readMultiLine checkWay "请输入检测方式-return 0/1"
cat << EOF >>$TEMP/$1.sh
${1}_check(){

    $checkWay
    return 1
}

EOF
    fi
}

gen_install(){
    readMultiLine installCmd "请输入安装命令"
cat << EOFF >>$TEMP/$1.sh

${1}_install(){
genSignS "$1" \$INSTALL
cat << 'EOF' >> \$INSTALL
minfo "......正在安装${1}......"
$installCmd
EOF
genSignE "$1" \$INSTALL
}

EOFF
}   

gen_config(){
cat << EOF >>$TEMP/$1.sh

${1}_config(){
# 加入配置文件更新映射
EOF
    if readReturn "是否有配置文件"; then
        cnote "此处输入为~/.zshrc 或者 ./zshrc 或 bin/wclip.sh 或 ~/bin/wclip.sh"
        readArray configFiles "输入配置文件以空格分隔，支持目录"
        declare -A config_map=()
        resolve_configFiles configFiles config_map
        {
            saveMap config_map
            echo "add_configMap config_map"
            echo ""
        } >> $TEMP/$1.sh

        for key in ${!config_map[@]}; do
            for file in ${config_map[$key]}; do
                readMultiLine configCmd "请输入${key}/${file}配置命令:"
cat << EOFF >> $TEMP/$1.sh
# 配置文件 $key/$file 
genSignS "$1" \$TEMP/$key/$file
cat << 'EOF' >> \$TEMP/$key/$file
$configCmd
EOF
genSignE "$1" \$TEMP/$key/$file
EOFF
            done
        done
    else
cat << EOFF >> $TEMP/$1.sh
return 0
EOFF
    fi

cat << EOF >>$TEMP/$1.sh
}
EOF
}

gen_update(){
    cnote "当尚不明确升级指令(或默认使用包管理升级) 可以保持空白ctrl-d直接跳过"
    readMultiLine updateCmd "请输入升级命令"
cat << EOFF >>$TEMP/$1.sh

${1}_update(){
minfo "......正在升级${1}......"
genSignS "$1" \$UPDATE
EOFF

    if [ -z "$(echo -e "$updateCmd" | tr -d '[:space:]')" ]; then
cat << EOFF >>$TEMP/$1.sh
cat << 'EOF' >> \$UPDATE
cerror "${1}暂时不支持自动升级，请手动升级或使用包管理"
EOF
EOFF
    else
cat << EOFF >>$TEMP/$1.sh
cat << 'EOF' >> \$UPDATE
$updateCmd
EOF
EOFF
    fi
cat << EOFF >>$TEMP/$1.sh
genSignE "$1" \$UPDATE
}
EOFF
}

gen_uninstall(){
    cnote "当尚不明确卸载指令 可以保持空白ctrl-d直接跳过"
    readMultiLine uninstallCmd "请输入卸载命令"
cat << EOFF >>$TEMP/$1.sh

${1}_uninstall(){
minfo "......正在卸载${1}......"
genSignS "$1" \$UNINSTALL
EOFF

    if [ -z "$(echo -e "$uninstallCmd" | tr -d '[:space:]')" ]; then
cat << EOFF >>$TEMP/$1.sh
cat << 'EOF' >> \$UNINSTALL
cerror "${1}暂时不支持自动卸载，请手动执行卸载命令"
EOF
EOFF
    else
cat << EOFF >>$TEMP/$1.sh
cat << 'EOF' >> \$UNINSTALL
if ${1}_check; then
$uninstallCmd
else
cwarn "${1}已经卸载，不再执行卸载操作"
fi
EOF
EOFF
    fi
cat << EOFF >>$TEMP/$1.sh
genSignE "$1" \$UNINSTALL
}
EOFF
}

check_complete(){   
    local fileName=$TEMP/$1.sh
    bash -n "$fileName" && csuccess "==> $1 : [y]" || cerror "==> $1 : [ERROR]"
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