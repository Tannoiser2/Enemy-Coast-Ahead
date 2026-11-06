## Mappa di volo sull'immagine originale (tradotta): le pedine stanno nelle fasce delle zone, nei riquadri dei
## dispersi e del rientro, nelle caselle di acquisizione delle dighe; i segnalini di ricognizione, allerta e turno
## di volo sulle loro tracce. A destra le tracce originali delle otto dighe con i loro segnalini.
## Coordinate: quelle della tavola originale (5100x3300) convertite con B(); la tela è mappa (0.75) + colonna dighe.
class_name MappaVolo
extends Tavola

signal pedina_cliccata(id: String)

const K := 0.75                       # scala dell'immagine volo.jpg rispetto alla tavola
const O := Vector2(1340, 20)          # origine del ritaglio nella tavola
const MW := 1395.0                    # larghezza della mappa sulla tela
const MH := 2415.0
const COL_X := 1420.0                 # colonna delle tracce delle dighe
const STRISCIA := Vector2(940, 292)   # dimensione di una traccia sulla tela
const PED := 88.0

const RECON := {
	"weser": [Vector2(1471, 531), Vector2(1471, 439), Vector2(1471, 344), Vector2(1471, 249)],
	"ruhr": [Vector2(1471, 1044), Vector2(1471, 950), Vector2(1471, 856), Vector2(1471, 762)],
	"costa_olandese": [Vector2(1468, 1590), Vector2(1468, 1496), Vector2(1468, 1404), Vector2(1468, 1311)],
}
const RTB := {
	"weser": Rect2(1587, 213, 256, 177), "ruhr": Rect2(1587, 716, 256, 174), "costa_olandese": Rect2(1586, 1265, 259, 178),
	"costa_inglese": Rect2(1466, 2100, 256, 172), "mare": Rect2(1466, 2100, 256, 172),
}
const DISPERSI := {
	"weser": Rect2(1587, 418, 256, 172), "ruhr": Rect2(1587, 916, 256, 174), "costa_olandese": Rect2(1586, 1469, 259, 174),
	"mare": Rect2(1466, 1895, 256, 174), "costa_inglese": Rect2(1466, 2300, 256, 177),
}
## dove si mettono onde e Lancaster in volo (coordinate tavola)
const AREA := {
	"weser": Rect2(1880, 240, 820, 330), "ruhr": Rect2(1880, 730, 560, 440), "costa_olandese": Rect2(1880, 1260, 1000, 380),
	"mare": Rect2(1760, 1920, 1080, 210), "costa_inglese": Rect2(1760, 2320, 1080, 250), "inghilterra": Rect2(1700, 2860, 1100, 160),
}
const SCAMPTON := Rect2(1420, 2950, 520, 260)
const DIGHE_BOX := {
	"diemel": Rect2(2530, 96, 220, 220), "lister": Rect2(2784, 216, 220, 224), "eder": Rect2(2746, 466, 224, 220),
	"mohne": Rect2(2636, 764, 220, 222), "sorpe": Rect2(2886, 794, 224, 222), "bever": Rect2(2454, 1020, 226, 220),
	"ennepe": Rect2(2706, 1046, 224, 224), "henne": Rect2(2950, 1064, 224, 220),
}
const ALLERTA := [Vector2(1537, 1727), Vector2(1653, 1750), Vector2(1765, 1768), Vector2(1876, 1790), Vector2(1982, 1812)]
const TURNI := [Vector2(3074, 1903), Vector2(3074, 1796), Vector2(3074, 1678), Vector2(3074, 1562), Vector2(3074, 1448),
	Vector2(2943, 1448), Vector2(2943, 1562), Vector2(2943, 1678), Vector2(2943, 1796), Vector2(2943, 1903)]
const FASI := {"v_pulizia": 2150, "v_bersagli": 2245, "v_acquis": 2350, "v_risolvi": 2480, "v_evita": 2600, "v_pericoli": 2705,
	"v_nav": 2800, "v_movi": 2905, "v_radio": 2985, "v_coord": 3110}
