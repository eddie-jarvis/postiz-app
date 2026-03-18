# Postiz × Home Assistant — Implementation Plan

**Goal:** Self-hosted social media management (LinkedIn + X) as a Home Assistant add-on, with analytics sensors and API access for David (OpenClaw agent).

**Repo:** eddie-jarvis/postiz-app (fork of gitroomhq/postiz-app)

---

## Phase 1: Home Assistant Add-on Wrapper

**Objective:** Package Postiz as a HA add-on so it installs and runs from the HA Supervisor UI.

**Deliverables:**
- `ha-addon/config.yaml` — add-on metadata (name, description, ports, arch, options)
- `ha-addon/Dockerfile` — multi-service container (Postiz app + Postgres + Redis + Temporal)
- `ha-addon/run.sh` — startup script that initializes DB, runs migrations, starts all services
- `ha-addon/repository.yaml` — so the repo can be added as a custom HA add-on repository

**Key decisions:**
- All-in-one container (Postiz + Postgres + Redis + Temporal via supervisord/s6-overlay) vs separate containers
  - **Recommendation:** All-in-one with s6-overlay. HA add-ons are single containers. Multi-container is only possible via docker-compose on the host, which defeats the add-on purpose.
- Expose port 4007 (web UI) + internal API on same port
- Persistent data via `/data` (HA maps this to persistent storage)
- Config options exposed in HA UI: JWT_SECRET, social media API keys

**Acceptance criteria:**
- [ ] Add repo URL to HA → add-on appears in store
- [ ] Install add-on → starts without errors
- [ ] Access Postiz UI at `http://<HA_IP>:4007`
- [ ] Create account, data persists across restarts

**Estimated complexity:** Medium-high (s6-overlay multi-process in single container)

---

## Phase 2: Connect Social Accounts + Verify API

**Objective:** Connect LinkedIn and X accounts, verify the Postiz public API works for programmatic posting.

**Deliverables:**
- LinkedIn Developer App created (OAuth credentials)
- X Developer App created (API keys)
- Both connected in Postiz UI
- API key generated in Postiz (Settings > Developers > Public API)
- Test scripts: create draft, schedule post, list integrations

**Key decisions:**
- LinkedIn requires OAuth 2.0 with callback URL — Postiz handles this via its UI
- X free tier is sufficient for posting
- Store API keys in 1Password, inject via HA add-on config options

**Acceptance criteria:**
- [ ] `curl -H "Authorization: <key>" http://<HA_IP>:4007/api/public/v1/integrations` returns LinkedIn + X
- [ ] Can create a scheduled post via API
- [ ] Can retrieve post analytics via API

---

## Phase 3: HA Custom Integration (Analytics Sensors)

**Objective:** Expose Postiz analytics as Home Assistant sensors for dashboards and automations.

**Deliverables:**
- `custom_components/postiz/` — HA custom integration
  - `__init__.py` — setup
  - `config_flow.py` — UI-based configuration (Postiz URL + API key)
  - `sensor.py` — sensor entities
  - `const.py` — constants
  - `manifest.json` — integration metadata
  - `coordinator.py` — data update coordinator (polls Postiz API)

**Sensors to expose:**
- `sensor.postiz_linkedin_followers` — follower count
- `sensor.postiz_linkedin_impressions_7d` — 7-day impressions
- `sensor.postiz_linkedin_engagement_rate` — engagement rate
- `sensor.postiz_x_followers` — X follower count
- `sensor.postiz_x_impressions_7d` — X 7-day impressions
- `sensor.postiz_posts_scheduled` — number of scheduled posts
- `sensor.postiz_posts_published_7d` — posts published last 7 days
- `sensor.postiz_top_post` — best performing post (title + engagement)

**Key decisions:**
- Poll interval: every 30 minutes (rate limit is 30 req/hour, we use ~5 per poll)
- Use `DataUpdateCoordinator` pattern for efficient polling
- Config flow for easy setup via HA UI

