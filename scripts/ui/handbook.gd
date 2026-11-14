class_name Handbook
extends RefCounted
## The player's handbook: every rule and keyword in plain words, in chapters.
## `Handbook.open(screen)` lays it over any screen (a battle carries on beneath it).
## Keyword wording comes from GameData.KEYWORDS so it cannot drift from the cards.

const CHAPTERS := ["Your turn", "Keywords", "Conditions", "Cards", "Collecting"]

## Longer explanations, one per keyword, to go with the short card text.
const KEYWORD_MORE := {
	"guard": "While you have a Guard print, the enemy cannot attack your Printer or your other prints. They have to knock the Guard down first. Guards you cannot reach are greyed out when you pick a target.",
	"rush": "Most prints are Cooling the turn they arrive and cannot attack. A Rush print skips that wait, but only against enemy prints, never straight at a Printer.",
	"brim": "A shell of extra plastic: the first hit it takes does nothing at all, however big. After that it is an ordinary print.",
	"siphon": "Every point of damage the print deals heals your Printer by the same amount, whether it hits a print or the enemy Printer.",
	"hover": "Hover prints float over the bench: only a print with Hover or Reach can attack them. Tools and Printer Powers can still hit them. Hover does not stop a Guard from being attacked first, and it does not protect the Printer.",
	"reach": "Reach is the answer to Hover. A print with Reach attacks Hover prints as easily as any other print.",
	"snap": "If Snap deals any damage to a print, that print is destroyed, however big it is. A hit that Brim swallows does not count. It works when Snap is hit back, too.",
	"quick": "Quick Draw prints strike first. If the hit destroys the other print, it never hits back. Against another Quick Draw print both hit together.",
	"overflow": "Damage past what it took to destroy a print goes on to hit the enemy Printer. A 5 Attack Overflow print destroying a 2 Health print hits the Printer for 3.",
	"reprint": "The first time it would be destroyed it comes back with 1 Health instead, and loses Reprint. Gear and Attack stay.",
	"menace": "Guard prints stop most attackers, but not Menace. One Guard cannot stand in its way. Two or more still can.",
	"ward": "The first tool the enemy aims at a Ward print is wasted (the card is still spent), and the Ward is gone. Tools that hit every print are not stopped.",
	"cloak": "Tools cannot be aimed at a Cloak print until it has attacked once. It can still be hit by attacks and by tools that hit every print.",
	"twin": "Two attacks every turn. Each one can pick a different target, and each hit can use Scorch or Thief.",
	"scorch": "Each hit sets the print it hit on Heat. A Heated print takes 1 damage at the start of its owner's turn, every turn, until it is gone.",
	"thief": "Each hit takes 1 Attack from the print it hit and adds 1 Health to the thief. Against a Heated print the theft is doubled. The thief also takes on its victim's colours.",
}

const GLOSSARY := [
	["Heat", "A Heated print takes 1 damage at the start of its owner's turn. Scorch and some tools cause it. It does not wear off."],
	["Jam", "A jammed print cannot attack until the end of its owner's next turn. The tag on the print says JAMMED."],
	["Poison", "Hurts a print at the start of its owner's turns: 1, then 2, then 3 damage, then it wears off. Cleanse removes it."],
	["Sleep", "A sleeping print is jammed for two of its owner's turns instead of one."],
	["Cleanse", "Removes Heat, Jam and Poison from your prints."],
	["Weakness", "A print with Weakness deals 2 extra damage to prints of one element, named on its card (Kilnpup: Nature)."],
	["Armor", "Shields a Printer. Damage comes off Armor before Health. It stays until it is used up."],
	["Shatter", "What a print does when it is destroyed. Its owner also gets 1 Filament back on the Spool."],
	["On Print", "What a print does the moment it arrives on the bench."],
	["Turn Start / Turn End", "Happens to the print on its owner's turn: at the start (after Heat) or the end. Seedpup adds Filament, Chronocat repairs itself."],
	["On Attack / On Kill", "When the print attacks, or when its attack destroys a print. Courier draws a card; Gridstag can attack again."],
	["On Hurt", "When the print takes damage and survives. Cairncrab gets angrier; Pebblepup armours your Printer."],
	["On Ally Print / On Foe Print", "When another of your prints arrives, or when an enemy print does. Capacitor powers up each new print; Gravelhopper hits the enemy ones."],
	["On Tool", "When you use a tool. Glyphhare grows, Voidmoth repairs your Printer."],
	["On Ally / Foe Shatter", "When one of your prints, or one of theirs, is destroyed. Monolith and Bramblemaw both grow."],
	["Fresh", "A print that has only just arrived. The tag says COOLING. It can attack from your next turn, unless it has Rush."],
]


