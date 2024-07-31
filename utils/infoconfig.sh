#!/bin/bash

# check_recordInstall(){
#     # declare -n recordInstall=$1
#     # declare -n ifInstall=$2
#     declare -i ifER=0
#     for reg in "${recordInstall[@]}"; do
#         if [[ -z ${ifInstall[$reg]} || ${ifInstall[$reg]} == "0" ]]; then
#             cerr "==> $reg : NOT INSTALLED"
#             ifER=$((ifER+1))
#         else
#             cinfo "==> $reg : INSTALLED"
#         fi
#     done

#     return $ifER
# }

# check_deps(){
#     # declare -n ifInstall=$1
#     local depL=$1
#     local ifER=0

#     for cmd in $depL; do
#         if [[ -z ${ifInstall[$cmd]} || ${ifInstall[$cmd]} == "0" ]]; then
#             if !cmdCheck $cmd; then
#                 cerror "未找到命令: $cmd"
#                 ifER=1
#             fi
#         fi
#     done
#     return $ifER
# }




# 带提示的安装配置函数
__info__install_select(){
    local sinName=$1
    finfo ".....处理 $sinName......"
    local status=0

    if [[ -f $REGP/$sinName.sh ]]; then
        source $REGP/$sinName.sh
        cinfo "==> 已成功加载注册文件: $REGP/$sinName.sh"

        ${sinName}_check

        if [[ -n ${ifInstall[$sinName]} && ${ifInstall[$sinName]} = "y" ]]; then
            cinfo "==> $sinName : [y]"
            status=0
        else
            cwarn "==> $sinName : [n]"
            status=1
            if [[ $SILENT_INSTALL == "n" ]]; then
                readBool ifins "是否安装 $sinName?"
                if [[ $ifins == y ]]; then
                    status=2
                fi
            else
                status=2
            fi
        fi
    else
        cwarn "未找到注册文件 $REGP/$sinName.sh"
        if [[ $SILENT_INSTALL == "n" ]]; then
            readBool ifins "请自行判断：该软件是否已经安装?"
            if [[ $ifins == y ]]; then
                status=3
            else
                status=4
                readBool ifins "是否需要安装?"
                if [[ $ifins == y ]]; then
                    status=5
                fi
            fi
        else
            status=5
        fi
    fi

    if [[ $status -ge 3 ]]; then
        if readReturn "是否需要生成注册文件?"; then
            gen_regFile $sinName
            source $REGP/$sinName.sh
        else
            cerror "未生成注册文件，无法安装 $sinName"
            exit 1
        fi
    fi

    # 安装
    if [[ $status -eq 2 || $status -eq 5 ]]; then
        cinfo "......安装 $sinName......"
        if [[ -n ${recordInstallMap[$sinName]} ]]; then
            cerror "==> 已在列表显示未安装，是不是卸载后没有记录信息?"
            
            if readReturn "是继续安装[y]？还是不安装[n]";then
                cinfo "继续安装 $sinName"
            else 
                deleteFromArray recordInstall $sinName recordInstallMap
                cinfo "已删除 $sinName"
                return 0
            fi
        else
            cinfo "添加 $sinName 到安装列表recordInstall"
            recordInstall+=("$sinName")
            recordInstallMap[$sinName]=1
        fi
    fi
    if [[ $status -eq 0 || $status -eq 3 ]]; then

        if [[ -z ${recordInstallMap[$sinName]} ]]; then
            cerror "已安装,但未出现在安装列表recordInstall...自动添加"
            recordInstall+=("$sinName")
            recordInstallMap[$sinName]=1
        fi
    fi
    # [ "$DEB" = "y" ] && cdebug "status: $status "
    # [ "$DEB" = "y" ] && saveMap recordInstallMap

    # 配置
    cinfo "......自动生成配置 $sinName......"
    # if [[ $status -eq 0 || $status -eq 3 ]]; then
    #     cwarn "检测到已经安装，是否仍然进行配置?"
    # fi
    if inArray recordConfig $sinName; then
        cinfo "==> 检测到已在配置列表recordConfig"
    else
        if [[ $SILENT_INSTALL == "n" ]]; then
            if readReturn "是否自动生成配置?(写入配置列表recordConfig)"; then
                recordConfig+=("$sinName")
            fi
        else
            recordConfig+=("$sinName")
        fi
    fi
}

