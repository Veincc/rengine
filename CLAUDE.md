# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Communication

- Reply to the project owner in Chinese.
- This repository is an actively simplified fork of reNgine. Check the current code before applying upstream assumptions.

## Project Overview

reNgine is a Django-based reconnaissance and vulnerability scanner. This fork is being reduced for secondary development: the original broad tool ecosystem has been narrowed to a focused scanning pipeline and the LLM/Bug Bounty/API-key-heavy features have been removed.

Removed major product areas:
- LLM/GPT/Ollama vulnerability reporting and attack suggestions.
- Bug Bounty mode, Bounty Hub, HackerOne settings, HackerOne import/sync/reporting.
- WAF detection, Google dorking, GF pattern matching, and most external API discovery integrations.

## Tech Stack

- Backend: Django 3.2, Python 3.10
- Task Queue: Celery 5.4 with Redis broker/backend
- Database: PostgreSQL 12
- Deployment: Docker Compose
- Web Server: Gunicorn + Nginx reverse proxy

## Current Tool Set

Kept scanning tools:
- Nuclei: template-based vulnerability scanning
- httpx: HTTP probing, status/title/basic technology checks
- naabu: port scanning
- ffuf: directory and file fuzzing
- sublist3r: OSINT subdomain discovery
- OneForAll: OSINT subdomain discovery
- katana: crawler and URL collection
- gau: historical/multi-source URL collection

Kept auxiliary tools:
- nmap
- vulscan: nmap script-based checks
- unfurl
- EyeWitness: screenshots

Fingerprinting:
- WhatWeb
- CMSeeK

Removed tools:
- subfinder, amass, gospider, hakrawler, waybackurls
- dalfox, crlfuzz, s3scanner, gf
- theHarvester, h8mail, ctfr, tlsx, netlas, chaos, wafw00f, GooFuzz
- TideFinger was added experimentally, then removed by project decision.

## Current Scan Flow

The current scan workflow is:

```text
[subdomain_discovery | osint]
  -> port_scan
  -> [fetch_url | dir_file_fuzz]
  -> fingerprint
  -> [vulnerability_scan | screenshot]
```

Details:
- `subdomain_discovery`: sublist3r + OneForAll.
- `osint`: framework remains, concrete tools are intentionally empty for future customization.
- `port_scan`: naabu plus optional nmap/vulscan behavior.
- `fetch_url`: katana + gau.
- `dir_file_fuzz`: ffuf, parallel with URL collection.
- `fingerprint`: WhatWeb + CMSeeK after URL collection/fuzzing dedup.
- `vulnerability_scan`: nuclei only.
- `screenshot`: EyeWitness.

Do not restore the old upstream scan chain or the removed dalfox/crlfuzz/s3scanner/WAF/GPT branches.

## Development Commands

Standard Docker commands:

```bash
make up
make build
make stop
make restart
make logs
make migrate
make test
```

Development commands:

```bash
make dev-up
make dev-down
make dev-restart
make dev-restart-web
make dev-restart-celery
make dev-logs
make dev-logs-web
make dev-logs-celery
make dev-migrate
make dev-shell
make dev-install-tools
```

Development mode uses `docker-compose.dev.yml` and `web/celery-entrypoint-dev.sh` to avoid pulling/installing tools on every restart. Use `scripts/install-tools.sh` through `make dev-install-tools` for manual one-shot tool installation.

Reload scan engine/tool fixtures after YAML changes:

```bash
docker compose -f docker-compose.dev.yml exec web python3 manage.py loaddata fixtures/default_scan_engines.yaml fixtures/external_tools.yaml
```

## Architecture

Django apps:
- `reNgine`: settings, Celery config, scan tasks, shared definitions.
- `dashboard`: dashboard and project views.
- `targetApp`: domain/target management.
- `scanEngine`: YAML scan engine configuration and installed tool management.
- `startScan`: scan execution, history, subdomains, endpoints, vulnerabilities, fingerprints.
- `recon_note`: notes and todos.
- `api`: DRF endpoints for core data and scan operations.

Key files:
- `web/reNgine/tasks.py`: current Celery task DAG and tool invocation code.
- `web/reNgine/definitions.py`: YAML config keys and constants.
- `web/reNgine/common_func.py`: shared helper functions.
- `web/reNgine/celery_custom_task.py`: custom `RengineTask` base class.
- `web/fixtures/default_scan_engines.yaml`: current default engine YAML.
- `web/fixtures/external_tools.yaml`: current external tool registry.
- `web/celery-entrypoint.sh`: production startup/tool bootstrap.
- `web/celery-entrypoint-dev.sh`: lightweight dev Celery startup.
- `scripts/install-tools.sh`: dev tool installation helper.

Deleted files:
- `web/reNgine/llm.py`
- `web/api/shared_api_tasks.py`

## Database Notes

Removed models/features:
- `OpenAiAPIKey`, `OllamaSettings`, `NetlasAPIKey`, `ChaosAPIKey`, `HackerOneAPIKey`, `UserPreferences`
- `Hackerone`
- `GPTVulnerabilityReport`
- WAF model/relationship and GF pattern tracking
- GPT/HackerOne fields on vulnerability records

Added model:
- `Fingerprint`

Cleanup migrations:
- `web/dashboard/migrations/0003_remove_api_keys_and_user_preferences.py`
- `web/scanEngine/migrations/0003_remove_hackerone.py`
- `web/startScan/migrations/0003_remove_waf_and_gf_add_fingerprint.py`

## Gotchas

- Do not reintroduce old constants such as `FETCH_GPT_REPORT`, `DEFAULT_GET_GPT_REPORT`, `GF_PATTERNS`, `DEFAULT_GF_PATTERNS`, `RUN_TIDEFINGER`, HackerOne constants, or OpenAI/Ollama settings.
- `whatportis` was removed; keep the socket-based fallback in `common_func.py`.
- `api.shared_api_tasks` no longer exists; avoid restoring API/HackerOne Celery queues.
- WAF detection remains removed. CMSeeK is retained only as fingerprinting/CMS technology detection.
- If Celery import fails, search for stale references to deleted modules, queue names, models, serializers, URLs, and YAML constants.