## Lays the handbook over `screen`. Returns the layer, so the caller can close it.
static func open(screen: GameScreen, chapter := 0) -> Control:
	var layer: Control = screen.modal(0.92)
	var P: bool = screen.P
	var box: Panel = screen.dialog(layer, Vector2(680, 1160) if P else Vector2(1100, 660))
	var bw := box.size.x
	var bh := box.size.y
	var title := UI.label("Player Handbook", 34, UI.GOLD, true, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 14), Vector2(bw, 44))

	var body_holder := Control.new()
	body_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(body_holder)

	var tab_buttons: Array = []
	var tabs_w := (bw - 40.0 - 8.0 * (CHAPTERS.size() - 1)) / CHAPTERS.size()
	var show := func(i: int) -> void:
		for ch in body_holder.get_children():
			body_holder.remove_child(ch)
			ch.queue_free()
		for j in tab_buttons.size():
			(tab_buttons[j] as Button).disabled = j == i
		var top := 124.0
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.position = Vector2(20, top)
		scroll.size = Vector2(bw - 40, bh - top - 76)
		body_holder.add_child(scroll)
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(bw - 64, 0)
		col.add_theme_constant_override("separation", 10)
		scroll.add_child(col)
		_fill(col, i, bw - 80.0)
	for i in CHAPTERS.size():
		var b := UI.button(CHAPTERS[i], "plain", Vector2(tabs_w, 44), 15 if P else 18)
		b.pressed.connect(show.bind(i))
		UI.place(box, b, Vector2(20 + i * (tabs_w + 8.0), 68))
		tab_buttons.append(b)
	var done := UI.button("Got it", "go", Vector2(220, 50))
	done.pressed.connect(func(): screen.close_modal(layer))
	UI.place(box, done, Vector2(bw * 0.5 - 110, bh - 64))
	show.call(clampi(chapter, 0, CHAPTERS.size() - 1))
	return layer


static func _fill(col: VBoxContainer, chapter: int, width: float) -> void:
	match chapter:
		0:
			_entry(col, width, "spool", UI.CYAN, "Filament", "Everything costs Filament. Your Printer starts by printing %d a turn, and every point you spend also comes off your Spool, which starts a battle holding %d. Run the Spool dry and you can print nothing, so spend it wisely. Printer mods can raise both numbers: Stepper Motors add Filament each turn and Bigger Spool, Spool Rack and others add to the Spool. The battle screen always shows your real amounts." % [GameData.PRINT_SPEED, GameData.SPOOL_SIZE])
			_entry(col, width, "snow", UI.CYAN, "Long prints", "A card that costs more than you can print this turn goes on your Printer and grows over the next turns. Your opponent can see it. Tap it when it is done and it arrives for free.")
			_entry(col, width, "cube", UI.AMBER, "Playing a print", "Drag it from your hand onto your side of the bench, or tap the card and then tap the bench. It is Cooling and cannot attack until your next turn, unless it has Rush.")
			_entry(col, width, "burst", UI.AMBER, "Attacking", "Tap a print tagged READY, then tap what to hit, or drag it onto the target. Both prints deal their Attack to each other. A print tagged DONE has already attacked, and COOLING means wait a turn.")
			_entry(col, width, "star", UI.GOLD, "Printer Power", "Every Printer has one Power. It costs %d Filament and works once a turn. The Workshop shows what each Printer's Power does." % GameData.POWER_COST)
			_entry(col, width, "hex", UI.BAD, "Winning", "Bring the enemy Printer's Health down to 0. A Printer starts with %d Health, and mods such as Reinforced Frame can add more, so your opponent's may be higher or lower than yours. If your hand drops below %d cards you are topped up at the start of your turn (Smart Slicer raises that), and your hand holds %d at most." % [GameData.PRINTER_HP, GameData.HAND_TOP_UP, GameData.MAX_HAND])
			_entry(col, width, "gear", UI.MUTED, "Controls", "Right-click or Esc cancels a choice. Space ends your turn. Tap any print on the bench to read its card. F11 switches fullscreen.")
		1:
			var order: Array = ["guard", "rush", "brim", "siphon", "twin", "scorch", "thief", "hover", "reach", "snap", "quick", "overflow", "reprint", "menace", "ward", "cloak"]
			for k in order:
				var d: Dictionary = GameData.KEYWORDS[k]
				var seen := _seen_on(k)
				var more: String = KEYWORD_MORE.get(k, "")
				_entry(col, width, _kw_icon(k), _kw_color(k), str(d["name"]), "%s\n%s%s" % [d["text"], more, ("\nSeen on: " + seen) if seen != "" else ""])
		2:
			for g in GLOSSARY:
				_entry(col, width, "", UI.CREAM, str(g[0]), str(g[1]))
			_entry(col, width, "", UI.CREAM, "Status tags on the bench", "READY (green): can attack now.   COOLING (blue): just printed, wait a turn.   DONE (grey): has attacked this turn.   JAMMED (cyan): cannot attack.")
		3:
			_entry(col, width, "cube", UI.AMBER, "Prints", "Creatures. Attack and Health sit in the corners. Many have an On Print effect when they arrive, or a Shatter effect when they are destroyed.")
			_entry(col, width, "flame", UI.BAD, "Tools", "One-shot effects named after real 3D printing tools. Drag one onto its target, or tap the card and then the target.")
			_entry(col, width, "shield", Color("dfe6f0"), "Equipment", "Printed gear you bolt onto one of your prints for the rest of the battle. It adds Attack and Health and sometimes a keyword. If the print is destroyed the gear goes with it.")
			_entry(col, width, "star", UI.GOLD, "Elements", "Eight elements: Fire, Water, Lightning, Nature, Ice, Stone, Wind and Arcane. A print that shares its Printer's element gets +1 Health.")
			_entry(col, width, "hex", UI.CYAN, "Rarity", "Common, Uncommon, Rare, Epic and Legendary, shown by the colour of the card's frame. Rarer cards cost more and do more.")
		4:
			_entry(col, width, "burst", UI.GOLD, "Packs", "You start with no cards, only Basic Packs: open them in Card Packs to find your cards. Basic Packs are nearly all Common; Blueprint Packs always hold an Uncommon or better, and Golden Spool Packs an Epic or better. Every pack can give a good card, the better packs just do it far more often. Every card is its own copy: open the same card again and your number goes up. A deck can use only as many copies as you own, and never more than 2 of one card (1 if Legendary). Spare copies you cannot use can be recycled for a few coins in Collection or after opening a pack.")
			_entry(col, width, "cube", UI.AMBER, "Blueprints", "Spend coins to take a card from Level 1 to Level 2 and Level 3: stronger or cheaper. Level 2 adds a mod slot and Level 3 a second one, and you can paint the card. Every copy of the card in your decks has it.")
			_entry(col, width, "gear", UI.CYAN, "Printer mods", "You battle with one active Printer, chosen in the Workshop (Use) or in Collection (Change): every deck uses it and only its mods count. Mods are bought in the Workshop. Each copy fits one Printer at a time and moves freely between Printers; buy extra copies to fit the same mod on several. A Printer carries one of each mod, and some mods need others fitted first. Upgrade a fitted mod for coins and Maker Rank to make it stronger: Stepper Motors can reach +4 Filament a turn. A Printer's Tune adds up its mods, and ranked opponents match yours.")
			_entry(col, width, "star", UI.GOLD, "Maker Rank", "Every battle gives XP. Higher ranks unlock Printers, mods and Blueprint tiers in the shops.")
			_entry(col, width, "coin", UI.GOLD, "Coins", "Earn coins from battles. Spend them on packs, Printers, mods, card levels and paints.")


