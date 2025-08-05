# LiveCaptionsXR Model Distribution - Cloudflare Deployment Script
# This script helps prepare and deploy the livecaptionsxrbucket to Cloudflare Pages

param(
    [string]$DeployMethod = "pages",
    [string]$ProjectName = "livecaptionsxr-models",
    [string]$GitRepo = ""
)

Write-Host "🚀 LiveCaptionsXR Model Distribution - Cloudflare Deployment" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "index.html")) {
    Write-Host "❌ Error: index.html not found. Please run this script from the livecaptionsxrbucket directory." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found index.html - we're in the right directory" -ForegroundColor Green

switch ($DeployMethod.ToLower()) {
    "pages" {
        Write-Host "📋 Deploying via Cloudflare Pages..." -ForegroundColor Yellow
        
        # Check if git is initialized
        if (-not (Test-Path ".git")) {
            Write-Host "🔧 Initializing git repository..." -ForegroundColor Yellow
            git init
            git add .
            git commit -m "Initial commit for Cloudflare Pages deployment"
            
            if ($GitRepo) {
                Write-Host "🔗 Adding remote repository: $GitRepo" -ForegroundColor Yellow
                git remote add origin $GitRepo
                git push -u origin main
                Write-Host "✅ Pushed to git repository" -ForegroundColor Green
            } else {
                Write-Host "⚠️  No git repository URL provided. Please manually push to your repository." -ForegroundColor Yellow
                Write-Host "   Then follow these steps:" -ForegroundColor Cyan
                Write-Host "   1. Go to https://dash.cloudflare.com" -ForegroundColor Cyan
                Write-Host "   2. Navigate to Pages" -ForegroundColor Cyan
                Write-Host "   3. Create a new project" -ForegroundColor Cyan
                Write-Host "   4. Connect to your git repository" -ForegroundColor Cyan
                Write-Host "   5. Configure build settings:" -ForegroundColor Cyan
                Write-Host "      - Framework preset: None" -ForegroundColor Cyan
                Write-Host "      - Build command: (leave empty)" -ForegroundColor Cyan
                Write-Host "      - Build output directory: ." -ForegroundColor Cyan
            }
        } else {
            Write-Host "✅ Git repository already initialized" -ForegroundColor Green
            git add .
            git commit -m "Update for Cloudflare Pages deployment"
            
            if ($GitRepo) {
                git push
                Write-Host "✅ Pushed updates to git repository" -ForegroundColor Green
            }
        }
    }
    
    "direct" {
        Write-Host "📦 Preparing for direct upload..." -ForegroundColor Yellow
        
        $zipFile = "livecaptionsxr-models.zip"
        
        # Remove existing zip if it exists
        if (Test-Path $zipFile) {
            Remove-Item $zipFile
        }
        
        # Create zip file
        Write-Host "📦 Creating zip file: $zipFile" -ForegroundColor Yellow
        Compress-Archive -Path * -DestinationPath $zipFile -Force
        
        if (Test-Path $zipFile) {
            Write-Host "✅ Zip file created successfully: $zipFile" -ForegroundColor Green
            Write-Host "📋 Next steps for direct upload:" -ForegroundColor Cyan
            Write-Host "   1. Go to https://dash.cloudflare.com" -ForegroundColor Cyan
            Write-Host "   2. Navigate to Pages" -ForegroundColor Cyan
            Write-Host "   3. Create a new project" -ForegroundColor Cyan
            Write-Host "   4. Choose 'Direct Upload'" -ForegroundColor Cyan
            Write-Host "   5. Upload the file: $zipFile" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Failed to create zip file" -ForegroundColor Red
        }
    }
    
    "wrangler" {
        Write-Host "🔧 Deploying via Cloudflare Workers Sites..." -ForegroundColor Yellow
        
        # Check if wrangler is installed
        try {
            $wranglerVersion = wrangler --version
            Write-Host "✅ Wrangler found: $wranglerVersion" -ForegroundColor Green
        } catch {
            Write-Host "❌ Wrangler not found. Installing..." -ForegroundColor Yellow
            npm install -g wrangler
        }
        
        # Check if user is logged in
        try {
            $accountInfo = wrangler whoami
            Write-Host "✅ Logged in to Cloudflare" -ForegroundColor Green
        } catch {
            Write-Host "🔐 Please login to Cloudflare..." -ForegroundColor Yellow
            wrangler login
        }
        
        # Check if wrangler.toml exists and is properly configured
        if (Test-Path "wrangler.toml") {
            Write-Host "✅ Found wrangler.toml configuration" -ForegroundColor Green
        } else {
            Write-Host "❌ wrangler.toml not found. Please ensure it exists in the current directory." -ForegroundColor Red
            Write-Host "   See workers-deploy-guide.md for configuration details." -ForegroundColor Cyan
            exit 1
        }
        
        # Check if src/index.js exists
        if (-not (Test-Path "src/index.js")) {
            Write-Host "❌ src/index.js not found. Please ensure the Worker script exists." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "🚀 Deploying to Cloudflare Workers Sites..." -ForegroundColor Yellow
        Write-Host "📋 This will deploy both static assets and Worker code together." -ForegroundColor Cyan
        
        wrangler deploy
        
        Write-Host ""
        Write-Host "🎉 Deployment complete!" -ForegroundColor Green
        Write-Host "📖 For detailed information, see: workers-deploy-guide.md" -ForegroundColor Cyan
    }
    
    default {
        Write-Host "❌ Unknown deployment method: $DeployMethod" -ForegroundColor Red
        Write-Host "Available methods: pages, direct, wrangler" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 Deployment preparation complete!" -ForegroundColor Green
Write-Host "📖 For detailed instructions, see: cloudflare-pages-deploy.md" -ForegroundColor Cyan 