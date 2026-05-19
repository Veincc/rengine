# AGENTS.md

This file provides guidance to Codex when working in this repository.

## Communication

- Use Chinese when replying to the project owner.
- This repository is in active secondary development. Prefer reading the current code before assuming upstream reNgine behavior.

## Project Overview

This is a simplified fork of reNgine, a Django-based reconnaissance and vulnerability scanning platform. The original broad toolchain has been reduced to a smaller, easier-to-maintain set focused on subdomain discovery, port scanning, URL collection, fingerprinting, nuclei scanning, directory fuzzing, and screenshots.

Major removed areas:
- LLM/GPT/Ollama vulnerability explanation and attack suggestion features.
- Bug Bounty mode, Bounty Hub, HackerOne integration, and HackerOne report submission.
- WAF detection, Google dorking, GF pattern matching, and most external API-key driven discovery integrations.

## Tech Stack

- Backend: Django 3.2, Python 3.10
- Task Queue: Celery 5.4 with Redis broker/backend
- Database: PostgreSQL 12
- Deployment: Docker Compose
- Web Server: Gunicorn + Nginx reverse proxy

## Current Tool Set

Core tools kept:
- Nuclei: template-based vulnerability scanning
- httpx: HTTP probing, status/title/basic technology checks
- naabu: port scanning
- ffuf: directory and file fuzzing
- sublist3r: OSINT subdomain discovery
- OneForAll: OSINT subdomain discovery
- katana: crawler and URL collection
- gau: historical/multi-source URL collection

Auxiliary tools kept:
- nmap
- vulscan: nmap NSE vulnerability scripts
- unfurl
- EyeWitness: screenshots

Fingerprinting tools:
- WhatWeb
- CMSeeK

Tools/features intentionally removed:
- subfinder, amass, gospider, hakrawler, waybackurls
- dalfox, crlfuzz, s3scanner, gf
- theHarvester, h8mail, ctfr, tlsx, netlas, chaos, wafw00f, GooFuzz
- TideFinger was tried briefly, then removed by project decision.

## Current Scan Flow

The active scan DAG is:

```text
[subdomain_discovery | osint]
  -> port_scan
  -> [fetch_url | dir_file_fuzz]
  -> fingerprint
  -> [vulnerability_scan | screenshot]
```

Task meaning:
- `subdomain_discovery`: runs sublist3r and OneForAll.
- `osint`: framework is preserved, but concrete OSINT tools are intentionally empty for later customization.
- `port_scan`: runs naabu and optional nmap/vulscan logic.
- `fetch_url`: runs katana and gau.
- `dir_file_fuzz`: runs ffuf in parallel with URL collection.
- `fingerprint`: runs WhatWeb and CMSeeK after URL collection/fuzzing dedup.
- `vulnerability_scan`: nuclei only.
- `screenshot`: EyeWitness.

Do not reintroduce the old flow `subdomain_discovery -> port_scan -> http_crawl -> vulnerability_scan`.

## Development Commands

Standard commands:

```bash
make up
make build
make stop
make restart
make logs
make migrate
make test
```

Development workflow commands:

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

Development mode uses `docker-compose.dev.yml` and `web/celery-entrypoint-dev.sh`. It is designed to avoid reinstalling or recloning tools on every container restart. Use `make dev-install-tools` only when the tool installation layer needs to be refreshed inside the dev container.

When YAML fixtures are changed, reload them:

```bash
docker compose -f docker-compose.dev.yml exec web python3 manage.py loaddata fixtures/default_scan_engines.yaml fixtures/external_tools.yaml
```

## Key Files

- `web/reNgine/tasks.py`: Celery scan DAG and tool task implementations.
- `web/reNgine/definitions.py`: YAML keys and scan constants.
- `web/reNgine/common_func.py`: shared helpers, including service-name fallback logic.
- `web/reNgine/celery_custom_task.py`: `RengineTask` base class and task tracking.
- `web/fixtures/default_scan_engines.yaml`: default scan engine YAML templates.
- `web/fixtures/external_tools.yaml`: current installed tool registry fixture.
- `web/celery-entrypoint.sh`: production container startup and tool bootstrap.
- `web/celery-entrypoint-dev.sh`: lightweight development Celery startup.
- `scripts/install-tools.sh`: one-shot dev tool installation helper.

Deleted/removed files:
- `web/reNgine/llm.py`
- `web/api/shared_api_tasks.py`

## Database State

Removed models/features:
- `OpenAiAPIKey`, `OllamaSettings`, `NetlasAPIKey`, `ChaosAPIKey`, `HackerOneAPIKey`, `UserPreferences`
- `Hackerone`
- `GPTVulnerabilityReport`
- WAF model/relationship and GF pattern tracking
- Vulnerability GPT/HackerOne fields

Added model:
- `Fingerprint` for fingerprinting results.

Relevant cleanup migrations:
- `web/dashboard/migrations/0003_remove_api_keys_and_user_preferences.py`
- `web/scanEngine/migrations/0003_remove_hackerone.py`
- `web/startScan/migrations/0003_remove_waf_and_gf_add_fingerprint.py`

## Important Gotchas

- Do not re-add `FETCH_GPT_REPORT`, `DEFAULT_GET_GPT_REPORT`, `GF_PATTERNS`, `DEFAULT_GF_PATTERNS`, `RUN_TIDEFINGER`, HackerOne constants, or OpenAI/Ollama settings.
- `whatportis` was removed because it caused dependency/import problems. Service descriptions should use the current socket-based fallback in `common_func.py`.
- `api_queue`/HackerOne background tasks were removed with `api.shared_api_tasks`.
- WAF detection is removed; CMS fingerprinting is handled through CMSeeK in the fingerprint phase.
- If Celery fails to import, first check for stale references to deleted modules/constants in `tasks.py`, `api/urls.py`, `api/views.py`, and entrypoint worker queue names.
