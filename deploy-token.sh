#!/bin/bash
# Cloudflare Pages 一键部署脚本 (API Token 版本)
# 使用方法: ./deploy-token.sh <你的API Token>

set -e

CF_API_TOKEN=$1

if [ -z "$CF_API_TOKEN" ]; then
    echo "❌ 使用方法: ./deploy-token.sh <API Token>"
    echo ""
    echo "获取 API Token:"
    echo "1. 登录 https://dash.cloudflare.com"
    echo "2. 点击右上角头像 → My Profile"
    echo "3. 左侧 API Tokens → Create Token"
    echo "4. 选择 'Custom token'，权限选择:"
    echo "   - Zone:Read, Zone Settings:Read"
    echo "   - Cloudflare Pages:Edit"
    echo "   - Account:Read"
    exit 1
fi

echo "🚀 开始部署 China Science Camp 到 Cloudflare Pages..."

# 获取 Zone ID
echo "📍 获取 uichain.org 的 Zone ID..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=uichain.org" \
    -H "Authorization: Bearer $CF_API_TOKEN")

ZONE_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') and len(d['result'])>0 else '')")

if [ -z "$ZONE_ID" ]; then
    echo "❌ 无法获取 Zone ID"
    echo "响应: $ZONE_RESPONSE"
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
    -H "Authorization: Bearer $CF_API_TOKEN" \
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

echo $PROJECT_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 项目创建成功' if d.get('success') else f'⚠️ 项目可能已存在: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知\")}')"

# 上传文件（直接部署）
echo "📤 上传网站文件..."

# 创建 deployment
DEPLOY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/china-science-camp/deployments" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
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
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "chinasciencecamp.uichain.org"}')

echo $DOMAIN_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 域名绑定成功！' if d.get('success') else f'⚠️ 域名绑定: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知\")}')"

echo ""
echo "🎉 部署完成！"
echo ""
echo "访问地址:"
echo "  - https://china-science-camp.pages.dev (Cloudflare 默认域名)"
echo "  - https://chinasciencecamp.uichain.org (你的自定义域名，DNS生效可能需要几分钟)"
