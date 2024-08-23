#!/bin/bash

# VERSION: 1

valgrind_info(){
    echo "用于检测程序中的内存错误和性能问题的工具"
}

valgrind_deps(){
    echo "__predeps__ bat"
}
valgrind_check(){
cmdCheck "valgrind"
return $?
}


valgrind_install(){
genSignS "valgrind" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装valgrind......"
if valgrind_check; then
    cwarn "valgrind已经安装，不再执行安装操作"
else
sudo apt install valgrind -y

fi
EOF
genSignE "valgrind" $INSTALL
}

valgrind_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc .valgrindsh"
    [".config/bat/syntaxes"]="valgrind.sublime-syntax"
)
# 注意:使用.valgrindrc会导致valgrind当成参数进行解析
# 此处使用.valgrindsh

add_configMap config_map

# 配置文件 ./.zshrc
genSignS valgrind $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# 加载valgrind启动脚本
[ -f ~/.valgrindsh ] && source ~/.valgrindsh
EOF
genSignE valgrind $TEMP/./.zshrc

# 配置文件 ./.valgrindsh
cat << 'EOF' >> $TEMP/./.valgrindsh
# 该文件为valgrind的配置选项

VALPORT=1500 # 监听的默认端口

# 定义不同工具的参数
typeset -A MEMCHECK_FLAGS=(
    "--num-callers" "40"
    "--track-origins" "yes"
    "--read-inline-info" "yes"
    "--leak-check" "full"
    "--show-reachable" "yes"
    "--leak-resolution" "high"
    "--trace-children" "yes"
)

typeset -A CALLGRIND_FLAGS=(
    "--dump-instr" "yes"
    "--collect-jumps" "yes"
    "--trace-children" "yes"
)

# 整合了高亮的valgrind
valgrind_bat() {
    # 检查当前shell是否为zsh==目前数组定义方式只能在zsh下使用
    if [[ -z "$ZSH_VERSION" ]]; then
        echo "Error: This script requires Zsh to run." >&2
        exit 1
    fi
    local stdout_tmp=$(mktemp)
    local stderr_tmp=$(mktemp)
    local combined_tmp=$(mktemp)
    local merge=false
    local VALFLAGS=()

    if [[ "$1" = "--merge" || "$1" = "-m" ]]; then
        shift
        merge=true
    elif [[ "$1" = "--server" ]]; then
        shift
        valgrind --log-socket=$(getip):$VALPORT "${VALFLAGS[@]}" "$@"
        return 0
    fi

    # 检测工具类型
    local tool="memcheck"  # 默认工具
    for arg in "$@"; do
        if [[ "$arg" == "--tool="* ]]; then
            tool="${arg#--tool=}"
            break
        fi
    done

    # 设置对应工具的参数
    case "$tool" in
        memcheck)
            for key value in "${(@kv)MEMCHECK_FLAGS}"; do
                VALFLAGS+=("$key=$value")
            done
            ;;
        callgrind)
            for key value in "${(@kv)CALLGRIND_FLAGS}"; do
                VALFLAGS+=("$key=$value")
            done
            ;;
    esac

    # 执行valgrind命令并捕获输出
    { 
      { valgrind "${VALFLAGS[@]}" "$@" 2> >(tee "$stderr_tmp" >&2); } | tee "$stdout_tmp"
    } > >(cat -v > "$combined_tmp") 2>&1 | tee -a "$combined_tmp" > /dev/null

    # 根据终端情况输出结果
    if [ -t 1 ] && [ -t 2 ] && [ "$merge" = "true" ]; then
        cat "$combined_tmp" | bat --language=valgrind
    else
        if [ -t 1 ]; then
            cat "$stdout_tmp" | bat --paging=always
        else
            cat "$stdout_tmp"
        fi

        if [ -t 2 ]; then
            cat "$stderr_tmp" | bat --language=valgrind >&2
        else
            cat "$stderr_tmp" >&2
        fi
    fi

    # 清理临时文件
    rm "$stdout_tmp" "$stderr_tmp" "$combined_tmp"
}

VALSERVERFLAGS=( # "--exit-at-zero"        #  当连接进程数降为零时不退出
)

