# Rust E2E Coverage

Current suite entrypoint:

- [`auth_contacts_e2e`](tests/full_e2e.rs)
- [`legacy_contact_recovery_e2e`](tests/full_e2e.rs)
- [`legacy_kit_recovery_e2e`](tests/full_e2e.rs)

Shared setup and helpers:

- owner/trusted pair creation and legacy-contact bootstrap: [`tests/support/legacy.rs`](tests/support/legacy.rs)
- auth helpers: [`tests/support/auth.rs`](tests/support/auth.rs)
- contacts and legacy-info helpers: [`tests/support/contacts.rs`](tests/support/contacts.rs)
- local/CI runner: [`scripts/run.sh`](scripts/run.sh)
- CI workflow: [`../../.github/workflows/rust-e2e-test.yml`](../../.github/workflows/rust-e2e-test.yml)

## Covered Scenarios

| Area | Covered behavior | Source |
| --- | --- | --- |
| Auth | fresh account creation for owner and trusted contact | [`tests/support/legacy.rs`](tests/support/legacy.rs), [`tests/support/auth.rs`](tests/support/auth.rs) |
| Auth | login with the initial password | [`run_auth_stage`](tests/full_e2e.rs), [`tests/support/auth.rs`](tests/support/auth.rs) |
| Auth | enable TOTP and login with TOTP | [`run_auth_stage`](tests/full_e2e.rs), [`tests/support/auth.rs`](tests/support/auth.rs) |
| Contacts | create a contact record | [`run_contacts_stage`](tests/full_e2e.rs) |
| Contacts | read back the contact record | [`run_contacts_stage`](tests/full_e2e.rs) |
| Contacts | update contact name and birth date | [`run_contacts_stage`](tests/full_e2e.rs) |
| Contacts | diff includes the created contact | [`run_contacts_stage`](tests/full_e2e.rs) |
| Contacts | contact isolation across accounts (`404` from trusted account) | [`run_contacts_stage`](tests/full_e2e.rs) |
| Contacts | delete the contact record | [`run_contacts_stage`](tests/full_e2e.rs) |
| Legacy | establish owner/trusted legacy relationship with accepted state | [`tests/support/legacy.rs`](tests/support/legacy.rs), [`tests/support/contacts.rs`](tests/support/contacts.rs) |
| Legacy | start recovery, owner rejects, recovery session disappears, accepted contact remains | [`run_legacy_reject_stage`](tests/full_e2e.rs) |
| Legacy | trusted contact stops recovery and both recovery-session views clear | [`run_legacy_stop_stage`](tests/full_e2e.rs) |
| Legacy | revoke and re-invite trusted contact back to accepted state | [`run_legacy_reinvite_stage`](tests/full_e2e.rs) |
| Legacy | full recovery flow to `READY` after owner approval | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | recovered contact changes password through legacy recovery | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | old password login fails after recovery | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | new password login succeeds after recovery | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | recovered login keeps the same `user_id` and master key | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | TOTP is cleared by recovery | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | recovery session is cleared after password reset | [`run_legacy_reset_stage`](tests/full_e2e.rs) |
| Recovery | legacy trusted contact remains configured after recovery | [`run_legacy_reset_stage`](tests/full_e2e.rs) |

## Not Covered Yet

- contact profile-picture / attachment flows
- object-store-backed scenarios
- passkey flows
- recovery via elapsed notice period without explicit owner approval
- multi-process shared fixtures; current reuse is scoped to one test binary
