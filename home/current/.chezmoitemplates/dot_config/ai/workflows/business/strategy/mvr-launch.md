---
description: Minimum Viable Runway launch — repo, site, auth, billing, flags, referrals, deploy
auto_execution_mode: 3
---

## Slash Command

- Trigger from chat: `/mvr-launch`
- Gated: proposes plan and awaits explicit approval before any mutation.

## Inputs (Prompted at Runtime)

- business_idea (text or BRD link)
- business_name
- logo preference (upload/library/todo)
- target personas → theme recommendation
- desired domain (optional)
- YouTube URL/ID (optional; can be added later)
- consent flags: auto-post on socials, analytics, email provider defaults
- note: all credentials (Cloudflare, OAuth, Stripe) use placeholders in `.env*`

## Defaults and Assumptions

- Email provider: Resend (generous free tier); configurable via env.
- Stripe: test mode only; keys in `.env*`.
- Cloudflare: bindings and tokens as env placeholders; deploy is manual until provided.
- Git remote: left blank if not present.
- Auto-post: disabled by default; can opt-in per-network.

1) Gate: propose plan and confirm
   - Summarize repo setup; toolchain (`mise` for node, bun, bazel); Next.js scaffold with Tailwind + `shadcn/ui` + `framer-motion`; theme choice by persona; pages (home/privacy/terms); GTM; Cloudflare Pages+Functions; `.env-example` and `.env` with placeholders; D1+KV; auth (Google/Apple/Email+OTP code) with thank-you email; Stripe test with 3 tiers and $1 validation path; feature flags for launch modes; referrals+leaderboard; survey+BRD interview; timeline views; social sharing/auto-post (consent); unit/e2e tests + mocks; GH Actions CI/CD.
   - Pause and require explicit approval.

2) Repo init and branches
   ```bash
   # If not in a git repo, initialize with empty first commit
   git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git init -b main && git commit --allow-empty -m "chore: initial empty commit"; }

   # Create branches if missing
   git show-ref --verify --quiet refs/heads/gh_pages || git branch gh_pages
   for b in env/prod env/stage env/dev; do git show-ref --verify --quiet refs/heads/$b || git branch "$b"; done

   # Switch to env/dev
   git switch env/dev
   ```

3) Ensure mise and toolchain (node, bun, bazel)
// turbo
   ```bash
   command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.jdx.dev/install.sh | sh

   cat > .mise.toml << 'EOF2'
   [tools]
   node = "lts"
   bun = "latest"
   bazel = "latest"
   EOF2

   mise install
   mise run -- node -v
   mise run -- bun --version
   mise run -- bazel --version || true
   ```

4) Scaffold Next.js + Tailwind
// turbo
   ```bash
   npx --yes create-next-app@latest web \
     --typescript --eslint --tailwind --app --src-dir=false --use-npm
   ```

5) UI libraries: shadcn/ui, radix, motion, icons
// turbo
   ```bash
   cd web
   npx --yes shadcn@latest init -y
   npm i framer-motion class-variance-authority tailwind-merge lucide-react @radix-ui/react-toast @radix-ui/react-slot
   ```

6) Theme and base components
   - Offer persona-based themes: Slate+Emerald (trust/clarity), Zinc+Violet (premium/modern), Stone+Cyan (clean/tech).
   - Apply via `tailwind.config.ts` and `app/globals.css`.
   - Add animated CTA, hero, toasts using `framer-motion` and `shadcn/ui`.

7) Pages and content
// turbo
   ```bash
   # Privacy and Terms
   mkdir -p app/(legal)
   cat > app/(legal)/privacy/page.tsx << 'EOF2'
   export default function Privacy() {
     return (<main className="prose mx-auto p-8"><h1>Privacy Policy</h1><p>Last updated: {{ now | date "2006-01-02" }}</p></main>);
   }
   EOF2
   cat > app/(legal)/terms/page.tsx << 'EOF2'
   export default function Terms() {
     return (<main className="prose mx-auto p-8"><h1>Terms of Use</h1><p>Last updated: {{ now | date "2006-01-02" }}</p></main>);
   }
   EOF2
   ```

   - Home page must include:
     - Problem/solution framing.
     - Benefits/features grid.
     - Newsletter input for infrequent updates.
     - Embedded YouTube (env-driven).
     - Founding Member ribbon option.

