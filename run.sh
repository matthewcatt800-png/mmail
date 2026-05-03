#!/data/data/com.termux/files/usr/bin/bash

echo "🔥 Starting Mmail..."

# load env
export $(cat .env | xargs)

# run server
node server.js
