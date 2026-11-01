# Package contract

Plume is a pure Roc package. Preserve the public guarantees documented in
`docs/type-safety.adoc` when changing its API.

- Represent validated domain values with opaque types. Keep every public way
  to construct them checked, including literal hooks. Never expose backing
  constructors or an unchecked raw JSON constructor.
- Cartesian coordinates are `Coordinate`: text or finite F64 numbers. Do not
  broaden them to arbitrary JSON-encodable values. Closed options use tags.
- Use nominal props with defaulted fields. Return `Try` only where failure is
  possible; reject invalid runtime input at construction with structured tags.
- Structured output goes through `InternalJson`. Escape the HTML title and
  embedded JSON for their separate contexts. Use multiline `\\` strings and
  interpolation for templates, never `Str.inspect` as serialization.
- A public type-boundary change needs a valid consumer example, a compile-time
  rejection case for the invalid state, and a runtime negative test when input
  can fail validation. Extend the fuzz properties for relevant runtime rules.
- Document public types, props, defaults, units, errors and intended use beside
  their definitions. The shared `roc-policy` gate checks presence; also review
  the generated documentation site for clarity and working links.
- Gallery PNGs come from the screenshot tasks. Use `blueprint run screenshots`
  to check them and `blueprint run screenshots-update` for an intentional
  visual change. Review the image diff; do not hand-edit stale screenshots.
- Keep named `##` comments before every top-level `expect`. Run
  `blueprint run check`; it includes consumer, type-contract and bounded fuzz
  checks. Review allocation baseline changes with measured evidence. A check
  must never accept a new baseline or rewrite expected example output.
- Follow the style guide linked from the manual and the SHA-pinned roc-automation
  workflows. Package/apps use the current nightly; scripts keep the fixed
  tooling compiler. Format each with its corresponding compiler.
- Keep manuals focused on API guarantees and contributor workflows. Do not
  copy test counts, execution budgets, platform measurements or run-specific
  compiler provenance from test definitions and diagnostics into prose.
- For pure performance investigations, build Zig code with
  `-Doptimize=ReleaseFast`, retain debug symbols, and state the measurement mode.
  Use ReleaseSafe separately for safety validation.
