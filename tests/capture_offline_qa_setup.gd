class_name CaptureOfflineQaSetup
extends RefCounted
## Checkpoint-local presentation fixture; it deliberately does not own process
## arguments, screenshot writes, or any persistent save mutation.

static func configure(main, mode: String) -> bool:
	if mode == "future_save_recovery":
		GameManager.profile = {"schema_version":Catalog.SCHEMA_VERSION + 1, "revision":91, "coins":777, "future_marker":"preserve"}
		GameManager.save_compatibility = ProfileRules.compatibility(GameManager.profile)
		main.screen = "workshop"
		return true
	return false
