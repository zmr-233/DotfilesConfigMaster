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
sudo apt install valgrind kcachegrind -y

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

#不同工具参数
MEMCHECK_FLAGS=(
    "--num-callers=40"                 # 增加调用栈的大小，可能会轻微增加内存使用和性能开销
    "--track-origins=yes"              # 跟踪未初始化值的来源，显著增加性能开销
    "--read-inline-info=yes"           # 使用内联函数的调试信息，可能增加启动时间
    "--leak-check=full"                # 进行详细的内存泄漏检测，会在程序退出时增加性能开销
    # "--show-reachable=yes"           # 显示所有仍然可达的内存块，增加程序结束时的分析时间（如果启用）
    "--leak-resolution=high"           # 高分辨率检测内存泄漏，增加检测泄漏的时间和资源开销（如果启用）
    "--trace-children=yes"             # 跟踪子进程，可能会轻微增加性能开销
)


CALLGRIND_FLAGS=(
    "--dump-instr=yes"      # 收集指令级别的信息--用于kcachegrind分析
    "--collect-jumps=yes"   # 收集条件跳转信息--用于kcachegrind分析
    "--trace-children=yes"
    "--dsymutil=yes"
)

# 整合了高亮的valgrind
valgrind_bat() {
    local stdout_tmp=$(mktemp)
    local stderr_tmp=$(mktemp)
    local combined_tmp=$(mktemp)
    local exetype=false
    local VALFLAGS=()

    if [[ "$1" = "--merge" || "$1" = "-m" ]]; then
        shift
        exetype=merge
    elif [[ "$1" = "--server" ]]; then
        shift
        exetype=server
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
            VALFLAGS=("${MEMCHECK_FLAGS[@]}")
            ;;
        callgrind)
            VALFLAGS=("${CALLGRIND_FLAGS[@]}")
            ;;
    esac

    if [ "$exetype" = "server" ]; then
        valgrind --log-socket=$(getip):$VALPORT "${VALFLAGS[@]}" "$@"
        return 0
    fi

    # 执行valgrind命令并捕获输出
    { 
      { valgrind "${VALFLAGS[@]}" "$@" 2> >(tee "$stderr_tmp" >&2); } | tee "$stdout_tmp"
    } > >(cat -v > "$combined_tmp") 2>&1 | tee -a "$combined_tmp" > /dev/null

    # 根据终端情况输出结果
    if [ -t 1 ] && [ -t 2 ] && [ "$exetype" = "merge" ]; then
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
    - include: server
    - include: memcheck
    - include: callgrind
    - match: '(==\d+==) (Copyright \(C\) \d+-\d+,.*)'
      captures:
        1: comment
        2: keyword
    - match: '(==\d+==) (Using )(Valgrind-\d+.\d+.\d+)(.*)'
      captures:
        1: comment
        2: keyword
        3: support.constant
        4: keyword
    - match: '(==\d+==) (Command: )(.+)'
      captures:
        1: comment
        2: keyword
        3: markup.bold
    - match: '(==\d+==)    (at|by)\s(0x[0-9A-Fa-f]+):\s(.+) (\(([^:]+):?\d*\))'
      captures:
        1: comment
        2: keyword
        3: constant.numeric
        4: entity.name.function
        5: storage.type
        6: variable.parameter
    - match: '(==\d+==) (ERROR SUMMARY:.+)'
      captures:
        1: comment
        2: keyword

    # Normal Match
    - match: '==\d+== (?! )' 
      scope: comment 
      push: lineA
 
    - match: '==\d+==  (?! )' 
      scope: comment 
      push: lineB 
    
    - match: '==\d+== {3,}(?! )' 
      scope: comment 
      push: lineC
    - match: '\d+'
      scope: constant.numeric
    - match: '\n'
      pop: true
  server:
    - match: '^(valgrind-listener started at)(.+)'
      captures:
        1: variable.parameter
        2: entity.name.function
    - match: '^(\()(\d+)(\)) ([\-]+.+)'
      captures:
        1: comment
        2: entity.name.function
        3: comment
        4: entity.name.function
      scope: entity.name.function
    - match: '^(\()(\d+)(\)) *(?!\-)'
      captures:
        1: comment
        2: entity.name.function
        3: comment
      push: main
  memcheck:
    - match: '(==\d+==) (Memcheck, a memory error detector)'
      captures:
        1: comment
        2: entity.name.function
  callgrind:
    - match: '(==\d+==) (Callgrind, a call-graph generating cache profiler)'
      captures:
        1: comment
        2: entity.name.function   
  lineA:
    - match: '\b(0x[0-9A-Fa-f]+|[0-9,]+)\b'
      scope: constant.numeric
    - match: '(?:(?!0x[0-9A-Fa-f]+|[0-9,]).)+'
      scope: variable
    - match: '\n'
      pop: true

  lineB:
    - match: '\b(0x[0-9A-Fa-f]+|[0-9,]+)\b'
      scope: constant.numeric
    - match: '(?:(?!0x[0-9A-Fa-f]+|[0-9,]).)+'
      scope: variable
    - match: '\n'
      pop: true
  
  lineC:
    - match: '\b(0x[0-9A-Fa-f]+|[0-9,]+)\b'
      scope: support.constant
    - match: '(?:(?!0x[0-9A-Fa-f]+|[0-9,]).)+'
      scope: string   
    - match: '\n'
      pop: true 

EOF

cat << 'EOF' >> $AFTERINSTALL
# bat必要的更新缓存操作
bat cache --build
EOF

return 0

}