8) Google Tag Manager
// turbo
   ```bash
   mkdir -p app/_components
   cat > app/_components/Gtm.tsx << 'EOF2'
   "use client";
   import Script from "next/script";
   export default function Gtm({ id }: { id?: string }) {
     const gtm = id || process.env.NEXT_PUBLIC_GTM_ID;
     if (!gtm) return null;
     return (
       <Script id="gtm" strategy="afterInteractive">{
         `(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
         new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
         j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
         'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode!.insertBefore(j,f);
         })(window,document,'script','dataLayer','${gtm}');`
       }</Script>
     );
   }
   EOF2
   ```

9) Environment files
// turbo
   ```bash
   cd web
   cat > .env-example << 'EOF2'
   # Public
   NEXT_PUBLIC_GTM_ID=
   NEXT_PUBLIC_THEME=slate-emerald|zinc-violet|stone-cyan
   NEXT_PUBLIC_YOUTUBE_ID=

   # Email (Resend default; swap later if desired)
   RESEND_API_KEY=

   # OAuth placeholders (Google/Apple)
   OAUTH_GOOGLE_CLIENT_ID=
   OAUTH_GOOGLE_CLIENT_SECRET=
   OAUTH_APPLE_CLIENT_ID=
   OAUTH_APPLE_TEAM_ID=
   OAUTH_APPLE_KEY_ID=
   OAUTH_APPLE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----'

   # Email OTP verification
   EMAIL_OTP_SIGNING_SECRET=

   # Stripe (test mode)
   STRIPE_SECRET_KEY=
   STRIPE_PUBLISHABLE_KEY=
   STRIPE_WEBHOOK_SECRET=

   # Cloudflare (placeholders; add when ready)
   CLOUDFLARE_ACCOUNT_ID=
   CLOUDFLARE_API_TOKEN=
   CLOUDFLARE_PAGES_PROJECT=
   CLOUDFLARE_KV_FLAGS_BINDING=FEATURE_FLAGS
   CLOUDFLARE_D1_DB_BINDING=DB

   # Feature flags & referrals
   LAUNCH_MODE=waitlist_only|waitlist_plus_1usd|open_with_cap|open_full
   REFERRAL_INVITES_DEFAULT=3
   REFERRAL_INVITES_BONUS_SURVEY=2

   # CI/CD toggles
   CI_E2E_ENABLED=true
   EOF2

   cp .env-example .env
   ```

10) Cloudflare Pages + Functions (Workers) setup
// turbo
   ```bash
   cd web
   npm i -D wrangler @cloudflare/next-on-pages
   cat > wrangler.toml << 'EOF2'
   name = "mvr-site"
   compatibility_date = "2024-04-02"
   [vars]
   NEXT_PUBLIC_GTM_ID = "${NEXT_PUBLIC_GTM_ID}"
   [kv_namespaces]
   binding = "FEATURE_FLAGS"
   id = ""
   [d1_databases]
   binding = "DB"
   database_name = "mvr_db"
   database_id = ""
   EOF2
   ```

   - Build with `next-on-pages` for Pages.
   - KV for feature flags; D1 for users/invites/referrals/otp/events.

11) Database schema (Cloudflare D1; minimal)
// turbo
   ```bash
   cd web
   mkdir -p schema
   cat > schema/001_init.sql << 'EOF2'
   CREATE TABLE IF NOT EXISTS users (
     id TEXT PRIMARY KEY,
     email TEXT UNIQUE NOT NULL,
     name TEXT,
     created_at TEXT DEFAULT (datetime('now'))
   );
   CREATE TABLE IF NOT EXISTS auth_providers (
     id TEXT PRIMARY KEY,
     user_id TEXT NOT NULL,
     provider TEXT NOT NULL,
     provider_id TEXT NOT NULL,
     FOREIGN KEY (user_id) REFERENCES users(id)
   );
   CREATE TABLE IF NOT EXISTS email_otps (
     email TEXT PRIMARY KEY,
     code TEXT NOT NULL,
     expires_at INTEGER NOT NULL
   );
   CREATE TABLE IF NOT EXISTS referrals (
     id TEXT PRIMARY KEY,
     inviter_id TEXT NOT NULL,
     invitee_email TEXT,
     accepted_user_id TEXT,
     created_at TEXT DEFAULT (datetime('now'))
   );
   CREATE TABLE IF NOT EXISTS memberships (
     user_id TEXT PRIMARY KEY,
     tier TEXT NOT NULL,
     status TEXT NOT NULL,
     stripe_cust_id TEXT,
     stripe_sub_id TEXT
   );
   CREATE TABLE IF NOT EXISTS events (
     id TEXT PRIMARY KEY,
     user_id TEXT,
     type TEXT NOT NULL,
     meta TEXT,
     created_at TEXT DEFAULT (datetime('now'))
   );
   EOF2
   ```

