## Lavagna di pianificazione della campagna sull'immagine originale (tradotta), in due colonne affiancate:
## segnalini sul turno di pianificazione, sulla traccia dei punti risorsa, sulle tracce dell'addestramento,
## squadre di terra nelle caselle a cui sono dedicate, stato delle modifiche e della sicurezza.
## Le coordinate dei segnalini sono quelle della tavola originale (5100x3300), convertite con B().
class_name Lavagna
extends Tavola

const K := 0.7
const TAGLIO := 1480.0          # y della tavola dove comincia la seconda colonna
const COL2 := 1285.0            # larghezza di una colonna (tavola)

const TURNO := [Vector2(748, 318), Vector2(884, 318), Vector2(1019, 318), Vector2(1154, 318)]
const BOX := {
	"requisizioni": Rect2(1076, 570, 155, 153), "addestramento": Rect2(1080, 1050, 151, 151),
	"riparazioni": Rect2(300, 2217, 149, 150), "radio": Rect2(533, 2163, 171, 218), "altimetro": Rect2(780, 2163, 171, 218),
	"cabina": Rect2(1023, 2163, 170, 218), "aerei": Rect2(1071, 2590, 146, 151), "ordigni": Rect2(1071, 2759, 146, 147),
}
const SEZIONI := {
	"p_req": Rect2(100, 548, 1140, 334), "p_sic": Rect2(100, 884, 1140, 138), "p_add": Rect2(100, 1030, 1140, 1016),
	"p_mod": Rect2(100, 2056, 1140, 340), "p_mod_tiri": Rect2(100, 2056, 1140, 340), "p_rec": Rect2(100, 2404, 1140, 98), "p_lancio": Rect2(100, 2508, 1140, 70),
	"f_aerei": Rect2(100, 2578, 1140, 176), "f_ordigni": Rect2(100, 2754, 1140, 168), "f_equip": Rect2(100, 2922, 1140, 166),
	"f_brief": Rect2(100, 3088, 1140, 56), "f_sortita": Rect2(100, 3144, 1140, 74),
}
const SICUREZZA := {"tirpitz": Rect2(425, 908, 92, 92), "polizia": Rect2(592, 908, 94, 92), "57sqn": Rect2(758, 908, 94, 92)}
const EQUIP := {"recluta": Rect2(473, 793, 70, 66), "esperto": Rect2(561, 793, 72, 66), "veterano": Rect2(651, 793, 72, 66)}
const COLORE_EQUIP := {"recluta": Color(0.36, 0.55, 0.3), "esperto": Color(0.3, 0.45, 0.62), "veterano": Color(0.62, 0.26, 0.2)}

var p: PartitaCampagna

func _init() -> void:
	W = COL2 * 2 * K
	H = 1810.0 * K

func imposta(partita: PartitaCampagna, f: Dictionary) -> void:
	p = partita
	fonts = f
	queue_redraw()

static func B(v: Vector2) -> Vector2:
	if v.y < TAGLIO:
		return (v - Vector2(60, 20)) * K
	return (v - Vector2(60, 20) - Vector2(0, TAGLIO - 20) + Vector2(COL2, 0)) * K

static func BR(r: Rect2) -> Rect2:
	return Rect2(B(r.position), r.size * K)

## Parte della lavagna da inquadrare nella fase corrente.
func vista_fase() -> Rect2:
	var f: String = p.s["fase"]
	if f in ["p_req", "p_sic"]:
		return Rect2(0, 0, COL2 * K, 1460 * K)
	return Rect2(COL2 * K, 0, COL2 * K, 1810 * K)

func _draw() -> void:
	if p == null or not p.s.get("campagna", false):
		return
	inizia()
	draw_rect(Rect2(0, 0, W, H), Color(0.09, 0.085, 0.08))
	draw_texture_rect(_tex("mappe/lavagna.jpg"), Rect2(0, 0, W, H), false)
	# la colonna non inquadrata resta in penombra
	var v := vista_fase()
	var altra := Rect2(0, 0, COL2 * K, H) if v.position.x > 0 else Rect2(COL2 * K, 0, COL2 * K, H)
	draw_rect(altra, Color(0, 0, 0, 0.45))
	_sezione()
	_turno_e_rp()
	_squadre()
	_requisiti()
	_sicurezza()
	_addestramento()
	_modifiche()
	finisci()

func _sezione() -> void:
	var f: String = p.s["fase"]
	if not SEZIONI.has(f):
		return
	var r := BR(SEZIONI[f])
	var a := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0)
	draw_rect(r.grow(2), Color(1, 0.7, 0.2, a), false, 5.0)
	queue_redraw()

