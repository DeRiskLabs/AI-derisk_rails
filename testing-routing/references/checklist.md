# Review Checklist — Routing Specs

- [ ] `require 'rails_helper'`; `RSpec.describe TheController, type: :routing` (controller
      class, not a string; engine class for mounting specs).
- [ ] Engine specs declare `routes { TheEngine.routes }`; paths relative to the mount.
- [ ] Route comment block copied from `routes.rb` near the top.
- [ ] Grouped `Resourceful Routes` / `Non-Resourceful Routes`, each with `permitted` AND
      `not permitted` contexts — all four quadrants where routes of both kinds exist.
- [ ] Permitted routes asserted with `route_to('controller#action', param: 'value')` via
      the controller-string helper.
- [ ] Captured path params asserted explicitly; public params are `uuid` /
      `<resource>_uuid`, never `:id`.
- [ ] Restricted resources (`only:`/`except:`) prove the excluded defaults with
      `not_to be_routable`.
- [ ] Standalone routes prove their unexposed verbs with `not_to be_routable`.
- [ ] Examples named `specify '#action for VERB /path'`.
- [ ] One expectation per example.
- [ ] Each mounted engine has a mounting spec pinning its mount path in the host app.
- [ ] No controller behaviour assertions (that belongs in a request spec).