const ORDINE_DIGHE := ["lister", "diemel", "eder", "henne", "sorpe", "bever", "ennepe", "mohne"]

## le texture devono restare in memoria finché vengono disegnate
static var TEX_TRACCE := {}

var p: PartitaVolo
var aree := []   # [Rect2 in coordinate tela, id del Lancaster]
var evidenzia := {}

func _init() -> void:
	W = COL_X + STRISCIA.x + 12
	H = MH

func imposta(partita: PartitaVolo, f: Dictionary) -> void:
	p = partita
	fonts = f
	queue_redraw()

static func B(v: Vector2) -> Vector2:
	return (v - O) * K

static func BR(r: Rect2) -> Rect2:
	return Rect2(B(r.position), r.size * K)

func _draw() -> void:
	if p == null:
		return
	inizia()
	aree.clear()
	draw_rect(Rect2(0, 0, W, H), Color(0.07, 0.07, 0.08))
	draw_texture_rect(_tex("mappe/volo.jpg"), Rect2(0, 0, MW, MH), false)
	_segnalini()
	for z in Dati.ZONE:
		_zona(z)
	_dighe_acquisizione()
	_tracce_dighe()
	finisci()

# ------------------------------------------------------------------ segnalini delle tracce
func _segnalini() -> void:
	var beige := Color(0.86, 0.81, 0.68)
	var inch := Color(0.2, 0.15, 0.1)
	# ricognizione delle zone ostili
	for z in RECON:
		var lv: int = clampi(int(p.s["recon_zone"].get(z, 0)), 0, 3)
		segnalino(B(RECON[z][lv]), 56, ["RICOGN.", str(lv)], Color(0.32, 0.5, 0.62), Color.WHITE)
	# allerta
	var al: int = clampi(int(p.s["allerta"]), 0, 4)
	segnalino(B(ALLERTA[al]), 62, ["ALLERTA"], Color(0.82, 0.22, 0.16), Color.WHITE, 10.0)
	# turno di volo
	var t: int = clampi(int(p.s["turno_volo"]), 1, 10)
	segnalino(B(TURNI[t - 1]) + Vector2(0, 8), 54, ["TURNO", "DI VOLO"], beige, inch)
	# fase in corso nella sequenza
	if FASI.has(p.s["fase"]):
		var c := B(Vector2(2915, FASI[p.s["fase"]]))
		var a := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 220.0)
		draw_arc(c, 22, 0, TAU, 32, Color(1, 0.75, 0.25, a), 5.0)
		queue_redraw()
	# bersaglio di riserva
	var rs: String = p.s.get("riserva", "")
	if rs != "" and DIGHE_BOX.has(rs):
		var rb := BR(DIGHE_BOX[rs])
		segnalino(rb.position + Vector2(rb.size.x - 6, 6), 46, ["RISERVA"], Color(0.95, 0.8, 0.35), inch, 0)

