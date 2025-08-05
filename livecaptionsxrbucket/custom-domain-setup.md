# Custom Domain Setup Guide

Based on your Cloudflare dashboard configuration, here's how to complete the custom domain setup for `livecaptionsxrbucket.com`.

## 🎯 Current Configuration

From your Cloudflare dashboard, you're configuring:
- **Worker**: `livecaptionsxr-models`
- **Custom Domain**: `livecaptionsxrbucket.com`
- **Route Pattern**: `*/.livecaptionsxrbucket.com/*`

## 📋 Steps to Complete Setup

### 1. Get Your Zone ID
1. In Cloudflare dashboard, go to your domain `livecaptionsxrbucket.com`
2. Look for the **Zone ID** in the right sidebar
3. Copy this ID (it's a 32-character string)

### 2. Update wrangler.toml
Replace `your-zone-id-here` in your `wrangler.toml` with your actual Zone ID:

```toml
# Custom domain configuration
zone_id = "your-actual-zone-id-here"
routes = [
  "livecaptionsxrbucket.com/*"
]
```

### 3. Add the Route in Cloudflare Dashboard
Based on your screenshot, you're adding:
- **Zone**: `livecaptionsxrbucket.com`
- **Route**: `*/.livecaptionsxrbucket.com/*`
- **Failure Mode**: "Fail closed (block)" (recommended for security)

### 4. Deploy with Updated Configuration
```bash
wrangler deploy
```

## 🔧 How the Route Works

According to the Cloudflare explanation in your screenshot:

### Static Asset Serving
- **Asset Matching**: Requests to `livecaptionsxrbucket.com/*` will first try to serve files from your assets directory
- **Example**: A request to `livecaptionsxrbucket.com/web/download.html` will serve the file from `web/download.html` in your assets

### Worker Fallback
- **No Asset Found**: If no matching asset exists, the request is forwarded to your Worker script (`src/index.js`)
- **API Routes**: Your `/api/health`, `/api/models`, and `/api/setup-guide` endpoints will work at `livecaptionsxrbucket.com/api/*`

## 🎉 Result

After setup, your dual-purpose platform will be available at:
- **Main Site**: `https://livecaptionsxrbucket.com`
- **Model Downloads**: `https://livecaptionsxrbucket.com/web/download.html`
- **API Health**: `https://livecaptionsxrbucket.com/api/health`
- **Models List**: `https://livecaptionsxrbucket.com/api/models`
- **Setup Guide**: `https://livecaptionsxrbucket.com/api/setup-guide`

## 🔒 Security Considerations

The "Fail closed (block)" setting is recommended because:
- ✅ Provides security by blocking requests that don't match your Worker logic
- ✅ Prevents accidental exposure of unintended resources
- ✅ Gives you full control over what gets served

## 📊 Monitoring

After deployment, monitor your site through:
- **Cloudflare Analytics**: Track traffic and performance
- **Worker Metrics**: Monitor API endpoint usage
- **Cache Analytics**: See how well your static assets are being cached

## 🚀 Next Steps

1. **Test the deployment**: Visit `https://livecaptionsxrbucket.com`
2. **Verify API endpoints**: Test `/api/health` and `/api/models`
3. **Check downloads**: Ensure model download pages work correctly
4. **Monitor performance**: Use Cloudflare analytics to track usage

Your dual-purpose platform will now be live with a professional custom domain! 