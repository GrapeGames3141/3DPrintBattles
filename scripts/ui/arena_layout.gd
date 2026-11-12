class_name Arena
extends RefCounted
## Where things sit on the battlefield, for landscape ("L") and portrait ("P").
##
## The workbench background is rendered by tools/render_arena.gd from these
## same numbers, so the glowing lanes baked into the picture line up with
## where the game stands the prints. Positions are in stage pixels. The
## picture is larger than the stage by `margin` on each side so that wider or
## taller screens still see bench, not black bars.

const PIXELS_PER_UNIT := 80.0
const RENDER_SCALE := 1.5

const SPECS := {
	"L": {
		"stage": Vector2(1280, 720),
		"margin": Vector2(320, 120),
		"image": "res://assets/ui/arena/workbench_landscape.jpg",
		"zone_foe": Rect2(250, 112, 720, 172),
		"zone_me": Rect2(320, 312, 760, 186),
		"mat_me": Rect2(4, 548, 292, 122),
		"mat_foe": Rect2(996, 150, 250, 104),
		"printer_me": Vector2(16, 392),
		"printer_me_scale": 1.5,
		"printer_foe": Vector2(1010, 24),
		"printer_foe_scale": 1.25,
	},
	"P": {
		"stage": Vector2(720, 1280),
		"margin": Vector2(120, 240),
		"image": "res://assets/ui/arena/workbench_portrait.jpg",
		"zone_foe": Rect2(20, 236, 640, 178),
		"zone_me": Rect2(60, 446, 650, 190),
		"mat_me": Rect2(0, 766, 222, 96),
		"mat_foe": Rect2(530, 142, 190, 84),
		"printer_me": Vector2(2, 640),
		"printer_me_scale": 1.2,
		"printer_foe": Vector2(536, 44),
		"printer_foe_scale": 1.0,
	},
}

## A slight colour cast per arena so campaign stops do not all look alike.
const TINTS := {
	"daily_arena": Color(1, 1, 1),
	"first_layers": Color(1, 1, 1),
	"element_bench": Color(0.9, 1.0, 1.08),
	"reinforced_run": Color(1.08, 0.98, 0.88),
	"masterwork_circuit": Color(0.94, 0.92, 1.12),
	"primordial_proof": Color(1.12, 0.9, 0.9),
}


static func spec(portrait: bool) -> Dictionary:
	return SPECS["P" if portrait else "L"]
