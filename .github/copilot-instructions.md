# kde-airthings

A KDE Plasma 6 widget (plasmoid) that displays live air quality readings and
history from an Airthings device. Plasmoid sources live entirely under
`package/`, following the standard Plasma applet layout: `package/metadata.json`
(id, version), `package/contents/config/` (kcfg settings schema), and
`package/contents/ui/` (QML UI + `code/*.mjs` JS logic).

## Build, test, and lint

There is no JS/QML test suite or package.json; this is a native Plasma widget
developed and exercised through KDE tooling. `.vscode/tasks.json` defines the
canonical dev workflow (run via VS Code's task runner or the equivalent shell
commands):

- **Lint QML**: `qmllint -I $(qtpaths6 --query QT_INSTALL_QML) package/contents/ui/*.qml`
- **Type-check JS**: `.mjs` files under `package/contents/ui/code/` use JSDoc
  + `// @ts-check`; `jsconfig.json` scopes strict TS checking to that folder.
  Run with `tsc --noEmit -p jsconfig.json` (or any TS-aware editor) if `tsc` is
  available.
- **Install/update the widget locally**: `kpackagetool6 -t Plasma/Applet -u package`
- **Run standalone (no install)**: `plasmawindowed com.github.yvand.airthings`
  (add `LANGUAGE=fr LANG=fr_FR.UTF-8` env vars to test the French locale)
- **Restart Plasma to pick up changes**: `systemctl --user restart plasma-plasmashell`
- **Translations**: `translate/merge.sh` extracts `i18n()`/`I18N_NOOP()` strings
  into `translate/template.pot` and merges into `translate/*.po`;
  `translate/build.sh` compiles `.po` → `.mo` into `package/contents/locale/`.
  Both require `gettext` (e.g. `nix-shell -p gettext --run translate/merge.sh`).
- **Release**: `scripts/release.sh X.Y.Z` bumps `package/metadata.json`,
  commits, tags `vX.Y.Z`, and pushes from `main` only (fails if the tree is
  dirty, not on `main`, out of sync with `origin/main`, or the tag exists).
  Pushing the tag triggers `.github/workflows/release.yml`, which compiles
  translations, zips `package/` into a `.plasmoid`, and publishes it as a
  release asset — `metadata.json`'s `Version` must match the tag.

## Before opening a PR

Add a bullet to the `[Unreleased]` section of `CHANGELOG.md` describing the
change, using the existing Keep a Changelog subsections (`### Added` /
`### Changed` / `### Fixed` / `### Removed`) — see existing dated sections in
that file for the expected tone and detail. A CI check
(`.github/workflows/changelog-check.yml`) fails PRs targeting `main` that
don't touch `CHANGELOG.md`; the only sanctioned bypass is adding the
`skip-changelog` label (e.g. for changes with no user-visible effect), not
silently omitting the entry.

## Architecture

- **`main.qml`** is the root `PlasmoidItem` and owns all shared state: the
  Airthings API `Client` (recreated whenever credentials change, via
  `onCredentialsKeyChanged`), the readings array, a refresh `Timer` driven by
  `cfg.refreshMinutes`, and the SQLite history `db` handle
  (`LocalStorage.openDatabaseSync`). It exposes `history()`, `historyStats()`,
  theme colors, and `qualityColor()` as properties/functions consumed by child
  components — `CompactRepresentation` and `FullRepresentation` both receive
  the root as `widget: root` rather than duplicating this state.
- **`code/api.mjs`** — stateless-ish `Client` class talking to the Airthings
  Consumer API (OAuth2 client-credentials token, cached until near expiry;
  `get()` retries once on 401 by clearing the token). Returns typed
  `ApiError { status, message, auth? }` objects on rejection.
- **`code/history.mjs`** — all local persistence. The Airthings API has no
  history endpoint, so every fetched reading is written to a `samples` SQLite
  table (`serial, sensor, ts` primary key dedupes re-fetches). `query()`
  averages rows into time buckets for sparklines/charts; `prune()` enforces
  `cfg.historyDays` retention.
- **`code/sensors.mjs`** — static metadata: sensor display names, decimals,
  unit labels, and good/fair/poor quality thresholds per unit (metric vs.
  imperial have separate threshold tables, e.g. `c` vs `f`, `bq` vs `pci`).
  `quality()` is the single source of truth for color-coding readings.
- **Config** (`package/contents/config/main.xml`) defines the kcfg schema in
  three groups (`General`, `Display`, `History`); each entry is surfaced as
  `Plasmoid.configuration.<name>` (aliased as `cfg` in QML) and edited via
  `ConfigGeneral.qml` / `ConfigDisplay.qml` / `ConfigHistory.qml`.
- **UI split**: `CompactRepresentation.qml` (panel icon/summary) and
  `FullRepresentation.qml` (expanded view with `SensorTile`, `Sparkline`,
  `DetailChart`) are the two representations Plasma switches between.

## Conventions

- JS modules use `// @ts-check` + JSDoc type annotations (see `api.mjs`,
  `history.mjs`, `sensors.mjs`) instead of TypeScript files; keep new `.mjs`
  code consistent with this style so `jsconfig.json`'s strict checking stays
  useful.
- User-visible strings are wrapped in `i18n(...)` in QML. Strings that
  originate in `.mjs` files (which can't call `i18n()` directly) are wrapped
  in a local `I18N_NOOP(text)` identity function purely so `xgettext` extracts
  them; the actual translation happens where the string is consumed in QML.
  Follow this pattern for any new user-facing string added to a `.mjs` file.
- Timestamps from the Airthings API are UTC without a timezone designator —
  always parse them with `parseUtcTimestamp()` from `api.mjs`, never
  `Date.parse()`/`new Date()` directly.
- Empty-array config values are meaningful, not "unset": `visibleSensors: []`
  means show every sensor; `compactSensors` empty slots have positional
  meaning (first empty = "first shown sensor", others = "skip this slot").
- French (`fr`) is the only bundled translation; update `translate/fr.po` via
  `translate/merge.sh` when adding/changing user-facing strings, then rebuild
  `.mo` files with `translate/build.sh` before packaging.
