#!/bin/bash

# Cleanup script to remove .vite directory from server

SERVER="bbc@server"
REMOTE_PATH="/home/bbc/htdocs/bbc.retrogamecoders.com/"

echo "🧹 Cleaning up .vite directory from server..."

# Remove .vite directory from server
ssh $SERVER "rm -rf $REMOTE_PATH.vite"

echo "✅ Cleanup completed!"
echo "The .vite directory has been removed from the server."
echo "Future deployments will exclude this directory."
