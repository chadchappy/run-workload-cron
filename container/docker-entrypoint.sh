#!/bin/bash
set -e

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }

log "Starting RunAI Workload Manager container..."

# Verify RunAI CLI is available
if command -v runai &> /dev/null; then
    log "RunAI CLI is pre-installed: $(runai version)"
else
    echo "ERROR: RunAI CLI not found!"
    exit 1
fi

# Configure RunAI CLI with control plane URL
log "Configuring RunAI CLI with control plane URL..."
su runai -c "export RUNAI_CLI_CONFIG_PATH=/home/runai/.runai && /usr/local/bin/runai config set --cp-url https://us-demo-west.runailabs-ps.com"
su runai -c "export RUNAI_CLI_CONFIG_PATH=/home/runai/.runai && /usr/local/bin/runai config set --auth-url https://us-demo-west.runailabs-ps.com"

log "RunAI CLI configured successfully"

# Set up environment for cron
log "Setting up environment for cron..."
printenv | grep -v "no_proxy" >> /etc/environment

# Set up cron schedule
log "Setting up cron schedule..."
# Cron schedule: Every hour except 8am-4pm Pacific (0 0-7,16-23 * * *)
echo "0 0-7,16-23 * * * . /etc/environment && /usr/local/bin/runai-daemon.sh >> /var/log/runai-daemon.log 2>&1" | crontab -u runai -

# Create supervisor configuration
log "Creating supervisor configuration..."
cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/dev/stdout
logfile_maxbytes=0
loglevel=info

[program:cron]
command=/usr/sbin/cron -f
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# Start supervisor
log "Starting supervisor to manage cron daemon..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

