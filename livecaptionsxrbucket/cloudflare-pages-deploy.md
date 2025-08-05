# Cloudflare Pages Deployment Guide

## Method 1: Cloudflare Pages (Recommended)

### Prerequisites
- Cloudflare account
- Git repository (GitHub, GitLab, or Bitbucket)

### Steps:

1. **Push to Git Repository**
   ```bash
   # If not already a git repository
   cd livecaptionsxrbucket
   git init
   git add .
   git commit -m "Initial commit for Cloudflare Pages"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Deploy via Cloudflare Dashboard**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
   - Navigate to "Pages" in the sidebar
   - Click "Create a project"
   - Choose "Connect to Git"
   - Select your repository
   - Configure build settings:
     - **Framework preset**: None
     - **Build command**: Leave empty
     - **Build output directory**: `.` (current directory)
     - **Root directory**: Leave empty (or specify if needed)

3. **Environment Variables** (if needed)
   - Add any environment variables in the Cloudflare Pages settings
   - For this static site, likely none needed

4. **Custom Domain** (optional)
   - In Pages settings, go to "Custom domains"
   - Add your domain and configure DNS

### Result
Your site will be available at: `https://your-project-name.pages.dev`

## Method 2: Cloudflare Workers Sites

### Prerequisites
- Cloudflare account
- Wrangler CLI installed: `npm install -g wrangler`

### Steps:

1. **Install Wrangler and Login**
   ```bash
   npm install -g wrangler
   wrangler login
   ```

2. **Create wrangler.toml**
   ```toml
   name = "livecaptionsxr-models"
   type = "webpack"
   account_id = "your-account-id"
   workers_dev = true
   route = ""
   zone_id = ""

   [site]
   bucket = "."
   entry-point = "workers-site"
   ```

3. **Deploy**
   ```bash
   cd livecaptionsxrbucket
   wrangler publish
   ```

## Method 3: Direct Upload via Cloudflare Dashboard

### Steps:

1. **Zip the Directory**
   ```bash
   cd livecaptionsxrbucket
   # On Windows PowerShell:
   Compress-Archive -Path * -DestinationPath livecaptionsxr-models.zip
   ```

2. **Upload via Cloudflare**
   - Go to Cloudflare Dashboard
   - Navigate to "Pages"
   - Create a new project
   - Choose "Direct Upload"
   - Upload your zip file

## Recommended Approach

**Use Cloudflare Pages** because:
- ✅ Automatic deployments from Git
- ✅ Global CDN
- ✅ Free tier available
- ✅ Easy custom domain setup
- ✅ Built-in analytics
- ✅ Automatic HTTPS

## Post-Deployment

1. **Test the site** at your assigned URL
2. **Set up custom domain** if desired
3. **Configure redirects** if needed
4. **Set up analytics** in Cloudflare dashboard

## File Structure Notes

Your current structure is perfect for static hosting:
- `index.html` - Main landing page
- `web/` - Additional web pages
- `flutter/` - Flutter integration code
- `docs/` - Documentation
- `scripts/` - Deployment scripts

All files will be served as static assets. 