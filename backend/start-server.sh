#!/bin/bash

echo "Starting RogueMine Highscore Backend..."
echo

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed or not in PATH"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if package.json exists
if [ ! -f package.json ]; then
    echo "Error: package.json not found"
    echo "Please run this script from the backend directory"
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d node_modules ]; then
    echo "Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install dependencies"
        exit 1
    fi
    echo
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo
    echo "Please edit .env file to configure your settings"
    echo "Press any key to continue..."
    read -n 1
fi

# Start the server
echo "Starting server..."
echo
echo "Server will be available at: http://localhost:56789"
echo "Health check: http://localhost:56789/health"
echo "Tunnel URL: https://mine-api.12389012.xyz"
echo
echo "Press Ctrl+C to stop the server"
echo

npm start
