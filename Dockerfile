FROM alpine:latest
WORKDIR /app

# 设置环境变量（固定哪吒Agent版本为v0.20.5）
ENV SERVER_DOMAIN=example.clawcloudrun.com
ENV UDP_PORT=5678
ENV PASSWORD=your-uuid-password
ENV DASHBOARD_VERSION=v0.20.5  # 直接指定固定版本

# 安装依赖 & 创建必要目录
RUN apk update && \
    apk add --no-cache curl wget openssl bash jq unzip ca-certificates && \
    mkdir -p /etc/hysteria

# 下载 hysteria2 主程序
RUN wget -q -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64 && \
    chmod +x /usr/local/bin/hysteria

# 自签 TLS 证书
RUN openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -subj "/CN=bing.com" -days 36500

# 下载并解压 nezha-agent (直接指定v0.20.5版本)
RUN set -eux; \
    API_URL="https://api.github.com/repos/nezhahq/agent/releases/tags/v0.20.5"; \
    AGENT_URL=$(curl -s -H "Accept: application/vnd.github.v3+json" $API_URL | jq -r '.assets[] | select(.name | endswith("linux_amd64.zip")) | .browser_download_url'); \
    if [ -z "$AGENT_URL" ] || [ "$AGENT_URL" = "null" ]; then \
        echo "❌ 获取 Agent 下载地址失败，退出"; exit 1; \
    fi; \
    wget -O nezha-agent.zip "$AGENT_URL"; \
    unzip nezha-agent.zip; \
    rm nezha-agent.zip; \
    chmod +x nezha-agent

# 拷贝 entrypoint 启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 显示 UDP 端口
EXPOSE ${UDP_PORT}/udp

# 启动脚本作为容器入口
ENTRYPOINT ["/start.sh"]