# 带提示的卸载配置函数
__info__uninstall_select(){
    local sinName=$1
    finfo ".....处理卸载 $sinName......"
    local status=0

    if [[ -f $REGP/$sinName.sh ]]; then
        source $REGP/$sinName.sh
        cinfo "==> 已成功加载注册文件: $REGP/$sinName.sh"

        ${sinName}_check

        if [[ -n ${ifInstall[$sinName]} && ${ifInstall[$sinName]} = "y" ]]; then
            cinfo "==> $sinName : [y]"
            status=0
        else
            cwarn "==> $sinName : [n]"
            status=1
        fi
    else
        cwarn "未找到注册文件 $REGP/$sinName.sh"
        status=2
    fi

    if [[ $status -eq 1 ]]; then
        cwarn "该$sinName未安装,无法卸载"
        if inArray recordConfig $sinName; then
            cinfo "检测到仍然在配置列表recordConfig中,是否需要删除该配置?"
            cnote "^^^^^^意味着你可能手动删除了，但是没有删除配置文件^^^^^^"
            if readReturn "是否删除配置?"; then
                deleteFromArray recordConfig $sinName
                return 0
            else
                return 0
            fi
        else
            return 0
        fi
    fi

    
    if [[ $status -eq 0 ]]; then
        if [[ -n ${recordInstallMap[$sinName]} ]]; then
            if readReturn "是否确认卸载 $sinName?"; then
                cinfo "卸载 $sinName"
                deleteFromArray recordInstall $sinName recordInstallMap

                if inArray recordConfig $sinName; then
                    cinfo "==> 检测到在配置列表recordConfig中，执行删除配置"
                    deleteFromArray recordConfig $sinName
                fi
            else
                cinfo "取消卸载 $sinName"
                return 0
            fi
        else
            cerror "==> $sinName 就不在安装列表recordInstall中，直接退出"
            cnote "^^^^^^^^^^^奇了怪了，你还要删一个就没安装过的东西？"
            return 0
        fi
    fi

    if [[ $status -eq 2 ]]; then
        cwarn "==> 无法卸载 $sinName，因为未找到注册文件"
    fi
}

__info__update_select(){
    local sinName=$1
    finfo ".....处理更新 $sinName......"
    local status=0

    if [[ -f $REGP/$sinName.sh ]]; then
        source $REGP/$sinName.sh
        cinfo "==> 已成功加载注册文件: $REGP/$sinName.sh"

        ${sinName}_check

        if [[ -n ${ifInstall[$sinName]} && ${ifInstall[$sinName]} = "y" ]]; then
            cinfo "==> $sinName : [y]"
            status=0
        else
            cwarn "==> $sinName : [n]"
            status=1
        fi
    else
        cwarn "未找到注册文件 $REGP/$sinName.sh"
        status=2
    fi

    if [[ $status -eq 0 ]]; then
        if readReturn "是否更新 $sinName?"; then
            cinfo "更新 $sinName"
            if [[ -z ${recordUpdateMap[$sinName]} ]]; then
                cinfo "添加 $sinName 到更新列表recordUpdate"
                recordUpdate+=("$sinName")
                recordUpdateMap[$sinName]=1
            fi
        else
            cinfo "跳过更新 $sinName"
        fi
    elif [[ $status -eq 1 ]]; then
        cwarn "该 $sinName 未安装，无法更新"
    elif [[ $status -eq 2 ]]; then
        cwarn "未找到注册文件，无法更新 $sinName"
    fi
}