**Acceptance criteria:**
- [ ] Integration installs via HACS or manual `custom_components/`
- [ ] Sensors update every 30 minutes with real data
- [ ] Sensors visible in HA developer tools

**Depends on:** Postiz API analytics endpoints being available (need to verify scope)

---

## Phase 4: David API Integration

**Objective:** Give David (OpenClaw agent) the ability to create, schedule, and manage content via Postiz API.

**Deliverables:**
- David TOOLS.md updated with Postiz API reference
- Shell wrapper script: `postiz-cli` (curl-based, stored in David's workspace)
  - `postiz-cli draft "content" --platform linkedin --schedule "2026-03-20T09:00"` 
  - `postiz-cli list-drafts`
  - `postiz-cli stats --days 7`
  - `postiz-cli integrations`
- David SOUL.md updated with Postiz workflow

**Workflow:**
1. David drafts content based on Emil's calendar, Slack, trends
2. David pushes draft to Postiz via API (scheduled as draft/pending)
3. Emil reviews in Postiz UI or via Telegram notification
4. Emil approves → Postiz publishes at scheduled time
5. David pulls analytics next day, adjusts strategy

**Acceptance criteria:**
- [ ] David can create a draft post via exec tool
- [ ] David can list scheduled posts
- [ ] David can pull engagement stats
- [ ] Emil receives Telegram notification when new draft is ready for review

---

## Phase 5: HA Dashboard

**Objective:** Beautiful dashboard card showing social media performance.

**Deliverables:**
- Lovelace dashboard YAML with:
  - Follower count cards (LinkedIn + X)
  - Impressions graph (7-day trend)
  - Engagement rate gauge
  - Upcoming scheduled posts list
  - Top performing post highlight

**Acceptance criteria:**
- [ ] Dashboard renders correctly
- [ ] Auto-updates with sensor data

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│  Home Assistant (Lenovo)                     │
│                                              │
│  ┌─────────────────────────────────────┐     │
│  │  Postiz Add-on (container)          │     │
│  │  ├── Postiz App (:4007)             │     │
│  │  ├── PostgreSQL                     │     │
│  │  ├── Redis                          │     │
│  │  └── Temporal                       │     │
│  └─────────────┬───────────────────────┘     │
│                │ REST API                     │
│  ┌─────────────┴───────────────────────┐     │
│  │  Custom Integration (sensors)       │     │
│  │  → Polls /public/v1/* every 30m     │     │
│  └─────────────────────────────────────┘     │
│                                              │
│  ┌─────────────────────────────────────┐     │
│  │  Dashboard (Lovelace)               │     │
│  │  → Renders sensor data              │     │
│  └─────────────────────────────────────┘     │
└──────────────────────┬──────────────────────┘
                       │ Tailscale / LAN
┌──────────────────────┴──────────────────────┐
│  MacBook (Eddie + David)                     │
│                                              │
│  David → curl Postiz API → create drafts     │
│  Eddie → orchestrates, notifies Emil         │
│  Emil  → reviews in Postiz UI / Telegram     │
└─────────────────────────────────────────────┘
```

---

## Execution Order

1. **Phase 1** → HA add-on (foundation — nothing works without this)
2. **Phase 2** → Connect accounts + verify API (manual setup, depends on Emil)
3. **Phase 3** → HA integration (sensors) — can develop in parallel with Phase 4
4. **Phase 4** → David integration (CLI wrapper + workflow)
5. **Phase 5** → Dashboard (polish, depends on Phase 3)

**Estimated total effort:** 2-3 focused dev sessions

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| s6-overlay complexity in HA container | Phase 1 delay | Fall back to docker-compose on host if add-on proves too complex |
| Postiz API doesn't expose analytics granularly | Phase 3 limited | Scrape from Postiz DB directly (we have Postgres access) |
| LinkedIn API rate limits | Phase 4 blocked | Postiz handles rate limiting internally |
| Temporal adds resource overhead on Lenovo | Performance | Monitor memory; disable Temporal if not needed for scheduling |
| HA add-on architecture changed (add-ons → apps) | Phase 1 rework | Docs suggest rename only, same underlying system |
