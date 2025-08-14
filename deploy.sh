#!/bin/bash

# Deploy script for jsbeeb BBC Micro emulator
# Uploads built files to bbc@server:/home/bbc/htdocs/bbc.retrogamecoders.com/

set -e  # Exit on any error

echo "🚀 Starting jsbeeb deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER="bbc@server"
REMOTE_PATH="/home/bbc/htdocs/bbc.retrogamecoders.com/"
LOCAL_BUILD_DIR="dist"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "vite.config.js" ]; then
    print_error "This script must be run from the jsbeeb project root directory"
    exit 1
fi

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    print_error "rsync is required but not installed. Please install rsync first."
    exit 1
fi

# Check if SSH key is available
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $SERVER exit 2>/dev/null; then
    print_error "Cannot connect to server. Please ensure SSH key is set up and server is accessible."
    exit 1
fi

print_status "Building project..."
npm run build

if [ ! -d "$LOCAL_BUILD_DIR" ]; then
    print_error "Build failed - $LOCAL_BUILD_DIR directory not found"
    exit 1
fi

print_status "Build completed successfully"

# Create backup of current server files
print_status "Creating backup of current server files..."
ssh $SERVER "if [ -d $REMOTE_PATH ]; then cp -r $REMOTE_PATH ${REMOTE_PATH}../$BACKUP_DIR; fi"

# Create rsync exclude file
cat > .rsync-exclude << EOF
# macOS system files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Development files
.git/
.gitignore
.gitmodules
.editorconfig
.prettierrc.json
.prettierignore
eslint.config.js
jsconfig.json

# Build and test files
tests/
test-*
*.test.js
*.spec.js
coverage/

# Development scripts
deploy.sh
run-container.sh
Makefile
Dockerfile
docker/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.cache/

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Documentation
README.md
CLAUDE.md
COPYING
*.md

# Source maps (optional - remove if you want them)
*.map
EOF

print_status "Uploading files to server..."

# Upload files using rsync with exclusions
print_status "Starting file transfer..."
if rsync -avz --delete \
    --exclude-from=.rsync-exclude \
    --exclude='.rsync-exclude' \
    --progress \
    "$LOCAL_BUILD_DIR/" \
    "$SERVER:$REMOTE_PATH"; then
    print_success "File transfer completed successfully"
else
    # Check if it's just a partial transfer warning (status 23)
    if [ $? -eq 23 ]; then
        print_warning "Partial transfer detected (some files may have been skipped)"
        print_status "This is usually safe to ignore - checking if critical files were transferred..."
        
        # Check if key files exist on server
        if ssh $SERVER "test -f $REMOTE_PATH/index.html && test -f $REMOTE_PATH/assets/index-*.js"; then
            print_success "Critical files verified on server - deployment should be functional"
        else
            print_error "Critical files missing - deployment may have failed"
            exit 1
        fi
    else
        print_error "File transfer failed with status $?"
        exit 1
    fi
fi

# Clean up exclude file
rm .rsync-exclude

# Set proper permissions on server
print_status "Setting file permissions..."
ssh $SERVER "chmod -R 755 $REMOTE_PATH && find $REMOTE_PATH -type f -exec chmod 644 {} \;"

print_success "Deployment completed successfully!"
print_status "Backup created at: ${REMOTE_PATH}../$BACKUP_DIR"
print_status "Server URL: https://bbc.retrogamecoders.com/"

# Optional: Test the deployment
read -p "Would you like to test the deployment? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Testing deployment..."
    if curl -s -o /dev/null -w "%{http_code}" https://bbc.retrogamecoders.com/ | grep -q "200"; then
        print_success "Deployment test successful!"
    else
        print_warning "Deployment test failed - site may not be responding correctly"
    fi
fi

print_success "🎉 jsbeeb deployment complete!"
