#!/bin/bash

# 检查未出现的命令
check_preCmd(){
    # declare -n preCmd_=$1
    declare -a uncCmd=()
    for cmd in "${preCmd_[@]}"; do
        if !cmdCheck $cmd; then
            cerror "未找到命令: $cmd"
            uncCmd+=($cmd)
        fi
    done
    if [ ${#uncCmd[@]} -ne 0 ]; then
        cerror "=> 以下命令未安装: ${uncCmd[@]}"
        exit 1
    fi
}

# 1.注册模块
register_regFiles(){
    minfo "......加载注册文件模块......."
    declare -n regFiles_=$1 # 存储所有注册文件
    declare -n ifInstall_=$2 # 存储是否安装
    declare -a preCmd # 存储未出现的命令
    
    # 读取注册文件
    if [ -z "$(ls -A $REGP/*.sh 2>/dev/null)" ]; then
        cwarn "regfiles文件夹为空"
    else
        if [[ ${#regFiles_[@]} -eq 0 ]]; then
            cinfo "==> 从注册文件目录读取"
            for script in $REGP/*.sh; do
                scpName=$(basename "$script" .sh)
                regFiles_+=("$scpName")
                source "$script"
            done
        else
            cinfo "==> 已从外部传入注册文件列表"
            for reg in "${regFiles_[@]}"; do
                source $REGP/$reg.sh
            done
        fi
    fi
    
    # 处理依赖关系
    cinfo "......处理依赖关系......"
    resolve_deps regFiles_ preCmd

    # 检查未出现的命令=>默认终止
    cinfo "......检查未出现的命令......"
    check_preCmd preCmd

    # 检查是否安装 ->生成哈希表
    cinfo "......检查是否已经安装过......"
    for reg in "${regFiles_[@]}"; do
        ${reg}_check
        if [ $? -eq 0 ]; then
            ifInstall_[$reg]=y
        else
            ifInstall_[$reg]=n
            #cwarn "====> 未安装: $reg"
        fi
    done

    # 输出哈希表
    # for reg in "${regFiles_[@]}"; do
    #     echo "$reg: ${ifInstall_[$reg]}"
    # done
}

# 2.读取config模块
register_hostname(){
    minfo "......加载Hostname配置模块......"
    # declare -n recordInstall_=$1 # 存储所有安装文件
    # declare -n recordConfig_=$2 # 存储所有config文件
    declare -a configFiles # 存储所有config文件
    local HOSTNAME=$(hostname)

    # 加载所有config文件
    cinfo "......加载所有config文件......"
    # 检查文件夹是否为空
    if [ -z "$(ls -A $CONFIGP/*.sh 2>/dev/null)" ]; then
        cwarn "config文件夹为空"
    else
        for script in $CONFIGP/*.sh; do
            scpName=$(basename "$script" .sh)
            configFiles+=("$scpName")
            source "$script"
        done
    fi

    # 检查${hostname}.sh是否存在
    if [ -f $CONFIGP/$HOSTNAME.sh ]; then
        source $CONFIGP/$HOSTNAME.sh
        csuccess "成功加载$HOSTNAME.sh"
    else
        cwarn "$HOSTNAME.sh不存在"
        if readReturn "使用空白配置[y] or 选择一个已有配置[n]";then
            csuccess "成功创建空白配置"
            return 0
        else
            cnote "当前所有配置 ${configFiles[@]}"
            readNoSpace configName "请输入选择的配置名称"
            if [[ -f $CONFIGP/$configName.sh ]]; then
                source $CONFIGP/$configName.sh
                csuccess "成功加载$configName.sh"
            else
                cerror "未找到$configName.sh"
                exit 1
            fi
        fi
    fi

    for rdi in "${recordInstall[@]}"; do
        recordInstallMap[$rdi]=y
    done

    for rdc in "${recordConfig[@]}"; do
        recordConfigMap[$rdc]=y
    done
}