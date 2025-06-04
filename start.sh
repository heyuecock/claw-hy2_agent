#!/bin/bash
set -e

echo "🟢 正在启动服务..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Nezha Agent 配置:"
echo "   - 服务器: ${NZ_SERVER}"
echo "   - 密钥: ${NZ_CLIENT_SECRET}"
echo "   - TLS: ${NZ_TLS}"
echo "   - 版本: ${DASHBOARD_VERSION:-latest}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Hysteria2 配置:"
echo "   - 域名: ${SERVER_DOMAIN}"
echo "   - UDP端口: ${UDP_PORT}"
echo "   - 密码: ${PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 生成 Nezha Agent 配置 (已移除uuid字段)
cat > /app/config.yaml <<EOF
debug: true
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 4
server: ${NZ_SERVER}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: ${NZ_TLS}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
client_secret: ${NZ_CLIENT_SECRET}
EOF

# 创建 Hysteria2 配置文件
cat > /etc/hysteria/config.yaml <<EOF
listen: :${UDP_PORT}

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: ${PASSWORD}

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF

# 启动 Hysteria2 到后台
/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml &

# 获取连接信息
SERVER_IP=$(curl -s https://api.ipify.org || echo "未知IP")
COUNTRY_CODE=$(curl -s https://ipapi.co/${SERVER_IP}/country/ || echo "XX")

echo "✅ 服务启动成功"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Hysteria2 客户端连接信息:"
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${UDP_PORT}?sni=bing.com&insecure=1#${SERVER_DOMAIN}-${COUNTRY_CODE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 启动 Nezha Agent 作为主进程
exec ./nezha-agent --config /app/config.yaml