static func _entry(col: VBoxContainer, width: float, icon: String, color: Color, head: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(width, 0)
	col.add_child(row)
	if icon != "":
		var ic := IconView.make(icon, 36, color)
		ic.custom_minimum_size = Vector2(36, 36)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label(head, 21, color, true, 3))
	var t := UI.label(text, 16, UI.CREAM, false)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(width - (60.0 if icon != "" else 0.0), 0)
	v.add_child(t)
	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.07)
	rule.custom_minimum_size = Vector2(width, 1)
	col.add_child(rule)


static func _kw_icon(k: String) -> String:
	return {"guard": "shield", "rush": "burst", "brim": "hex", "siphon": "drop", "twin": "star", "scorch": "flame", "thief": "gear", "hover": "star", "reach": "check", "snap": "flame", "quick": "burst", "overflow": "drop", "reprint": "twin", "menace": "lock", "ward": "hex", "cloak": "snow"}.get(k, "cube")


static func _kw_color(k: String) -> Color:
	return {"guard": Color("dfe6f0"), "rush": UI.AMBER, "brim": UI.CYAN, "siphon": UI.GOOD, "twin": UI.GOLD, "scorch": UI.BAD, "thief": Color("c9a0ff"), "hover": Color("b8f0d8"), "reach": Color("b8f0d8"), "snap": UI.BAD, "quick": UI.AMBER, "overflow": UI.GOOD, "reprint": UI.GOLD, "menace": Color("c9a0ff"), "ward": UI.CYAN, "cloak": Color("8fb4e8")}.get(k, UI.CREAM)


## A few cards that carry the keyword, rarest last, so a player can find one.
static func _seen_on(k: String) -> String:
	var names: Array = []
	for rarity in ["common", "uncommon", "rare"]:
		for c in GameData.collectible():
			if c["type"] == "creature" and (c["kw"] as Array).has(k) and c["rarity"] == rarity and names.size() < 3 and not names.has(c["name"]):
				names.append(c["name"])
				break
	return ", ".join(names)