# ------------------------------------------------------------------ zone
func _zona(z: String) -> void:
	# onde e Lancaster in volo
	var gs := p.gruppi().filter(func(g): return p.zona_gruppo(g) == z and p.capo_gruppo(g)["pos"] == "volo")
	var area := BR(AREA[z])
	var x := area.position.x
	var y := area.position.y
	for g in gs:
		var m := p.lanc_gruppo(g).filter(func(l): return l["pos"] == "volo")
		var larg := 10.0 + m.size() * (PED + 4)
		if x + larg > area.end.x and x > area.position.x:
			x = area.position.x
			y += PED + 40
		_gruppo(g, m, Rect2(x, y, larg, PED + 34))
		x += larg + 12
	# dispersi e rientro
	if DISPERSI.has(z):
		var r := BR(DISPERSI[z])
		var ls: Array = p.s["lanc"].filter(func(l): return l["zona"] == z and l["pos"] == "smarrito")
		_fila(ls, Rect2(r.position + Vector2(r.size.x * 0.3, 8), Vector2(r.size.x * 0.68, r.size.y - 14)), 46)
	if RTB.has(z) and z != "mare":
		var r := BR(RTB[z])
		var ls: Array = p.s["lanc"].filter(func(l): return l["zona"] == z and l["pos"] == "rtb")
		_fila(ls, Rect2(r.position + Vector2(r.size.x * 0.32, 8), Vector2(r.size.x * 0.66, r.size.y - 14)), 46)
	if z == "inghilterra":
		var r := BR(SCAMPTON)
		var att: Array = p.s["lanc"].filter(func(l): return l["pos"] == "attesa")
		var rientrati: Array = p.s["lanc"].filter(func(l): return l["zona"] == "inghilterra" and l["pos"] == "rtb")
		if not att.is_empty():
			testo("grassetto", "in attesa di decollo", r.position + Vector2(r.size.x * 0.62, -8), 20, Color(0.95, 0.92, 0.85))
			_fila(att, Rect2(r.position + Vector2(r.size.x * 0.25, 4), Vector2(r.size.x * 0.75, r.size.y * 0.55)), 44)
		if not rientrati.is_empty():
			testo("grassetto", "rientrati a Scampton", r.position + Vector2(r.size.x * 0.62, r.size.y * 0.6), 20, Color(0.85, 0.95, 0.87))
			_fila(rientrati, Rect2(r.position + Vector2(r.size.x * 0.25, r.size.y * 0.65), Vector2(r.size.x * 0.75, r.size.y * 0.35)), 40)

func _fila(ls: Array, r: Rect2, lato: float) -> void:
	if ls.is_empty():
		return
	var col := maxi(1, int(r.size.x / (lato + 4)))
	var passo := Vector2(lato + 4, lato + 4)
	var righe := int(ceil(float(ls.size()) / col))
	if righe * passo.y > r.size.y and righe > 1:
		passo.y = (r.size.y - lato) / (righe - 1)
	for i in ls.size():
		_pedina(ls[i], r.position + Vector2((i % col) * passo.x + lato * 0.5, (i / col) * passo.y + lato * 0.5), lato)

func _gruppo(g: String, m: Array, r: Rect2) -> void:
	if g.begins_with("O:"):
		var o: Dictionary = p.s["onde"][g.substr(2)]
		var buona: bool = o["buona"]
		var cart := Rect2(r.position, Vector2(r.size.x, 30))
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, Color(0.86, 0.81, 0.68, 0.92) if buona else Color(0.22, 0.22, 0.24, 0.92))
		draw_rect(r, Color(0.35, 0.28, 0.18), false, 2.0)
		draw_string(fonts["grassetto"], cart.position + Vector2(6, 24), o["nome"] + ("" if buona else " (scompaginata)"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 23,
			Color(0.2, 0.14, 0.08) if buona else Color(0.95, 0.85, 0.6))
	for i in m.size():
		var l: Dictionary = m[i]
		var capo: bool = g.begins_with("O:") and p.s["onde"][g.substr(2)]["capo"] == l["id"]
		_pedina(l, r.position + Vector2(5 + PED * 0.5 + i * (PED + 4), 30 + PED * 0.5 + 2), PED, capo)

func _pedina(l: Dictionary, c: Vector2, lato: float, capo := false) -> void:
	var r := Rect2(c - Vector2(lato, lato) * 0.5, Vector2(lato, lato))
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.55))
	var t := _tex("pedine/%s_f.png" % l["id"])
	if t:
		draw_texture_rect(t, r, false)
	if p.danneggiato(l):
		draw_rect(Rect2(r.position + Vector2(0, lato * 0.82), Vector2(lato, lato * 0.18)), Color(0.55, 0.05, 0.1, 0.92))
	if int(l["upkeep"]) >= 0:
		draw_rect(Rect2(r.position + Vector2(lato * 0.62, -lato * 0.08), Vector2(lato * 0.42, lato * 0.24)), Color(0.86, 0.82, 0.72))
		draw_rect(Rect2(r.position + Vector2(lato * 0.67, -lato * 0.03), Vector2(lato * 0.32, lato * 0.14)), Color(0.3, 0.3, 0.28))
	if l["elite"] != "":
		var rt := _tex("ritratti/%s.png" % l["elite"])
		if rt:
			var q := Rect2(r.position + Vector2(-lato * 0.14, -lato * 0.14), Vector2(lato * 0.4, lato * 0.4))
			draw_texture_rect(rt, q, false)
			draw_rect(q, Color(0.85, 0.83, 0.7), false, 1.5)
	if capo:
		draw_rect(r.grow(3), Color(0.95, 0.75, 0.3), false, 3.0)
	var ng: int = l.get("guasti", []).size()
	if ng > 0:
		draw_circle(r.position + Vector2(lato * 0.88, lato * 0.82), lato * 0.16, Color(0.85, 0.2, 0.15))
		draw_string(fonts["grassetto"], r.position + Vector2(lato * 0.72, lato * 0.9), str(ng), HORIZONTAL_ALIGNMENT_CENTER, lato * 0.32, int(lato * 0.26), Color.WHITE)
	if evidenzia.get(l["id"], false):
		var a := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
		draw_rect(r.grow(5), Color(1, 0.8, 0.3, a), false, 4.0)
		queue_redraw()
	aree.append([r, l["id"]])

