#无提醒的静默配置
__silent__install_config_all(){
    declare -g -a recordInstall=() # 存储所有安装文件
    declare -g -a recordConfig=() # 存储所有config文件
    # 强制静默所有文件
    for reg in "${regFiles[@]}"; do
        if cmdCheck "${reg}_install"; then
            recordInstall+=("$reg")
        fi
        if cmdCheck "${reg}_config"; then
            recordConfig+=("$reg")
        fi
    done
    __info__install
    __info__config    
}

__silent__config_hostname_all(){
    if [[ ${#recordConfig[@]} -eq 0 ]]; then
        cerror "recordConfig为空--请检查\$hostname.sh文件是否被正确读取"
        return
    fi
    __info__config 
}