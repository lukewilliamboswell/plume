# Example screenshots

Use Node.js 18 or later, npm and the Chromium system dependencies documented by
[Playwright](https://playwright.dev/docs/browsers#install-system-dependencies).
Provision the locked JavaScript packages and matching Chromium headless shell:

```sh
blueprint run screenshots-setup
blueprint run screenshots
blueprint run screenshots-update
```

The normal check also ensures the packages and browser are installed. Setup
without flags downloads into the user browser cache and never installs system
packages. CI uses `blueprint run screenshots-setup -- --with-deps` to install
its OS dependencies explicitly. Only the headless shell is downloaded.

The check builds and runs the current examples using the first successful case
in `tests/spec.json`. Its output must match the recorded case before rendering.
The example sources, case inventory, README image links and committed PNGs must
agree; missing or stale entries fail.

Canonical checks run on x64 Ubuntu Linux. `package-lock.json` pins Playwright;
its browser inventory selects and verifies the matching browser version and
revision. `fonts.conf` fixes generic monospace to Liberation Mono. A browser
preflight verifies the actual selected font and fails if it falls back.
The viewport, scale, locale, timezone and rendering options live in `render.mjs`.
JavaScript handles the browser and PNG boundary; the Roc driver owns compiling
and executing examples.

Rendering waits for the actual Plotly promise, loaded fonts and stable completed
captures. It checks the versioned CDN asset against the current HTML's SRI hash,
then supplies those exact bytes to the browser. Load errors, browser exceptions,
invalid Plotly schemas and unexpected requests fail the check. Diagnostics for
mode-inactive scatter line/marker containers and empty axes on non-Cartesian
figures are retained in the report; all other diagnostics fail the check.

Comparisons use decoded RGBA pixels with zero tolerance. Check failures retain
`report.json`, generated HTML, expected and actual PNGs, and highlighted pixel
differences under `.screenshots-out/`; CI uploads that directory even on failure.
The comparator and validation negative tests run before rendering.

Update mode renders the same inputs and changes baselines only after every
example renders successfully. Review and commit the changes under
`examples/demo-images/`. CI always uses check mode.

When upgrading Playwright, update its exact package version and npm lock,
run setup, then explicitly update and review the screenshots. Keep baseline
changes in the same review as the behavior they show.
