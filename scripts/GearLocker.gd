# GearLocker.gd
# Equipment management — attach armor, weapons, and accessories to prints.
# Scene file: res://scenes/GearLocker.tscn
#
# SCENE TREE:
# GearLocker (Node2D)
# ├── Background (ColorRect) — #1A1A2E full screen
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
# │   │   ├── TitleLabel (Label) — "⚙ Gear Locker" size 24
# │   │   └── BackBtn (Button) — "← Workshop" min 120x44
# │   ├── PrintList (VBoxContainer) — left 380px, scrollable, your prints
# │   │   [Built dynamically]
# │   ├── EquipPanel (Panel) — center, width 400px, full height, #0D0D1A
# │   │   ├── EquipTitle (Label) — "Select a Print first" size 20 center
# │   │   ├── PrintPreview (ColorRect) — 100x100 center
# │   │   ├── ArmorSlot (HBoxContainer)
# │   │   │   ├── SlotLabel (Label) — "🛡 Armor:" size 18
# │   │   │   ├── SlotValue (Label) — "None" size 18 color #AAAAAA
# │   │   │   └── ChangeArmorBtn (Button) — "Change" min 100x36
# │   │   ├── WeaponSlot (HBoxContainer)
# │   │   │   ├── SlotLabel (Label) — "⚔ Weapon:" size 18
# │   │   │   ├── SlotValue (Label) — "None" size 18 color #AAAAAA
# │   │   │   └── ChangeWeaponBtn (Button) — "Change" min 100x36
# │   │   └── AccessorySlot (HBoxContainer)
# │   │       ├── SlotLabel (Label) — "💍 Accessory:" size 18
# │   │       ├── SlotValue (Label) — "None" size 18 color #AAAAAA
# │   │       └── ChangeAccessoryBtn (Button) — "Change" min 100x36
# │   └── EquipmentPicker (Panel) — equipment_picker, full screen overlay
# │       hidden by default, bg #1A1A2E CC (semi-transparent)
# │       ├── PickerTitle (Label) — "Choose Armor" size 22 color #E8A020
# │       ├── PickerGrid (GridContainer) — columns 3, equipment options
# │       ├── UnequipBtn (Button) — "Remove Equipment" color #884444
# │       └── CancelBtn (Button) — "Cancel" color #444444

extends Node2D

var _selected_print_iid = ""   # Currently selected print instance ID
var _picker_slot = ""           # "armor" | "weapon" | "accessory"

@onready var print_list: VBoxContainer     = $UI/PrintList
@onready var equip_title: Label            = $UI/EquipPanel/EquipTitle
@onready var print_preview: ColorRect      = $UI/EquipPanel/PrintPreview
@onready var armor_value: Label            = $UI/EquipPanel/ArmorSlot/SlotValue
@onready var weapon_value: Label           = $UI/EquipPanel/WeaponSlot/SlotValue
@onready var accessory_value: Label        = $UI/EquipPanel/AccessorySlot/SlotValue
@onready var equipment_picker: Panel       = $UI/EquipmentPicker
@onready var picker_title: Label           = $UI/EquipmentPicker/PickerTitle
@onready var picker_grid: GridContainer    = $UI/EquipmentPicker/PickerGrid

func _ready() -> void:
	equipment_picker.visible = false
	_build_print_list()
	_clear_equip_panel()

# ─────────────────────────────────────────────────────────────────────────────
# PRINT LIST
# ─────────────────────────────────────────────────────────────────────────────
func _build_print_list() -> void:
	for child in print_list.get_children():
		child.queue_free()

	var prints = SaveManager.get_prints()
	if prints.is_empty():
		var lbl = Label.new()
		lbl.text = "No prints yet.\nVisit the Filament Market!"
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		print_list.add_child(lbl)
		return

	for inst in prints:
		var creature = GameData.CREATURES[inst["creature_id"]]
		var card = Panel.new()
		card.custom_minimum_size = Vector2(340, 70)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(56, 56)
		swatch.color = creature["placeholder_color"]
		hbox.add_child(swatch)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)

		var name_lbl = Label.new()
		name_lbl.text = creature["name"]
		name_lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(name_lbl)

		# Show equipped items summary
		var eq = inst["equipment"]
		var eq_text = []
		if eq["armor"] != "":
			eq_text.append("🛡 " + GameData.EQUIPMENT[eq["armor"]]["name"])
		if eq["weapon"] != "":
			eq_text.append("⚔ " + GameData.EQUIPMENT[eq["weapon"]]["name"])
		if eq["accessory"] != "":
			eq_text.append("💍 " + GameData.EQUIPMENT[eq["accessory"]]["name"])
		var summary_lbl = Label.new()
		summary_lbl.text = ", ".join(eq_text) if eq_text.size() > 0 else "No equipment"
		summary_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		summary_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(summary_lbl)

		var select_btn = Button.new()
		select_btn.text = "Manage"
		select_btn.custom_minimum_size = Vector2(90, 40)
		select_btn.pressed.connect(_on_print_selected.bind(inst["instance_id"]))
		hbox.add_child(select_btn)

		print_list.add_child(card)

