#!/bin/bash

# AI药物名称纠正工具运行脚本
# 
# 使用方法:
#   ./run.sh                           # 基本运行
#   ./run.sh --thinking                # 开启思考模式
#   ./run.sh --dir /path/to/files      # 指定目录
#   ./run.sh --dir /path/to/files --thinking  # 组合使用

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查conda是否安装
check_conda() {
    if ! command -v conda &> /dev/null; then
        print_error "conda未安装或未在PATH中找到"
        print_info "请先安装Anaconda或Miniconda"
        exit 1
    fi
    print_success "conda已找到"
}

# 检查conda环境是否存在
check_conda_env() {
    local env_name="dev"
    
    if ! conda env list | grep -q "^${env_name}\s"; then
        print_error "conda环境 '${env_name}' 不存在"
        print_info "请先创建conda环境："
        echo "  conda create -n ${env_name} python=3.10"
        echo "  conda activate ${env_name}"
        echo "  pip install -r requirements.txt -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
        exit 1
    fi
    print_success "conda环境 '${env_name}' 已找到"
}

# 检查.env文件是否存在
check_env_file() {
    if [ ! -f ".env" ]; then
        print_error ".env文件不存在"
        print_info "请创建.env文件并配置以下内容："
        echo ""
        echo "OPENAI_API_KEY=your_api_key_here"
        echo "OPENAI_BASE_URL=your_api_base_url_here"
        echo ""
        exit 1
    fi
    print_success ".env文件已找到"
}

# 检查main.py是否存在
check_main_py() {
    if [ ! -f "main.py" ]; then
        print_error "main.py文件不存在"
        exit 1
    fi
    print_success "main.py文件已找到"
}

# 激活conda环境并运行脚本
run_script() {
    local env_name="dev"
    
    print_info "激活conda环境: ${env_name}"
    
    # 获取conda的base路径
    CONDA_BASE=$(conda info --base)
    source ${CONDA_BASE}/etc/profile.d/conda.sh
    
    # 激活环境
    conda activate ${env_name}
    
    if [ $? -eq 0 ]; then
        print_success "环境激活成功"
        
        # 构建命令
        cmd="python main.py"
        
        # 添加传递的参数
        if [ $# -gt 0 ]; then
            cmd="$cmd $@"
            print_info "运行命令: $cmd"
        else
            print_info "运行命令: $cmd (使用默认参数)"
        fi
        
        # 运行脚本
        eval $cmd
        
        if [ $? -eq 0 ]; then
            print_success "脚本执行完成"
        else
            print_error "脚本执行失败"
            exit 1
        fi
    else
        print_error "conda环境激活失败"
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo "AI药物名称纠正工具运行脚本"
    echo ""
    echo "使用方法:"
    echo "  ./run.sh                              # 基本运行，处理当前目录下的Excel文件"
    echo "  ./run.sh --thinking                   # 开启思考模式进行更详细处理"
    echo "  ./run.sh --dir /path/to/files         # 指定目录处理Excel文件"
    echo "  ./run.sh --dir /path/to/files --thinking  # 同时指定目录和开启思考模式"
    echo ""
    echo "注意事项:"
    echo "  - 确保已创建conda环境 'correct-drug-env'"
    echo "  - 确保.env文件包含正确的API配置"
    echo "  - Excel文件应包含药物名称数据在第一列"
    echo ""
}

# 主函数
main() {
    # 显示使用说明
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    print_info "开始运行AI药物名称纠正工具..."
    echo ""
    
    # 执行检查
    check_conda
    check_conda_env
    check_env_file
    check_main_py
    
    echo ""
    print_info "所有检查通过，开始运行脚本..."
    echo ""
    
    # 运行脚本
    run_script "$@"
}

# 运行主函数
main "$@" 