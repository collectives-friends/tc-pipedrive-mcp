# tc-pipedrive-mcp

> **Domæne:** TC (collectives-friends / True Collective) · **Secrets-kilde:** self-hosted Infisical (`infisical.sliplane.app`, projekt `true-collective`, env `prod`) · **Repo-klasse:** code (MCP-server, Node/TS).

## Project Context

Model Context Protocol-server der eksponerer Pipedrive API v2 for LLM-klienter (Claude). TC-fork af `WillDent/pipedrive-mcp-server` med et TC-overlay ovenpå (Infisical-secrets, CI-gate, get-deals-fixes). Serveren er primært læse-fokuseret (deals, persons, organisationer, pipelines, stages, leads, søgning) plus et sæt write/CRUD-tools (create/update deals, persons, orgs, notes, activities).

**Stack:** Node 20 (Docker) / Node 22 (CI), TypeScript ESM (`"type": "module"`), pakke-manager **npm** (`package-lock.json`). MCP via `@modelcontextprotocol/sdk`; Pipedrive-SDK `pipedrive@22`; rate-limiting via `bottleneck`; validering via `zod`; JWT-auth via `jsonwebtoken`.

**Kode-form:** Al server-logik ligger reelt i `src/index.ts` (én fil) + `src/types.d.ts`. Tools og prompts registreres samme sted.

**Transport:** `stdio` (default, lokal brug) eller `sse` (HTTP, til Docker/remote). Styres via `MCP_TRANSPORT`. SSE lytter på `MCP_PORT` (default 3000) med `/sse`, message-endpoint og `/health`.

**Nøgle-kommandoer:**
```
npm ci            # install (lockfile-tro)
npm run build     # tsc → build/  (dette er verify-gaten; CI kører kun denne)
npm start         # node build/index.js  (kræver build først)
npm run dev       # node --import tsx src/index.ts  (uden build)
```

**Deploy:** Kører som container på Sliplane. `Dockerfile` er multi-stage (builder → production) og starter via `infisical-entrypoint.sh`, som logger ind med service-machine-identity og injicerer secrets via `infisical run`. **Push til `main` udløser Sliplane autoDeploy til prod.**

## Metodik

Dette repo følger den kanoniske udviklings- og deployment-tilgang i `claude-loadout/core/METHODOLOGY.md` (fingerprint stack og domæne · vault-secrets aldrig disk · git draft-PR · propose-only · verifikation før "done" · superpowers-triggers) samt klasse-profilen `core/profiles/code.md` (Node/TS via npm: `npm run build` er verify, da repoet ikke har en test-suite). På dev-box er kerne og profil i kontekst via user-memory. Repo-specifikke regler nedenfor vinder ved konflikt.

## Repo-specifikke regler og gotchas

- **Verify = `npm run build` (tsc).** Der er INGEN test-suite; CI (`.github/workflows/ci.yml`) kører kun `npm ci` + `npm run build`. Vis build-output før du claimer done. Fejler tsc, sig det med output.
- **`.github/workflows/ci.yml` er GENERERET** af `collectives-friends/.github` (`ci-sync/sync.sh`). Rediger den ALDRIG direkte i dette repo · ret `manifest.json` + `sync.sh` i `.github`-repoet og kør sync på ny.
- **Ugentlig upstream auto-merge.** `.github/workflows/auto-update.yml` merger `WillDent/pipedrive-mcp-server` ind hver mandag 04:23 UTC og pusher til `main` (Sliplane deployer). Ved merge-konflikt aborterer den og kræver manuel resolution. Hold TC-ændringer små og lokaliserede så upstream fortsat kan merges rent · undgå unødige omskrivninger af `src/index.ts`.
- **Push til `main` = prod-deploy.** Arbejd altid på branch + **draft-PR**. Merge/push til `main` aldrig uden Stefans eksplicitte godkendelse.
- **Write-tools registreres via et løst handle** (bevidst, commit `7ec3b97`) for at undgå at `tsc` løber tør for hukommelse (OOM) ved streng typning af hele CRUD-sættet. Lav ikke drive-by "oprydning" til strikt typning her · det kan genindføre build-OOM.
- **Secrets bor i Infisical, ikke `.env`.** Se `.claude/rules/secrets.md`. Platform-env indeholder KUN Infisical-bootstrap-vars (`INFISICAL_CLIENT_ID/SECRET/API_URL/PROJECT_ID/ENV/PATH`) + ikke-hemmelig config. Hardkod aldrig en secret i kode, Dockerfile, compose eller markdown. Commit aldrig en `.env` med rigtige værdier (kun `.env.example` med tomme nøgler). Kør secret-scan før commit.
- **Lokal kørsel med secrets:** `infisical run --projectId=<true-collective> --env=prod --domain=https://infisical.sliplane.app/api --path=/<service> -- npm run dev` (se `.claude/rules/secrets.md` for fuld kommando).
- **Kun CLAUDE.md/AGENTS.md-scope for metodik-arbejde.** Rør ikke kode, CI eller Docker i samme ombæring som metodik-dokumentation.
