"""Card abilities as small builders, so every card's rules and its rules text
come from one place and cannot drift apart.

    ability(dmg(2, "print"), draw(1))     ->  On Print: ...
    ability(sh_dmg(2, "all"))             ->  Shatter: ...

`at` says what an effect aims at; the first aimed effect decides the card's
`target`.
"""

KW_NAMES = {"guard": "Guard", "rush": "Rush", "brim": "Brim", "siphon": "Siphon", "twin": "Twin Nozzle",
            "scorch": "Scorch", "thief": "Filament Thief"}


def _e(op, sentence, target="", **kw):
    d = {"op": op}
    d.update(kw)
    return {"effect": d, "text": sentence, "target": target}


def _kws(kw):
    return " and " + ", ".join(KW_NAMES[k] for k in kw) if kw else ""


def dmg(n, at="enemy"):
    return {
        "enemy": _e("damage", "Deal %d damage." % n, "enemy", n=n, to="target"),
        "print": _e("damage", "Deal %d damage to an enemy print." % n, "enemy_print", n=n, to="target"),
        "all": _e("damage", "Deal %d damage to all enemy prints." % n, "", n=n, to="enemy_prints"),
        "printer": _e("damage", "Deal %d damage to the enemy Printer." % n, "", n=n, to="enemy_printer"),
        "everything": _e("damage", "Deal %d damage to all prints." % n, "", n=n, to="all_prints"),
    }[at]


def heal(n, at="friendly"):
    if at == "printer":
        return _e("heal", "Repair your Printer by %d." % n, "", n=n, to="own_printer")
    if at == "all":
        return _e("heal", "Repair all your prints by %d." % n, "", n=n, to="friendly_prints")
    return _e("heal", "Repair %d." % n, "friendly", n=n, to="target")


def buff(a, h, at="print", kw=()):
    sign = "+%d/+%d" % (a, h)
    if at == "others":
        return _e("buff", "Give your other prints %s%s." % (sign, _kws(kw)), "", atk=a, hp=h, kw=list(kw), to="other_friendly_prints")
    if at == "all":
        return _e("buff", "Give your prints %s%s." % (sign, _kws(kw)), "", atk=a, hp=h, kw=list(kw), to="friendly_prints")
    return _e("buff", "Give a friendly print %s%s." % (sign, _kws(kw)), "friendly_print", atk=a, hp=h, kw=list(kw), to="target")


def draw(n):
    return _e("draw", "Draw a card." if n == 1 else "Draw %d cards." % n, "", n=n)


def speed(n):
    return _e("filament", "+%d Print Speed this turn." % n, "", n=n)


def spool(n):
    return _e("spool", "Add %d Filament to your Spool." % n, "", n=n)


def armor(n):
    return _e("armor", "Your Printer gains %d Armor." % n, "", n=n)


def jam(at="print"):
    if at == "all":
        return _e("jam", "Jam all enemy prints.", "", to="enemy_prints")
    return _e("jam", "Jam an enemy print.", "enemy_print", to="target")


def heat(n=2, at="print"):
    if at == "all":
        return _e("heat", "Heat all enemy prints.", "", n=n, to="enemy_prints")
    return _e("heat", "Heat an enemy print.", "enemy_print", n=n, to="target")


def poison():
    return _e("poison", "Poison an enemy print: 1, then 2, then 3 damage at the start of its turns.", "enemy_print", to="target")


def sleep(n=2):
    return _e("sleep", "Put an enemy print to sleep: it cannot attack for %d turns." % n, "enemy_print", n=n, to="target")


def cleanse():
    return _e("cleanse", "Cleanse your prints of Heat, Jam and Poison.", "", to="friendly_prints")


def weakness(element):
    """A creature's Weakness ability: it hits prints of one element harder."""
    return {"text": "Weakness: Deals +2 damage to %s prints." % element, "target": "", "on_print": [], "shatter": [], "beats": element}


def a_poison():
    return _e("poison", "Poison the print it hit.", "", to="trigger")


def steal(a, h, bonus=0):
    s = "Steal %d Attack and %d Health from an enemy print." % (a, h) if h else "Steal %d Attack from an enemy print." % a
    return _e("steal", s, "enemy_print", atk=a, hp=h, bonus_hp=bonus, to="target")


def bounce():
    return _e("bounce", "Blow an enemy print back to its owner's hand.", "enemy_print", to="target")


def destroy():
    return _e("destroy", "Destroy an enemy print.", "enemy_print", to="target")


def summon(n=1, card="test_bot"):
    return _e("summon", "Print %d Test Bot%s." % (n, "" if n == 1 else "s"), "", n=n, card=card)


