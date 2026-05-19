#!/bin/bash

# Development entrypoint - skip tool installation
# Tools should be pre-installed in the Docker image

echo "=== Development Mode ==="
echo "Skipping tool installation (use production entrypoint for first-time setup)"

# apply existing migrations
python3 manage.py migrate

loglevel='debug'

# Start main scan worker with watchmedo for auto-reload
echo "Starting Celery Workers (with auto-reload)..."

# Main scan worker - auto-reload on .py file changes
watchmedo auto-restart --recursive --pattern="*.py" --directory="/usr/src/app/reNgine/" -- celery -A reNgine.tasks worker --loglevel=$loglevel --optimization=fair --autoscale=$MAX_CONCURRENCY,$MIN_CONCURRENCY -Q main_scan_queue &

# Other workers (simplified for development)
generate_worker_command() {
    local queue=$1
    local concurrency=$2
    local worker_name=$3

    echo "celery -A reNgine.tasks worker --pool=gevent --optimization=fair --autoscale=$concurrency,1 --loglevel=$loglevel -Q $queue -n $worker_name &"
}

workers=(
    "initiate_scan_queue:10:initiate_scan_worker"
    "subscan_queue:10:subscan_worker"
    "report_queue:5:report_worker"
    "send_notif_queue:5:send_notif_worker"
    "run_command_queue:20:run_command_worker"
    "fingerprint_queue:5:fingerprint_worker"
)

commands=""
for worker in "${workers[@]}"; do
    IFS=':' read -r queue concurrency worker_name <<< "$worker"
    commands+="$(generate_worker_command "$queue" "$concurrency" "$worker_name")"$'\n'
done

eval "$commands"

wait
