## Mappa di volo (scenari 6-9): le sei zone dall'Inghilterra al Weser, con i riquadri dei dispersi e del rientro,
## la ricognizione delle zone ostili, le onde e i Lancaster isolati; a destra i riquadri di acquisizione delle dighe
## e la traccia dei turni di volo. Tutto disegnato qui, in italiano.
class_name MappaVolo
extends Control

signal pedina_cliccata(id: String)

const W := 1050.0
const H := 1010.0
const ZONE_ALTE := {"weser": 175.0, "ruhr": 175.0, "costa_olandese": 165.0, "mare": 150.0, "costa_inglese": 145.0, "inghilterra": 160.0}
const COLORI := {"weser": Color(0.17, 0.53, 0.62), "ruhr": Color(0.62, 0.84, 0.89), "costa_olandese": Color(0.62, 0.84, 0.89),
	"mare": Color(0.93, 0.93, 0.66), "costa_inglese": Color(0.93, 0.93, 0.66), "inghilterra": Color(0.75, 0.75, 0.72)}

var p: PartitaVolo
var fonts := {}
var tex_sfondo: Texture2D
var tex := {}
var scala := 1.0
var origine := Vector2.ZERO
var aree := []   # [Rect2 in coordinate mappa, id del Lancaster]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "
	tex_sfondo = load("res://assets/mappe/volo.jpg")

func imposta(partita: PartitaVolo, f: Dictionary) -> void:
	p = partita
	fonts = f
	queue_redraw()

func _tex(nome: String) -> Texture2D:
	if not tex.has(nome):
		var path := "res://assets/" + nome
		tex[nome] = load(path) if ResourceLoader.exists(path) else null
	return tex[nome]

func _zona_rect(z: String) -> Rect2:
	var y := 8.0
	for k in ["weser", "ruhr", "costa_olandese", "mare", "costa_inglese", "inghilterra"]:
		var h: float = ZONE_ALTE[k]
		if k == z:
			return Rect2(8, y, 600, h - 6)
		y += h
	return Rect2()

