# 安全部署指南

## 改进内容

### 原脚本的安全问题
- `deploy.sh <邮箱> <API Key>` - 凭证作为命令行参数传递
- `deploy-token.sh <API Token>` - Token 作为命令行参数传递

**风险**：
1. 命令行历史（`~/.bash_history`）会记录完整命令和凭证
2. 进程列表（`ps aux`）可看到命令参数
3. 系统日志可能记录完整命令

### 改进后的安全方案

#### 方式一：API Token（推荐）

使用 `deploy-token-secure.sh`：

```bash
# 方法1：先设置环境变量（推荐，Token 不会进入历史记录）
export CF_API_TOKEN='你的API Token'
./deploy-token-secure.sh

# 方法2：单次设置（仅当前命令有效）
CF_API_TOKEN='你的API Token' ./deploy-token-secure.sh
```

#### 方式二：Global API Key

使用 `deploy-secure.sh`：

```bash
# 方法1：先设置环境变量
export CF_EMAIL='你的邮箱'
export CF_API_KEY='你的Global API Key'
./deploy-secure.sh

# 方法2：单次设置
CF_EMAIL='邮箱' CF_API_KEY='Key' ./deploy-secure.sh
```

### 环境变量 vs 命令行参数

| 特性 | 命令行参数 | 环境变量 |
|------|-----------|---------|
| shell history | ❌ 会记录 | ✅ 不会记录（export 会记录，但值不会） |
| 进程列表 | ❌ 其他用户可见 | ✅ 不可见 |
| 系统日志 | ❌ 可能记录 | ✅ 更安全 |

### 额外安全措施

1. **使用 `.env` 文件（不推荐提交到 Git）**
   ```bash
   # .env 文件（已添加到 .gitignore）
   CF_API_TOKEN=your_token_here
   
   # 加载环境变量
   source .env
   ./deploy-token-secure.sh
   ```

2. **使用密码管理器**
   ```bash
   # 例如使用 1Password CLI
   export CF_API_TOKEN=$(op read "op://vault/item/field")
   ./deploy-token-secure.sh
   ```

3. **限制 API Token 权限**
   - 只授予必要的权限（Zone:Read, Pages:Edit）
   - 设置 IP 限制（如果适用）
   - 定期轮换 Token

### 清理历史记录

如果之前使用过旧脚本，建议清理 shell 历史：

```bash
# 查看历史记录
history | grep "deploy.sh\|deploy-token.sh"

# 删除特定行
history -d <行号>

# 或清空整个历史（谨慎操作）
history -c
```

### 文件清单

- `deploy-token-secure.sh` - 使用 API Token 的安全版本
- `deploy-secure.sh` - 使用 Global API Key 的安全版本
- `README-SECURITY.md` - 本文档

### 旧脚本处理建议

建议删除或重命名旧脚本，避免误用：

```bash
# 备份旧脚本
git mv deploy.sh deploy-old.sh
git mv deploy-token.sh deploy-token-old.sh

# 添加新脚本
git add deploy-secure.sh deploy-token-secure.sh README-SECURITY.md
git commit -m "改进部署脚本安全性：使用环境变量替代命令行参数"
git push
```
