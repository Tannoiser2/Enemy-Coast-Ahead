## Lavagna di pianificazione della campagna (Mission Planning Blotter): turni di pianificazione, punti risorsa,
## personale di terra, equipaggi e addestramento, aerei e Upkeep, modifiche, ricognizione, sicurezza e specialisti.
## Tutto disegnato qui, su carta, in italiano.
class_name Lavagna
extends Control

const W := 1050.0
const H := 1010.0
const CARTA := Color(0.80, 0.75, 0.63)
const CARTA2 := Color(0.86, 0.82, 0.72)
const INCH := Color(0.16, 0.13, 0.09)
const INCH2 := Color(0.38, 0.32, 0.24)
const ROSSO := Color(0.62, 0.12, 0.1)
const VERDE := Color(0.16, 0.38, 0.2)
const BLU := Color(0.13, 0.27, 0.42)

var p: PartitaCampagna
var fonts := {}
var scala := 1.0
var origine := Vector2.ZERO
var tex := {}

func imposta(partita: PartitaCampagna, f: Dictionary) -> void:
	p = partita
	fonts = f
	queue_redraw()

func _tex(nome: String) -> Texture2D:
	if not tex.has(nome):
		var path := "res://assets/" + nome
		tex[nome] = load(path) if ResourceLoader.exists(path) else null
	return tex[nome]

func _t(f: String, testo: String, pos: Vector2, sz: int, col := INCH, w := -1.0, al := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(fonts[f], pos, testo, al, w, sz, col)

func _riquadro(r: Rect2, titolo: String) -> void:
	draw_rect(r, CARTA2)
	draw_rect(r, INCH2, false, 1.5)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 26)), Color(0.28, 0.24, 0.18))
	_t("titoli", titolo, r.position + Vector2(10, 19), 16, Color(0.95, 0.9, 0.8))