# 启动监听服务器
valgrind_server(){
    local curPORT=${1:-$VALPORT}
    local log_file=$(mktemp)

    # 输出重定向到临时文件
    valgrind-listener $curPORT "${VALSERVERFLAGS[@]}" > "$log_file" &

    # 使用 tail -f 来监视日志文件，并通过 bat 输出带颜色的日志
    # 来源: https://github.com/sharkdp/bat/blob/master/doc/README-zh.md#tail--f
    tail -f "$log_file" | bat --paging=never --language=valgrind
}
# 用bat给valgrind彩色输出的别名
alias val=valgrind_bat
# 启动监听服务器
alias valserver=valgrind_server

EOF

# 配置文件 .config/bat/syntaxes/valgrind.sublime-syntax 
cat << 'EOF' >> $TEMP/.config/bat/syntaxes/valgrind.sublime-syntax
%YAML 1.2

---

name: valgrind
file_extensions:
  - val
  - valgrind
scope: source.val
first_line_match: '==\d+=='

variables:
  basic_types: 'asm|__asm__|auto|bool|_Bool|char|_Complex|double|float|_Imaginary|int|long|short|signed|unsigned|void'

contexts:
  main:
    - match: '^==\d+== Copyright \(C\) \d+-\d+,.*'
      scope: comment
    - match: '^(==\d+==) (Using )(Valgrind-\d+.\d+.\d+)(.*)'
      captures:
        1: comment
        2: keyword
        3: support.constant
        4: keyword
    - match: '^(==\d+==) (Command: )(.+)'
      captures:
        1: comment
        2: keyword
        3: markup.bold
    - match: '^(==\d+==) ([^ ].*)'
      captures:
        1: comment
        2: keyword   
    - match: '^(==\d+==)  ([^ ].*)'
      captures:
        1: comment
        2: markup.changed    

    # 匹配函数调用及内存地址
    - match: '(at|by)\s(0x[0-9A-F]+):\s(.+)\s(\(([^:]+):?(\d*)\))'
      captures:
        1: keyword
        2: constant.numeric
        3: entity.name.function
        4: storage.type
        5: variable.parameter

    - match: ==\d+==
      scope: comment

    # 匹配内存错误类型
    - match: 'Conditional jump or move depends on uninitialised value\(s\)'
      scope: invalid
      comment: "匹配未初始化值导致的条件跳转或移动"

    - match: 'Use of uninitialised value of size \d+'
      scope: invalid

    - match: 'Invalid (free|read|write) of size \d+'
      scope: invalid

    - match: 'Mismatched free\(\)'
      scope: invalid

    - match: 'Address 0x[0-9A-Fa-f]+ is \d+ bytes inside a block of size \d+ free.?d'
      scope: invalid

    # 匹配堆内存摘要部分
    - match: 'HEAP SUMMARY:'
      scope: markup.heading

    - match: 'total heap usage: \d+ allocs, \d+ frees, \d+ bytes allocated'
      scope: markup.bold

    - match: 'LEAK SUMMARY:'
      scope: markup.heading

    - match: 'definitely lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'indirectly lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'possibly lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'still reachable: \d+ bytes in \d+ blocks'
      scope: markup.inserted

    - match: 'suppressed: \d+ bytes in \d+ blocks'
      scope: markup.changed

    # 内存地址匹配
    - match: '0x[0-9A-Fa-f]+'
      scope: constant.numeric

    # 匹配错误摘要部分
    - match: 'ERROR SUMMARY: \d+ errors from \d+ contexts \(suppressed: \d+ from \d+\)'
      scope: message.error

    - match: 'Rerun with --leak-check=full to see details of leaked memory'
      scope: keyword
    - match: 'Use --track-origins=yes to see where uninitialised values come from'
      scope: keyword    
    - match: 'For lists of detected and suppressed errors, rerun with: -s'
      scope: keyword 
    # 匹配数字
    - match: '\d+'
      scope: constant.numeric

EOF

cat << 'EOF' >> $AFTERINSTALL
# bat必要的更新缓存操作
bat cache --build
EOF
return 0
}
