# common_agent_skills/derisk_rails/authoring-serializers/references/checklist.md


# Authoring Checklist — Serializers

- [ ] Lives at `apis/v1/app/serializers/v1/<resource>_serializer.rb`.
- [ ] Inherits `V1::BaseSerializer` (which includes `JSONAPI::Serializer`).
- [ ] `set_type :plural`; `set_id(&:uuid)`.
- [ ] Only intended `attributes` exposed (derived accessors allowed).
- [ ] Relationships declared with the related serializer and `id_method_name: :uuid`.
- [ ] `STANDARD_INCLUDES` constant defines default includes for the controller.
- [ ] No business logic, computation, or data fetching in the serializer.
- [ ] Internal `id` never exposed where `uuid` is the public identifier.
- [ ] Response shape inherits the JSON:API envelope from the base (no bespoke envelope).
- [ ] Failure documents produced by the shared `ErrorSerializer`
      (`{ errors: [{ status, title, detail, source }] }`, conventional pointers).
- [ ] Shared error helpers interpolate the actual resource type — no hard-coded resource
      names.
