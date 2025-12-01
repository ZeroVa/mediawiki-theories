# Consciousness Compare MediaWiki sandbox

This folder spins up a MediaWiki instance that mimics the look, color palette, and general layout of the Next.js app (`src/app/page.tsx`). It includes a custom theme (fonts, colors, cards, buttons, hero, badges, dark mode toggle) and a starter Main Page wikitext.

## Palette + typography (mirrors the app)
- Background/foreground: `#fafafa` / `#171717` (dark: `#0a0a0a` / `#ededed`)
- Muted/backdrop: `#f5f5f5` (dark: `#1c1c1c`)
- Muted foreground/border: `#737373` / `#e5e5e5` (dark: `#a3a3a3` / `#262626`)
- Primary: `#1d4ed8` (dark: `#3b82f6`); primary foreground: `#f8fafc` (dark: `#e5e7eb`)
- Fonts: Roboto (body), Playfair Display (headings), Geist Mono (mono)

## Quick start (hands-off)
1) From repo root: `docker compose -f mediawiki/docker-compose.yml up -d`
2) Wait ~30s for first boot. The bundled entrypoint will:
   - wait for MariaDB
   - run `maintenance/install.php` with the env vars in `docker-compose.yml`
   - append the theme require
   - persist `LocalSettings.php` to `mediawiki/data/LocalSettings.php` and symlink it in the container
3) Visit http://localhost:8080 (login: `admin` / `adminpass` by default) and set the Main Page content using `mediawiki/content/MainPage.wikitext`.

## Deploying to Railway
- The repo now ships a `Dockerfile` that bakes in the theme and entrypoint; Railpack will pick this up automatically.
- Add a MySQL service in Railway. The container will read `MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, and `MYSQLDATABASE` automatically (or use `MW_DB_*` overrides). You can also set `MYSQL_URL=${{ MySQL.MYSQL_URL }}` from the Railway UI and the entrypoint will parse it for you.
- Set env vars on the app service: choose `MW_ADMIN_USER` / `MW_ADMIN_PASS`, optionally `MW_SITENAME`, and set `MW_SITE_SERVER` to your Railway URL (e.g., `https://mediawiki-theories-production.up.railway.app`). If Railway injects `RAILWAY_STATIC_URL` or `RAILWAY_PUBLIC_DOMAIN`, the entrypoint will use those when `MW_SITE_SERVER` is unset. `PORT` is set by Railway and the entrypoint rewrites Apache to listen on it.
- Mount a Railway volume at `/data` (for `LocalSettings.php`) and another at `/var/www/html/images` for uploads. Without volumes, installs/uploads are wiped on redeploy.
- Deploy. On first boot the entrypoint auto-installs MediaWiki, appends `localsettings.d/consciousness-theme.php`, and writes `LocalSettings.php` to `/data/LocalSettings.php`. Watch logs for `LocalSettings ready; starting Apache ...`.
- After it comes up, log in with the admin credentials you set and paste `content/MainPage.wikitext` into the Main Page, then upload `Consciousness-map-preview.jpg` to restore the preview image.

### Notes on the install command
- DB host is `database`, DB name/user/pass: `mediawiki` / `wikiuser` / `example`.
- The installer sets the default skin to Vector 2022; the theme module is added by the line you append.
- If you prefer the web installer, use the same DB credentials and add the `require_once` line afterward.

## Theme pieces included here
- `localsettings.d/consciousness-theme.php`: Registers the ResourceLoader module, forces Vector 2022, and injects the CSS/JS.
- `theme/consciousness-theme.css`: Color tokens, typography, card/button styles, badges per category, page shell width, hero block, and prose styling. Includes light/dark palettes that match `src/app/globals.css`.
- `theme/consciousness-theme.js`: Applies the theme (respects `prefers-color-scheme` + localStorage) and adds a personal-bar toggle.
- `content/MainPage.wikitext`: A drop-in Main Page layout using the classes above to mimic the current homepage hero, featured questions, theory tiles, and map callout. Replace placeholder text/links with real pages as you import content.
- `init/entrypoint.sh`: Auto-installs MediaWiki on first boot, appends the theme require, and persists `LocalSettings.php` to `mediawiki/data`.

## Mapping app features to MediaWiki
- Navigation: Vector 2022 + custom header styling; edit `MediaWiki:Sidebar` to mirror `/questions`, `/theories`, `/compare`.
- Questions/Theories data: use Cargo or Semantic MediaWiki to store structured fields (category, color, counts) and render grids; current sample uses static HTML cards.
- Comparison table: implement via a Lua/Scribunto module or PageForms list combined with Cargo queries to build a matrix similar to `ComparisonTable` in the app.
- Auth/permissions: keep default MediaWiki auth for now; if you need OAuth or SSO parity, add the matching auth extension and tweak group permissions.
- Dark mode: shipped via `consciousness-theme.js` and `[data-theme]` CSS—no user gadget setup required.

## Assets
- Upload `public/consciousness-map-preview.jpg` to the wiki (as `Consciousness-map-preview.jpg`) so the Main Page map preview renders.
- Lucide icons aren’t pulled in; use SVG uploads or Font Awesome if you need icons in content areas.

## Tear-down
- `docker compose -f mediawiki/docker-compose.yml down -v` removes containers and the MariaDB volume (`db_data`). Images under `mediawiki/images` persist locally.
