# Install this fork on a new server

This installs a new, empty instance with the custom internal chat, flow builder,
WhatsApp campaigns, template builder and reply-window/resumption UI. Internal Chat
and Flow Builder remain disabled for new accounts until a Super Admin enables them.

## Requirements

- A Linux server with Git, Bash, OpenSSL, Docker Engine and Docker Compose v2.
- A domain pointing to the server, with an HTTPS reverse proxy that supports WebSockets.
- Sufficient memory for the production asset build (8 GB RAM recommended).
- SMTP credentials for invitations, password resets and outgoing email.

The production Compose file builds this checkout. The upstream installer scripts,
marketplace images and `chatwoot/chatwoot` images install the upstream application;
use the commands below for this fork.

## Install

```bash
git clone --branch feat/internal-chat --single-branch https://github.com/chatcall1/chatwoot.git
cd chatwoot
bin/setup-production-env https://support.example.com
```

Replace the example URL with your actual domain. The setup command creates `.env`
with unique session, encryption, PostgreSQL and Redis keys and refuses to overwrite
an existing file. Keep these keys unchanged after installation.

Edit `.env` to configure `MAILER_SENDER_EMAIL`, `SMTP_ADDRESS`, `SMTP_PORT`,
`SMTP_USERNAME`, `SMTP_PASSWORD` and the authentication/TLS settings required by your
mail provider. Other integrations can be configured afterward through the dashboard
and Super Admin settings. `.env.example` describes the available settings.

```bash
docker compose -f docker-compose.production.yaml up -d --build
docker compose -f docker-compose.production.yaml ps -a
docker compose -f docker-compose.production.yaml logs --tail=100 prepare rails sidekiq
```

Compose waits for PostgreSQL and Redis, creates the schema and installation settings,
then starts Rails and Sidekiq. The `prepare` service should finish with exit code 0;
`rails`, `sidekiq`, `postgres` and `redis` should stay running. No manual SQL or feature
migration is needed. PostgreSQL includes pgvector and the required search extensions.

Configure your reverse proxy to forward the domain to `127.0.0.1:3000`, preserve the
`Host` header, set `X-Forwarded-Proto: https`, and forward WebSocket upgrades for
`/cable`. To change the local port, add `CHATWOOT_PORT=3001` to `.env` before starting.
PostgreSQL and Redis are accessible only inside the Compose network.

Open `https://support.example.com/installation/onboarding` to create the first account
and Super Admin. Then open `/super_admin`, edit the desired account and enable
**Internal Chat** and/or **Flow Builder**. Other accounts keep their existing settings.
WhatsApp requires connecting the account's own inbox and obtaining approval for its
message templates. Captain and other external integrations require their own credentials
and any applicable licenses; the installer does not provide them.

## Verify

- `/health` returns `{"status":"woot"}` through your HTTPS domain.
- The dashboard and flow editor load their assets.
- A new account does not expose Internal Chat or Flow Builder before Super Admin activation.
- After activation, the account can open Internal Chat and create a draft flow.
- Sidekiq remains running and processes background work.

## Update this installation

Keep using the same checkout, `.env` and Compose project. Do not delete the volumes.
Build first, then stop the application processes while the database is upgraded:

```bash
git pull --ff-only origin feat/internal-chat
docker compose -f docker-compose.production.yaml build
docker compose -f docker-compose.production.yaml stop rails sidekiq
docker compose -f docker-compose.production.yaml run --rm prepare
docker compose -f docker-compose.production.yaml up -d
```

If database preparation fails, resolve the reported error before restarting the application.
The named volumes preserve PostgreSQL, Redis and uploaded files across container rebuilds.
