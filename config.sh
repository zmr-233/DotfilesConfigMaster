#!/bin/bash

# 设置目录信息
PWD=$(pwd)
TEMP=$PWD/temp
SRCP=$PWD/src
UTILSP=$PWD/utils
CONFIGP=$PWD/config
REGP=$PWD/regfiles
CURDOTFILES=$PWD/CURDOTFILES
HISTORYP=$PWD/history # $(hostname).$(date +%Y%m%d%H%M)

mkdir -p $TEMP
mkdir -p $SRCP
mkdir -p $UTILSP
mkdir -p $CONFIGP
mkdir -p $REGP
mkdir -p $CURDOTFILES
mkdir -p $HISTORYP

# 设置文件信息
INSTALL=$TEMP/install.sh
UPDATE=$TEMP/update.sh
UNINSTALL=$TEMP/uninstall.sh
cat << EOF | tee $INSTALL $UPDATE $UNINSTALL >/dev/null
#!/bin/bash

# 加载实用函数
for script in $UTILSP/*.sh; do
    source "\$script"
done

# 加载注册文件
for script in $REGP/*.sh; do
    source "\$script"
done
EOF

# 全局变量
declare -A allConfigMap=() # 所有配置文件

declare -a regFiles=() # 存储所有注册文件
declare -A ifInstall=() # 存储是否安装

# 用于记录安装信息
declare -a recordInstall=() # 存储所有安装文件
declare -a recordConfig=() # 存储所有config文件
declare -A recordInstallMap=() # 为了访问速度
declare -A recordConfigMap=() # 为了访问速度

# 记录升级信息
declare -a recordUpdate=() # 存储所有升级文件
declare -A recordUpdateMap=() # 为了访问速度

# 从命令行参数解析而来
declare -a INSTALL_LIST
declare -a CONFIG_LIST

SILENT_INSTALL=n # 是否静默安装
DEB=n # 是否开启调试模式
IFTEST=n # 是否模拟安装

# 加载实用函数
for script in $UTILSP/*.sh; do
    source "$script"
done

# config_single
# final_config
# final_install


zmr233tools(){
    cecho DIM "============================================================"
    echo -e "${CYAN_BOLD} _______  __ ____  ____  __________  ${YELLOW_BOLD} _____           _      ${RESET}"
    echo -e "${CYAN_BOLD}|__  /  \/  |  _ \|___ \|___ /___ /  ${YELLOW_BOLD}|_   _|__   ___ | |___  ${RESET}"
    echo -e "${CYAN_BOLD}  / /| |\/| | |_) | __) | |_ \ |_ \  ${YELLOW_BOLD}  | |/ _ \ / _ \| / __| ${RESET}"
    echo -e "${CYAN_BOLD} / /_| |  | |  _ < / __/ ___) |__) | ${YELLOW_BOLD}  | | (_) | (_) | \__ \ ${RESET}"
    echo -e "${CYAN_BOLD}/____|_|  |_|_| \_\_____|____/____/  ${YELLOW_BOLD}  |_|\___/ \___/|_|___/ ${RESET}"
    cecho DIM "============================================================"
}

welcome(){
    echo ""
    cecho CYAN_BOLD ">>>>>> 欢迎使用 DotfilesConfigMaster <<<<<<<"
    cecho CYAN_BOLD "————————————模块化管理dotfiles工具———————————"
    echo ""
}

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -n|--no|--simulate)
                IFTEST=y
                cinfo "IFTEST set to 'y'"
                ;;
            -s|--silent)
                SILENT_INSTALL=y
                cinfo "SILENT_INSTALL set to 'y'"
                ;;
            --install=*)
                IFS=',' read -r -a INSTALL_LIST <<< "${1#*=}"
                cinfo "INSTALL_LIST set to '${INSTALL_LIST[*]}'"
                ;;
            --config=*)
                IFS=',' read -r -a CONFIG_LIST <<< "${1#*=}"
                cinfo "CONFIG_LIST set to '${CONFIG_LIST[*]}'"
                ;;
            --istcfg=*|--install--config=*)
                IFS=',' read -r -a BOTH_LIST <<< "${1#*=}"
                INSTALL_LIST=("${BOTH_LIST[@]}")
                CONFIG_LIST=("${BOTH_LIST[@]}")
                cinfo "INSTALL_LIST and CONFIG_LIST set to '${BOTH_LIST[*]}'"
                ;;
            -d|--debug)
                DEB=y
                cinfo "DEB set to 'y'"
                ;;
            --all=*)
                SILENT_ALL="${1#*=}"
                cinfo "SILENT_ALL set to '${SILENT_ALL}'"
                ;;
            -h|--help)
                info_help
                exit 0
                ;;
            *)
                cerror "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
}

main() {
    zmr233tools
    welcome
    parse_args "$@"

    # 1. 加载注册文件模块
    register_regFiles regFiles ifInstall

    # --istcfg=a,b,c,d --config=a,b,c,d 选项 => 指定快速安装
    # 简单粗暴，不检查依赖关系
    if [[ ${#INSTALL_LIST[@]} -gt 0 || ${#CONFIG_LIST[@]} -gt 0 ]]; then
        minfo "指定快速安装模式: 仅用于生成install.sh，不检查任何依赖关系"

        cinfo "......自动生成安装指令ing......"
        for reg in "${INSTALL_LIST[@]}"; do
            ${reg}_install && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
        done

        cinfo "......自动生成配置文件ing......"
        for reg in "${CONFIG_LIST[@]}"; do
            ${reg}_config && csuccess "==> $reg : [y]" || cerror "==> $reg : [ERROR]"
        done

        finalgen_installsh
        exit 1
    fi

    # --all=xxx 选项 => 静默快速安装
    if [[ -n $SILENT_ALL && -f $CONFIGP/$SILENT_ALL.sh ]]; then
        minfo "--all=xxx模式: 快速静默安装"
        source $CONFIGP/$SILENT_ALL.sh
        __info__install
        __info__config
        finalgen_installsh
        $PWD/install.sh && csuccess "install.sh安装成功" || cerror "install.sh安装失败"
        exit 1
    elif [[ -n $SILENT_ALL ]];then
        cerror "没有找到此hostname文件: $SILENT_ALL.sh"
        exit 1
    fi

    # 2.加载Hostname配置模块
    register_hostname

    # .............................................................
    # 3. 交互式配置
    # .............................................................
    
    info_install_list # 打印安装信息

    minfo "......交互式配置......"
    cnote "A/1-创建注册文件"
    cnote "B/2-交互式配置/安装"
    cnote "C/3-交互式卸载"
    cnote "D/4-交互式升级"
    cnote "E/5-生成README.md"
    cnote "Q/0-退出"
    readNoSpace selecT "输入数字/大小写字符进行选择"
    case $selecT in
        A|a|1)
            readArray regNames "请输入要注册的所有软件(用空格分隔):"
            for regName in ${regNames}; do
                gen_regFile $regName
            done
            ;;
        B|b|2)
            info_config_install
            finalgen_installsh
            cwarn "强烈建议自行检查install.sh执行,否则一切后果自负! 没准你写了sudo rm -rf /*(笑) "
            if readReturn "是否不检查直接执行install.sh?"; then
                cline "YELLOW" "倒计时后执行: " && countdown 5
                minfo $'\n\n\n\n\n'"=================================执行install.sh================================="
                $PWD/install.sh && csuccess "install.sh安装成功" || cerror "install.sh安装失败"
            else
                cinfo "请手动执行 $PWD/install.sh"
            fi
            ;;
        C|c|3)
            info_uninstall
            finalgen_uninstallsh
            cwarn "强烈建议自行检查uninstall.sh执行,否则一切后果自负! 没准你写了sudo rm -rf /*(笑) "
            if readReturn "是否不检查直接执行uninstall.sh?"; then
                cline "YELLOW" "倒计时后执行: " && countdown 5
                minfo $'\n\n\n\n\n'"=================================执行uninstall.sh================================="
                $PWD/uninstall.sh && csuccess "uninstall.sh卸载成功" || cerror "uninstall.sh卸载失败"
            else
                cinfo "请手动执行 $PWD/uninstall.sh"
            fi
            ;;
        D|d|4)
            info_update
            finalgen_updatesh
            cwarn "强烈建议自行检查update.sh执行,否则一切后果自负! 没准你写了sudo rm -rf /*(笑) "
            if readReturn "是否不检查直接执行update.sh?"; then
                cline "YELLOW" "倒计时后执行: " && countdown 5
                minfo $'\n\n\n\n\n'"=================================执行update.sh================================="
                $PWD/update.sh && csuccess "update.sh升级成功" || cerror "update.sh升级成功"
            else
                cinfo "请手动执行 $PWD/update.sh"
            fi            
            ;;
        E|e|5)
            finalgen_readme
            mv $TEMP/README.md $PWD/README.md
            ;;
        Q|q|0)
            minfo "退出"
            exit 0
            ;;
        *)
            cerror "输入错误"
            exit 1
            ;;
    esac

    csuccess "==========config.sh========= END..."
}

main "$@"