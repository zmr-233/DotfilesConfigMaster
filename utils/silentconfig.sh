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