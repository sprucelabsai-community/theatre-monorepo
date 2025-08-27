#!/bin/bash
set -e

# ────────────────────────────────────────────────────
# Kill any previous serve-heartwood.sh instances
# ────────────────────────────────────────────────────
SCRIPT_NAME="serve-heartwood.sh"
CURRENT_PID=$$

# Get all other running serve-heartwood.sh PIDs (excluding current)
OTHER_PIDS=$(pgrep -f "$SCRIPT_NAME" | grep -v "$CURRENT_PID" || true)

if [ -n "$OTHER_PIDS" ]; then
    echo "Found other running instances of $SCRIPT_NAME: $OTHER_PIDS"
    echo "Terminating previous instances..."
    echo "$OTHER_PIDS" | xargs kill -9 2>/dev/null || true
fi

# ────────────────────────────────────────────────────
# Set DIR to the current working directory
# ────────────────────────────────────────────────────
DIR="$(pwd)"
source ./support/hero.sh
shouldCreateCaddyfile=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --shouldCreateCaddyfile=*)
        shouldCreateCaddyfile="${key#*=}"
        shift
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# ────────────────────────────────────────────────────
# Validate Heartwood installation
# ────────────────────────────────────────────────────
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill"
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Heartwood not installed. Skipping server start."
    exit 0
fi

heartwood_dist_dir="$heartwood_skill_dir/dist"
if [ ! -d "$heartwood_dist_dir" ]; then
    echo "Error: The $heartwood_dist_dir directory does not exist. Please run 'yarn bundle.heartwood'."
    exit 0
fi

web_server_port=8080
if [ -f "$heartwood_dist_dir/../.env" ]; then
    source "$heartwood_dist_dir/../.env"
    web_server_port=${WEB_SERVER_PORT:-8080}
fi

# ────────────────────────────────────────────────────
# Logging and setup
# ────────────────────────────────────────────────────
mkdir -p .processes
log_file=".processes/caddy-heartwood.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Caddy server on port $web_server_port" >>"$log_file"

# ────────────────────────────────────────────────────
# Stop any existing Caddy process
# ────────────────────────────────────────────────────
if [ -f ".processes/caddy-heartwood.pid" ]; then
    old_pid=$(cat .processes/caddy-heartwood.pid)
    if ps -p "$old_pid" -o comm= | grep -q "caddy"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Stopping existing Caddy process with PID $old_pid" >>"$log_file"
        kill "$old_pid" 2>/dev/null || true
        sleep 2
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Found stale PID file ($old_pid). Removing." >>"$log_file"
        rm -f .processes/caddy-heartwood.pid
    fi
fi

# Check if lsof is available
if ! command -v lsof &>/dev/null; then
    echo "Warning: 'lsof' is not installed. Skipping orphaned Caddy process cleanup."
    skip_lsof=true
else
    skip_lsof=false
fi

# Kill any orphaned caddy processes on the specified port
if [ "$skip_lsof" = false ]; then
    CADDY_PIDS=$(lsof -ti :$web_server_port -sTCP:LISTEN | xargs ps -o pid=,comm= | grep caddy | awk '{print $1}' || true)

    if [ -n "$CADDY_PIDS" ]; then
        echo "Terminating orphaned Caddy processes on port $web_server_port: $CADDY_PIDS"
        echo "$CADDY_PIDS" | xargs kill -9 2>/dev/null || true
    fi
else
    echo "Skipping orphaned Caddy process cleanup due to missing 'lsof'."
fi

# ────────────────────────────────────────────────────
# Create Caddyfile if required
# ────────────────────────────────────────────────────
if [ "$shouldCreateCaddyfile" = true ]; then
    cat >Caddyfile <<EOF
:$web_server_port {
    bind 0.0.0.0
    root * $heartwood_dist_dir
    file_server

    log {
        output file .processes/caddy-access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }
}
EOF
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddyfile created" >>"$log_file"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipping Caddyfile creation" >>"$log_file"
fi

# ────────────────────────────────────────────────────
# Log output with timestamps
# ────────────────────────────────────────────────────
log_with_timestamp() {
    while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" >>"$log_file"
    done
}

# ────────────────────────────────────────────────────
# Start Caddy
# ────────────────────────────────────────────────────
echo "$(date '+%Y-%m-%d %H:%M:%S') - Launching Caddy" >>"$log_file"
(caddy run --config ./Caddyfile 2>&1 | log_with_timestamp) &
caddy_pid=$!

echo "$caddy_pid" >.processes/caddy-heartwood.pid
echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy started with PID $caddy_pid" >>"$log_file"
echo "Heartwood is serving on port $web_server_port..."
sleep 3

# ────────────────────────────────────────────────────
# Health checks
# ────────────────────────────────────────────────────
if ! ps -p "$caddy_pid" >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy process exited immediately" >>"$log_file"
    echo "Error: Caddy exited unexpectedly. See logs below:"
    tail -20 "$log_file"
    exit 1
fi

if ! nc -zv 127.0.0.1 "$web_server_port" >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy not responding on port $web_server_port" >>"$log_file"
    echo "Error: Caddy is not responding. See logs below:"
    tail -20 "$log_file"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy is running and responding on port $web_server_port" >>"$log_file"
hero "Heartwood is now available at http://localhost:$web_server_port"

# ────────────────────────────────────────────────────
# Create monitor script
# ────────────────────────────────────────────────────
cat >.processes/monitor-caddy.sh <<'EOF'
#!/bin/bash
log_file=".processes/caddy-heartwood.log"
pid_file=".processes/caddy-heartwood.pid"

if [ ! -f "$pid_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: PID file missing" >> "$log_file"
    exit 1
fi

pid=$(cat "$pid_file")

if ! ps -p "$pid" > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy process $pid not running" >> "$log_file"
    echo "Caddy process is not running. Please check logs."
    exit 1
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy process $pid is running normally" >> "$log_file"
fi
EOF

chmod +x .processes/monitor-caddy.sh
echo "Monitor script created: .processes/monitor-caddy.sh"