func _turno_e_rp() -> void:
	var beige := Color(0.86, 0.81, 0.68)
	var inch := Color(0.2, 0.15, 0.1)
	var t: int = clampi(int(p.s["piano"]), 1, 4)
	segnalino(B(TURNO[t - 1]), 54, ["TURNO", "PIANIF."], beige, inch)
	# traccia 0-9: RP (unità e decine), richieste, addestramenti extra, rischio
	var rp: int = int(p.s["rp"])
	var su := []
	su.append([rp % 10, ["RP"], Color(0.95, 0.85, 0.45), inch])
	su.append([(rp / 10) % 10, ["RP x10"] if rp < 100 else ["RP x10", "+100"], Color(0.95, 0.7, 0.3), inch])
	if int(p.s["richieste"]) > 0:
		su.append([mini(int(p.s["richieste"]), 9), ["RICHIESTE"], Color(0.8, 0.8, 0.82), inch])
	if int(p.s["giri_extra"]) > 0:
		su.append([mini(int(p.s["giri_extra"]), 9), ["EXTRA"], Color(0.7, 0.85, 0.7), inch])
	if p.s["fase"] == "f_sortita" or p.s["fase"].begins_with("v_") or p.s["fase"] == "concluso":
		var rv: int = int(p.s["rischio"])
		su.append([rv % 10, ["RISCHIO"] if rv < 10 else ["RISCHIO", "+10"], Color(0.82, 0.22, 0.16), Color.WHITE])
	var per := {}
	for m in su:
		var k: int = m[0]
		var n: int = per.get(k, 0)
		per[k] = n + 1
		var c := B(Vector2(168 + 101.2 * k, 448 + n * 34))
		segnalino(c + Vector2((n % 2) * 8, 0), 52, m[1], m[2], m[3])

func _squadra(q: Dictionary, c: Vector2, lato: float) -> void:
	var d := p.dati_squadra(q["id"])
	var stanca: bool = q.get("stanca", false)
	var v: Array = d["stanco"] if stanca else d["fresco"]
	var nome: String = String(d["nome"]).replace("Squadra ", "")
	segnalino(c, lato, [nome, "%d·%d·%d" % v], Color(0.62, 0.55, 0.45) if stanca else Color(0.9, 0.84, 0.7), Color(0.22, 0.14, 0.08))

func _squadre() -> void:
	var per_box := {}
	var libere := []
	for q in p.s["squadre"]:
		var b: String = q.get("dedicata", "")
		if b != "" and BOX.has(b):
			per_box[b] = per_box.get(b, []) + [q]
		else:
			libere.append(q)
	for b in per_box:
		var r := BR(BOX[b])
		var qs: Array = per_box[b]
		for i in qs.size():
			var lato := 50.0
			var c := r.position + Vector2(r.size.x - lato * 0.5 - 4 - (i % 2) * (lato + 4), lato * 0.5 + 4 + (i / 2) * (lato + 4))
			_squadra(qs[i], c, lato)
	# squadre libere sopra le illustrazioni delle squadre di terra
	var base := BR(Rect2(109, 767, 314, 92))
	for i in libere.size():
		var lato := 50.0
		_squadra(libere[i], base.position + Vector2(lato * 0.5 + i * (lato + 3), base.size.y * 0.5), lato)

func _badge(c: Vector2, t: String, col := Color(0.95, 0.85, 0.45)) -> void:
	var f: Font = fonts["grassetto"]
	var sz := 22
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 12
	var r := Rect2(c - Vector2(w * 0.5, 14), Vector2(w, 28))
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.5))
	draw_rect(r, col)
	draw_rect(r, Color(0.2, 0.15, 0.1), false, 1.5)
	draw_string(f, r.position + Vector2(0, 21), t, HORIZONTAL_ALIGNMENT_CENTER, w, sz, Color(0.15, 0.1, 0.06))

func _requisiti() -> void:
	for e in EQUIP:
		var r := BR(EQUIP[e])
		_badge(r.get_center() + Vector2(0, -r.size.y * 0.55), "%d" % int(p.s["equipaggi"][e]))
		if p.s["riposati"][e]:
			_badge(r.get_center() + Vector2(0, r.size.y * 0.75), "riposo", Color(0.7, 0.85, 0.7))
	var integri: int = p.s["aerei"].filter(func(a): return int(a["danni"]) == 0).size()
	var danneggiati: int = p.s["aerei"].size() - integri
	var rl := BR(Rect2(797, 770, 96, 89))
	_badge(rl.get_center() + Vector2(0, -rl.size.y * 0.62), "%d" % integri + (" + %d danneggiati" % danneggiati if danneggiati > 0 else ""))
	var ru := BR(Rect2(949, 799, 67, 60))
	_badge(ru.get_center() + Vector2(0, -ru.size.y * 0.75), "%d" % p.s["upkeep_scorta"].size())

