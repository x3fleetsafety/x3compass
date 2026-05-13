#!/bin/bash
# X3 Compass — Deploy script
# Usage: ./scripts/deploy.sh

set -e
echo "=== Deploying X3 Compass ==="

# 1. Verify prereqs
command -v wrangler >/dev/null || { echo "Install wrangler: npm i -g wrangler"; exit 1; }
command -v supabase >/dev/null || { echo "Install supabase CLI: brew install supabase/tap/supabase"; exit 1; }

# 2. Deploy marketing + app to Cloudflare Pages
echo "→ Deploying site to Cloudflare Pages..."
wrangler pages deploy site --project-name=x3compass

# 3. Apply Supabase migrations
echo "→ Applying Supabase migrations..."
supabase db push

# 4. Deploy Edge Functions
echo "→ Deploying Edge Functions..."
supabase functions deploy compass-agent
supabase functions deploy compass-onboarding
supabase functions deploy partner-billing
supabase functions deploy affiliate-tracker

echo "=== Deploy complete ==="
echo "Marketing: https://x3compass.com"
echo "App:       https://x3compass.com/app/dashboard.html"
