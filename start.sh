#!/bin/bash
set -e

echo "🟢 正在启动服务..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Nezha Agent 配置:"
echo "   - 服务器: ${NZ_SERVER}"
echo "   - 密钥: ${NZ_CLIENT_SECRET}"
echo "   - TLS: ${NZ_TLS}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Hysteria2 配置:"
echo "   - 域名: ${SERVER_DOMAIN}"
echo "   - UDP端口: ${UDP_PORT}"
echo "   - 密码: ${PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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

# 启动 Nezha Agent 使用命令行参数
exec ./nezha-agent \
    -s "${NZ_SERVER}" \
    -p "${NZ_CLIENT_SECRET}" \
    --tls="${NZ_TLS}" \
    --debug \
    --disable-auto-update \
    --disable-force-update \
    --report-delay=4 \
    --ip-report-period=1800 \
    --disable-command-execute=false \
    --disable-nat=false \
    --disable-send-query=false \
    --skip-conn=false \
    --skip-procs=false \
    --use-ipv6-countrycode=false
