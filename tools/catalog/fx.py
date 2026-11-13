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


def _join(parts):
    return " ".join(p["text"] for p in parts)


def ability(*parts):
    """For creatures: On Print effects, then Shatter effects."""
    on = [p for p in parts if not p.get("shatter")]
    sh = [p for p in parts if p.get("shatter")]
    out = {"text": "", "target": "", "on_print": [], "shatter": []}
    lines = []
    if on:
        lines.append("On Print: " + _join(on))
        out["on_print"] = [p["effect"] for p in on]
        out["target"] = next((p["target"] for p in on if p["target"]), "")
    if sh:
        lines.append("Shatter: " + _join(sh))
        out["shatter"] = [p["effect"] for p in sh]
    out["text"] = " ".join(lines)
    return out


def tool_effect(*parts):
    """For tools: plain effects and text."""
    return {"text": _join(parts), "target": next((p["target"] for p in parts if p["target"]), ""),
            "effects": [p["effect"] for p in parts]}