# ------------------------------------------------------------------ dighe
func _dighe_acquisizione() -> void:
	for d in DIGHE_BOX:
		var b := BR(DIGHE_BOX[d])
		var dd: Dictionary = p.s["dighe"][d]
		if dd["breccia"]:
			segnalino(b.get_center() + Vector2(0, -10), 92, ["BRECCIA"], Color(0.62, 0.1, 0.08), Color.WHITE, -12)
		var qui: Array = p.s["lanc"].filter(func(l): return l.get("diga", "") == d and (l["pos"] in PartitaVolo.POS_BERSAGLIO or l["pos"] in ["acquisizione", "in_arrivo"]))
		_fila(qui, Rect2(b.position + Vector2(6, b.size.y * 0.42), Vector2(b.size.x - 12, b.size.y * 0.56)), 44)

func _tracce_dighe() -> void:
	var y := 0.0
	var passo := (H - STRISCIA.y) / 7.0
	for d in ORDINE_DIGHE:
		var r := Rect2(COL_X, y, STRISCIA.x, STRISCIA.y)
		traccia_diga(self, d, r)
		y += passo

## Disegna la traccia originale di una diga con i segnalini (usata anche dalla scheda del bersaglio).
## r è il rettangolo della striscia (immagine 740x230) nelle coordinate correnti del controllo c.
static func traccia_diga(c: CanvasItem, d: String, r: Rect2, partita = null, f := {}) -> void:
	var me = c
	var pp: Partita = partita if partita != null else me.p
	var fo: Dictionary = f if not f.is_empty() else me.fonts
	if not TEX_TRACCE.has(d):
		TEX_TRACCE[d] = load("res://assets/mappe/traccia_%s.jpg" % d)
	var t: Texture2D = TEX_TRACCE[d]
	c.draw_texture_rect(t, r, false)
	var k := r.size.x / 740.0
	var dd: Dictionary = pp.s["dighe"][d]
	# caselle 0..4 (coordinate nell'immagine 740x230)
	var caselle := [Rect2(50, 60, 110, 146), Rect2(160, 60, 200, 146), Rect2(360, 104, 123, 102), Rect2(483, 104, 114, 102), Rect2(597, 104, 95, 102)]
	var acqua_x := {2: 360, 3: 483, 4: 597}
	var inch := Color(0.15, 0.12, 0.08)
	var marcatori := []
	if dd.get("vista", true):
		marcatori.append(["danni", clampi(pp.danni_diga(d), 0, 4), Color(0.85, 0.2, 0.15), Color.WHITE])
		marcatori.append(["ricogn.", clampi(int(dd["recon"]), 0, 4), Color(0.32, 0.5, 0.62), Color.WHITE])
		if int(dd.get("attivita", 0)) > 0:
			marcatori.append(["attività", clampi(int(dd["attivita"]), 0, 4), Color(0.6, 0.55, 0.85), Color.WHITE])
		if int(dd.get("flak", 0)) > 0:
			marcatori.append(["contraerea", clampi(int(dd["flak"]), 0, 4), Color(0.25, 0.25, 0.27), Color.WHITE])
	var per_casella := {}
	for m in marcatori:
		var i: int = m[1]
		var n: int = per_casella.get(i, 0)
		per_casella[i] = n + 1
		var cas: Rect2 = caselle[i]
		var lw := minf(cas.size.x - 8, 104.0)
		var lh := 34.0
		var pos := Vector2(cas.position.x + 4, cas.position.y + 4 + n * (lh + 3))
		if n >= 3:
			pos = Vector2(cas.position.x + 4 + lw * 0.5, cas.position.y + 4 + (n - 3) * (lh + 3))
		var q := Rect2(r.position + pos * k, Vector2(lw, lh) * k)
		c.draw_rect(Rect2(q.position + Vector2(2, 2) * k, q.size), Color(0, 0, 0, 0.5))
		c.draw_rect(q, m[2])
		var fs := int(22 * k)
		while fs > 6 and (fo["grassetto"] as Font).get_string_size(m[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > q.size.x - 2:
			fs -= 1
		c.draw_string(fo["grassetto"], q.position + Vector2(0, q.size.y * 0.5 + fs * 0.36), m[0], HORIZONTAL_ALIGNMENT_CENTER, q.size.x, fs, m[3])
	# livello dell'acqua: cornice sulla colonna giusta
	var aq: int = int(dd.get("acqua", 4))
	if acqua_x.has(aq) and dd.get("vista", true):
		var ax: float = acqua_x[aq]
		var q2 := Rect2(r.position + Vector2(ax + 1, 62) * k, Vector2((caselle[aq] as Rect2).size.x - 2, 42) * k)
		c.draw_rect(q2, Color(1, 0.75, 0.25), false, 3.0 * k)
	if dd["breccia"]:
		c.draw_rect(Rect2(r.position + Vector2(50, 60) * k, Vector2(642, 146) * k), Color(0.7, 0.1, 0.08, 0.35))
		c.draw_string(fo["titoli"], r.position + Vector2(50, 160) * k, "BRECCIA", HORIZONTAL_ALIGNMENT_CENTER, 642 * k, int(48 * k), Color(1, 0.9, 0.85))
	# Upkeep a segno (valore o ?) e mancati
	var mancati := 0
	var kx := 0
	for u in dd["upkeep"]:
		if u["esito"] != "colpito":
			mancati += 1
			continue
		var v := int(u["valore"])
		var q3 := Rect2(r.position + Vector2(168 + kx * 40, 150) * k, Vector2(34, 34) * k)
		c.draw_rect(q3, Color(0.95, 0.8, 0.35) if v >= 0 else Color(0.75, 0.72, 0.62))
		c.draw_rect(q3, inch, false, 1.5 * k)
		c.draw_string(fo["grassetto"], q3.position + Vector2(0, 26 * k), str(v) if v >= 0 else "?", HORIZONTAL_ALIGNMENT_CENTER, q3.size.x, int(24 * k), inch)
		kx += 1
	if mancati > 0:
		c.draw_string(fo["grassetto"], r.position + Vector2(692, 50) * k, "%d" % mancati, HORIZONTAL_ALIGNMENT_CENTER, 48 * k, int(30 * k), Color(1, 0.8, 0.4))
	if not dd.get("vista", true):
		c.draw_rect(Rect2(r.position + Vector2(50, 60) * k, Vector2(642, 146) * k), Color(0.05, 0.05, 0.06, 0.55))
		c.draw_string(fo["testo"], r.position + Vector2(50, 150) * k, "mai fotografata", HORIZONTAL_ALIGNMENT_CENTER, 642 * k, int(30 * k), Color(0.85, 0.85, 0.85))

# ------------------------------------------------------------------ interazione
func _id_sotto(pt: Vector2) -> String:
	var m := a_tela(pt)
	for i in range(aree.size() - 1, -1, -1):
		if (aree[i][0] as Rect2).has_point(m):
			return aree[i][1]
	return ""

func _gui_input(e: InputEvent) -> void:
	super._gui_input(e)
	if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not era_trascinamento():
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