# ─────────────────────────────────────────────────────────────────────────────
# EQUIP PANEL
# ─────────────────────────────────────────────────────────────────────────────
func _on_print_selected(instance_id: String) -> void:
	_selected_print_iid = instance_id
	_refresh_equip_panel()

func _refresh_equip_panel() -> void:
	var inst = SaveManager.get_print_by_instance_id(_selected_print_iid)
	if inst.is_empty():
		_clear_equip_panel()
		return

	var creature = GameData.CREATURES[inst["creature_id"]]
	equip_title.text = creature["name"]
	print_preview.color = creature["placeholder_color"]

	# Armor slot
	var armor_id: String = inst["equipment"]["armor"]
	armor_value.text = GameData.EQUIPMENT[armor_id]["name"] if armor_id != "" else "None"

	# Weapon slot
	var weapon_id: String = inst["equipment"]["weapon"]
	weapon_value.text = GameData.EQUIPMENT[weapon_id]["name"] if weapon_id != "" else "None"

	# Accessory slot
	var acc_id: String = inst["equipment"]["accessory"]
	accessory_value.text = GameData.EQUIPMENT[acc_id]["name"] if acc_id != "" else "None"

func _clear_equip_panel() -> void:
	equip_title.text = "Select a Print to manage gear"
	print_preview.color = Color(0.2, 0.2, 0.2)
	armor_value.text = "—"
	weapon_value.text = "—"
	accessory_value.text = "—"

# ─────────────────────────────────────────────────────────────────────────────
# SLOT BUTTONS
# ─────────────────────────────────────────────────────────────────────────────
func _on_change_armor_btn_pressed() -> void:
	_open_picker("armor")

func _on_change_weapon_btn_pressed() -> void:
	_open_picker("weapon")

func _on_change_accessory_btn_pressed() -> void:
	_open_picker("accessory")

func _open_picker(slot: String) -> void:
	if _selected_print_iid == "":
		return
	_picker_slot = slot
	picker_title.text = "Choose %s" % slot.capitalize()
	equipment_picker.visible = true
	_build_picker_grid(slot)

func _build_picker_grid(slot: String) -> void:
	for child in picker_grid.get_children():
		child.queue_free()

	# Show all owned equipment of this type that is unattached
	var owned = SaveManager.get_equipment_owned()
	var found = false

	for eq_inst in owned:
		var eq_data = GameData.EQUIPMENT[eq_inst["equipment_id"]]
		if eq_data["type"] != slot:
			continue
		# Skip if attached to a different print
		if eq_inst["attached_to"] != "" and eq_inst["attached_to"] != _selected_print_iid:
			continue

		found = true
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 80)
		btn.text = "%s\n%s" % [eq_data["name"], eq_data["description"]]
		if eq_inst["attached_to"] == _selected_print_iid:
			btn.text += "\n[Equipped]"
		btn.pressed.connect(_on_equipment_picked.bind(eq_inst["instance_id"]))
		picker_grid.add_child(btn)

	if not found:
		var lbl = Label.new()
		lbl.text = "No %s equipment available.\nVisit the Filament Market!" % slot
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		picker_grid.add_child(lbl)

func _on_equipment_picked(eq_instance_id: String) -> void:
	SaveManager.equip_item(eq_instance_id, _selected_print_iid)
	equipment_picker.visible = false
	_refresh_equip_panel()
	_build_print_list()

func _on_unequip_btn_pressed() -> void:
	# Remove whatever is in the current slot
	var inst = SaveManager.get_print_by_instance_id(_selected_print_iid)
	if inst.is_empty():
		return
	var slot_iid: String = inst["equipment"][_picker_slot]
	if slot_iid == "":
		equipment_picker.visible = false
		return
	# Detach by equipping nothing — find the instance and clear attached_to
	var eq_owned = SaveManager.get_equipment_owned()
	for eq_inst in eq_owned:
		if eq_inst["instance_id"] == slot_iid:
			eq_inst["attached_to"] = ""
			break
	inst["equipment"][_picker_slot] = ""
	SaveManager.save_game()
	equipment_picker.visible = false
	_refresh_equip_panel()
	_build_print_list()

func _on_cancel_btn_pressed() -> void:
	equipment_picker.visible = false

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
