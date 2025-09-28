#!/bin/bash

# Kill any existing server on port 8000
echo "Checking for existing servers on port 8000..."
if lsof -i:8000 > /dev/null 2>&1; then
    echo "Killing existing server..."
    kill -9 $(lsof -t -i:8000) 2>/dev/null
    sleep 1
fi

echo "Starting Rotaenot HTML5 Server..."
echo "Game will be available at: http://localhost:8000/rotaenot.html"
echo ""

# Start the Python server
python3 server.py