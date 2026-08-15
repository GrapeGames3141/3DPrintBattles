extends Node
## Immutable launch catalog. Runtime objects store IDs only, never presentation nodes.

const SCHEMA_VERSION := 4
const CATALOG_VERSION := "0.1.0"
const RARITIES := [
	{"id":"common", "name":"Common", "color":"#b7bcc7", "weight_bps":4500, "blueprint":50, "print":20},
	{"id":"uncommon", "name":"Uncommon", "color":"#66d17a", "weight_bps":2500, "blueprint":120, "print":40},
	{"id":"rare", "name":"Rare", "color":"#69a7ff", "weight_bps":1500, "blueprint":300, "print":70},
	{"id":"epic", "name":"Epic", "color":"#c884ff", "weight_bps":800, "blueprint":600, "print":110},
	{"id":"legendary", "name":"Legendary", "color":"#ffd65a", "weight_bps":400, "blueprint":1200, "print":160},
	{"id":"mythic", "name":"Mythic", "color":"#ff965c", "weight_bps":200, "blueprint":2500, "print":220},
	{"id":"prismatic", "name":"Prismatic", "color":"#ff8ce8", "weight_bps":80, "blueprint":5000, "print":300},
	{"id":"primordial", "name":"Primordial", "color":"#f5d66f", "weight_bps":20, "blueprint":12000, "print":500}
]
const ELEMENTS := ["Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane"]
# Each key maps defender element to fixed-point multiplier (100 = 1.0x).
const ELEMENT_CHART := {
	"Fire":{"Fire":100,"Water":60,"Lightning":100,"Nature":150,"Ice":150,"Stone":100,"Wind":100,"Arcane":100},
	"Water":{"Fire":150,"Water":100,"Lightning":60,"Nature":60,"Ice":150,"Stone":100,"Wind":100,"Arcane":100},
	"Lightning":{"Fire":100,"Water":150,"Lightning":100,"Nature":60,"Ice":100,"Stone":60,"Wind":150,"Arcane":100},
	"Nature":{"Fire":60,"Water":150,"Lightning":150,"Nature":100,"Ice":60,"Stone":150,"Wind":60,"Arcane":100},
	"Ice":{"Fire":60,"Water":60,"Lightning":150,"Nature":150,"Ice":100,"Stone":100,"Wind":150,"Arcane":100},
	"Stone":{"Fire":150,"Water":100,"Lightning":150,"Nature":60,"Ice":100,"Stone":100,"Wind":60,"Arcane":100},
	"Wind":{"Fire":100,"Water":100,"Lightning":60,"Nature":150,"Ice":60,"Stone":150,"Wind":100,"Arcane":100},
	"Arcane":{"Fire":100,"Water":100,"Lightning":100,"Nature":100,"Ice":100,"Stone":100,"Wind":100,"Arcane":150}
}

