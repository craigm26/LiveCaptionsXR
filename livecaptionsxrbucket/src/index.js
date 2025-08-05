/**
 * LiveCaptionsXR Model Distribution Worker
 * Dual-purpose: Direct model downloads + Gemma 3N distribution setup guide
 * Serves static assets with optional API functionality
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Handle API routes if needed
    if (url.pathname.startsWith("/api/")) {
      return handleApiRequest(request, url);
    }
    
    // Serve static assets
    return env.ASSETS.fetch(request);
  },
};

/**
 * Handle API requests (placeholder for future functionality)
 */
async function handleApiRequest(request, url) {
  const path = url.pathname;
  
  switch (path) {
    case "/api/health":
      return new Response(JSON.stringify({ 
        status: "healthy", 
        service: "LiveCaptionsXR Model Distribution",
        purpose: "Dual-purpose: Direct downloads + Gemma 3N setup guide",
        timestamp: new Date().toISOString()
      }), {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
      });
      
    case "/api/models":
      return new Response(JSON.stringify({
        models: [
          {
            name: "Whisper Base",
            size: "141 MB",
            description: "OpenAI Whisper base model for speech recognition",
            url: "https://livecaptionsxrbucket.com/whisper_base.bin",
            purpose: "LiveCaptionsXR speech processing",
            fileName: "whisper_base.bin",
            expectedSize: 147951465,
            modelKey: "whisper-base"
          },
          {
            name: "Gemma 3N E2B",
            size: "2.92 GB", 
            description: "Google Gemma 3N 2B parameter model for text generation",
            url: "https://livecaptionsxrbucket.com/gemma-3n-E2B-it-int4.task",
            purpose: "LiveCaptionsXR text processing & fine-tuning example",
            fileName: "gemma-3n-E2B-it-int4.task",
            expectedSize: 3133601792,
            modelKey: "gemma-3n-E2B-it-int4"
          },
          {
            name: "Gemma 3N E4B",
            size: "4.11 GB",
            description: "Google Gemma 3N 4B parameter model for enhanced text generation", 
            url: "https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task",
            purpose: "LiveCaptionsXR enhanced processing & fine-tuning example",
            fileName: "gemma-3n-E4B-it-int4.task",
            expectedSize: 4398046511,
            modelKey: "gemma-3n-E4B-it-int4"
          }
        ],
        system_info: {
          purpose: "Dual-purpose platform",
          primary_use: "Direct model downloads for LiveCaptionsXR applications",
          secondary_use: "Complete example for setting up Gemma 3N model distribution systems",
          fine_tuning_ready: true,
          deployment_templates: true,
          flutter_integration: {
            model_download_manager: "lib/core/services/model_download_manager.dart",
            web_interface: "web/model_downloads_page.html",
            compatibility: "Full compatibility with LiveCaptionsXR app"
          }
        }
      }), {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
      });
      
    case "/api/setup-guide":
      return new Response(JSON.stringify({
        title: "Gemma 3N Model Distribution Setup Guide",
        description: "Complete guide for setting up your own model distribution system",
        resources: [
          {
            name: "Deployment Guide",
            description: "Step-by-step deployment instructions",
            url: "/workers-deploy-guide.md",
            type: "documentation"
          },
          {
            name: "Cloudflare Pages Guide", 
            description: "Deploy using Cloudflare Pages",
            url: "/cloudflare-pages-deploy.md",
            type: "deployment"
          },
          {
            name: "System Documentation",
            description: "Complete system architecture and setup",
            url: "/README.md", 
            type: "documentation"
          },
          {
            name: "Technical Summary",
            description: "Consolidated technical overview",
            url: "/CONSOLIDATED_SUMMARY.md",
            type: "documentation"
          }
        ],
        deployment_options: [
          "Cloudflare Workers Sites",
          "Cloudflare Pages", 
          "AWS S3 + CloudFront",
          "Google Cloud Storage",
          "Azure Blob Storage"
        ],
        features: [
          "Fine-tuning workflow support",
          "Model version management",
          "Global CDN distribution",
          "API endpoints for integration",
          "Progress tracking for downloads",
          "Cross-platform compatibility"
        ]
      }), {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
      });
      
    default:
      return new Response(JSON.stringify({ 
        error: "API endpoint not found" 
      }), {
        status: 404,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
      });
  }
} 