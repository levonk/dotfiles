#!/bin/bash
set -e

# Optionally clone shared models repo
if [ "$GIT_CLONE_MODELS" = "true" ] && [ -n "$MODELS_REPO_URL" ]; then
  if [ ! -d /workspace/shared/.git ]; then
    git clone "$MODELS_REPO_URL" /workspace/shared
  fi
fi

# Optionally clone project repo
if [ "$GIT_CLONE_PROJECT" = "true" ] && [ -n "$PROJECT_REPO_URL" ]; then
  if [ ! -d /workspace/project/.git ]; then
    git clone "$PROJECT_REPO_URL" /workspace/project
  fi
fi

mkdir -p /home/dev/.ssh
cat /tmp/host_id_ed25519.pub >> /home/dev/.ssh/authorized_keys
chown -R dev:dev /home/dev/.ssh
chmod 600 /home/dev/.ssh/authorized_keys

# Start supervisor (which runs VNC, noVNC, etc.)
exec /usr/bin/supervisord

service ssh start
