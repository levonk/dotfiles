FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Xfce, VNC server, noVNC, git, ssh, and basic dev tools
RUN apt-get update && \
	apt-get install -y \
	xfce4 xfce4-terminal tigervnc-standalone-server tigervnc-common \
	supervisor wget git openssh-server sudo curl \
	dbus-x11 x11-xserver-utils && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

# Install noVNC
RUN mkdir -p /opt/novnc && \
	wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz --strip-components=1 -C /opt/novnc && \
	wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz | tar xz --strip-components=1 -C /opt/novnc/utils/websockify

# Create user
env USERNAME=dev
RUN useradd -ms /bin/bash $USERNAME && \
	echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /home/dev/.local/share/chezmoi && chown -R dev:dev /home/dev/.local

# Install chezmoi (latest, as root)
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# SSH for VSCode/other IDEs
RUN mkdir /var/run/sshd
EXPOSE 22

# VNC and noVNC ports
EXPOSE 5901 6080

# Install VSCode Remote CLI (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Expose code-server port
EXPOSE 8080


# Copy supervisor config and entrypoint
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER $USERNAME
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