func _draw() -> void:
	if p == null or not p.s.get("campagna", false):
		return
	scala = minf(size.x / W, size.y / H)
	origine = (size - Vector2(W, H) * scala) * 0.5
	draw_set_transform(origine, 0.0, Vector2(scala, scala))
	draw_rect(Rect2(0, 0, W, H), CARTA)
	for i in 40:
		draw_line(Vector2(0, 30 + i * 26), Vector2(W, 30 + i * 26), Color(0.7, 0.64, 0.52, 0.35), 1.0)
	draw_rect(Rect2(4, 4, W - 8, H - 8), INCH2, false, 2.0)
	_testata(Rect2(12, 12, W - 24, 118))
	_squadre(Rect2(12, 140, 470, 300))
	_equipaggi(Rect2(492, 140, 546, 190))
	_modifiche(Rect2(492, 340, 546, 100))
	_aerei(Rect2(12, 450, 1026, 130))
	_ricognizione(Rect2(12, 590, 640, 410))
	_sicurezza(Rect2(662, 590, 376, 200))
	_specialisti(Rect2(662, 800, 376, 200))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _testata(r: Rect2) -> void:
	_t("titoli", "LAVAGNA DI PIANIFICAZIONE", r.position + Vector2(4, 30), 25)
	_t("serif", "617° Squadron, RAF Scampton · Operazione Chastise", r.position + Vector2(6, 56), 19, INCH2)
	var piano: int = int(p.s["piano"])
	var x0 := 520.0
	for t in range(1, 5):
		var c := Rect2(x0 + (t - 1) * 124, r.position.y, 118, 66)
		var att := t == piano
		draw_rect(c, Color(0.95, 0.85, 0.55) if att else (Color(0.7, 0.65, 0.54) if t < piano else CARTA2))
		draw_rect(c, ROSSO if att else INCH2, false, 3.0 if att else 1.0)
		_t("titoli", "TURNO %d" % t, c.position + Vector2(0, 22), 16, INCH, c.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		var luna: bool = t % 2 == 1
		var cc := c.position + Vector2(20, 46)
		if luna:
			draw_circle(cc, 10, Color(0.98, 0.95, 0.8))
			draw_arc(cc, 10, 0, TAU, 24, INCH2, 1.0)
		else:
			draw_circle(cc, 10, Color(0.15, 0.15, 0.2))
		_t("testo", ["", "mar.-apr.", "aprile", "maggio", "maggio"][t], c.position + Vector2(36, 44), 13, INCH2)
		_t("testo", "luna" if luna else "senza luna", c.position + Vector2(36, 59), 13, INCH2)
	_t("titoli", "PUNTI RISORSA", Vector2(x0, r.position.y + 92), 16, INCH2)
	_t("macchina", "%d RP" % int(p.s["rp"]), Vector2(x0 + 150, r.position.y + 96), 30, ROSSO)
	_t("testo", "richieste di RP: %d · addestr. extra: %d" % [int(p.s["richieste"]), int(p.s["giri_extra"])], Vector2(x0 + 260, r.position.y + 92), 14, INCH2)
	_t("testo", "Fase: " + _fase(), r.position + Vector2(6, 86), 16, INCH)
	if p.s["fase"] == "f_sortita":
		var rr := Dati.rischio(int(p.s["rischio"]))
		_t("testo", "Rischio per la sicurezza: %d (%s)" % [int(p.s["rischio"]), rr[1]], r.position + Vector2(6, 106), 15, ROSSO)

func _fase() -> String:
	return {"p_req": "requisizioni", "p_sic": "sicurezza", "p_add": "addestramento", "p_mod": "modifiche", "p_rec": "ricognizione",
		"p_lancio": "decidere il lancio", "f_aerei": "controllo degli aerei", "f_ordigni": "controllo degli Upkeep", "f_equip": "controllo degli equipaggi",
		"f_brief": "briefing", "f_sortita": "sortita e onde"}.get(p.s["fase"], "raid in corso")

func _squadre(r: Rect2) -> void:
	_riquadro(r, "PERSONALE DI TERRA")
	var i := 0
	for q in Dati.SQUADRE:
		var c := Rect2(r.position + Vector2(8 + (i % 2) * 229, 34 + (i / 2) * 88), Vector2(223, 82))
		var mia := p.squadra(q["id"])
		var presente := not mia.is_empty()
		draw_rect(c, Color(0.93, 0.9, 0.82) if presente else Color(0.74, 0.7, 0.6))
		draw_rect(c, INCH2, false, 1.0)
		_t("grassetto", q["nome"], c.position + Vector2(8, 19), 15, INCH if presente else INCH2)
		if not presente:
			_t("testo", "da requisire: %d RP" % int(q["costo"]), c.position + Vector2(8, 40), 14, INCH2)
			_t("testo", "maneggio %d · erk %d · sortita %d" % q["fresco"], c.position + Vector2(8, 60), 13, INCH2)
		else:
			var stanca: bool = mia.get("stanca", false)
			var v: Array = q["stanco"] if stanca else q["fresco"]
			_t("testo", "maneggio %d · erk %d · sortita %d" % v, c.position + Vector2(8, 40), 14, INCH)
			_t("grassetto", "affaticata" if stanca else "fresca", c.position + Vector2(8, 60), 13, ROSSO if stanca else VERDE)
			var ded: String = mia.get("dedicata", "")
			_t("testo", ("a: " + p._min(PartitaCampagna.BOX.get(ded, ded))) if ded != "" else "libera", c.position + Vector2(90, 60), 13, BLU, 128)
		i += 1

func _equipaggi(r: Rect2) -> void:
	_riquadro(r, "EQUIPAGGI E ADDESTRAMENTO")
	var col := [130.0, 210.0, 300.0, 400.0, 480.0]
	var y := r.position.y + 50
	var tit := ["equipaggi", "navigazione", "quota e vel.", "puntamento", ""]
	for k in 4:
		_t("grassetto", tit[k], Vector2(r.position.x + col[k] - 30, y), 13, INCH2, 100, HORIZONTAL_ALIGNMENT_CENTER)
	var tot_q := 0
	for e in ["recluta", "esperto", "veterano"]:
		y += 30
		_t("grassetto", PartitaCampagna.PLURALE[e].capitalize(), Vector2(r.position.x + 10, y), 16)
		var n: int = int(p.s["equipaggi"][e])
		_t("macchina", str(n), Vector2(r.position.x + col[0] - 30, y), 20, INCH, 100, HORIZONTAL_ALIGNMENT_CENTER)
		var k := 1
		for c in ["nav", "quota", "bomba"]:
			var v: int = int(p.s["addestramento"][e][c])
			if c == "quota":
				tot_q += v
			_t("macchina", str(v), Vector2(r.position.x + col[k] - 30, y), 20, INCH if n > 0 else INCH2, 100, HORIZONTAL_ALIGNMENT_CENTER)
			k += 1
		if p.s["riposati"][e]:
			_t("testo", "riposati", Vector2(r.position.x + col[4] - 10, y), 13, VERDE)
	y += 32
	var w := "Bonus Wallis: OTTENUTO" if p.s.get("bonus_wallis", false) and not p.s["quarantena"] else "Bonus Wallis: quota e velocità %d su 12" % tot_q
	_t("testo", w, Vector2(r.position.x + 10, y), 14, VERDE if p.s.get("bonus_wallis", false) else INCH2)

func _modifiche(r: Rect2) -> void:
	_riquadro(r, "MODIFICHE AI LANCASTER")
	var voci := [["Radio VHF", p.s["vhf"], "un 6"], ["Luci Aldis (altimetro)", p.s["aldis"], "%d/2 sei" % mini(int(p.s["sei"]["altimetro"]), 2)],
		["Mirino Dann (cabina)", p.s["dann"], "%d/2 sei" % mini(int(p.s["sei"]["cabina"]), 2)]]
	var i := 0
	for v in voci:
		var c := Rect2(r.position + Vector2(8 + i * 178, 34), Vector2(172, 58))
		draw_rect(c, Color(0.8, 0.9, 0.78) if v[1] else Color(0.93, 0.9, 0.82))
		draw_rect(c, VERDE if v[1] else INCH2, false, 2.0 if v[1] else 1.0)
		_t("grassetto", v[0], c.position + Vector2(8, 20), 14, INCH, 160)
		_t("testo", "installata" if v[1] else "in lavorazione: " + v[2], c.position + Vector2(8, 44), 13, VERDE if v[1] else INCH2, 160)
		i += 1

func _aerei(r: Rect2) -> void:
	_riquadro(r, "AEREI E UPKEEP")
	var integri: int = p.s["aerei"].filter(func(a): return int(a["danni"]) == 0).size()
	_t("testo", "Lancaster: %d (%d integri, %d danneggiati) · Upkeep in deposito: %d · ancora da requisire: %d Lancaster" % [p.s["aerei"].size(), integri, p.s["aerei"].size() - integri, p.s["upkeep_scorta"].size(), p.s["aerei_liberi"].size()], r.position + Vector2(10, 46), 15)
	var x := r.position.x + 10
	for a in p.s["aerei"]:
		var t := _tex("pedine/%s_f.png" % a["id"])
		var c := Rect2(x, r.position.y + 58, 50, 50)
		if t:
			draw_texture_rect(t, c, false, Color(1, 1, 1) if int(a["danni"]) == 0 and not a.get("fermo", false) else Color(0.6, 0.45, 0.4))
		if int(a["danni"]) > 0:
			draw_rect(Rect2(c.position + Vector2(0, 40), Vector2(50, 10)), ROSSO)
		_t("testo", a["id"].substr(3), c.position + Vector2(0, 66), 12, INCH2, 50, HORIZONTAL_ALIGNMENT_CENTER)
		x += 53

func _ricognizione(r: Rect2) -> void:
	_riquadro(r, "RICOGNIZIONE FOTOGRAFICA")
	var y := r.position.y + 50
	var i := 0
	for z in ["costa_olandese", "ruhr", "weser"]:
		var c := Rect2(r.position + Vector2(10 + i * 208, 34), Vector2(200, 46))
		draw_rect(c, Color(0.93, 0.9, 0.82))
		draw_rect(c, INCH2, false, 1.0)
		_t("grassetto", Dati.NOME_ZONA[z], c.position + Vector2(8, 18), 14)
		var lv: int = int(p.s["recon_zone"][z])
		for k in 4:
			var b := Rect2(c.position + Vector2(8 + k * 26, 24), Vector2(22, 18))
			draw_rect(b, ROSSO if k == lv else Color(0.82, 0.78, 0.68))
			_t("grassetto", str(k), b.position + Vector2(0, 14), 12, Color.WHITE if k == lv else INCH2, 22, HORIZONTAL_ALIGNMENT_CENTER)
		i += 1
	y = r.position.y + 106
	var col := [10.0, 120.0, 160.0, 250.0, 330.0, 410.0, 490.0]
	var tit := ["diga", "rv", "ricognizione", "contraerea", "fotoel.", "palloni", "acqua"]
	for k in tit.size():
		_t("grassetto", tit[k], Vector2(r.position.x + col[k], y), 13, INCH2)
	for d in ["mohne", "eder", "sorpe", "ennepe", "lister", "diemel", "bever", "henne"]:
		y += 34
		var x: Dictionary = p.s["dighe"][d]
		draw_line(Vector2(r.position.x + 6, y + 9), Vector2(r.end.x - 6, y + 9), Color(0.6, 0.55, 0.45, 0.6), 1.0)
		_t("grassetto", Dati.DIGHE[d]["nome"], Vector2(r.position.x + col[0], y), 16)
		_t("macchina", str(int(Dati.DIGHE[d]["rv"])), Vector2(r.position.x + col[1], y), 17)
		var rec: int = int(x["recon"])
		for k in 4:
			var b := Rect2(Vector2(r.position.x + col[2] + k * 19, y - 14), Vector2(17, 18))
			var pieno := k < rec
			draw_rect(b, BLU if pieno else Color(0.86, 0.82, 0.72))
			draw_rect(b, INCH2, false, 1.0)
			var ic: String = Dati.ICONE[d][k + 1]
			var ci := Color.WHITE if pieno else INCH
			if ic == "o":
				draw_arc(b.get_center(), 4.5, 0, TAU, 14, ci, 1.6)
			elif ic == "r":
				draw_colored_polygon(PackedVector2Array([b.get_center() + Vector2(0, -6), b.get_center() + Vector2(5, 0), b.get_center() + Vector2(0, 6), b.get_center() + Vector2(-5, 0)]), ci)
		if x.get("vista", false):
			_t("macchina", str(int(x["flak"])), Vector2(r.position.x + col[3] + 20, y), 17)
			_t("macchina", str(int(x["fari"])), Vector2(r.position.x + col[4] + 14, y), 17)
			_t("macchina", str(int(x["palloni"])), Vector2(r.position.x + col[5] + 14, y), 17)
			_t("testo", Dati.ACQUA[int(x["acqua"])], Vector2(r.position.x + col[6], y), 14)
		else:
			_t("testo", "mai fotografata", Vector2(r.position.x + col[3], y), 14, INCH2)

func _sicurezza(r: Rect2) -> void:
	_riquadro(r, "SICUREZZA")
	var y := r.position.y + 50
	if p.s["sicurezza"].is_empty():
		_t("testo", "Nessuna misura di sicurezza in gioco.", Vector2(r.position.x + 10, y), 14, INCH2)
		y += 22
	for m in p.s["sicurezza"]:
		var nome: String = PartitaCampagna.GIRATI[m["id"]][0] if m["girato"] else PartitaCampagna.SEGNALINI_SIC[m["id"]][0]
		_t("grassetto", nome, Vector2(r.position.x + 10, y), 15, BLU)
		_t("testo", "turno %d%s" % [int(m["turno"]), ", girato" if m["girato"] else ""], Vector2(r.position.x + 250, y), 13, INCH2)
		y += 24
	if p.s["quarantena"]:
		_t("grassetto", "Scampton in quarantena", Vector2(r.position.x + 10, y), 15, ROSSO)
		y += 24
	if p.s["spia"]:
		_t("grassetto", "Una spia si aggira per la base!", Vector2(r.position.x + 10, y), 15, ROSSO)
		y += 24
	_t("testo", "Il rischio si calcola al briefing.", Vector2(r.position.x + 10, r.end.y - 12), 13, INCH2)

func _specialisti(r: Rect2) -> void:
	_riquadro(r, "SPECIALISTI")
	var y := r.position.y + 50
	var col := 0
	for e in p.s["elite"]:
		var t := ""
		match e:
			"spia": continue
			"jinx": t = "Il cane di Gibson (mascotte)"
			"armiere": t = "Armiere esperto"
			_: t = "%s, %s" % [Dati.SPECIALISTI[e]["nome"], Dati.RUOLI[Dati.SPECIALISTI[e]["ruolo"]][0].to_lower()]
		_t("testo", t, Vector2(r.position.x + 10 + col * 182, y), 14, INCH, 176)
		col += 1
		if col == 2:
			col = 0
			y += 22
	if p.s["elite"].filter(func(x): return x != "spia").is_empty():
		_t("testo", "Ogni sei equipaggi e con i buoni addestramenti arriva uno specialista.", Vector2(r.position.x + 10, y), 13, INCH2, 356)
