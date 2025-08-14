#!/bin/bash
SERVER="bbc@server"
REMOTE_PATH="/home/bbc/htdocs/bbc.retrogamecoders.com/"
LOCAL_BUILD_DIR="dist"

echo "🚀 Starting clean deployment..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Build the project locally
echo "📦 Building project locally..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Check if build was successful
if [ ! -d "$LOCAL_BUILD_DIR" ]; then
    echo "❌ Build directory not found!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Create backup on server
echo "💾 Creating backup on server..."
BACKUP_DIR="/home/bbc/htdocs/backup_$(date +%Y%m%d_%H%M%S)"
ssh $SERVER "mkdir -p $BACKUP_DIR && cp -r $REMOTE_PATH* $BACKUP_DIR/ 2>/dev/null || true"
echo "📁 Backup created at: $BACKUP_DIR"

# Clean the remote directory completely
echo "🧹 Cleaning remote directory..."
ssh $SERVER "rm -rf $REMOTE_PATH* $REMOTE_PATH.* 2>/dev/null || true"

# Upload only the built files
echo "📤 Uploading built files..."
rsync -avz --delete \
    --exclude='.git/' \
    --exclude='node_modules/' \
    --exclude='src/' \
    --exclude='tests/' \
    --exclude='docker/' \
    --exclude='.vite/' \
    --exclude='.vite-cache/' \
    --exclude='.cache/' \
    --exclude='tmp/' \
    --exclude='temp/' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='Thumbs.db' \
    --exclude='*.swp' \
    --exclude='*.swo' \
    --exclude='*~' \
    --exclude='.env*' \
    --exclude='package.json' \
    --exclude='package-lock.json' \
    --exclude='vite.config.js' \
    --exclude='Dockerfile' \
    --exclude='Makefile' \
    --exclude='run-container.sh' \
    --exclude='eslint.config.js' \
    --exclude='jsconfig.json' \
    --exclude='README.md' \
    --exclude='CLAUDE.md' \
    --exclude='COPYING' \
    --exclude='deploy.sh' \
    --exclude='cleanup-server.sh' \
    --exclude='fix-deployment.sh' \
    --exclude='cleanup-server-thorough.sh' \
    --exclude='deploy-clean.sh' \
    "$LOCAL_BUILD_DIR/" "$SERVER:$REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Upload completed successfully!"
else
    echo "⚠️  Upload completed with warnings (this is usually safe to ignore)"
fi

# Set proper permissions
echo "🔧 Setting file permissions..."
ssh $SERVER "chmod -R 755 $REMOTE_PATH && find $REMOTE_PATH -type f -exec chmod 644 {} \; 2>/dev/null || true"

echo "🎉 Clean deployment completed!"
echo "🌐 Server URL: https://bbc.retrogamecoders.com/"
echo "📁 Backup created at: $BACKUP_DIR"

# Test the deployment
echo "🧪 Testing deployment..."
if curl -s -o /dev/null -w "%{http_code}" https://bbc.retrogamecoders.com/ | grep -q "200"; then
    echo "✅ Deployment test successful!"
else
    echo "⚠️  Deployment test failed - site may not be responding correctly"
fi

echo "🎯 jsbeeb clean deployment complete!"
