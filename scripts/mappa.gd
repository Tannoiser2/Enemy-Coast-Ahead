## Mappa del bersaglio: sfondo originale (senza scritte inglesi), caselle e scritte italiane disegnate qui,
## pedine dei Lancaster che si spostano con un'animazione. Le coordinate sono quelle del ritaglio 1050x1010
## della mappa originale.
class_name MappaBersaglio
extends Control

signal pedina_cliccata(id: String)

const W := 1050.0
const H := 1010.0
const PED := 70.0

const LAYOUT := {
	"mohne": {
		"vicino": Rect2(700, 110, 325, 325), "lontano": Rect2(18, 700, 287, 295), "salita": Rect2(22, 80, 150, 145),
		"sgancio": [Vector2(278, 435), 160.0, 37.0], "rilasciati": [Vector2(140, 490), 95.0, 37.0], "angolo": 24.0,
		"zone": {"lontana": [Vector2(800, 790), 150.0], "vicina": [Vector2(632, 705), 140.0], "ravvicinata": [Vector2(450, 620), 140.0]},
		"gv": Vector2(958, 822), "gq": Vector2(905, 935),
		"titoli": {"lontana": Vector2(903, 612), "vicina": Vector2(680, 555), "ravvicinata": Vector2(498, 482)},
		"scritte": [["corsa", Vector2(1004, 525), 80.0], ["richiamo", Vector2(650, 482), -10.0], ["richiamo", Vector2(742, 492), -80.0],
			["richiamo", Vector2(836, 590), -80.0], ["risalita obbligatoria", Vector2(495, 222), 8.0], ["la diga", Vector2(232, 228), 0.0]],
		"nota": "Si usa anche per le dighe\nDiemel, Lister, Henne ed Ennepe.", "nota_pos": Vector2(500, 128),
	},
	"eder": {
		"vicino": Rect2(700, 65, 325, 320), "lontano": Rect2(18, 668, 287, 287), "salita": Rect2(212, 65, 150, 145),
		"michel": Rect2(8, 155, 197, 200),
		"sgancio": [Vector2(345, 402), 155.0, 45.0], "rilasciati": [Vector2(238, 490), 95.0, 45.0], "angolo": 30.0,
		"zone": {"lontana": [Vector2(822, 745), 150.0], "vicina": [Vector2(655, 640), 140.0], "ravvicinata": [Vector2(490, 535), 140.0]},
		"gv": Vector2(965, 815), "gq": Vector2(895, 925), "m_vicina": true,
		"titoli": {"lontana": Vector2(946, 604), "vicina": Vector2(733, 514), "ravvicinata": Vector2(563, 416)},
		"scritte": [["corsa", Vector2(1002, 468), 80.0], ["richiamo", Vector2(692, 437), 8.0], ["richiamo", Vector2(795, 480), -75.0],
			["richiamo", Vector2(897, 467), -88.0], ["risalita obbligatoria", Vector2(580, 106), -16.0], ["la diga", Vector2(446, 243), 0.0]],
	},
	"sorpe": {
		"vicino": Rect2(20, 610, 345, 335), "lontano": Rect2(755, 688, 267, 267), "salita": Rect2(755, 452, 150, 148),
		"sgancio": [Vector2(583, 510), 155.0, 45.0], "rilasciati": [Vector2(673, 628), 95.0, 45.0], "angolo": 32.0,
		"zone": {"lontana": [Vector2(236, 214), 124.0], "ravvicinata": [Vector2(416, 300), 118.0]},
		"gv": Vector2(112, 112), "gq": Vector2(76, 214), "titolo": Vector2(800, 92),
		"titoli": {"lontana": Vector2(350, 88), "ravvicinata": Vector2(532, 184)},
		"scritte": [["corsa", Vector2(50, 457), -80.0], ["richiamo", Vector2(202, 437), 90.0], ["richiamo", Vector2(332, 462), -80.0],
			["risalita obbligatoria", Vector2(522, 758), -10.0], ["la diga", Vector2(742, 413), 0.0]],
		"nota": "Si usa anche per la diga della Bever.\nLuci Aldis: nessun effetto.", "nota_pos": Vector2(800, 140),
	},
}

var p: Partita
var tex := {}
var fonts := {}
var mappa := "mohne"
var pos_attuale := {}
var evidenzia := {}   # id del Lancaster -> true se cliccabile ora
var lampo := {}       # id -> tempo residuo dell'effetto (colpito, abbattuto)
var scala := 1.0
var origine := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "
	for m in ["mohne", "eder", "sorpe"]:
		tex["mappa_" + m] = load("res://assets/mappe/%s.jpg" % m)

