#!/bin/bash
# Cloudflare Pages 部署脚本 (API Token 方式 - 安全版本)
# 使用方法: 先设置环境变量 CF_API_TOKEN，然后运行 ./deploy-token.sh

set -e

# 从环境变量读取 API Token（更安全，不会出现在命令历史和进程列表中）
CF_API_TOKEN="${CF_API_TOKEN:-}"

if [ -z "$CF_API_TOKEN" ]; then
    echo "❌ 错误: 未设置 CF_API_TOKEN 环境变量"
    echo ""
    echo "使用方法:"
    echo "  export CF_API_TOKEN='你的API Token'"
    echo "  ./deploy-token.sh"
    echo ""
    echo "或者一次性设置（仅当前会话有效）:"
    echo "  CF_API_TOKEN='你的API Token' ./deploy-token.sh"
    echo ""
    echo "获取 API Token:"
    echo "1. 访问 https://dash.cloudflare.com"
    echo "2. 点击右上角头像 → My Profile"
    echo "3. 选择 API Tokens → Create Token"
    echo "4. 选择 'Custom token'，配置以下权限:"
    echo "   - Zone:Read, Zone Settings:Read"
    echo "   - Cloudflare Pages:Edit"
    echo "   - Account:Read"
    exit 1
fi

echo "🚀 开始部署 China Science Camp 到 Cloudflare Pages..."

# 查询 Zone ID
echo "🔍 查询 uichain.org 的 Zone ID..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=uichain.org" \
    -H "Authorization: Bearer $CF_API_TOKEN")

ZONE_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') and len(d['result'])>0 else '')")

if [ -z "$ZONE_ID" ]; then
    echo "❌ 无法获取 Zone ID"
    echo "响应: $ZONE_RESPONSE"
    exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# 查询 Account ID
echo "🔍 查询 Account ID..."
ACCOUNT_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['account']['id'] if d.get('result') and len(d['result'])>0 else '')")
echo "✅ Account ID: $ACCOUNT_ID"

# 创建 Pages 项目
echo "🔧 创建 Pages 项目..."
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

echo $PROJECT_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 项目创建/已存在' if d.get('success') else f'⚠️ 项目创建结果: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知错误\")}')"

# 检查 site.zip 是否存在
if [ ! -f "site.zip" ]; then
    echo "❌ 错误: site.zip 文件不存在"
    echo "请先创建 site.zip 文件"
    exit 1
fi

# 部署网站文件
echo "📦 部署网站文件..."

# 创建 deployment
DEPLOY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/china-science-camp/deployments" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -F "file=@site.zip")

echo $DEPLOY_RESPONSE | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    url = d['result']['url']
    print(f'✅ 部署成功!')
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

echo $DOMAIN_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 自定义域名添加成功' if d.get('success') else f'⚠️ 域名添加结果: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知错误\")}')"

echo ""
echo "🎉 部署完成!"
echo ""
echo "访问地址:"
echo "  - https://china-science-camp.pages.dev (Cloudflare 自动域名)"
echo "  - https://chinasciencecamp.uichain.org (自定义域名，需DNS配置生效)"
