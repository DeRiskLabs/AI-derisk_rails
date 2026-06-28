---
name: no-inline-javascript
title: "No Inline JavaScript — Use Rails Assets"
description: "JavaScript never lives in a view. No inline <script> blocks, no Slim javascript: filter blocks, no on*= handler attributes, no server data interpolated into a <script>. Use the app's Rails asset convention, pass server data through DOM-safe channels, and vendor third-party libraries instead of loading them from a CDN."
category: authoring
status: active
version: 1.0
applies_to:
  - Rails
  - JavaScript
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

**Why:** with all JS in one place we can refactor it, keep it tidy, lint/test it,
fingerprint and cache it, and reason about it. Inline JS is unrefactorable,
untestable, uncacheable, and duplicated across views.


## Where JS lives

Use the app's established Rails asset convention. Do not invent a second JavaScript
pipeline for one page.

- If the app uses importmap, add modules/controllers to the importmap-managed structure.
- If the app uses Stimulus, put behavior in Stimulus controllers.
- If the app uses jsbundling, Propshaft, or Sprockets directly, follow that structure.
- If `project_context/agent_skills/` defines a local asset convention, follow it.
- Do not hardcode raw `public/` script paths from templates.
- Vendor third-party libraries through the project's asset mechanism; do not load them
  from a CDN unless the project explicitly allows it.


## Passing server data to JS

The reason inline JS is tempting is that JS often needs server data or route URLs. Hand it
over through the DOM, not through string interpolation in a `<script>`.

- Small scalars / route URLs -> `data-` attributes, or Stimulus values when Stimulus is
  the app convention.
- Structured blobs -> a `<script type="application/json">` island read via `textContent`
  (this is data, not executable JS).
- Route templates that need an id -> emit a `...-url-template` value with a placeholder
  and replace it in the asset file.

```slim
#workflow-editor data-controller="workflow-editor"
                 data-workflow-editor-steps-url-value=editor_steps_path
  script#editor-graph-data type="application/json"
    = raw @graph_json
```

```javascript
// app/javascript/workflow_builder/controllers/workflow_editor_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static values = { stepsUrl: String }
  connect() {
    const graph = JSON.parse(document.getElementById("editor-graph-data").textContent)
    // this.stepsUrlValue is available
  }
}
```


## Binding behaviour

No `on*=` attributes. Bind behavior from an asset file using the app's convention. If the
app uses Stimulus, bind with `data-action`:

```slim
button.btn data-action="code-editor#validate" = t("…validate")
```

```javascript
// app/javascript/code_studio/controllers/code_editor_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  validate() { /* … */ }
}
```

For shared behavior, bind once through the project convention. Do not sprinkle
`onclick="dismissFlash(this)"` across templates:

```slim
.page-alert data-controller="flash"
  button.page-alert__dismiss-button data-action="flash#dismiss"
```

```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  dismiss() { this.element.remove() }
}
```

Where a project has no Stimulus or equivalent convention, use a Rails-managed asset file
that binds with `addEventListener` keyed off ids, semantic classes, or `data-` hooks.


## Checklist before a view is done

- [ ] No `<script>` with executable inline body in the view.
- [ ] No `javascript:` Slim filter.
- [ ] No `on*=` attributes.
- [ ] No ERB/Slim interpolation inside a `<script>`.
- [ ] JS lives in the app's Rails asset structure.
- [ ] Third-party JS is vendored through the app's asset mechanism, not loaded from CDN.
- [ ] Server data reaches JS through `data-` attributes, Stimulus values, or a JSON island.

Pairs with [[authoring-presenters]] (view-language output) and the asset-pipeline styling
foundation (CSS side of the same rule).