func imposta(partita: Partita, f: Dictionary) -> void:
	p = partita
	fonts = f
	_aggiorna_mappa()
	pos_attuale.clear()
	queue_redraw()

func _aggiorna_mappa() -> void:
	mappa = Dati.DIGHE[p.diga_corrente()]["mappa"]

func _tex(nome: String) -> Texture2D:
	if not tex.has(nome):
		var path := "res://assets/" + nome
		tex[nome] = load(path) if ResourceLoader.exists(path) else null
	return tex[nome]

# ------------------------------------------------------------------ geometria
func _rot(v: Vector2, gradi: float) -> Vector2:
	return v.rotated(deg_to_rad(gradi))

func _scorta(zona: String, i: int) -> Vector2:
	var L: Dictionary = LAYOUT[mappa]
	var z: Array = L["zone"][zona]
	var d: float = z[1] * 0.5 + 38.0
	return z[0] + _rot(Vector2(0, -d if i == 0 else d), L["angolo"])

func _griglia(r: Rect2, i: int, n: int) -> Vector2:
	var area := Rect2(r.position + Vector2(10, 54), r.size - Vector2(20, 64))
	var col := maxi(1, int(area.size.x / (PED + 8)))
	if n <= 2:
		col = maxi(col, n)
	var righe := int(ceil(float(n) / col))
	var cw := area.size.x / col
	var ch := minf(area.size.y / maxi(righe, 1), PED + 14)
	var c := i % col
	var rr := i / col
	var tot_h := ch * righe
	return area.position + Vector2(cw * (c + 0.5), (area.size.y - tot_h) * 0.5 + ch * (rr + 0.5))

## Posizione (coordinate mappa) di ogni Lancaster sulla mappa del bersaglio.
func posizioni() -> Dictionary:
	var L: Dictionary = LAYOUT[mappa]
	var r := {}
	var avv: Dictionary = p.s["avv"]
	for box in ["vicino", "lontano", "salita"]:
		var qui := p.lanc_in(box)
		for i in qui.size():
			r[qui[i]["id"]] = _griglia(L[box], i, qui.size())
	if avv.has("lanc"):
		var l := p.lanc(avv["lanc"])
		if l["pos"] == "avvicinamento":
			r[l["id"]] = L["zone"][avv["zona"]][0]
		elif l["pos"] == "sgancio":
			r[l["id"]] = L["sgancio"][0]
		var k := 0
		for e in avv.get("scorte", []):
			var x := p.lanc(e)
			if x["pos"] == "scorta" and L["zone"].has(avv["zona"]):
				r[e] = _scorta(avv["zona"], k)
				k += 1
	return r

func _process(delta: float) -> void:
	if p == null:
		return
	var nuovo_m: String = Dati.DIGHE[p.diga_corrente()]["mappa"]
	if nuovo_m != mappa:
		mappa = nuovo_m
	var mosso := false
	var obiettivi := posizioni()
	for id in obiettivi:
		var t: Vector2 = obiettivi[id]
		if not pos_attuale.has(id):
			pos_attuale[id] = t
		var c: Vector2 = pos_attuale[id]
		if c.distance_to(t) > 0.5:
			pos_attuale[id] = c.lerp(t, minf(1.0, delta * 6.0))
			mosso = true
	for id in pos_attuale.keys():
		if not obiettivi.has(id):
			pos_attuale.erase(id)
			mosso = true
	for id in lampo.keys():
		lampo[id] -= delta
		mosso = true
		if lampo[id] <= 0:
			lampo.erase(id)
	if mosso:
		queue_redraw()

# ------------------------------------------------------------------ disegno
func _calcola_scala() -> void:
	scala = minf(size.x / W, size.y / H)
	origine = (size - Vector2(W, H) * scala) * 0.5