func _draw() -> void:
	if p == null:
		return
	scala = minf(size.x / W, size.y / H)
	origine = (size - Vector2(W, H) * scala) * 0.5
	draw_set_transform(origine, 0.0, Vector2(scala, scala))
	aree.clear()
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.07, 0.085))
	draw_texture_rect(tex_sfondo, Rect2(8, 8, 600, H - 16), false)
	for z in Dati.ZONE:
		_zona(z)
	_acquisizione(Rect2(624, 8, 418, 640))
	_traccia_volo(Rect2(624, 660, 418, 342))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _t(f: String, testo: String, pos: Vector2, sz: int, col: Color, w := -1.0, al := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(fonts[f], pos + Vector2(1, 1), testo, al, w, sz, Color(0, 0, 0, 0.6 * col.a))
	draw_string(fonts[f], pos, testo, al, w, sz, col)

func _zona(z: String) -> void:
	var r := _zona_rect(z)
	var ostile: bool = Dati.PERICOLI_ZONA[z][2]
	draw_rect(r, Color(0.1, 0.11, 0.13, 0.35))
	draw_rect(r, Color(0.55, 0.57, 0.6, 0.7), false, 1.5)
	# linguetta colorata con il nome della zona
	var tab := Rect2(r.position, Vector2(34, r.size.y))
	draw_rect(tab, COLORI[z])
	var nome: String = Dati.NOME_ZONA[z]
	var f: Font = fonts["titoli"]
	var w := f.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	draw_set_transform(origine + (tab.position + Vector2(24, tab.size.y * 0.5 + w * 0.5)) * scala, -PI / 2, Vector2(scala, scala))
	draw_string(f, Vector2.ZERO, nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.08, 0.08, 0.1))
	draw_set_transform(origine, 0.0, Vector2(scala, scala))
	# pericoli della zona
	var info: Array = Dati.PERICOLI_ZONA[z]
	var tp := ""
	if int(info[0]) == 0:
		tp = "nessun pericolo"
	elif ostile:
		tp = "%d pericoli + 1 per onda o aereo + allerta" % int(info[0])
	else:
		tp = "%d %s (non evitabili)" % [int(info[0]), "pericolo" if int(info[0]) == 1 else "pericoli"]
	_t("testo", tp, r.position + Vector2(44, 20), 15, Color(0.85, 0.87, 0.9, 0.9))
	# ricognizione
	if ostile:
		var rec: int = int(p.s["recon_zone"].get(z, 0))
		var rr := Rect2(r.end.x - 190, r.position.y + 6, 182, 26)
		draw_rect(rr, Color(0.12, 0.12, 0.14, 0.9))
		for i in 4:
			var c := Rect2(rr.position + Vector2(84 + i * 24, 3), Vector2(20, 20))
			draw_rect(c, Color(0.95, 0.42, 0.27) if i == rec else Color(0.3, 0.31, 0.33))
			draw_string(fonts["grassetto"], c.position + Vector2(0, 16), str(i), HORIZONTAL_ALIGNMENT_CENTER, 20, 14, Color.WHITE)
		draw_string(fonts["testo"], rr.position + Vector2(6, 19), "ricognizione", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.86, 0.88))
	# riquadri dei dispersi e del rientro
	var x_box := r.end.x - 190
	var disp := Rect2(x_box, r.position.y + 38, 88, r.size.y - 46)
	var rtb := Rect2(x_box + 94, r.position.y + 38, 88, r.size.y - 46)
	if z != "inghilterra":
		draw_rect(disp, Color(0.25, 0.2, 0.2, 0.75))
		draw_rect(disp, Color(0.6, 0.45, 0.45), false, 1.5)
		draw_string(fonts["grassetto"], disp.position + Vector2(0, 16), "dispersi", HORIZONTAL_ALIGNMENT_CENTER, disp.size.x, 14, Color(0.95, 0.85, 0.85))
	else:
		draw_rect(disp, Color(0.22, 0.22, 0.2, 0.75))
		draw_rect(disp, Color(0.55, 0.55, 0.5), false, 1.5)
		draw_string(fonts["grassetto"], disp.position + Vector2(0, 16), "in attesa", HORIZONTAL_ALIGNMENT_CENTER, disp.size.x, 14, Color(0.92, 0.92, 0.88))
	draw_rect(rtb, Color(0.18, 0.24, 0.2, 0.75))
	draw_rect(rtb, Color(0.45, 0.6, 0.48), false, 1.5)
	draw_string(fonts["grassetto"], rtb.position + Vector2(0, 16), "rientro", HORIZONTAL_ALIGNMENT_CENTER, rtb.size.x, 14, Color(0.85, 0.95, 0.87))
	# contenuto
	var x := r.position.x + 44
	var y := r.position.y + 32
	var gs := p.gruppi().filter(func(g): return p.zona_gruppo(g) == z and p.capo_gruppo(g)["pos"] == "volo")
	for g in gs:
		var m := p.lanc_gruppo(g).filter(func(l): return l["pos"] == "volo")
		var larg := 12.0 + m.size() * 40.0
		if x + larg > x_box - 6:
			x = r.position.x + 44
			y += 62
		_gruppo(g, m, Rect2(x, y, larg, 58))
		x += larg + 8
	var nd := 0
	for l in p.s["lanc"]:
		if l["zona"] != z:
			continue
		if l["pos"] == "smarrito":
			_pedina(l, disp.position + Vector2(disp.size.x * 0.5, 44 + nd * 46), 40)
			nd += 1
	var nr := 0
	for l in p.s["lanc"]:
		if l["zona"] == z and l["pos"] == "rtb":
			var col := nr % 2
			_pedina(l, rtb.position + Vector2(24 + col * 42, 44 + (nr / 2) * 44), 38)
			nr += 1
	if z == "inghilterra":
		var na := 0
		for l in p.s["lanc"]:
			if l["pos"] == "attesa":
				_pedina(l, disp.position + Vector2(24 + (na % 2) * 42, 44 + (na / 2) * 40), 36)
				na += 1

