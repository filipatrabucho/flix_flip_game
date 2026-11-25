extends RefCounted
## Tiny translation layer. Portuguese text is the key; English lives in i18n_en.gd.

const EN = preload("res://scripts/i18n_en.gd")

static var lang := "pt"


static func t(s: String) -> String:
	if lang == "pt" or s == "":
		return s
	var d: Dictionary = EN.STRINGS
	return str(d.get(s, s))


## Picks the right field of a {"pt": ..., "en": ...} dictionary.
static func pick(d: Dictionary) -> String:
	return str(d.get(lang, d.get("pt", "")))