func _draw() -> void:
	if p == null:
		return
	_calcola_scala()
	draw_set_transform(origine, 0.0, Vector2(scala, scala))
	var L: Dictionary = LAYOUT[mappa]
	draw_texture_rect(tex["mappa_" + mappa], Rect2(0, 0, W, H), false)
	# titolo della diga
	var nome_diga: String = Dati.DIGHE[p.diga_corrente()]["nome"].to_upper()
	_testo(fonts["titoli"], "DIGA DELLA " + nome_diga, L.get("titolo", Vector2(525, 34)), 40 if not L.has("titolo") else 32, Color(0.95, 0.95, 0.95), 0.0, true)
	if L.has("nota"):
		var righe: PackedStringArray = L["nota"].split("\n")
		for i in righe.size():
			_testo(fonts["testo"], righe[i], L["nota_pos"] + Vector2(0, i * 24), 19, Color(0.86, 0.88, 0.9, 0.92), 0.0, true)
	_box_cerchio(L["vicino"], "Cerchio vicino", ["si può passare al Cerchio lontano", "o lasciare il bersaglio", "si possono sparare razzi Very"])
	_box_cerchio(L["lontano"], "Cerchio lontano", ["si può passare al Cerchio vicino", "o lasciare il bersaglio"])
	_box_salita(L["salita"])
	if L.has("michel"):
		_box_michel(L["michel"])
	_zone(L)
	_sgancio(L)
	for sc in L["scritte"]:
		_testo(fonts["grassetto"], sc[0], sc[1], 19, Color(0.86, 0.87, 0.9, 0.85), sc[2], true)
	# pedine
	var ord := pos_attuale.keys()
	for id in ord:
		_pedina(p.lanc(id), pos_attuale[id])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _testo(f: Font, t: String, c: Vector2, sz: int, col: Color, gradi := 0.0, centrato := true, ombra := true) -> void:
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var off := Vector2(-w * 0.5 if centrato else 0.0, sz * 0.35)
	draw_set_transform(origine + c * scala, deg_to_rad(gradi), Vector2(scala, scala))
	if ombra:
		draw_string(f, off + Vector2(1.5, 1.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.6 * col.a))
	draw_string(f, off, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform(origine, 0.0, Vector2(scala, scala))

func _testo_box(f: Font, t: String, r: Rect2, sz: int, col: Color) -> void:
	draw_string(f, Vector2(r.position.x, r.position.y + sz), t, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, sz, col)

const FONDO_BOX := Color(0.44, 0.46, 0.49, 1.0)
const BORDO_BOX := Color(0.26, 0.27, 0.29, 1.0)
const TESTO_BOX := Color(0.1, 0.1, 0.11)

func _box_cerchio(r: Rect2, titolo: String, righe: Array) -> void:
	draw_rect(r.grow(6), FONDO_BOX)
	draw_rect(r.grow(6), BORDO_BOX, false, 4.0)
	_testo(fonts["titoli"], titolo, r.position + Vector2(r.size.x * 0.5, 30), 30, TESTO_BOX, 0.0, true, false)
	var c := r.get_center() + Vector2(0, 14)
	var rag := minf(r.size.x, r.size.y) * 0.34
	draw_arc(c, rag, 0, TAU, 64, Color(0.15, 0.15, 0.16, 0.4), 2.5)
	for i in righe.size():
		_testo(fonts["testo"], righe[i], r.position + Vector2(r.size.x * 0.5, r.size.y - 12 - (righe.size() - 1 - i) * 18), 15, Color(0.95, 0.96, 0.97, 0.85), 0.0, true, false)

func _box_salita(r: Rect2) -> void:
	draw_rect(r.grow(4), FONDO_BOX)
	draw_rect(r.grow(4), BORDO_BOX, false, 4.0)
	_testo(fonts["titoli"], "Risalita", r.position + Vector2(r.size.x * 0.5, 26), 25, TESTO_BOX, 0.0, true, false)
	_testo(fonts["testo"], "si torna per forza", r.position + Vector2(r.size.x * 0.5, r.size.y - 30), 13, Color(0.95, 0.95, 0.96, 0.85), 0.0, true, false)
	_testo(fonts["testo"], "al Cerchio vicino", r.position + Vector2(r.size.x * 0.5, r.size.y - 14), 13, Color(0.95, 0.95, 0.96, 0.85), 0.0, true, false)

func _box_michel(r: Rect2) -> void:
	draw_rect(r, Color(0.2, 0.21, 0.23, 0.95))
	draw_rect(r, Color(0.7, 0.72, 0.75), false, 2.0)
	_segno_m(r.position + Vector2(22, 24), 13)
	_testo(fonts["titoli"], "Michelskopf", r.position + Vector2(r.size.x * 0.5 + 14, 26), 22, Color(0.95, 0.95, 0.95), 0.0, true, false)
	var y := r.position.y + 58
	for riga in [["2 dadi dopo lo sgancio", Color(0.85, 0.86, 0.88)], ["3 o meno: impatto", Color(0.95, 0.45, 0.35)], ["4 o più: risale", Color(0.85, 0.86, 0.88)], ["-1 per ogni segno M", Color(0.95, 0.95, 0.95)]]:
		_testo(fonts["testo"], riga[0], Vector2(r.position.x + r.size.x * 0.5, y), 17, riga[1], 0.0, true, false)
		y += 30
	if p.s["avv"].has("lanc") and p.s["avv"]["diga"] == "eder":
		_testo(fonts["grassetto"], "segni M ora: %d" % int(p.s["avv"]["m"]), Vector2(r.position.x + r.size.x * 0.5, r.end.y - 14), 17, Color(1, 0.8, 0.4), 0.0, true, false)

func _segno_m(c: Vector2, rag: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -rag), c + Vector2(rag, 0), c + Vector2(0, rag), c + Vector2(-rag, 0)])
	draw_colored_polygon(pts, Color(0.12, 0.12, 0.13))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.9, 0.9, 0.9), 1.5)
	draw_string(fonts["grassetto"], c + Vector2(-rag * 0.55, rag * 0.45), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, int(rag * 1.2), Color.WHITE)

