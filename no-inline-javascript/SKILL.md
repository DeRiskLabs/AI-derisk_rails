---
name: no-inline-javascript
title: No Inline JavaScript — All JS Through the Asset Pipeline
description: JavaScript never lives in a view. No inline <script> blocks, no Slim javascript: filter blocks, no on*= handler attributes, no server data interpolated into a <script>. All JS lives in structured files in the Rails asset pipeline (Propshaft), reads server data from data- attributes or a JSON island, and binds behaviour with addEventListener. Use whenever a view needs behaviour, a page needs a script, or a third-party JS library is involved.
category: authoring
status: active
version: 1.0
applies_to:
  - Rails
  - JavaScript
  - Propshaft
  - Slim
priority: REQUIRED
triggers:
  - a view needs client-side behaviour
  - adding or moving a <script> tag
  - inline onclick / onchange / on*= attribute
  - server data or a route URL needed in JS
  - vendoring a third-party JS library (d3, etc.)
  - converting ERB to Slim that contains a script
anti_triggers:
  - pure server-rendered view with no behaviour
  - non-Rails Ruby work
user_invocable: true
last_reviewed_at: 2026-06-28
---


# No Inline JavaScript

**Inline JavaScript is never acceptable.** We have a Rails asset pipeline; bypassing it
is unnecessary and erodes confidence in the work. This is the JS counterpart of the
no-inline-styles rule — same severity, same reasoning.

Banned, with no exceptions:

- inline `<script> … </script>` blocks in a view (ERB or Slim),
- the Slim `javascript:` filter (it only emits a literal inline `<script>` — it is **not**
  a pipeline mechanism),
- `on*=` handler attributes (`onclick`, `onchange`, `onsubmit`, `oninput`, …),
- ERB/Slim interpolation of server data or route helpers **into** a `<script>`
  (`const X = <%= raw @json %>`),
- third-party libraries pulled from a CDN (`<script src="https://…">`).

**Why:** with all JS in one place we can refactor it, keep it tidy, lint/test it, fingerprint
and cache it, and reason about it. Inline JS is unrefactorable, untestable, uncacheable, and
duplicated across views. (See the platform's [[app-lib-placement]] instinct: own code lives
in a known structured home, never scattered.)


## Where JS lives

Mirror the CSS pipeline. The container has a `lib/css_builder.rb` + `css:build` rake hooked
into `assets:precompile`, with convention-based bundle discovery and Propshaft fingerprinting.
JS uses the **same shape**:

- Container JS under `app/assets/javascripts/` (or the project's established JS root);
  per-engine JS under that engine's `app/assets/javascripts/<engine>/`.
- One bundle per delivery surface, referenced with `javascript_include_tag` (digested by
  Propshaft) — **never** a hardcoded `<script src="/javascript/…">` to a raw `public/` file.
- Third-party libraries are **vendored into the pipeline**, not loaded from a CDN — this
  keeps the open-source-first, swappable-dependency posture and avoids a runtime external
  dependency.


## Passing server data to JS

The reason inline JS is tempting is that JS often needs server data or route URLs. Hand it
over through the DOM, not through string interpolation in a `<script>`:

```slim
/ a JSON island for structured data
#workflow-editor data-steps-url=editor_steps_path
                 data-validate-url=editor_validate_path
  script#editor-graph-data type="application/json"
    = raw @graph_json
```

```javascript
// app/assets/javascripts/workflow_builder/editor.js
const root  = document.getElementById("workflow-editor");
const graph = JSON.parse(document.getElementById("editor-graph-data").textContent);
const stepsUrl = root.dataset.stepsUrl;
```

- Small scalars / route URLs → `data-` attributes on a root element.
- Structured blobs → a `<script type="application/json">` island read via `textContent`
  (note: `application/json` is data, not executable JS — it is not an inline script).
- Route templates that need an id → emit a `data-…-url-template` with a `__ID__`
  placeholder and `.replace()` in JS, exactly as before — just sourced from the DOM.


## Binding behaviour

No `on*=` attributes. Bind in the pipeline file:

```slim
button.btn#btn-validate type="button" = t("…validate")
```

```javascript
document.getElementById("btn-validate")
        ?.addEventListener("click", submitValidate);
```

For shared behaviour (e.g. flash dismissal), expose one module method and bind by class —
do not sprinkle `onclick="dismissFlash(this)"` across every layout:

```javascript
document.querySelectorAll(".page-alert__dismiss-button")
        .forEach((b) => b.addEventListener("click", () =>
          b.closest(".page-alert")?.remove()));
```


## Checklist before a view is done

- [ ] No `<script>` with inline body in the view (only `javascript_include_tag` / a JSON island).
- [ ] No `javascript:` Slim filter.
- [ ] No `on*=` attributes.
- [ ] No ERB/Slim interpolation inside a `<script>`.
- [ ] All third-party JS vendored through the pipeline, not a CDN.
- [ ] Server data reaches JS via `data-` attributes / a JSON island read from the DOM.

Pairs with [[authoring-presenters]] (view-language output) and the asset-pipeline styling
foundation (CSS side of the same rule).
