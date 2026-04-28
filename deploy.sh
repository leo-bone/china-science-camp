#!/bin/bash
# Cloudflare Pages 一键部署脚本
# 使用方法: ./deploy.sh <你的Cloudflare邮箱> <你的Global API Key>

set -e

CF_EMAIL=$1
CF_API_KEY=$2

if [ -z "$CF_EMAIL" ] || [ -z "$CF_API_KEY" ]; then
    echo "❌ 使用方法: ./deploy.sh <Cloudflare邮箱> <Global API Key>"
    echo ""
    echo "获取 Global API Key:"
    echo "1. 登录 https://dash.cloudflare.com"
    echo "2. 点击右上角头像 → My Profile"
    echo "3. 左侧 API Tokens → Global API Key → View"
    exit 1
fi

echo "🚀 开始部署 China Science Camp 到 Cloudflare Pages..."

# 获取 Zone ID
echo "📍 获取 uichain.org 的 Zone ID..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=uichain.org" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY")

ZONE_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') and len(d['result'])>0 else '')")

if [ -z "$ZONE_ID" ]; then
    echo "❌ 无法获取 Zone ID，请检查邮箱和 API Key 是否正确"
    exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# 获取 Account ID
echo "📍 获取 Account ID..."
ACCOUNT_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['account']['id'] if d.get('result') and len(d['result'])>0 else '')")
echo "✅ Account ID: $ACCOUNT_ID"

# 创建 Pages 项目
echo "📦 创建 Pages 项目..."
PROJECT_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "china-science-camp",
        "production_branch": "main",
        "build_config": {
            "build_command": "",
            "destination_dir": "/",
            "root_dir": ""
        }
    }')

echo $PROJECT_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 项目创建成功' if d.get('success') else f'⚠️ 项目可能已存在或创建失败: {d}')"

# 上传文件（直接部署）
echo "📤 上传网站文件..."

# 创建 deployment
DEPLOY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/china-science-camp/deployments" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -F "file=@site.zip")

echo $DEPLOY_RESPONSE | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    url = d['result']['url']
    print(f'✅ 部署成功！')
    print(f'🌐 临时访问地址: {url}')
else:
    print(f'❌ 部署失败: {d}')
"

# 添加自定义域名
echo "🔗 添加自定义域名 chinasciencecamp.uichain.org..."
DOMAIN_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/china-science-camp/domains" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "chinasciencecamp.uichain.org"}')

echo $DOMAIN_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 域名绑定成功！' if d.get('success') else f'⚠️ 域名绑定: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知\")}')"

echo ""
echo "🎉 部署完成！"
echo ""
echo "访问地址:"
echo "  - https://china-science-camp.pages.dev (Cloudflare 默认域名)"
echo "  - https://chinasciencecamp.uichain.org (你的自定义域名，DNS生效可能需要几分钟)"
echo ""
echo "如果自定义域名无法访问，请在 Cloudflare Dashboard 检查 DNS 记录是否已自动添加。"