func _gruppo(g: String, m: Array, r: Rect2) -> void:
	if g.begins_with("O:"):
		var o: Dictionary = p.s["onde"][g.substr(2)]
		var buona: bool = o["buona"]
		draw_rect(r, Color(0.76, 0.7, 0.58, 0.95) if buona else Color(0.2, 0.2, 0.22, 0.95))
		draw_rect(r, Color(0.35, 0.3, 0.2), false, 2.0)
		draw_string(fonts["serif"], r.position + Vector2(5, 14), o["nome"] + ("" if buona else " · scompaginata"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8, 14, Color(0.15, 0.12, 0.08) if buona else Color(0.95, 0.85, 0.6))
	for i in m.size():
		var l: Dictionary = m[i]
		_pedina(l, r.position + Vector2(26 + i * 40, 37), 34, g.begins_with("O:") and p.s["onde"][g.substr(2)]["capo"] == l["id"])

func _pedina(l: Dictionary, c: Vector2, lato: float, capo := false) -> void:
	var r := Rect2(c - Vector2(lato, lato) * 0.5, Vector2(lato, lato))
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.5))
	var t := _tex("pedine/%s_f.png" % l["id"])
	if t:
		draw_texture_rect(t, r, false)
	if p.danneggiato(l):
		draw_rect(Rect2(r.position + Vector2(0, lato - 9), Vector2(lato, 9)), Color(0.55, 0.05, 0.1, 0.9))
	if int(l["upkeep"]) >= 0:
		draw_rect(Rect2(r.position + Vector2(lato - 12, -4), Vector2(14, 9)), Color(0.86, 0.82, 0.72))
		draw_rect(Rect2(r.position + Vector2(lato - 10, -2), Vector2(10, 5)), Color(0.3, 0.3, 0.28))
	if capo:
		draw_rect(r.grow(2), Color(0.95, 0.75, 0.3), false, 2.0)
	var ng: int = l.get("guasti", []).size()
	if ng > 0:
		draw_circle(r.position + Vector2(5, 5), 8, Color(0.85, 0.2, 0.15))
		draw_string(fonts["grassetto"], r.position + Vector2(-3, 10), str(ng), HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color.WHITE)
	aree.append([r, l["id"]])