func _sicurezza() -> void:
	for m in p.s["sicurezza"]:
		var r := BR(SICUREZZA[m["id"]])
		var nome: String = PartitaCampagna.GIRATI[m["id"]][0] if m["girato"] else "IN GIOCO"
		var col := Color(0.82, 0.22, 0.16) if m["girato"] else Color(0.3, 0.55, 0.3)
		var f: Font = fonts["grassetto"]
		var sz := 15
		while sz > 8 and f.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > r.size.x + 20:
			sz -= 1
		var q := Rect2(r.position + Vector2(-10, r.size.y * 0.38), Vector2(r.size.x + 20, 22))
		draw_rect(q, col)
		draw_string(f, q.position + Vector2(0, 16), nome, HORIZONTAL_ALIGNMENT_CENTER, q.size.x, sz, Color.WHITE)
	if p.s["spia"]:
		segnalino(B(Vector2(1000, 950)), 62, ["SPIA"], Color(0.15, 0.15, 0.16), Color(0.95, 0.3, 0.25), -8)
	if p.s["quarantena"]:
		segnalino(B(Vector2(1180, 975)), 62, ["QUARAN-", "TENA"], Color(0.82, 0.22, 0.16), Color.WHITE, 6)

func _addestramento() -> void:
	var y := {"nav": 1590.0, "quota": 1792.0, "bomba": 1987.0}
	var mx := {"nav": 7, "quota": 7, "bomba": 8}
	var ordine := ["recluta", "esperto", "veterano"]
	for c in y:
		var per := {}
		for i in ordine.size():
			var e: String = ordine[i]
			var lv: int = clampi(int(p.s["addestramento"][e][c]), 0, mx[c])
			var n: int = per.get(lv, 0)
			per[lv] = n + 1
			var pos := B(Vector2(213 + 101.3 * lv, y[c] - 22 + n * 24))
			var nome: String = {"recluta": "RECL.", "esperto": "ESP.", "veterano": "VET."}[e]
			var alpha := 1.0 if int(p.s["equipaggi"][e]) > 0 else 0.45
			var col: Color = COLORE_EQUIP[e]
			col.a = alpha
			segnalino(pos + Vector2((n - 1) * 6, 0), 40, [nome], col, Color(1, 1, 1, alpha))
	var wr := BR(Rect2(991, 1513, 233, 364))
	if p.s.get("bonus_wallis", false) and not p.s["quarantena"]:
		segnalino(wr.get_center() + Vector2(0, 60), 86, ["BONUS", "OTTENUTO"], Color(0.3, 0.55, 0.3), Color.WHITE, -10)
	else:
		var tot := 0
		for e in ordine:
			tot += int(p.s["addestramento"][e]["quota"])
		_badge(wr.position + Vector2(wr.size.x * 0.5, wr.size.y + 18), "quota e velocità: %d su 12" % tot, Color(0.9, 0.84, 0.7))

func _modifiche() -> void:
	var stati := {"radio": [p.s["vhf"], "un 6"], "altimetro": [p.s["aldis"], "%d di 2 sei" % mini(int(p.s["sei"]["altimetro"]), 2)],
		"cabina": [p.s["dann"], "%d di 2 sei" % mini(int(p.s["sei"]["cabina"]), 2)]}
	for b in stati:
		var r := BR(BOX[b])
		if stati[b][0]:
			segnalino(r.get_center() + Vector2(0, 10), 70, ["FATTA"], Color(0.3, 0.55, 0.3), Color.WHITE, -12)
		else:
			_badge(r.position + Vector2(r.size.x * 0.5, r.size.y + 14), stati[b][1], Color(0.9, 0.84, 0.7))
	var danneggiati: int = p.s["aerei"].filter(func(a): return int(a["danni"]) > 0).size()
	if danneggiati > 0:
		var rr := BR(BOX["riparazioni"])
		_badge(rr.position + Vector2(rr.size.x * 0.5, rr.size.y + 14), "%d da riparare" % danneggiati, Color(0.95, 0.75, 0.65))
