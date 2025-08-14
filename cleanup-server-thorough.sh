#!/bin/bash
SERVER="bbc@server"
REMOTE_PATH="/home/bbc/htdocs/bbc.retrogamecoders.com/"
echo "🧹 Thorough cleanup of development files from server..."
ssh $SERVER << 'EOF'
cd /home/bbc/htdocs/bbc.retrogamecoders.com/
echo "Removing all development directories and files..."
rm -rf node_modules/
rm -rf dist/
rm -rf .vite/
rm -rf .vite-cache/
rm -rf .cache/
rm -rf tmp/
rm -rf temp/
rm -f package.json
rm -f package-lock.json
rm -f vite.config.js
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
rm -f cleanup-server-thorough.sh
rm -rf tests/
rm -rf docker/
rm -rf src/
echo "Setting proper permissions..."
chmod -R 755 .
find . -type f -exec chmod 644 {} \; 2>/dev/null || true
echo "✅ Thorough cleanup completed!"
EOF
echo "🎉 Server has been thoroughly cleaned!"
echo "The site should now serve static files correctly at https://bbc.retrogamecoders.com/"