12) Auth strategy (Email code + OAuth Google/Apple; email always required)
   - Email code flow:
     - Create OTP (store in `email_otps`), email via Resend, verify; send thank-you email post-signup.
   - OAuth flow:
     - After Google/Apple, require/verify email via OTP if not verified.
   - Store providers in `auth_providers`.
   - All provider keys remain placeholders in `.env*`.

13) Billing with Stripe (test mode) and tiers
   - Three tiers with placeholder prices; $1 validation path (reversed) for priority access.
   - Track `memberships`; GTM events: `tier_selected`, `card_submitted`, `card_1usd_result`.

14) Feature flags and launch modes (KV)
   - Modes: `waitlist_only`, `waitlist_plus_1usd`, `open_with_cap`, `open_full`.
   - Admin route toggles flags (KV) without redeploy; 1-month email notice requirement baked into flows.

15) Referrals, leaderboard, and rewards
   - Default 3 invites; +2 on survey completion.
   - Track inviter/invitee; free month reward after first paid month.
   - Leaderboard snippets and progress nudges.

16) Survey and BRD
   - Post-waitlist micro-survey (30–45s).
   - Interview the command runner to generate a lightweight BRD; store in `docs/BRD.md`.

17) Social sharing and auto-post
   - One-click links: Threads, Bluesky, X, Facebook, Instagram, LinkedIn, YouTube, Twitch, TikTok, etc.
   - Optional auto-post behind consent flag; also log GTM events.
   - Auto-post when an invite is accepted (opt-in).

18) Timeline views
   - Private/public/friends views of signup, invites sent, shares, email/card validations, conversions.

19) Testing and mocks
// turbo
   ```bash
   cd web
   npm i -D vitest @testing-library/react @testing-library/jest-dom msw @vitest/ui playwright
   npx playwright install --with-deps
   ```

   - Unit tests: components and flows (OTP, waitlist, referral sharing).
   - MSW for API mocks.
   - E2E: Playwright for signup, email validation, waitlist, referral accept.

20) Bazel setup (WORKSPACE/BUILD minimal)
// turbo
   ```bash
   cd ..
   cat > WORKSPACE << 'EOF2'
   workspace(name = "mvr")
   EOF2

   cat > BUILD << 'EOF2'
   package(default_visibility = ["//visibility:public"])
   EOF2

   cat > web/BUILD << 'EOF2'
   package(default_visibility = ["//visibility:public"])
   # Placeholder targets; extend with specific rules as needed.
   filegroup(
     name = "srcs",
     srcs = glob(["**/*"], exclude = ["node_modules/**", ".next/**", "out/**"]),
   )
   EOF2
   ```

21) GitHub Actions CI/CD
// turbo
   ```bash
   cd web
   mkdir -p .github/workflows
   cat > .github/workflows/ci.yml << 'EOF2'
   name: CI
   on:
     push:
       branches: [ "env/**" ]
     pull_request:
   jobs:
     build-test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with: { node-version: "lts/*" }
         - run: npm ci
           working-directory: web
         - run: npm run type-check --if-present
           working-directory: web
         - run: npm test --if-present -- --run
           working-directory: web
         - run: npm run build
           working-directory: web
     deploy-pages:
       if: startsWith(github.ref, 'refs/heads/env/')
       needs: build-test
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with: { node-version: "lts/*" }
         - run: npm ci
           working-directory: web
         - run: npx @cloudflare/next-on-pages@latest
           working-directory: web
         # Add wrangler publish once CF secrets exist
   EOF2
   ```

22) GTM events to emit
   - `view_home`, `click_CTA`, `submit_waitlist`, `start_validation`, `complete_validation`,
     `start_signup`, `signup_success`, `tier_selected`, `card_submitted`, `card_1usd_result`,
     `email_verified`, `referral_share`, `referral_accept`, `invite_grant`.

23) Git flow and remote
   - Leave git remote blank if not defined.
   - Commit all generated files with messages per step.

24) Final summary and next steps
   - Print: branches created, toolchain versions, local dev commands, instructions to add env secrets and run `wrangler pages deploy` when ready.
