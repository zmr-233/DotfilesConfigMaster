#!/bin/bash

__pre_OPWD=$(pwd)
script_dir=$(dirname "$0")
cd $script_dir

# 设置目录信息
OPWD=$(pwd)
TEMP=$OPWD/temp
SRCP=$OPWD/src
UTILSP=$OPWD/utils
CONFIGP=$OPWD/config
REGP=$OPWD/regfiles
CURDOTFILES=$OPWD/CURDOTFILES
BACKUPP=$OPWD/backup # $(hostname).$(date +%Y%m%d%H%M)

mkdir -p $TEMP
mkdir -p $SRCP
mkdir -p $UTILSP
mkdir -p $CONFIGP
mkdir -p $REGP
mkdir -p $CURDOTFILES
mkdir -p $BACKUPP

# 设置文件信息
INSTALL=$TEMP/install.sh
AFTERINSTALL=$TEMP/installafter.sh
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

# 设置代理
if ! checkCmd "proxy";then
    MODULE_INFO "......加载系统代理......."  
    if readReturn "未检测到WSL2用于从宿主代理中获得代理的proxy()函数，请确认是否设置代理";then
        readNoSpace port_n "请输入宿主代理端口号"
        export HOST_IP=$(ip route | grep default | awk '{print $3}');
        export PROXY_PORT=$port_n;
        export {all_proxy,ALL_PROXY}="socks5://${HOST_IP}:${PROXY_PORT}";
        export {ftp_proxy,FTP_PROXY}="http://${HOST_IP}:${PROXY_PORT}";
        export {http_proxy,HTTP_PROXY}="http://${HOST_IP}:${PROXY_PORT}";
        export {https_proxy,HTTPS_PROXY}="http://${HOST_IP}:${PROXY_PORT}";        
        alias sudop='sudo --preserve-env=all_proxy,ALL_PROXY,ftp_proxy,FTP_PROXY,http_proxy,HTTP_PROXY,https_proxy,HTTPS_PROXY'
        alias sudo='sudop'
    fi
fi

ISCONFIG=y # Bug:用于checkCfg的判断困难问题
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
SILENT_HOSTNAME=n # 完全静默安装hostname.sh
DEB=n # 是否开启调试模式
IFTEST=n # 是否模拟安装
FINAL_EXECUTE=""

