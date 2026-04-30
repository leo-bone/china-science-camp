#!/bin/bash
# Cloudflare Pages 部署脚本 (Global API Key 方式 - 安全版本)
# 使用方法: 先设置环境变量，然后运行 ./deploy.sh

set -e

# 从环境变量读取凭证（更安全，不会出现在命令历史和进程列表中）
CF_EMAIL="${CF_EMAIL:-}"
CF_API_KEY="${CF_API_KEY:-}"

if [ -z "$CF_EMAIL" ] || [ -z "$CF_API_KEY" ]; then
    echo "❌ 错误: 未设置必要的环境变量"
    echo ""
    echo "使用方法:"
    echo "  export CF_EMAIL='你的Cloudflare邮箱'"
    echo "  export CF_API_KEY='你的Global API Key'"
    echo "  ./deploy.sh"
    echo ""
    echo "或者一次性设置（仅当前会话有效）:"
    echo "  CF_EMAIL='邮箱' CF_API_KEY='Key' ./deploy.sh"
    echo ""
    echo "获取 Global API Key:"
    echo "1. 访问 https://dash.cloudflare.com"
    echo "2. 点击右上角头像 → My Profile"
    echo "3. 选择 API Tokens → Global API Key → View"
    exit 1
fi

echo "🚀 开始部署 China Science Camp 到 Cloudflare Pages..."

# 查询 Zone ID
echo "🔍 查询 uichain.org 的 Zone ID..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=uichain.org" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY")

ZONE_ID=$(echo $ZONE_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') and len(d['result'])>0 else '')")

if [ -z "$ZONE_ID" ]; then
    echo "❌ 无法获取 Zone ID，请检查邮箱和 API Key 是否正确"
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

echo $PROJECT_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 项目创建/已存在' if d.get('success') else f'⚠️ 项目创建结果: {d}')"

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
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
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
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "chinasciencecamp.uichain.org"}')

echo $DOMAIN_RESPONSE | python3 -c "import sys,json; d=json.load(sys.stdin); print('✅ 自定义域名添加成功' if d.get('success') else f'⚠️ 域名添加结果: {d.get(\"errors\", [{}])[0].get(\"message\", \"未知错误\")}')"

echo ""
echo "🎉 部署完成!"
echo ""
echo "访问地址:"
echo "  - https://china-science-camp.pages.dev (Cloudflare 自动域名)"
echo "  - https://chinasciencecamp.uichain.org (自定义域名，需DNS配置生效)"
echo ""
echo "💡 提示: 如果自定义域名无法访问，请检查 Cloudflare Dashboard 中的 DNS 记录配置"
