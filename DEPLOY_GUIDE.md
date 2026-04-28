# China Science Camp - Deployment Guide

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `china-science-camp`
3. Make it public
4. Click "Create repository"

## Step 2: Push Code to GitHub

```bash
# Navigate to the project folder
cd /Users/leo/WorkBuddy/Claw/reports/china-science-camp

# Initialize git (if not already)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: China Science Camp website"

# Add remote (replace with your actual repo URL)
git remote add origin https://github.com/leo-bone/china-science-camp.git

# Push to GitHub
git push -u origin main
```

## Step 3: Deploy on Cloudflare Pages

1. Go to https://dash.cloudflare.com
2. Navigate to "Pages" → "Create a project"
3. Connect to GitHub → Select `leo-bone/china-science-camp`
4. Configure build settings:
   - **Build command**: (leave empty - static site)
   - **Build output directory**: `/` (root)
5. Click "Save and Deploy"

## Step 4: Configure Custom Domain

1. In Cloudflare Pages project settings, go to "Custom domains"
2. Click "Set up a custom domain"
3. Enter: `chinasciencecamp.uichain.org`
4. Cloudflare will provide DNS records to add

## Step 5: Add DNS Record

1. Go to Cloudflare DNS settings for `uichain.org`
2. Add a CNAME record:
   - **Name**: `chinasciencecamp`
   - **Target**: `[your-cloudflare-pages-domain].pages.dev`
   - **Proxy status**: Proxied (orange cloud)
3. Wait 5-10 minutes for propagation

## Step 6: Verify

Visit https://chinasciencecamp.uichain.org to confirm it's working!

## Troubleshooting

- If DNS doesn't resolve, check that the CNAME is correctly pointing to the Pages domain
- If styles don't load, ensure all files are in the repository root
- For HTTPS issues, ensure "Always Use HTTPS" is enabled in Cloudflare
