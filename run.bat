@echo off
REM AI Drug Name Correction Tool - Windows Batch Script
REM Usage:
REM   run.bat                         - Basic run
REM   run.bat --thinking              - Enable thinking mode
REM   run.bat --dir "C:\path\to\files" - Specify directory

setlocal enabledelayedexpansion

REM Set console encoding to UTF-8
chcp 65001 >nul 2>&1

REM Show help if requested
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help
if "%1"=="/?" goto :show_help

echo.
echo [INFO] Starting AI Drug Name Correction Tool...
echo.

REM Check if conda is available
echo [INFO] Checking conda installation...
where conda >nul 2>&1
if errorlevel 1 (
    echo [ERROR] conda not found in PATH
    echo [INFO] Please install Anaconda or Miniconda first
    echo.
    pause
    exit /b 1
)
echo [SUCCESS] conda found

REM Check if conda environment exists
echo [INFO] Checking conda environment...
set "env_name=correct-drug-env"
conda env list | findstr "%env_name%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] conda environment '%env_name%' does not exist
    echo [INFO] Please create the environment first:
    echo   conda create -n %env_name% python=3.10
    echo   conda activate %env_name%
    echo   pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)
echo [SUCCESS] conda environment '%env_name%' found

REM Check if .env file exists
echo [INFO] Checking .env file...
if not exist ".env" (
    echo [ERROR] .env file not found
    echo [INFO] Please create .env file with:
    echo   OPENAI_API_KEY=your_api_key_here
    echo   OPENAI_BASE_URL=your_api_base_url_here
    echo.
    pause
    exit /b 1
)
echo [SUCCESS] .env file found

REM Check if main.py exists
echo [INFO] Checking main.py file...
if not exist "main.py" (
    echo [ERROR] main.py file not found
    pause
    exit /b 1
)
echo [SUCCESS] main.py file found

echo.
echo [INFO] All checks passed, starting script...
echo.

REM Activate conda environment
echo [INFO] Activating conda environment: %env_name%
call conda activate %env_name%
if errorlevel 1 (
    echo [ERROR] Failed to activate conda environment
    pause
    exit /b 1
)
echo [SUCCESS] Environment activated

REM Build command
set "cmd=python main.py"
if not "%~1"=="" (
    set "cmd=!cmd! %*"
    echo [INFO] Running command: !cmd!
) else (
    echo [INFO] Running command: !cmd! with default parameters
)

REM Run the script
!cmd!
if errorlevel 1 (
    echo [ERROR] Script execution failed
    pause
    exit /b 1
) else (
    echo [SUCCESS] Script execution completed
)

REM Keep window open if double-clicked
if "%~1"=="" (
    echo.
    pause
)

goto :end

:show_help
echo.
echo AI Drug Name Correction Tool - Windows Batch Script
echo.
echo Usage:
echo   run.bat                           - Basic run, process Excel files in current directory
echo   run.bat --thinking                - Enable thinking mode for detailed processing
echo   run.bat --dir "C:\path\to\files"  - Specify directory to process Excel files
echo   run.bat --dir "C:\path\to\files" --thinking - Combine directory and thinking mode
echo.
echo Requirements:
echo   - Conda environment 'correct-drug-env' must be created
echo   - .env file must contain correct API configuration
echo   - Excel files should contain drug name data in first column
echo.
pause
goto :end

:end
endlocal 