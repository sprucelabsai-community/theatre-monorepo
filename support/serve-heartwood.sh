#!/bin/bash
set -e

# Set DIR to the current working directory
DIR="$(pwd)"
source ./support/hero.sh

# Default value for shouldCreateCaddyfile
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
        # Unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# is heartwood even installed
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill"
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Heartwood not installed. Skipping serve..."
    exit 0
fi

# Define the path to the heartwood-skill directory
heartwood_dist_dir="$heartwood_skill_dir/dist"

# Check if the heartwood-skill directory exists
if [ ! -d "$heartwood_dist_dir" ]; then
    echo "Error: The $heartwood_dist_dir directory does not exist. You need to run 'yarn bundle.heartwood'."
    exit 0
fi

web_server_port=8080

# look inside packages/spruce-heartwood-skill/.env
# if it exists, source it
if [ -f "$heartwood_dist_dir/../.env" ]; then
    source "$heartwood_dist_dir/../.env"
    # if WEB_SERVER_PORT is set, use it
    web_server_port=${WEB_SERVER_PORT:-8080}
fi

# Ensure the .processes directory exists
mkdir -p .processes

# Create timestamped log entry
log_file=".processes/caddy-heartwood.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Caddy server on port $web_server_port" >> "$log_file"

# Check if Caddy is already running
if [ -f ".processes/caddy-heartwood.pid" ]; then
    old_pid=$(cat .processes/caddy-heartwood.pid)
    if ps -p "$old_pid" > /dev/null 2>&1; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Caddy already running with PID $old_pid. Stopping it first." >> "$log_file"
        kill "$old_pid" 2>/dev/null || true
        sleep 2
    fi
fi

# Create a Caddyfile if shouldCreateCaddyfile is true
if [ "$shouldCreateCaddyfile" = true ]; then
    echo ":$web_server_port {
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
}" >Caddyfile
    echo "Caddyfile created with logging enabled."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Created new Caddyfile" >> "$log_file"
else
    echo "Skipping Caddyfile creation."
fi

# Function to log with timestamp
log_with_timestamp() {
    while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" >> "$log_file"
    done
}

# Run Caddy with better logging
echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing: caddy run --config ./Caddyfile" >> "$log_file"

# Start Caddy and capture both stdout and stderr with timestamps
(caddy run --config ./Caddyfile 2>&1 | log_with_timestamp) &
caddy_pid=$!

# Save the PID of the Caddy process
echo "$caddy_pid" > .processes/caddy-heartwood.pid
echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy started with PID: $caddy_pid" >> "$log_file"

echo "Starting webserver on $web_server_port..."

# Wait for Caddy to start
sleep 3

# Check if Caddy process is still running
if ! ps -p "$caddy_pid" > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy process died immediately" >> "$log_file"
    echo "Error: Caddy process died. Check logs:"
    tail -20 "$log_file"
    exit 1
fi

# Check if Caddy is listening on the port
if ! nc -zv 127.0.0.1 "$web_server_port" >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy not responding on port $web_server_port" >> "$log_file"
    echo "Error: Caddy did not start successfully. Recent logs:"
    tail -20 "$log_file"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy successfully started and responding on port $web_server_port" >> "$log_file"
hero "Heartwood is now serving at http://localhost:$web_server_port"

# Create a monitoring script
cat > .processes/monitor-caddy.sh << 'EOF'
#!/bin/bash
# Monitor Caddy and restart if needed

log_file=".processes/caddy-heartwood.log"
pid_file=".processes/caddy-heartwood.pid"

if [ ! -f "$pid_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: PID file not found" >> "$log_file"
    exit 1
fi

pid=$(cat "$pid_file")

if ! ps -p "$pid" > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Caddy process $pid not running. Service died!" >> "$log_file"
    echo "Caddy process died! Check $log_file for details."
    exit 1
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Caddy process $pid is running normally" >> "$log_file"
fi
EOF

chmod +x .processes/monitor-caddy.sh

echo "Monitoring script created at .processes/monitor-caddy.sh"
echo "Run it periodically to check if Caddy is still running."