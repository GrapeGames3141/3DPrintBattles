class_name SteamAdapter
extends RefCounted
## Plugin boundary. Steamworks initialization is supplied by a release-only GodotSteam integration.
func is_available() -> bool: return false
func encrypted_app_ticket() -> PackedByteArray: return PackedByteArray()
