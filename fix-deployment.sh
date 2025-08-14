#!/bin/bash

# Fix deployment script - moves files from dist/ to root and cleans up

SERVER="bbc@server"
REMOTE_PATH="/home/bbc/htdocs/bbc.retrogamecoders.com/"

echo "🔧 Fixing deployment structure..."

# Move files from dist/ to root and clean up
ssh $SERVER << 'EOF'
cd /home/bbc/htdocs/bbc.retrogamecoders.com/

echo "Moving files from dist/ to root..."
# Move all contents from dist/ to current directory
mv dist/* . 2>/dev/null || true
mv dist/.* . 2>/dev/null || true

echo "Removing dist directory..."
rmdir dist 2>/dev/null || true

echo "Cleaning up development files..."
# Remove development-only files and directories
rm -rf node_modules/
rm -rf tests/
rm -rf docker/
rm -rf .vite/
rm -f Dockerfile
rm -f Makefile
rm -f run-container.sh
rm -f eslint.config.js
rm -f jsconfig.json
rm -f README.md
rm -f CLAUDE.md
rm -f COPYING
rm -f deploy.sh
rm -f cleanup-server.sh
rm -f fix-deployment.sh

echo "Setting proper permissions..."
chmod -R 755 .
find . -type f -exec chmod 644 {} \; 2>/dev/null || true

echo "✅ Deployment structure fixed!"
EOF

echo "🎉 Deployment structure has been fixed!"
echo "The site should now work correctly at https://bbc.retrogamecoders.com/"
