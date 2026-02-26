#!/bin/bash
set -e

echo "🚀 Setting up Makerkit development environment..."

# Install Docker CLI
echo "📦 Installing Docker CLI..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install PNPM
echo "📦 Installing PNPM..."
npm install -g pnpm

# Install Supabase CLI
echo "📦 Installing Supabase CLI..."
npm install -g supabase

# Install dependencies
echo "📦 Installing project dependencies..."
cd /workspace
pnpm install

# Start Supabase
echo "🔧 Starting Supabase..."
pnpm run supabase:web:start &

# Wait for Supabase to be ready
echo "⏳ Waiting for Supabase to start..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if pnpm --filter web supabase status > /dev/null 2>&1; then
    echo "✅ Supabase is ready!"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  echo "Waiting... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo "❌ Supabase failed to start in time"
  exit 1
fi

# Extract keys from Supabase status
echo "🔑 Extracting Supabase keys..."
cd /workspace/apps/web
SUPABASE_STATUS=$(pnpm supabase status)

ANON_KEY=$(echo "$SUPABASE_STATUS" | grep "anon key:" | awk '{print $3}')
SERVICE_ROLE_KEY=$(echo "$SUPABASE_STATUS" | grep "service_role key:" | awk '{print $3}')

# Get Codespace URLs
CODESPACE_NAME="${CODESPACE_NAME:-localhost}"
if [ "$CODESPACE_NAME" != "localhost" ]; then
  SUPABASE_URL="https://${CODESPACE_NAME}-54321.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  SITE_URL="https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
  SUPABASE_URL="http://127.0.0.1:54321"
  SITE_URL="http://localhost:3000"
fi

# Create .env.local
echo "📝 Creating .env.local..."
cd /workspace/apps/web
cat > .env.local << EOF
NEXT_PUBLIC_SITE_URL=${SITE_URL}
NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
EOF

echo "✅ Setup complete!"
echo ""
echo "🌐 Your URLs:"
echo "   App: ${SITE_URL}"
echo "   Supabase API: ${SUPABASE_URL}"
echo "   Supabase Studio: https://${CODESPACE_NAME}-54323.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
echo ""
echo "🚀 Run 'pnpm run dev' to start the Next.js app"
