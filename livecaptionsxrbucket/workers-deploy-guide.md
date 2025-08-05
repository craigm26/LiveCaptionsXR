# Cloudflare Workers Sites Deployment Guide

Based on the [Cloudflare Workers Static Assets documentation](https://developers.cloudflare.com/workers/static-assets/), this guide shows how to deploy your `livecaptionsxrbucket` using Cloudflare Workers Sites.

## 🚀 Quick Deploy with Workers Sites

### Prerequisites
- Cloudflare account
- Node.js and npm installed
- Wrangler CLI: `npm install -g wrangler`

### Step 1: Install and Authenticate
```bash
npm install -g wrangler
wrangler login
```

### Step 2: Configure Your Project
The `wrangler.toml` file is already configured for your project:

```toml
name = "livecaptionsxr-models"
compatibility_date = "2025-01-01"
main = "./src/index.js"

[assets]
directory = "."
binding = "ASSETS"
not_found_handling = "404-page"
```

### Step 3: Deploy
```bash
cd livecaptionsxrbucket
wrangler deploy
```

## 📋 How It Works

According to the [Cloudflare documentation](https://developers.cloudflare.com/workers/static-assets/):

### Static Asset Serving
- **Assets Directory**: The `directory = "."` setting tells Wrangler to upload all files from the current directory
- **Automatic Caching**: Cloudflare provides automatic caching across its global network
- **Tiered Caching**: Assets are cached at multiple levels for optimal performance

### Routing Behavior
- **Default**: If a URL matches a file in your assets directory, it's served directly
- **Worker Fallback**: If no matching asset is found, the Worker script handles the request
- **404 Handling**: Uses `not_found_handling = "404-page"` for proper error responses

### API Integration
The included Worker script (`src/index.js`) provides:
- `/api/health` - Service health check
- `/api/models` - List available models
- Static asset serving for all other requests

## 🎯 Benefits of Workers Sites

### Performance
- **Global CDN**: Assets served from locations closest to users
- **Automatic Caching**: First request caches the asset, subsequent requests are served from cache
- **Tiered Caching**: Reduces latency and origin fetches

### Integration
- **Single Deployment**: Both Worker code and static assets deployed together
- **Tight Integration**: Assets and Worker logic run as a unified unit
- **Custom Logic**: Add API endpoints alongside static file serving

### Cost Efficiency
- **Free Tier**: 100,000 requests per day
- **Pay-as-you-go**: Only pay for what you use
- **No bandwidth charges**: Static assets served from Cloudflare's network

## 🔧 Configuration Options

### Custom Domain Setup
1. Add your domain to Cloudflare
2. Update `wrangler.toml`:
```toml
zone_id = "your-zone-id"
routes = ["yourdomain.com/*"]
```

### Advanced Routing
For more complex routing, you can modify the Worker script:

```javascript
// Example: Custom routing logic
if (url.pathname.startsWith("/api/")) {
  return handleApiRequest(request, url);
} else if (url.pathname.startsWith("/models/")) {
  // Custom model serving logic
  return handleModelRequest(request, url);
} else {
  // Serve static assets
  return env.ASSETS.fetch(request);
}
```

### Caching Headers
The Worker can add custom headers to static assets:

```javascript
const response = await env.ASSETS.fetch(request);
const newResponse = new Response(response.body, response);
newResponse.headers.set('Cache-Control', 'public, max-age=31536000');
return newResponse;
```

## 📊 Monitoring and Analytics

After deployment, you can monitor your site through:
- **Cloudflare Dashboard**: Real-time analytics and performance metrics
- **Workers Analytics**: Request counts, error rates, and response times
- **Cache Analytics**: Cache hit ratios and performance improvements

## 🔄 Continuous Deployment

For automatic deployments, you can integrate with:
- **GitHub Actions**: Deploy on push to main branch
- **GitLab CI/CD**: Automated deployment pipeline
- **Wrangler CLI**: Manual deployments with `wrangler deploy`

## 🎉 Result

Your site will be available at:
- **Workers.dev**: `https://livecaptionsxr-models.your-subdomain.workers.dev`
- **Custom Domain**: If configured, your custom domain

## 📚 Additional Resources

- [Cloudflare Workers Static Assets Documentation](https://developers.cloudflare.com/workers/static-assets/)
- [Wrangler CLI Documentation](https://developers.cloudflare.com/workers/wrangler/)
- [Workers Sites Configuration](https://developers.cloudflare.com/workers/static-assets/configuration/)
- [Routing and Domains](https://developers.cloudflare.com/workers/configuration/routes-and-domains/) 