const CREATURES := [
	{"id":"cinderpaw","name":"Cinderpaw","rarity":"common","element":"Fire","bend":18,"hp":34,"attack":9,"speed":7,"cost":2,"ability":"Ember Pounce","ability_cost":2,"cooldown":2,"starter":true,"sprite_sheet":"res://assets/creatures/2d/cinderpaw_sprite_sheet.png","raw_print":"res://assets/creatures/2d/raw/cinderpaw_raw_print.png"},
	{"id":"aquafin","name":"Aquafin","rarity":"common","element":"Water","bend":17,"hp":36,"attack":8,"speed":6,"cost":2,"ability":"Tidal Patch","ability_cost":2,"cooldown":3,"starter":true,"sprite_sheet":"res://assets/creatures/2d/aquafin_sprite_sheet.png","raw_print":"res://assets/creatures/2d/raw/aquafin_raw_print.png"},
	{"id":"voltwig","name":"Voltwig","rarity":"common","element":"Lightning","bend":16,"hp":30,"attack":10,"speed":9,"cost":2,"ability":"Static Hop","ability_cost":2,"cooldown":2,"starter":true,"sprite_sheet":"res://assets/creatures/2d/voltwig_sprite_sheet.png","raw_print":"res://assets/creatures/2d/raw/voltwig_raw_print.png"},
	{"id":"mossmunk","name":"Mossmunk","rarity":"common","element":"Nature","bend":13,"hp":31,"attack":7,"speed":8,"cost":1,"ability":"Root Guard","ability_cost":1,"cooldown":3,"sprite_sheet":"res://assets/creatures/2d/mossmunk_sprite_sheet.png","raw_print":"res://assets/creatures/2d/raw/mossmunk_raw_print.png"},
	{"id":"frostling","name":"Frostling","rarity":"uncommon","element":"Ice","bend":26,"hp":42,"attack":12,"speed":6,"cost":3,"ability":"Cold Snap","ability_cost":3,"cooldown":3},
	{"id":"stoneback","name":"Stoneback","rarity":"uncommon","element":"Stone","bend":29,"hp":49,"attack":10,"speed":4,"cost":3,"ability":"Shell Brace","ability_cost":2,"cooldown":3},
	{"id":"galehopper","name":"Galehopper","rarity":"uncommon","element":"Wind","bend":24,"hp":35,"attack":13,"speed":11,"cost":3,"ability":"Gust Step","ability_cost":2,"cooldown":2},
	{"id":"sparkotter","name":"Sparkotter","rarity":"uncommon","element":"Lightning","bend":27,"hp":39,"attack":13,"speed":9,"cost":3,"ability":"Charge Current","ability_cost":3,"cooldown":3},
	{"id":"glassdrake","name":"Glassdrake","rarity":"rare","element":"Fire","bend":42,"hp":56,"attack":17,"speed":8,"cost":4,"ability":"Molten Wing","ability_cost":4,"cooldown":3},
	{"id":"coralisk","name":"Coralisk","rarity":"rare","element":"Water","bend":41,"hp":61,"attack":15,"speed":6,"cost":4,"ability":"Reef Repair","ability_cost":3,"cooldown":3},
	{"id":"runestag","name":"Runestag","rarity":"rare","element":"Arcane","bend":46,"hp":53,"attack":18,"speed":10,"cost":4,"ability":"Rune Burst","ability_cost":4,"cooldown":3},
	{"id":"brambleowl","name":"Brambleowl","rarity":"rare","element":"Nature","bend":43,"hp":55,"attack":16,"speed":9,"cost":4,"ability":"Thorn Volley","ability_cost":3,"cooldown":3},
	{"id":"ironmaw","name":"Ironmaw","rarity":"epic","element":"Stone","bend":61,"hp":75,"attack":20,"speed":5,"cost":5,"ability":"Forge Wall","ability_cost":3,"cooldown":4},
	{"id":"aurorawing","name":"Aurorawing","rarity":"epic","element":"Ice","bend":58,"hp":64,"attack":22,"speed":12,"cost":5,"ability":"Aurora Chill","ability_cost":4,"cooldown":3},
	{"id":"thunderelk","name":"Thunderelk","rarity":"epic","element":"Lightning","bend":63,"hp":67,"attack":23,"speed":11,"cost":5,"ability":"Stampede Arc","ability_cost":4,"cooldown":3},
	{"id":"coalgriffin","name":"Coalgriffin","rarity":"legendary","element":"Fire","bend":82,"hp":88,"attack":28,"speed":9,"cost":6,"ability":"Cinder Crown","ability_cost":5,"cooldown":4},
	{"id":"tidewhale","name":"Tidewhale","rarity":"legendary","element":"Water","bend":86,"hp":100,"attack":24,"speed":5,"cost":6,"ability":"Deep Renewal","ability_cost":5,"cooldown":4},
	{"id":"skyforge","name":"Skyforge","rarity":"legendary","element":"Wind","bend":80,"hp":80,"attack":29,"speed":14,"cost":6,"ability":"Jetstream","ability_cost":5,"cooldown":3},
	{"id":"pyraxis","name":"Pyraxis","rarity":"mythic","element":"Arcane","bend":105,"hp":115,"attack":35,"speed":11,"cost":7,"ability":"Prism Nova","ability_cost":6,"cooldown":4},
	{"id":"verdantitan","name":"Verdantitan","rarity":"mythic","element":"Nature","bend":108,"hp":128,"attack":31,"speed":7,"cost":7,"ability":"Ancient Bloom","ability_cost":6,"cooldown":4},
	{"id":"miragefox","name":"Miragefox","rarity":"prismatic","element":"Ice","bend":126,"hp":118,"attack":39,"speed":15,"cost":8,"ability":"Layer Shift","ability_cost":6,"cooldown":3},
	{"id":"voidmanta","name":"Voidmanta","rarity":"prismatic","element":"Arcane","bend":130,"hp":122,"attack":40,"speed":13,"cost":8,"ability":"Void Weave","ability_cost":6,"cooldown":3},
	{"id":"worldcoil","name":"Worldcoil","rarity":"primordial","element":"Stone","bend":160,"hp":160,"attack":47,"speed":6,"cost":9,"ability":"Bedquake","ability_cost":7,"cooldown":5},
	{"id":"starloom","name":"Starloom","rarity":"primordial","element":"Arcane","bend":165,"hp":145,"attack":51,"speed":12,"cost":9,"ability":"First Print","ability_cost":7,"cooldown":5}
]
const ARMOR := [
	{"id":"helm","name":"Layered Helm","hp":10,"speed":0,"armor":0,"blueprint":80,"print":25},
	{"id":"chest_plate","name":"Chest Plate","hp":18,"speed":-1,"armor":1,"blueprint":150,"print":45},
	{"id":"leg_guards","name":"Leg Guards","hp":8,"speed":1,"armor":0,"blueprint":100,"print":30},
	{"id":"full_suit","name":"Full Suit","hp":30,"speed":-2,"armor":2,"blueprint":400,"print":100},
	{"id":"arcane_core","name":"Arcane Core","hp":12,"speed":0,"armor":0,"blueprint":800,"print":200},
	{"id":"shadow_cloak","name":"Shadow Cloak","hp":5,"speed":2,"armor":0,"blueprint":600,"print":150},
	{"id":"titan_plate","name":"Titan Plate","hp":45,"speed":-3,"armor":0,"blueprint":1200,"print":300}
]
const SUPPORT_CARDS := [
	{"id":"raw_filament","name":"Raw Filament","cost":0,"effect":"filament","amount":2}, {"id":"heated_spool","name":"Heated Spool","cost":0,"effect":"filament","amount":3}, {"id":"quick_patch","name":"Quick Patch","cost":1,"effect":"heal","amount":7}, {"id":"reinforced_layer","name":"Reinforced Layer","cost":1,"effect":"shield","amount":4}, {"id":"arcane_spark","name":"Arcane Spark","cost":1,"effect":"attack_buff","amount":3},
	{"id":"coolant","name":"Coolant","cost":1,"effect":"heal","amount":5}, {"id":"spare_nozzle","name":"Spare Nozzle","cost":1,"effect":"cooldown","amount":1}, {"id":"switchback","name":"Switchback","cost":1,"effect":"switch_discount","amount":2}, {"id":"dense_infill","name":"Dense Infill","cost":2,"effect":"shield","amount":7}, {"id":"overclock","name":"Overclock","cost":2,"effect":"filament","amount":4},
	{"id":"flux_tape","name":"Flux Tape","cost":1,"effect":"heal","amount":4}, {"id":"windup","name":"Windup","cost":1,"effect":"attack_buff","amount":2}, {"id":"resin_wash","name":"Resin Wash","cost":1,"effect":"cleanse","amount":1}, {"id":"calibration","name":"Calibration","cost":1,"effect":"draw","amount":1}, {"id":"safety_brace","name":"Safety Brace","cost":2,"effect":"shield","amount":6},
	{"id":"hot_swap","name":"Hot Swap","cost":1,"effect":"switch_discount","amount":3}, {"id":"filament_snare","name":"Filament Snare","cost":2,"effect":"debuff","amount":2}, {"id":"print_accelerant","name":"Print Accelerant","cost":0,"effect":"filament","amount":1}, {"id":"repair_drone","name":"Repair Drone","cost":2,"effect":"heal","amount":10}, {"id":"spark_guard","name":"Spark Guard","cost":1,"effect":"shield","amount":3},
	{"id":"forge_map","name":"Forge Map","cost":1,"effect":"draw","amount":2}, {"id":"layer_lock","name":"Layer Lock","cost":2,"effect":"debuff","amount":3}, {"id":"emergency_coil","name":"Emergency Coil","cost":0,"effect":"filament","amount":2}, {"id":"tempered_edge","name":"Tempered Edge","cost":2,"effect":"attack_buff","amount":5}, {"id":"thermal_paste","name":"Thermal Paste","cost":1,"effect":"cooldown","amount":2},
	{"id":"spool_siphon","name":"Spool Siphon","cost":2,"effect":"debuff","amount":1}, {"id":"soft_reset","name":"Soft Reset","cost":2,"effect":"cleanse","amount":1}, {"id":"print_preview","name":"Print Preview","cost":1,"effect":"draw","amount":1}, {"id":"anchor_bolt","name":"Anchor Bolt","cost":1,"effect":"shield","amount":5}, {"id":"final_pass","name":"Final Pass","cost":3,"effect":"attack_buff","amount":7}
]

func creature(id: String) -> Dictionary:
	for item in CREATURES:
		if item.id == id: return item.duplicate(true)
	return {}

func rarity(id: String) -> Dictionary:
	for item in RARITIES:
		if item.id == id: return item.duplicate(true)
	return RARITIES[0].duplicate(true)

func support_card(id: String) -> Dictionary:
	for item in SUPPORT_CARDS:
		if item.id == id: return item.duplicate(true)
	return {}

func element_multiplier(attacker: String, defender: String) -> int:
	return int(ELEMENT_CHART.get(attacker, {}).get(defender, 100))
