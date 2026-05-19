#!/bin/bash

# apply existing migrations
python3 manage.py migrate

# make migrations for specific apps
apps=(
    "targetApp"
    "scanEngine"
    "startScan"
    "dashboard"
    "recon_note"
)

create_migrations() {
    local app=$1
    echo "Creating migrations for $app..."
    python3 manage.py makemigrations $app
    echo "Finished creating migrations for $app"
    echo "----------------------------------------"
}

echo "Starting migration creation process..."

for app in "${apps[@]}"
do
    create_migrations $app
done

echo "Migration creation process completed."

# apply migrations again
echo "Applying migrations..."
python3 manage.py migrate
echo "Migration process completed."


python3 manage.py collectstatic --no-input --clear

# Load default engines, keywords, and external tools
python3 manage.py loaddata fixtures/default_scan_engines.yaml --app scanEngine.EngineType
python3 manage.py loaddata fixtures/default_keywords.yaml --app scanEngine.InterestingLookupModel
python3 manage.py loaddata fixtures/external_tools.yaml --app scanEngine.InstalledExternalTool

# install firefox https://askubuntu.com/a/1404401
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 1:1snap1-0ubuntu2
Pin-Priority: -1
' | tee /etc/apt/preferences.d/mozilla-firefox
apt update -qq
apt install -y -qq firefox

# clone dirsearch default wordlist
if [ ! -d "/usr/src/wordlist" ]
then
  echo "Making Wordlist directory"
  mkdir /usr/src/wordlist
fi

if [ ! -f "/usr/src/wordlist/dicc.txt" ]
then
  echo "Downloading Default Directory Bruteforce Wordlist"
  wget -q https://raw.githubusercontent.com/maurosoria/dirsearch/master/db/dicc.txt -O /usr/src/wordlist/dicc.txt
fi

# clone eyewitness
if [ ! -d "/usr/src/github/EyeWitness" ]
then
  echo "Cloning EyeWitness"
  git clone -q https://github.com/FortyNorthSecurity/EyeWitness /usr/src/github/EyeWitness
fi
pip install -q psutil fuzzywuzzy selenium pyvirtualdisplay

# clone vulscan
if [ ! -d "/usr/src/github/scipag_vulscan" ]
then
  echo "Cloning Nmap Vulscan script"
  git clone -q https://github.com/scipag/vulscan /usr/src/github/scipag_vulscan
  echo "Symlinking to nmap script dir"
  ln -s /usr/src/github/scipag_vulscan /usr/share/nmap/scripts/vulscan
fi

# install WhatWeb
if [ ! -d "/usr/src/github/WhatWeb" ]
then
  echo "Cloning WhatWeb"
  git clone -q https://github.com/urbanadventurer/WhatWeb /usr/src/github/WhatWeb
fi
cd /usr/src/github/WhatWeb && gem install bundler -N && bundle install

# clone CMSeeK
if [ ! -d "/usr/src/github/CMSeeK" ]
then
  echo "Cloning CMSeeK"
  git clone -q https://github.com/Tuhinshubhra/CMSeeK /usr/src/github/CMSeeK
fi
pip install -q -r /usr/src/github/CMSeeK/requirements.txt

# store scan_results
if [ ! -d "/usr/src/scan_results" ]
then
  mkdir /usr/src/scan_results
fi

# test tools
naabu
nuclei

# httpx alias
echo 'alias httpx="/go/bin/httpx"' >> ~/.bashrc

loglevel='info'
if [ "$DEBUG" == "1" ]; then
    loglevel='debug'
fi

generate_worker_command() {
    local queue=$1
    local concurrency=$2
    local worker_name=$3
    local app=${4:-"reNgine.tasks"}
    local directory=${5:-"/usr/src/app/reNgine/"}

    local base_command="celery -A $app worker --pool=gevent --optimization=fair --autoscale=$concurrency,1 --loglevel=$loglevel -Q $queue -n $worker_name"

    if [ "$DEBUG" == "1" ]; then
        echo "watchmedo auto-restart --recursive --pattern=\"*.py\" --directory=\"$directory\" -- $base_command &"
    else
        echo "$base_command &"
    fi
}

echo "Starting Celery Workers..."

commands=""

# Main scan worker
if [ "$DEBUG" == "1" ]; then
    commands+="watchmedo auto-restart --recursive --pattern=\"*.py\" --directory=\"/usr/src/app/reNgine/\" -- celery -A reNgine.tasks worker --loglevel=$loglevel --optimization=fair --autoscale=$MAX_CONCURRENCY,$MIN_CONCURRENCY -Q main_scan_queue &"$'\n'
else
    commands+="celery -A reNgine.tasks worker --loglevel=$loglevel --optimization=fair --autoscale=$MAX_CONCURRENCY,$MIN_CONCURRENCY -Q main_scan_queue &"$'\n'
fi

# API shared task worker
if [ "$DEBUG" == "1" ]; then
    commands+="watchmedo auto-restart --recursive --pattern=\"*.py\" --directory=\"/usr/src/app/api/\" -- celery -A api.shared_api_tasks worker --pool=gevent --optimization=fair --concurrency=30 --loglevel=$loglevel -Q api_queue -n api_worker &"$'\n'
else
    commands+="celery -A api.shared_api_tasks worker --pool=gevent --concurrency=30 --optimization=fair --loglevel=$loglevel -Q api_queue -n api_worker &"$'\n'
fi

# worker format: "queue_name:concurrency:worker_name"
workers=(
    "initiate_scan_queue:30:initiate_scan_worker"
    "subscan_queue:30:subscan_worker"
    "report_queue:20:report_worker"
    "send_notif_queue:10:send_notif_worker"
    "send_task_notif_queue:10:send_task_notif_worker"
    "send_file_to_discord_queue:5:send_file_to_discord_worker"
    "parse_nmap_results_queue:10:parse_nmap_results_worker"
    "geo_localize_queue:20:geo_localize_worker"
    "query_whois_queue:10:query_whois_worker"
    "remove_duplicate_endpoints_queue:30:remove_duplicate_endpoints_worker"
    "run_command_queue:50:run_command_worker"
    "fingerprint_queue:10:fingerprint_worker"
)

for worker in "${workers[@]}"; do
    IFS=':' read -r queue concurrency worker_name <<< "$worker"
    commands+="$(generate_worker_command "$queue" "$concurrency" "$worker_name")"$'\n'
done
commands="${commands%&}"

eval "$commands"

wait