__info__install(){
    declare -A ifIns

    minfo "......自动生成安装指令ing......"
    if [[ ${#recordInstall[@]} -eq 0 ]]; then
        cwarn "无任何生成安装指令任务"
        return 0
    fi

    # 解析依赖关系
    register_regFiles recordInstall ifIns

    for reg in "${regFiles[@]}"; do
        if [[ ${ifIns[$reg]} -eq 0 ]]; then
            ${reg}_install && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
        fi
    done
}


__info__uninstall(){
    minfo "......自动生成卸载指令ing......"
    if [[ ${#recordInstall[@]} -eq 0 ]]; then
        cwarn "无任何生成卸载指令任务"
        return 0
    fi

    for reg in "${recordInstall[@]}"; do
        ${reg}_uninstall && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
    done
}

__info__config(){
    minfo "......自动生成配置文件ing......"
    if [[ ${#recordConfig[@]} -eq 0 ]]; then
        cerror "无任何生成配置文件任务"
        return 0
    fi
    # 生成配置文件
    for reg in "${recordConfig[@]}"; do
        ${reg}_config && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
    done
}

__info__update(){
    minfo "......自动生成更新指令ing......"
    if [[ ${#recordUpdate[@]} -eq 0 ]]; then
        cwarn "无任何生成更新指令任务"
        return 0
    fi

    # 遍历需要更新的软件列表
    for reg in "${recordUpdate[@]}"; do
        if type "${reg}_update" &>/dev/null; then
            # 如果存在对应的更新函数，则调用之
            ${reg}_update && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
        else
            # 如果不存在对应的更新函数，打印错误信息
            cerror "未找到 $reg 的更新函数"
        fi
    done
}

info_config_install(){
    readArray sinNames "请输入要配置/安装的所有软件(用空格分隔):"
    [ "$DEB" = "y" ] && cdebug "sinNames: ${sinNames[*]}"
    for sinName in "${sinNames[@]}"; do
        __info__install_select $sinName
    done    
    __info__install
    __info__config
}

info_uninstall(){
    readArray sinNames "请输入要卸载的所有软件(用空格分隔):"
    [ "$DEB" = "y" ] && cdebug "sinNames: ${sinNames[*]}"
    for sinName in "${sinNames[@]}"; do
        __info__uninstall_select $sinName
    done
    __info__uninstall
    __info__config
}

info_update(){
    minfo "......自动生成更新指令ing......"
    if readReturn "是否一键升级所有软件?";then
        declare -g -a recordUpdate=("${recordInstall[@]}")
    else
        readArray sinNames "请输入要更新的所有软件(用空格分隔):"
        [ "$DEB" = "y" ] && cdebug "sinNames: ${sinNames[*]}"
        for sinName in "${sinNames[@]}"; do
            __info__update_select $sinName
        done
    fi
    __info__update
}

#====   Help Function   ====
info_help() {
  cnote "Usage: script.sh [OPTIONS]"
  cinput "Options:"
  cinfo "  -n, --no, --simulate        Set IFTEST=y"
  cinfo "  -s, --silent                Set SILENT_INSTALL=y"
  cinfo "  --install=a,b,c,d           Add a, b, c, d to INSTALL_LIST array"
  cinfo "  --config=a,b,c,d            Add a, b, c, d to CONFIG_LIST array"
  cinfo "  --istcfg=a,b,c,d            Add a, b, c, d to both INSTALL_LIST and CONFIG_LIST arrays"
  cinfo "  --install--config=a,b,c,d   Add a, b, c, d to both INSTALL_LIST and CONFIG_LIST arrays"
  cinfo "  --debug                     Set DEB=y"
  cinfo "  --all=xxx                   Set SILENT_ALL=xxx"
  cinfo "  -h, --help                  Display this help message"
}

# 打印安装信息
info_install_list() {
    minfo "......显示安装信息......"
    local count=0
    local max_per_line=4

    finfo "========$(hostname)安装检测========"
    for item in "${recordInstall[@]}"; do
        # 每输出4个项后换行
        if (( count % max_per_line == 0 )) && (( count > 0 )); then
            echo "" # 新行
            cline "DIM" "==> "
        elif (( count  == 0 )); then
            cline "DIM" "==> "
        fi

        # 检查是否安装
        if [[ ${ifInstall[$item]} == "y" ]]; then
            # 检查理论上是否应该安装
            if [[ -n ${recordInstallMap[$item]} ]]; then
                # 检查是否配置
                if [[ -n ${recordConfigMap[$item]} ]]; then
                    cline "GREEN_BOLD" "$item : [y]   "
                else
                    echo ""
                    cwarn "==> $item : [y]-配置信息缺失"
                    count=-1
                fi
            else
                echo ""
                cwarn "==> 你的$(hostname).sh说你安装了，但是实际上没有装: $item"
                count=-1
            fi
        else
            # 未安装
            if [[ -n ${recordInstallMap[$item]} ]]; then
                cline "RED_BOLD" "$item : [n]   "
            else
                echo ""
                cwarn "==> 你实际上安装了，但是没有配置在$(hostname).sh中: $item"
                count=-1 
            fi
        fi

        ((count++))
    done
    # 处理额外的项（如果有）
    echo ""
    finfo "========其余未安装项========"
    count=0

    for item in "${regFiles[@]}"; do
        # 每输出4个项后换行
        if (( count % max_per_line == 0 )) && (( count > 0 )); then
            echo "" # 新行
            cline "DIM" "==> "
        elif (( count  == 0 )); then
            cline "DIM" "==> "
        fi
        # 跳过已经存在于recordInstallMap的项
        if [[ -z ${recordInstallMap[$item]} ]]; then
            # 检查是否安装
            if [[ ${ifInstall[$item]} == "y" ]]; then
                echo ""
                cwarn "==> 你实际上安装了，但是没有配置在$(hostname).sh中: $item"
                count=-1
            else
                cline "RED" "$item : [n]   "
            fi
        fi

        ((count++))
    done
    
    echo ""
}