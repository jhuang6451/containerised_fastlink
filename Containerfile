FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

COPY fastlink.deb /tmp/airport-client.deb

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    fonts-wqy-microhei \
    libgtk-3-0 \
    libx11-xcb1 \
    libnss3 \
    libasound2 \
    ca-certificates \
    libayatana-appindicator3-1 \
    libkeybinder-3.0-0 \
    libdbus-1-3 \
    /tmp/airport-client.deb \
    && rm /tmp/airport-client.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 清理锁文件 -> D-Bus -> Xvfb -> fluxbox -> x11vnc -> websockify -> 客户端
RUN echo '#!/bin/bash\n\
# 1. 清理可能存在的 X11 残留锁文件，防止重启失败
rm -f /tmp/.X*-lock /tmp/.X11-unix/X*\n\
\n\
# 2. 启动 D-Bus
mkdir -p /var/run/dbus\n\
dbus-uuidgen > /var/lib/dbus/machine-id\n\
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address --fork\n\
export $(dbus-launch)\n\
\n\
# 3. 启动虚拟显示器 (使用 24 位色深)
Xvfb :99 -screen 0 1024x768x24 &\n\
export DISPLAY=:99\n\
sleep 1\n\
\n\
# 4. 启动轻量级窗口管理器
fluxbox &\n\
\n\
# 5. 启动 VNC 服务端
x11vnc -display :99 -nopw -forever -bg -xkb -q -noxdamage -shared\n\
\n\
# 6. 启动 noVNC 代理 (监听 6080，转发到 5900)
websockify --web /usr/share/novnc/ 6080 localhost:5900 &\n\
\n\
# 7. 启动你的客户端
echo "启动客户端..."\n\
exec FastLink "$@"\n\
' > /start.sh && chmod +x /start.sh

# VNC 默认端口 5900, noVNC 端口 6080
EXPOSE 7892 5900 6080

ENTRYPOINT ["/start.sh"]