func _quadrato_ruotato(c: Vector2, lato: Vector2, gradi: float, fondo: Color, bordo: Color, spessore: float, raggio := 0.0) -> void:
	draw_set_transform(origine + c * scala, deg_to_rad(gradi), Vector2(scala, scala))
	var r := Rect2(-lato * 0.5, lato)
	if fondo.a > 0:
		draw_rect(r, fondo)
	if spessore > 0:
		draw_rect(r, bordo, false, spessore)
	draw_set_transform(origine, 0.0, Vector2(scala, scala))

func _zone(L: Dictionary) -> void:
	var ang: float = L["angolo"]
	var avv: Dictionary = p.s["avv"]
	var zona_att: String = avv.get("zona", "") if avv.has("lanc") else ""
	for zona in L["zone"]:
		var z: Array = L["zone"][zona]
		var c: Vector2 = z[0]
		var lato: float = z[1]
		var attiva: bool = zona == zona_att
		# pannello esterno con le due strisce delle scorte
		_quadrato_ruotato(c, Vector2(lato + 40, lato + 2 * 76 + 10), ang, Color(0.5, 0.52, 0.55, 0.88), Color(1, 0.78, 0.3) if attiva else Color(0.35, 0.36, 0.38), 5.0 if attiva else 3.0)
		for i in 2:
			var e := _scorta(zona, i)
			_quadrato_ruotato(e, Vector2(lato + 8, 62), ang, Color(0.4, 0.41, 0.44, 0.9), Color(0.3, 0.31, 0.33), 2.0)
			_testo(fonts["testo"], "scorta", e + _rot(Vector2(0, 0), ang), 18, Color(0.15, 0.15, 0.16), ang, true, false)
		var principale := Color(0.78, 0.79, 0.8, 0.96) if zona != "lontana" else Color(0.86, 0.86, 0.85, 0.97)
		_quadrato_ruotato(c, Vector2(lato, lato), ang, principale, Color(0.25, 0.26, 0.28), 6.0 if zona == "lontana" else 3.0)
		if zona == "lontana":
			_testo(fonts["titoli"], "avvicinamento", c + _rot(Vector2(0, 8), ang), 24, Color(0.82, 0.1, 0.1), ang - 18, true, false)
			_testo(fonts["testo"], "contraerea", c + _rot(Vector2(-30, -lato * 0.36), ang), 16, TESTO_BOX, ang, true, false)
			_testo(fonts["grassetto"], "-2 se sganci qui", c + _rot(Vector2(0, lato * 0.36), ang), 15, Color(0.75, 0.1, 0.1), ang, true, false)
		else:
			_testo(fonts["testo"], "contraerea, poi", c + _rot(Vector2(0, -lato * 0.22), ang), 16, TESTO_BOX, ang, true, false)
			_testo(fonts["testo"], "mitragliatrici", c + _rot(Vector2(0, -lato * 0.22 + 20), ang), 16, TESTO_BOX, ang, true, false)
			if zona == "ravvicinata":
				_testo(fonts["testo"], "sgancio tardivo?", c + _rot(Vector2(0, lato * 0.3), ang), 15, TESTO_BOX, ang, true, false)
			if zona == "vicina" and L.get("m_vicina", false):
				_segno_m(c + _rot(Vector2(0, lato * 0.3), ang), 11)
		var col_t := Color(0.95, 0.42, 0.27) if not attiva else Color(1, 0.75, 0.3)
		_testo(fonts["titoli"], zona, L["titoli"][zona] + _rot(Vector2(0, -14), ang), 34, col_t, ang, true)
	# caselle dei gettoni (zona lontana)
	for k in ["gv", "gq"]:
		_quadrato_ruotato(L[k], Vector2(86, 86), ang, Color(0.35, 0.36, 0.38, 0.92), Color(0.2, 0.2, 0.22), 4.0)
		var tipo := "v" if k == "gv" else "q"
		var g: String = avv.get(tipo, "") if avv.has("lanc") else ""
		var gs: String = avv.get("sg_" + tipo, "") if avv.has("lanc") else ""
		if gs != "":
			_gettone(L[k], gs, tipo, true, ang)
		elif g != "":
			_gettone(L[k], g, tipo, false, ang)
		else:
			_testo(fonts["testo"], "velocità" if tipo == "v" else "quota", L[k], 15, Color(0.85, 0.86, 0.88, 0.8), ang, true, false)

