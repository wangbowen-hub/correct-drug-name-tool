@echo off
:: AI药物名称纠正工具运行脚本 (Windows版本)
:: 
:: 使用方法:
::   双击run.bat                        # 基本运行
::   run.bat --thinking                  # 开启思考模式
::   run.bat --dir "C:\path\to\files"    # 指定目录
::   run.bat --dir "C:\path\to\files" --thinking  # 组合使用

setlocal enabledelayedexpansion

:: 设置控制台编码为UTF-8
chcp 65001 >nul

:: 颜色定义（Windows ANSI转义序列）
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: 打印带颜色的消息函数
goto :skip_functions

:print_info
echo %BLUE%[信息]%NC% %~1
goto :eof

:print_success
echo %GREEN%[成功]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[警告]%NC% %~1
goto :eof

:print_error
echo %RED%[错误]%NC% %~1
goto :eof

:show_usage
echo.
echo AI药物名称纠正工具运行脚本 (Windows版本)
echo.
echo 使用方法:
echo   双击run.bat                           # 基本运行，处理当前目录下的Excel文件
echo   run.bat --thinking                    # 开启思考模式进行更详细处理
echo   run.bat --dir "C:\path\to\files"      # 指定目录处理Excel文件
echo   run.bat --dir "C:\path\to\files" --thinking  # 同时指定目录和开启思考模式
echo.
echo 注意事项:
echo   - 确保已创建conda环境 'correct-drug-env'
echo   - 确保.env文件包含正确的API配置
echo   - Excel文件应包含药物名称数据在第一列
echo.
pause
goto :eof

:check_conda
call :print_info "检查conda是否安装..."
where conda >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "conda未安装或未在PATH中找到"
    call :print_info "请先安装Anaconda或Miniconda"
    echo.
    pause
    exit /b 1
)
call :print_success "conda已找到"
goto :eof

:check_conda_env
call :print_info "检查conda环境是否存在..."
set "env_name=correct-drug-env"

conda env list | findstr /r "^%env_name%\s" >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "conda环境 '%env_name%' 不存在"
    call :print_info "请先创建conda环境："
    echo   conda create -n %env_name% python=3.10
    echo   conda activate %env_name%
    echo   pip install -r requirements.txt -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
    echo.
    pause
    exit /b 1
)
call :print_success "conda环境 '%env_name%' 已找到"
goto :eof

:check_env_file
call :print_info "检查.env文件是否存在..."
if not exist ".env" (
    call :print_error ".env文件不存在"
    call :print_info "请创建.env文件并配置以下内容："
    echo.
    echo OPENAI_API_KEY=your_api_key_here
    echo OPENAI_BASE_URL=your_api_base_url_here
    echo.
    pause
    exit /b 1
)
call :print_success ".env文件已找到"
goto :eof

:check_main_py
call :print_info "检查main.py文件是否存在..."
if not exist "main.py" (
    call :print_error "main.py文件不存在"
    pause
    exit /b 1
)
call :print_success "main.py文件已找到"
goto :eof

:run_script
set "env_name=correct-drug-env"
call :print_info "激活conda环境: %env_name%"

:: 激活conda环境
call conda activate %env_name%

if %errorlevel% neq 0 (
    call :print_error "conda环境激活失败"
    pause
    exit /b 1
)

call :print_success "环境激活成功"

:: 构建命令
set "cmd=python main.py"

:: 添加传递的参数
if "%~1" neq "" (
    set "cmd=%cmd% %*"
    call :print_info "运行命令: !cmd!"
) else (
    call :print_info "运行命令: !cmd! (使用默认参数)"
)

:: 运行脚本
%cmd%

if %errorlevel% neq 0 (
    call :print_error "脚本执行失败"
    pause
    exit /b 1
) else (
    call :print_success "脚本执行完成"
)

goto :eof

:skip_functions

:: 主程序开始
echo.
call :print_info "开始运行AI药物名称纠正工具..."
echo.

:: 检查帮助参数
if "%1"=="-h" call :show_usage & exit /b 0
if "%1"=="--help" call :show_usage & exit /b 0
if "%1"=="/?" call :show_usage & exit /b 0

:: 执行检查
call :check_conda
if %errorlevel% neq 0 exit /b 1

call :check_conda_env
if %errorlevel% neq 0 exit /b 1

call :check_env_file
if %errorlevel% neq 0 exit /b 1

call :check_main_py
if %errorlevel% neq 0 exit /b 1

echo.
call :print_info "所有检查通过，开始运行脚本..."
echo.

:: 运行脚本
call :run_script %*

:: 如果是双击运行，保持窗口打开
if "%~1"=="" (
    echo.
    pause
)

endlocal 