# Synthetic startup preservation fixtures

These deliberately small files are invented test data, never copied from a player.
The primary-owned verification runner copies common sidecars plus one named case
into a fresh E-based QA root before Godot starts, records byte size and SHA-256 for
every file, and requires the entire file set and bytes to remain unchanged afterward.
The state suite exercises the actual autoload startup, not a mocked profile loader.

Cases: invalid historical 40-card deck/ownership, future schema, invalid primary
with recoverable backup, and invalid backup without a primary. Empty arrays are
valid JSON but invalid profile dictionaries, allowing recovery testing without an
unrelated JSON parser error. A normal state run also requires its clean QA root to
remain empty. Runtime compatibility/recovery markers must match the expected case.

No fixture grants prototype ownership, migrates a profile, or authorizes live-save
access. Run `tools/run_team_battle_tests.ps1 -Suite startup` from the project.
