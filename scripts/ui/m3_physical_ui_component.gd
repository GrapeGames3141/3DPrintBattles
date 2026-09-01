class_name M3PhysicalUiComponent
extends RefCounted
## M3 plate orchestrator. Route controls live in their physical component owners.

const PLATE := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const ARCHIVE_WORKBENCH := preload("res://scripts/ui/physical_archive_workbench_component.gd")
const SUPPLY_REWARD := preload("res://scripts/ui/physical_supply_reward_component.gd")
const RESULT_RECEIPT := preload("res://scripts/ui/physical_result_receipt_component.gd")
const SETTINGS_RECOVERY := preload("res://scripts/ui/physical_settings_recovery_component.gd")

const MASTER_PATHS := {
	"unified_library":"res://assets/ui/physical_ui/m3/CO-01-archive-folio-grid-text-free-v4.png",
	"archive_detail":"res://assets/ui/physical_ui/m3/CO-02-archive-folio-detail-text-free-v3.png",
	"unified_deck":"res://assets/ui/physical_ui/m3/DK-01-deck-workbench-text-free-v2.png",
	"unified_market":"res://assets/ui/physical_ui/m3/MK-01-supply-cabinet-text-free-v2.png",
	"settings":"res://assets/ui/physical_ui/m3/ST-01-settings-instrument-text-free-v3.png",
	"recovery":"res://assets/ui/physical_ui/m3/SY-02-recovery-ledger-text-free-v2.png",
	"result":"res://assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png",
	"pack":"res://assets/ui/physical_ui/m3/RW-02-pack-opening-v3.png"
}

func render(main: Control) -> void:
	var key := "recovery" if GameManager.is_save_read_only() else str(main.screen)
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	# A committed receipt is a modal route, never an overlay over the originating surface.
	if not pending.is_empty(): key = "pack"
	if key == "unified_library" and not str(main.unified_inspector_id).is_empty(): key = "archive_detail"
	if key == "m3_result": key = "result"
	if not MASTER_PATHS.has(key): key = "unified_library"
	var plate := PLATE.new(); plate.name = "M3Physical%sPlate" % key.capitalize()
	var path := str(MASTER_PATHS[key]); plate.configure(ResourceLoader.load(path) as Texture2D if ResourceLoader.exists(path) else null); plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); main.add_child(plate); main._apply_synthetic_host_inset_stress(plate)
	var surface := plate.content_layer(); surface.name = "M3Physical%sSurface" % key.capitalize()
	var margin := Callable(self, "_margin"); var heading := Callable(self, "_heading"); var scroll := Callable(self, "_scroll")
	match key:
		"unified_library", "archive_detail": PhysicalArchiveWorkbenchComponent.new().render_archive(main, surface, margin, heading)
		"unified_deck": PhysicalArchiveWorkbenchComponent.new().render_deck(main, surface, margin, heading, scroll)
		"unified_market": PhysicalSupplyRewardComponent.new().render_market(main, surface, margin, heading, scroll)
		"settings": PhysicalSettingsRecoveryComponent.new().render_settings(main, surface, margin, heading)
		"recovery": PhysicalSettingsRecoveryComponent.new().render_recovery(main, surface, margin, heading)
		"result": PhysicalResultReceiptComponent.new().render(main, surface, margin, heading)
		"pack": PhysicalSupplyRewardComponent.new().render_pack(main, surface, margin, heading)
	main._visual_toast(surface)

func _margin(surface: Control, name: String, rect := Rect2(0.055, 0.07, 0.89, 0.87)) -> VBoxContainer:
	var holder := MarginContainer.new(); holder.name = name + "Margin"; holder.anchor_left = rect.position.x; holder.anchor_top = rect.position.y; holder.anchor_right = rect.end.x; holder.anchor_bottom = rect.end.y; holder.add_theme_constant_override("margin_left", 8); holder.add_theme_constant_override("margin_right", 8); holder.add_theme_constant_override("margin_top", 8); holder.add_theme_constant_override("margin_bottom", 8); surface.add_child(holder)
	var body := VBoxContainer.new(); body.name = name; body.add_theme_constant_override("separation", 7); holder.add_child(body); return body

func _heading(main: Control, host: Container, title: String, subtitle: String, back_action: Callable = Callable(), back_tooltip := "Return to Workshop") -> void:
	var action: Callable = back_action if back_action.is_valid() else main.navigate_to.bind("workshop")
	var back: Button = main._visual_button("UnifiedFoundryWorkshopReturn", "←", action, Color("8a6945")); back.custom_minimum_size = Vector2(56, 56); back.tooltip_text = back_tooltip; back.accessibility_name = back.tooltip_text; host.add_child(back)
	var h: Label = main.label(title, 22, Color("2d2118")); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; host.add_child(h)
	var s: Label = main.label(subtitle, 13, Color("513c25")); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; host.add_child(s)

func _scroll(host: Container, name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new(); scroll.name = name; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; host.add_child(scroll)
	var content := VBoxContainer.new(); content.name = name + "Body"; content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation", 6); scroll.add_child(content); return content