func _gettone(c: Vector2, id: String, tipo: String, sgancio: bool, ang: float) -> void:
	var g := Dati.gettone(id)
	var fondo := Color(0.76, 0.7, 0.58) if not sgancio else Color(0.97, 0.75, 0.68)
	_quadrato_ruotato(c, Vector2(78, 78), ang, fondo, Color(0.25, 0.22, 0.18), 2.0)
	var t1: String = ("avvicin." if not sgancio else "sgancio")
	_testo(fonts["testo"], t1, c + _rot(Vector2(0, -26), ang), 13, Color(0.35, 0.3, 0.25), ang, true, false)
	_testo(fonts["grassetto"], g["av"] if not sgancio else g["sg"], c + _rot(Vector2(0, -4), ang), 17 if g["av"] != "irregolare" else 14, Color(0.12, 0.1, 0.08), ang, true, false)
	if sgancio:
		_testo(fonts["grassetto"], "%+d" % int(g["mod"]), c + _rot(Vector2(0, 20), ang), 20, Color(0.8, 0.1, 0.1), ang, true, false)
		if g["m"]:
			_segno_m(c + _rot(Vector2(-26, 20), ang), 8)
	else:
		_testo(fonts["testo"], "%d gettoni" % int(g["n"]) if int(g["n"]) != 1 else "1 gettone", c + _rot(Vector2(0, 20), ang), 14, Color(0.12, 0.1, 0.08), ang, true, false)

func _sgancio(L: Dictionary) -> void:
	var sg: Array = L["sgancio"]
	_quadrato_ruotato(sg[0] + Vector2(-4, -6), Vector2(sg[1] + 34, sg[1] + 34), sg[2], Color(0.27, 0.29, 0.32, 1.0), Color(0, 0, 0, 0), 0.0)
	_quadrato_ruotato(sg[0], Vector2(sg[1], sg[1]), sg[2], Color(0.21, 0.22, 0.25, 1.0), Color(0.88, 0.12, 0.1), 9.0)
	_testo(fonts["titoli"], "sgancio", sg[0] + _rot(Vector2(0, -sg[1] * 0.3), sg[2] - 45.0), 26, Color(0.95, 0.42, 0.27), sg[2] - 45.0, true)
	var ri: Array = L["rilasciati"]
	_quadrato_ruotato(ri[0] + Vector2(-3, -3), Vector2(ri[1] + 22, ri[1] + 22), ri[2], Color(0.27, 0.29, 0.32, 1.0), Color(0, 0, 0, 0), 0.0)
	_quadrato_ruotato(ri[0], Vector2(ri[1], ri[1]), ri[2], Color(0.3, 0.31, 0.33, 1.0), Color(0.75, 0.76, 0.78), 3.0)
	_testo(fonts["testo"], "Upkeep", ri[0] + Vector2(0, -8), 17, Color(0.85, 0.86, 0.88), 0.0, true, false)
	_testo(fonts["testo"], "sganciati", ri[0] + Vector2(0, 12), 17, Color(0.85, 0.86, 0.88), 0.0, true, false)
	# Upkeep sganciati in questo turno
	var n := 0
	for u in p.dg()["upkeep"]:
		if int(u.get("t", -9)) == int(p.s["turni"]) and n < 3:
			_upkeep_icona(ri[0] + Vector2(-26 + n * 26, 34), 11)
			n += 1