func _acquisizione(r: Rect2) -> void:
	draw_rect(r, Color(0.1, 0.11, 0.13, 0.95))
	draw_rect(r, Color(0.4, 0.42, 0.45), false, 1.5)
	_t("titoli", "LE DIGHE", r.position + Vector2(12, 28), 22, Color.WHITE)
	_t("testo", "bersaglio di riserva: %s" % Dati.DIGHE[p.s["riserva"]]["nome"], r.position + Vector2(140, 26), 15, Color(0.95, 0.8, 0.5))
	var y := r.position.y + 42
	for gruppo in [["Weser", ["eder", "diemel", "lister"]], ["Ruhr", ["mohne", "sorpe", "ennepe", "bever", "henne"]]]:
		_t("grassetto", "zona del %s" % gruppo[0] if gruppo[0] == "Weser" else "zona della %s" % gruppo[0], Vector2(r.position.x + 12, y + 14), 14, Color(0.6, 0.8, 0.85))
		y += 20
		for d in gruppo[1]:
			var b := Rect2(r.position.x + 8, y, r.size.x - 16, 62)
			var dd: Dictionary = p.s["dighe"][d]
			var rotta: bool = dd["breccia"]
			draw_rect(b, Color(0.5, 0.1, 0.1, 0.9) if rotta else Color(0.2, 0.21, 0.24))
			draw_rect(b, Color(0.45, 0.47, 0.5), false, 1.0)
			draw_string(fonts["titoli"], b.position + Vector2(8, 22), Dati.DIGHE[d]["nome"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
			var info := "ricogn. %d · danni %d/%d" % [int(dd["recon"]), p.danni_diga(d), p.capacita(d)]
			if int(dd["flak"]) > 0:
				info += " · contraerea %d" % int(dd["flak"])
			if rotta:
				info = "BRECCIA · " + info
			draw_string(fonts["testo"], b.position + Vector2(8, 44), info, HORIZONTAL_ALIGNMENT_LEFT, 230, 13, Color(0.85, 0.86, 0.88))
			# Lancaster in acquisizione o sulla mappa del bersaglio
			var k := 0
			for l in p.s["lanc"]:
				if l.get("diga", "") == d and (l["pos"] in PartitaVolo.POS_BERSAGLIO or l["pos"] in ["acquisizione", "in_arrivo"]):
					if k < 5:
						_pedina(l, b.position + Vector2(b.size.x - 22 - k * 36, 31), 32)
					k += 1
			y += 66
		y += 4

func _traccia_volo(r: Rect2) -> void:
	draw_rect(r, Color(0.1, 0.11, 0.13, 0.95))
	draw_rect(r, Color(0.4, 0.42, 0.45), false, 1.5)
	_t("titoli", "TURNI DI VOLO", r.position + Vector2(12, 28), 22, Color.WHITE)
	_t("grassetto", "allerta %d" % int(p.s["allerta"]), r.position + Vector2(r.size.x - 100, 26), 17, Color(1, 0.55, 0.45) if int(p.s["allerta"]) >= 3 else Color(0.85, 0.86, 0.88))
	var cw := (r.size.x - 20) / 5.0
	for t in range(1, 11):
		var i := t - 1
		var c := Rect2(r.position + Vector2(10 + (i % 5) * cw, 44 + (i / 5) * 140), Vector2(cw - 6, 130))
		var att: bool = t == int(p.s["turno_volo"])
		draw_rect(c, Color(0.3, 0.27, 0.18) if att else Color(0.17, 0.18, 0.2))
		draw_rect(c, Color(1, 0.78, 0.32) if att else Color(0.35, 0.36, 0.38), false, 2.0 if att else 1.0)
		draw_string(fonts["grassetto"], c.position + Vector2(0, 20), "Turno %d" % t if t < 10 else "Rientro", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 15, Color(0.9, 0.9, 0.9))
		draw_string(fonts["testo"], c.position + Vector2(0, 42), Dati.ORA_VOLO[t], HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 15, Color(0.7, 0.72, 0.75))
		var nota := ""
		if t in [6, 7, 8]:
			nota = "visibilità -2"
		elif t == 9:
			nota = "nebbia"
		if nota != "":
			draw_string(fonts["testo"], c.position + Vector2(0, 66), nota, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 13, Color(0.55, 0.75, 0.8))

# ------------------------------------------------------------------ interazione
func _id_sotto(pt: Vector2) -> String:
	var m := (pt - origine) / scala
	for a in aree:
		if (a[0] as Rect2).has_point(m):
			return a[1]
	return ""

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := _id_sotto(e.position)
		if id != "":
			pedina_cliccata.emit(id)

func _get_tooltip(at: Vector2) -> String:
	var id := _id_sotto(at)
	if id == "":
		return ""
	var l := p.lanc(id)
	var t := "%s · pilota %s\nEquipaggio %s (addestramento %d, navigazione %d)" % [l["id"], l["pilota"], Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower(), p.addestramento(l), p.nav(l)]
	if l["elite"] != "":
		var r: Array = Dati.RUOLI[p.ruolo(l)]
		t += "\nSpecialista: %s, %s." % [Dati.SPECIALISTI[l["elite"]]["nome"], r[0].to_lower()]
	t += "\nBersaglio: %s%s" % [Dati.DIGHE[l["primario"]]["nome"] if l.get("primario", "") != "" else "nessuno", (", poi %s" % Dati.DIGHE[l["secondario"]]["nome"]) if l.get("secondario", "") != "" else ""]
	t += "\nUpkeep a bordo: " + ("sì" if int(l["upkeep"]) >= 0 else "no")
	if p.danneggiato(l):
		t += "\nDanneggiato."
	for g in l.get("guasti", []):
		t += "\n- " + Dati.PERICOLI[g]
	return t
