# Example screenshots

Use Docker, Node.js and the repository's Blueprint environment:

```sh
blueprint run screenshots
blueprint run screenshots-update
```

The check builds and runs the current examples using the first successful case
in `tests/spec.json`. Its output must match the recorded case before rendering.
The example sources, case inventory, README image links and committed PNGs must
agree; missing or stale entries fail.

The browser helper runs in the Docker image pinned in `Dockerfile`, with the
matching Playwright package pinned in `package-lock.json`. The container fixes
Chromium, fonts and OS libraries; the driver always selects `linux/amd64`.
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
The comparator's negative tests run when building the helper image.

Update mode renders the same inputs and changes baselines only after every
example renders successfully. Review and commit the changes under
`examples/demo-images/`. CI always uses check mode.

When upgrading the browser, update the image digest and matching exact package
version together, regenerate the npm lock, then explicitly update and review the
screenshots. Keep baseline changes in the same review as the behavior they show.