func _upkeep_icona(c: Vector2, r: float) -> void:
	# il cilindro dell'Upkeep visto di lato
	var rect := Rect2(c - Vector2(r * 1.3, r * 0.75), Vector2(r * 2.6, r * 1.5))
	draw_rect(rect, Color(0.32, 0.33, 0.3))
	draw_rect(rect, Color(0.08, 0.08, 0.08), false, 1.5)
	draw_line(rect.position + Vector2(rect.size.x * 0.33, 0), rect.position + Vector2(rect.size.x * 0.33, rect.size.y), Color(0.12, 0.12, 0.12), 1.2)
	draw_line(rect.position + Vector2(rect.size.x * 0.66, 0), rect.position + Vector2(rect.size.x * 0.66, rect.size.y), Color(0.12, 0.12, 0.12), 1.2)

func _pedina(l: Dictionary, c: Vector2) -> void:
	var r := Rect2(c - Vector2(PED, PED) * 0.5, Vector2(PED, PED))
	draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.55))
	var t := _tex("pedine/%s_f.png" % l["id"])
	if t:
		draw_texture_rect(t, r, false)
	if p.danneggiato(l):
		draw_rect(Rect2(r.position + Vector2(0, PED - 20), Vector2(PED, 20)), Color(0.45, 0.05, 0.1, 0.9))
		draw_string(fonts["grassetto"], r.position + Vector2(0, PED - 5), "danneggiato", HORIZONTAL_ALIGNMENT_CENTER, PED, 12, Color(1, 0.88, 0.88))
	if int(l["upkeep"]) >= 0:
		draw_rect(Rect2(r.position + Vector2(PED - 28, -10), Vector2(34, 22)), Color(0.86, 0.82, 0.72))
		_upkeep_icona(r.position + Vector2(PED - 11, 1), 8)
	if l["elite"] != "":
		var rt := _tex("ritratti/%s.png" % l["elite"])
		if rt:
			draw_texture_rect(rt, Rect2(r.position + Vector2(-12, -12), Vector2(30, 30)), false)
			draw_rect(Rect2(r.position + Vector2(-12, -12), Vector2(30, 30)), Color(0.85, 0.83, 0.7), false, 1.5)
	if l["segnalino"] != "":
		var testo := "a vuoto" if l["segnalino"] == "passaggio" else "osservato"
		draw_rect(Rect2(r.position + Vector2(-6, PED - 10), Vector2(PED + 12, 18)), Color(0.83, 0.77, 0.62))
		draw_string(fonts["grassetto"], r.position + Vector2(-6, PED + 4), testo, HORIZONTAL_ALIGNMENT_CENTER, PED + 12, 13, Color(0.2, 0.15, 0.1))
	if evidenzia.get(l["id"], false):
		var a := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
		draw_rect(r.grow(5), Color(1, 0.8, 0.3, a), false, 4.0)
		queue_redraw()
	if lampo.has(l["id"]):
		draw_rect(r.grow(8), Color(1, 0.3, 0.1, clampf(lampo[l["id"]], 0, 1)), false, 6.0)

func colpisci(id: String) -> void:
	lampo[id] = 1.2

# ------------------------------------------------------------------ interazione
func _id_sotto(pt: Vector2) -> String:
	var m := (pt - origine) / scala
	var ids := pos_attuale.keys()
	ids.reverse()
	for id in ids:
		if Rect2(pos_attuale[id] - Vector2(PED, PED) * 0.5, Vector2(PED, PED)).has_point(m):
			return id
	return ""

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := _id_sotto(e.position)
		if id != "":
			pedina_cliccata.emit(id)
	if e is InputEventMouseMotion:
		var id := _id_sotto(e.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != "" and evidenzia.get(id, false) else Control.CURSOR_ARROW

func _get_tooltip(at: Vector2) -> String:
	var id := _id_sotto(at)
	if id == "":
		return ""
	return testo_lanc(p.lanc(id))

func testo_lanc(l: Dictionary) -> String:
	var t := "%s · pilota %s\nEquipaggio %s (addestramento %d)" % [l["id"], l["pilota"], Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower(), p.addestramento(l)]
	if l["elite"] != "":
		var r: Array = Dati.RUOLI[p.ruolo(l)]
		t += "\nSpecialista: %s, %s. %s" % [Dati.SPECIALISTI[l["elite"]]["nome"], r[0].to_lower(), r[1]]
	t += "\nUpkeep a bordo: " + ("sì" if int(l["upkeep"]) >= 0 else "no")
	if p.danneggiato(l):
		t += "\nDanneggiato: -1 allo sgancio, un altro colpo lo abbatte."
	return t
