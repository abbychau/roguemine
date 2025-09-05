@echo off
echo Starting RogueMine Highscore Backend...
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if package.json exists
if not exist package.json (
    echo Error: package.json not found
    echo Please run this script from the backend directory
    pause
    exit /b 1
)

REM Install dependencies if node_modules doesn't exist
if not exist node_modules (
    echo Installing dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo Error: Failed to install dependencies
        pause
        exit /b 1
    )
    echo.
)

REM Check if .env file exists
if not exist .env (
    echo Creating .env file from template...
    copy .env.example .env
    echo.
    echo Please edit .env file to configure your settings
    echo Press any key to continue...
    pause >nul
)

REM Start the server
echo Starting server...
echo.
echo Server will be available at: http://localhost:56789
echo Health check: http://localhost:56789/health
echo Tunnel URL: https://mine-api.12389012.xyz
echo.
echo Press Ctrl+C to stop the server
echo.

npm start