# 加载实用函数
for script in $UTILSP/*.sh; do
    source "$script"
done

# config_single
# final_config
# final_install

# 用于执行最后的操作
final_execute(){
    local CHFLAG=$1
    if [[ -z $FINAL_EXECUTE ]]; then
        return
    fi
    if [ -n $CHFLAG ] && [ "$CHFLAG" = "DO_NOT_CHECK" ];then
        MODULE_INFO $'\n\n\n\n\n'"=================================执行$FINAL_EXECUTE.sh================================="
        $OPWD/$FINAL_EXECUTE.sh && SUCCESS "$FINAL_EXECUTE.sh执行完成" || ERROR "$FINAL_EXECUTE.sh执行失败"
    else
        WARN "强烈建议自行检查$FINAL_EXECUTE.sh执行,否则一切后果自负! 没准你写了sudo rm -rf /*(笑) "
        if readReturn "是否不检查直接执行$FINAL_EXECUTE.sh?"; then
            nECHO "YELLOW" "倒计时后执行: " && countdown 2
            MODULE_INFO $'\n\n\n\n\n'"=================================执行$FINAL_EXECUTE.sh================================="
            $OPWD/$FINAL_EXECUTE.sh && SUCCESS "$FINAL_EXECUTE.sh执行完成" || ERROR "$FINAL_EXECUTE.sh执行失败"
        else
            INFO "请手动执行 $OPWD/$FINAL_EXECUTE.sh"
        fi
    fi
    FINAL_EXECUTE=""
}

zmr233tools(){
    ECHO DIM "============================================================"
    echo -e "${CYAN_BOLD} _______  __ ____  ____  __________  ${YELLOW_BOLD} _____           _      ${RESET}"
    echo -e "${CYAN_BOLD}|__  /  \/  |  _ \|___ \|___ /___ /  ${YELLOW_BOLD}|_   _|__   ___ | |___  ${RESET}"
    echo -e "${CYAN_BOLD}  / /| |\/| | |_) | __) | |_ \ |_ \  ${YELLOW_BOLD}  | |/ _ \ / _ \| / __| ${RESET}"
    echo -e "${CYAN_BOLD} / /_| |  | |  _ < / __/ ___) |__) | ${YELLOW_BOLD}  | | (_) | (_) | \__ \ ${RESET}"
    echo -e "${CYAN_BOLD}/____|_|  |_|_| \_\_____|____/____/  ${YELLOW_BOLD}  |_|\___/ \___/|_|___/ ${RESET}"
    ECHO DIM "============================================================"
}

welcome(){
    echo ""
    ECHO CYAN_BOLD ">>>>>> 欢迎使用 DotfilesConfigMaster <<<<<<<"
    ECHO CYAN_BOLD "————————————模块化管理dotfiles工具———————————"
    echo ""
}

info_help() {
  NOTE "Usage: script.sh [OPTIONS]"
  INPUT "Options:"
  INFO "  -n, --no, --simulate        Set IFTEST=y"
  INFO "  -s, --silent                Set SILENT_INSTALL=y"
  INFO "  -S, --silent-hostname       Do silently execute hostname.sh"
  INFO "  --install=a,b,c,d           Add a, b, c, d to INSTALL_LIST array"
  INFO "  --config=a,b,c,d            Add a, b, c, d to CONFIG_LIST array"
  INFO "  --istcfg=a,b,c,d            Add a, b, c, d to both INSTALL_LIST and CONFIG_LIST arrays"
  INFO "  --install--config=a,b,c,d   Add a, b, c, d to both INSTALL_LIST and CONFIG_LIST arrays"
  INFO "  --debug                     Set DEB=y"
  INFO "  --all=xxx                   Set SILENT_ALL=xxx"
  INFO "  -h, --help                  Display this help message"
}

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -n|--no|--simulate)
                IFTEST=y
                INFO "IFTEST set to 'y'"
                ;;
            -s|--silent)
                SILENT_INSTALL=y
                INFO "SILENT_INSTALL set to 'y'"
                ;;
            -S|--silent-hostname)
                SILENT_HOSTNAME=y
                INFO "SILENT_HOSTNAME set to 'y'"
                ;;
            --install=*)
                IFS=',' read -r -a INSTALL_LIST <<< "${1#*=}"
                INFO "INSTALL_LIST set to '${INSTALL_LIST[*]}'"
                ;;
            --config=*)
                IFS=',' read -r -a CONFIG_LIST <<< "${1#*=}"
                INFO "CONFIG_LIST set to '${CONFIG_LIST[*]}'"
                ;;
            --istcfg=*|--install--config=*)
                IFS=',' read -r -a BOTH_LIST <<< "${1#*=}"
                INSTALL_LIST=("${BOTH_LIST[@]}")
                CONFIG_LIST=("${BOTH_LIST[@]}")
                INFO "INSTALL_LIST and CONFIG_LIST set to '${BOTH_LIST[*]}'"
                ;;
            -d|--debug)
                DEB=y
                INFO "DEB set to 'y'"
                ;;
            --all=*)
                SILENT_ALL="${1#*=}"
                INFO "SILENT_ALL set to '${SILENT_ALL}'"
                ;;
            -h|--help)
                info_help
                exit 0
                ;;
            --zmr233)
                ZMR_TEST=y;DEB=y
                WARN "zmr233测试安装模式--警告：是用来测试虚拟机的"
                exit 0
                ;;
            *)
                ERROR "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
}

other_methods(){
    while true; do
        MODULE_INFO "......其他特殊操作......"
        NOTE "这些特殊函数基本上不具有可移植性，纯粹是为了zmr233方便装机而服务的"
        ECHO YELLOW_BOLD "A/1-更换清华源"
        ECHO YELLOW_BOLD "B/2-为github生成ssh密钥对"
        ECHO YELLOW_BOLD "C/3-无条件安装+配置整个regFiles"
        ECHO YELLOW_BOLD "D/4-无条件仅配置\$hostname.sh"
        ECHO YELLOW_BOLD "Q/0-退出"
        readNoSpace selecT "输入数字/大小写字符进行选择"
        
        case $selecT in
            A|a|1)
                __predeps___change_repository
                ;;
            B|b|2)
                ssh_githubssh
                ;;
            C|c|3)
                __silent__install_config_all
                finalgen_installsh
                FINAL_EXECUTE="install"
                ;;
            D|d|4)
                __silent__config_hostname_all
                finalgen_installsh
                FINAL_EXECUTE="install"
                ;;
            Q|q|0)
                MODULE_INFO "退出"
                break
                ;;
            *)
                ERROR "输入错误，请重新输入"
                ;;
        esac
        final_execute
    done
    # 覆盖install.sh
    # if [[ -f $fileName ]]; then
    #     safeOverwrite install.sh $TEMP $OPWD
    # fi
    # chmod +x $OPWD/install.sh
}

main() {
    zmr233tools
    welcome
    parse_args "$@"

    # 1. 加载注册文件模块
    register_regFiles regFiles ifInstall

    # --zmr233模式--用来测试安装虚拟机的
    if [[ -n $ZMR_TEST ]]; then
        MODULE_INFO "zmr233测试安装模式"
        __test__do_not_run_in_your_pc
        exit 1
    fi

    # --istcfg=a,b,c,d --config=a,b,c,d 选项 => 指定快速安装
    # 简单粗暴，不检查依赖关系
    if [[ ${#INSTALL_LIST[@]} -gt 0 || ${#CONFIG_LIST[@]} -gt 0 ]]; then
        MODULE_INFO "指定快速安装模式: 仅用于生成install.sh，不检查任何依赖关系"

        INFO "......自动生成安装指令ing......"
        for reg in "${INSTALL_LIST[@]}"; do
            ${reg}_install && SUCCESS "==> $reg : [y]" || ERROR "==> $reg : [ERROR]"
        done

        INFO "......自动生成配置文件ing......"
        for reg in "${CONFIG_LIST[@]}"; do
            ${reg}_config && SUCCESS "==> $reg : [y]" || ERROR "==> $reg : [ERROR]"
        done

        finalgen_installsh
        exit 1
    fi

    # --all=xxx 选项 => 静默快速安装
    if [[ -n $SILENT_ALL && -f $CONFIGP/$SILENT_ALL.sh ]]; then
        MODULE_INFO "--all=xxx模式: 快速静默安装+配置指定hostname.sh所有内容"
        source $CONFIGP/$SILENT_ALL.sh
        __info__install
        __info__config
        finalgen_installsh
        $OPWD/install.sh && SUCCESS "install.sh安装成功" || ERROR "install.sh安装失败"
        exit 1
    elif [[ -n $SILENT_ALL ]];then
        ERROR "没有找到此hostname文件: $SILENT_ALL.sh"
        exit 1
    fi

    # 2.加载Hostname配置模块
    register_hostname

    
    if [ "$SILENT_HOSTNAME" = "y" ];then
        MODULE_INFO "执行完全静默安装hostname.sh"
        __silent__config_hostname_all
        finalgen_installsh
        FINAL_EXECUTE="install"
        final_execute "DO_NOT_CHECK"
        exit 0
    fi
    # .............................................................
    # 3. 交互式配置
    # .............................................................
    while true; do # 一次循环后默认就退出了
        info_install_list # 打印安装信息
        MODULE_INFO "......交互式配置......"
        ECHO YELLOW_BOLD "A/1-创建注册文件"
        ECHO YELLOW_BOLD "B/2-交互式配置/安装"
        ECHO YELLOW_BOLD "C/3-交互式卸载"
        ECHO YELLOW_BOLD "D/4-交互式升级"
        ECHO YELLOW_BOLD "E/5-生成README.md"
        ECHO YELLOW_BOLD "Z-其他特殊操作"
        ECHO YELLOW_BOLD "Q/0-退出"
        readNoSpace selecT "输入数字/大小写字符进行选择"
        case $selecT in
            A|a|1)
                readArray regNames "请输入要注册的所有软件(用空格分隔):"
                for regName in "${regNames[@]}"; do
                    gen_regFile $regName
                done
                ;;
            B|b|2)
                info_config_install
                finalgen_installsh
                FINAL_EXECUTE="install"
                ;;
            C|c|3)
                info_uninstall
                finalgen_uninstallsh
                FINAL_EXECUTE="uninstall"
                ;;
            D|d|4)
                info_update
                finalgen_updatesh
                FINAL_EXECUTE="update"        
                ;;
            E|e|5)
                finalgen_readme
                mv $TEMP/README.md $OPWD/README.md
                ;;
            Z|z)
                other_methods        
                ;;
            Q|q|0)
                MODULE_INFO "退出"
                break
                ;;
            *)
                ERROR "输入错误"
                ;;
        esac
        final_execute
    done
    SUCCESS "==========config.sh========= END..."
}

main "$@"

cd $__pre_OPWD # 返回原目录