def sh_dmg(n, at="all"):
    x = dmg(n, at)
    x["shatter"] = True
    return x


def sh_draw(n):
    x = draw(n)
    x["shatter"] = True
    return x


def sh_spool(n):
    x = spool(n)
    x["shatter"] = True
    return x


def sh_heal(n):
    x = heal(n, "printer")
    x["shatter"] = True
    return x


def sh_buff(a, h):
    x = buff(a, h, "others")
    x["shatter"] = True
    return x


def sh_armor(n):
    x = armor(n)
    x["shatter"] = True
    return x


def sh_summon(n=1):
    x = summon(n)
    x["shatter"] = True
    return x



# ------------------------------------------------------------- triggers
# A creature can also carry abilities that fire on moments other than arriving
# or being destroyed. `on(when, effect...)` wraps effects with their moment;
# the effects aim at things that need no choice (itself, a random enemy...).
TRIGGERS = {
    "attack": "On Attack", "hurt": "On Hurt", "kill": "On Kill", "turn_start": "Turn Start", "turn_end": "Turn End",
    "ally_print": "On Ally Print", "foe_print": "On Foe Print", "tool": "On Tool",
    "ally_shatter": "On Ally Shatter", "foe_shatter": "On Foe Shatter",
}


def on(when, *parts):
    assert when in TRIGGERS, when
    out = []
    for p in parts:
        q = dict(p)
        q["when"] = when
        out.append(q)
    return out if len(out) > 1 else out[0]


def a_dmg(n, to):
    s = {"random_enemy": "Deal %d damage to a random enemy print.", "enemy_printer": "Deal %d damage to the enemy Printer.",
         "enemy_prints": "Deal %d damage to all enemy prints.", "trigger": "Deal %d damage to it.",
         "target": "Deal %d damage to the print it hit."}[to]
    return _e("damage", s % n, "", n=n, to=to)


def a_buff(a, h, to, kw=()):
    sign = "+%d/+%d" % (a, h)
    s = {"self": "This gets %s." % sign, "trigger": "Give it %s." % sign,
         "friendly_prints": "Give your prints %s." % sign, "other_friendly_prints": "Give your other prints %s." % sign,
         "random_friendly": "Give a random friendly print %s." % sign}[to]
    return _e("buff", s, "", atk=a, hp=h, kw=list(kw), to=to)


def a_heal(n, to):
    s = {"self": "Repair this by %d.", "own_printer": "Repair your Printer by %d.", "friendly_prints": "Repair your prints by %d."}[to]
    return _e("heal", s % n, "", n=n, to=to)


def a_jam(to="random_enemy"):
    s = {"random_enemy": "Jam a random enemy print.", "enemy_prints": "Jam all enemy prints."}[to]
    return _e("jam", s, "", to=to)


def a_heat(n, to="random_enemy"):
    s = {"random_enemy": "Heat a random enemy print.", "enemy_prints": "Heat all enemy prints."}[to]
    return _e("heat", s, "", n=n, to=to)


def a_refresh():
    return _e("refresh", "This can attack again.", "", to="self")


def a_give(card, name):
    return _e("give", "Add a %s to your hand." % name, "", card=card)


def a_mill(n):
    return _e("mill", "Your opponent's deck loses %d card%s." % (n, "" if n == 1 else "s"), "", n=n)


def _join(parts):
    return " ".join(p["text"] for p in parts)


def ability(*parts):
    """For creatures: On Print effects, then triggered ones, then Shatter effects."""
    flat = []
    for p in parts:
        flat.extend(p if isinstance(p, list) else [p])
    on_ = [p for p in flat if not p.get("shatter") and not p.get("when")]
    sh = [p for p in flat if p.get("shatter")]
    tr = [p for p in flat if p.get("when")]
    out = {"text": "", "target": "", "on_print": [], "shatter": []}
    lines = []
    if on_:
        lines.append("On Print: " + _join(on_))
        out["on_print"] = [p["effect"] for p in on_]
        out["target"] = next((p["target"] for p in on_ if p["target"]), "")
    if tr:
        out["trig"] = []
        for when in TRIGGERS:
            group = [p for p in tr if p["when"] == when]
            if group:
                out["trig"].append({"when": when, "fx": [p["effect"] for p in group]})
                lines.append(TRIGGERS[when] + ": " + _join(group))
    if sh:
        lines.append("Shatter: " + _join(sh))
        out["shatter"] = [p["effect"] for p in sh]
    out["text"] = " ".join(lines)
    return out


def tool_effect(*parts):
    """For tools: plain effects and text."""
    return {"text": _join(parts), "target": next((p["target"] for p in parts if p["target"]), ""),
            "effects": [p["effect"] for p in parts]}
