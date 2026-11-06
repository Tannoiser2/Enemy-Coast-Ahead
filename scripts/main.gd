## Interfaccia di Enemy Coast Ahead: menu, mappa del bersaglio, scheda della diga, turni d'attacco, squadriglia,
## pannello delle decisioni con i dadi, registro della missione, aiuto, salvataggi locali e su Firebase.
extends Node

const SALVA_LOCALE := "user://eca_partita.json"

const C_FONDO := Color(0.05, 0.06, 0.075)
const C_PANNELLO := Color(0.13, 0.145, 0.165)
const C_PANNELLO2 := Color(0.18, 0.195, 0.22)
const C_BORDO := Color(0.32, 0.34, 0.37)
const C_TESTO := Color(0.88, 0.89, 0.9)
const C_GRIGIO := Color(0.6, 0.62, 0.65)
const C_ARANCIO := Color(0.95, 0.42, 0.27)
const C_ROSSO := Color(0.85, 0.13, 0.12)
const C_ORO := Color(1.0, 0.78, 0.32)
const C_CARTA := Color(0.76, 0.7, 0.58)
const C_ACQUA := Color(0.56, 0.79, 0.81)

var g: Partita
var bot: Bot
var net
var fonts := {}
var tema: Theme
var radice: Control
var ui: Control
var mappa: MappaBersaglio
var mappa_volo: MappaVolo
var bottone_vista: Button
var vista_volo := false
var ultima_fase_volo := false
var scheda_diga: Control
var traccia: Control
var squadriglia: VBoxContainer
var pannello_scelte: VBoxContainer
var titolo_scelta: Label
var testo_scelta: RichTextLabel
var dadi: Control
var registro: RichTextLabel
var titolo_scen: Label
var finestra: Control
var eventi_visti := 0
var log_visti := 0

func _ready() -> void:
	get_window().title = "Enemy Coast Ahead · The Dambuster Raid"
	fonts = {
		"testo": load("res://assets/font/Testo.ttf"), "grassetto": load("res://assets/font/TestoGrassetto.ttf"),
		"titoli": load("res://assets/font/Titoli.ttf"), "serif": load("res://assets/font/Serif.ttf"),
		"macchina": load("res://assets/font/Macchina.ttf"),
	}
	tema = _crea_tema()
	net = load("res://scripts/net.gd").new()
	add_child(net)
	radice = Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.theme = tema
	var cl := CanvasLayer.new()
	add_child(cl)
	cl.add_child(radice)
	var sfondo := ColorRect.new()
	sfondo.color = C_FONDO
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(sfondo)
	_menu()

# ================================================================ tema
func _stile(fondo: Color, bordo := Color(0, 0, 0, 0), spessore := 0, raggio := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _crea_tema() -> Theme:
	var t := Theme.new()
	t.default_font = fonts["testo"]
	t.default_font_size = 17
	t.set_color("font_color", "Label", C_TESTO)
	t.set_color("default_color", "RichTextLabel", C_TESTO)
	t.set_font("bold_font", "RichTextLabel", fonts["grassetto"])
	t.set_font("normal_font", "RichTextLabel", fonts["testo"])
	t.set_stylebox("normal", "Button", _stile(Color(0.24, 0.26, 0.29), C_BORDO, 1))
	t.set_stylebox("hover", "Button", _stile(Color(0.33, 0.3, 0.24), C_ORO, 1))
	t.set_stylebox("pressed", "Button", _stile(Color(0.4, 0.33, 0.2), C_ORO, 2))
	t.set_stylebox("disabled", "Button", _stile(Color(0.16, 0.17, 0.19), Color(0.25, 0.26, 0.28), 1))
	t.set_stylebox("focus", "Button", _stile(Color(0, 0, 0, 0), C_ORO, 1))
	t.set_color("font_color", "Button", C_TESTO)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.46, 0.48))
	t.set_font("font", "Button", fonts["grassetto"])
	t.set_stylebox("panel", "PanelContainer", _stile(C_PANNELLO, C_BORDO, 1, 4))
	t.set_stylebox("panel", "TooltipPanel", _stile(Color(0.1, 0.11, 0.13, 0.97), C_ORO, 1))
	t.set_color("font_color", "TooltipLabel", C_TESTO)
	t.set_font("font", "TooltipLabel", fonts["testo"])
	t.set_font_size("font_size", "TooltipLabel", 15)
	t.set_stylebox("normal", "LineEdit", _stile(Color(0.1, 0.11, 0.13), C_BORDO, 1))
	t.set_color("font_color", "LineEdit", C_TESTO)
	t.set_stylebox("panel", "TabContainer", _stile(C_PANNELLO, C_BORDO, 1))
	t.set_stylebox("tab_selected", "TabContainer", _stile(C_PANNELLO2, C_ORO, 1))
	t.set_stylebox("tab_unselected", "TabContainer", _stile(Color(0.1, 0.11, 0.13), C_BORDO, 1))
	t.set_stylebox("tab_hovered", "TabContainer", _stile(Color(0.2, 0.2, 0.22), C_ORO, 1))
	t.set_color("font_selected_color", "TabContainer", C_ORO)
	t.set_color("font_unselected_color", "TabContainer", C_GRIGIO)
	t.set_font("font", "TabContainer", fonts["grassetto"])
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.4, 0.42, 0.45)
	sb.set_corner_radius_all(3)
	t.set_stylebox("grabber", "VScrollBar", sb)
	t.set_stylebox("scroll", "VScrollBar", _stile(Color(0.1, 0.11, 0.12)))
	return t

func _etichetta(t: String, font := "testo", sz := 17, col := C_TESTO) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", fonts[font])
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

func _bottone(t: String, f: Callable, sz := 17) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", sz)
	b.pressed.connect(f)
	return b

func _svuota() -> void:
	for c in radice.get_children():
		if c is ColorRect and c.get_index() == 0:
			continue
		c.queue_free()
	finestra = null

# ================================================================ menu
func _menu() -> void:
	_svuota()
	g = null
	var m := Control.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(m)
	var cop := TextureRect.new()
	cop.texture = load("res://assets/ui/copertina.jpg")
	cop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cop.anchor_bottom = 1.0
	cop.anchor_right = 0.42
	cop.offset_left = 30
	cop.offset_top = 30
	cop.offset_bottom = -30
	m.add_child(cop)
	var col := VBoxContainer.new()
	col.anchor_left = 0.45
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_top = 40
	col.offset_right = -40
	col.offset_bottom = -30
	col.add_theme_constant_override("separation", 8)
	m.add_child(col)
	col.add_child(_etichetta("ENEMY COAST AHEAD", "titoli", 54, Color(0.95, 0.95, 0.95)))
	col.add_child(_etichetta("Operazione Chastise · The Dambuster Raid, 16-17 maggio 1943", "serif", 26, C_GRIGIO))
	col.add_child(_etichetta("Solitario: comandi il 617° Squadron contro le dighe della Ruhr.", "testo", 18, C_TESTO))
	var sep := HSeparator.new()
	col.add_child(sep)
	col.add_child(_etichetta("SCENARI D'ATTACCO", "titoli", 22, C_ARANCIO))
	var sc_box := VBoxContainer.new()
	sc_box.add_theme_constant_override("separation", 6)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(sc_box)
	sc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var prima := _riga_scenario("Prima partita (consigliata)", "Scenario 5 semplificato: un solo Lancaster con equipaggio veterano, cielo sereno, allerta 1, nessun dubbio sulla diga. Il modo migliore per imparare l'avvicinamento e lo sgancio.", func(): _nuova(5, true))
	sc_box.add_child(prima)
	for n in [1, 2, 3, 4, 5]:
		var sc: Dictionary = Dati.SCENARI[n]
		var lancs: Array = sc["lanc"]
		var info := "%s · %d Lancaster · %s" % [sc["ora"], lancs.size(), sc["storia"]]
		sc_box.add_child(_riga_scenario("Scenario %d · %s" % [n, sc["titolo"]], info, func(): _nuova(n, false)))
	var tv := _etichetta("SCENARI DI VOLO", "titoli", 22, C_ARANCIO)
	sc_box.add_child(tv)
	for n in [6, 7, 8, 9]:
		var sv: Dictionary = Dati.VOLI[n]
		sc_box.add_child(_riga_scenario("Scenario %d · %s" % [n, sv["titolo"]], "%s · %s" % [sv["ora"], sv["storia"]], func(): _nuova(n, false)))
	var basso := HBoxContainer.new()
	basso.add_theme_constant_override("separation", 10)
	col.add_child(basso)
	if FileAccess.file_exists(SALVA_LOCALE):
		basso.add_child(_bottone("Continua la partita salvata", _carica_locale))
	var codice := LineEdit.new()
	codice.placeholder_text = "codice online"
	codice.custom_minimum_size = Vector2(150, 0)
	codice.max_length = 6
	basso.add_child(codice)
	var esito := _etichetta("", "testo", 15, C_GRIGIO)
	basso.add_child(_bottone("Riprendi online", func(): _carica_online(codice.text.strip_edges().to_upper(), esito)))
	basso.add_child(_bottone("Regole e aiuto", func(): _aiuto()))
	col.add_child(esito)
	col.add_child(_etichetta("Versione digitale per uso personale del gioco GMT di Jeremy White (2014). Scenari d'attacco 1-5.", "testo", 13, Color(0.45, 0.47, 0.5)))

func _riga_scenario(titolo: String, testo: String, f: Callable) -> Control:
	var pc := PanelContainer.new()
	var v := VBoxContainer.new()
	pc.add_child(v)
	var b := _bottone(titolo, f, 18)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(b)
	var l := _etichetta(testo, "testo", 15, C_GRIGIO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	v.add_child(l)
	return pc

# ================================================================ partita
func _nuova(scen: int, facile: bool) -> void:
	if scen >= 6:
		var v := PartitaVolo.new()
		v.nuova_volo(scen)
		g = v
	else:
		g = Partita.new()
		g.nuova(scen, 0, facile)
	_avvia()

func _da_dati(d: Dictionary) -> void:
	g = PartitaVolo.new() if d.get("volo", false) else Partita.new()
	g.importa(d)

func is_volo() -> bool:
	return g != null and g.s.get("volo", false)

func fase_volo() -> bool:
	return is_volo() and (g.s["fase"].begins_with("v_") or g.s["fase"] == "specialisti" or (g.s["fase"] == "concluso"))

func _avvia() -> void:
	bot = Bot.new(g)
	eventi_visti = g.s["eventi"].size()
	log_visti = 0
	_costruisci_tavolo()
	_aggiorna()

func _costruisci_tavolo() -> void:
	_svuota()
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(ui)
	# barra in alto
	var barra := HBoxContainer.new()
	barra.position = Vector2(12, 8)
	barra.size = Vector2(1416, 40)
	barra.anchor_right = 1.0
	barra.offset_right = -12
	barra.add_theme_constant_override("separation", 10)
	ui.add_child(barra)
	barra.add_child(_etichetta("ENEMY COAST AHEAD", "titoli", 26, Color(0.95, 0.95, 0.95)))
	titolo_scen = _etichetta("", "serif", 21, C_GRIGIO)
	titolo_scen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titolo_scen.clip_text = true
	barra.add_child(titolo_scen)
	if is_volo():
		bottone_vista = _bottone("Mappa del bersaglio", _cambia_vista, 15)
		barra.add_child(bottone_vista)
	barra.add_child(_bottone("Aiuto", func(): _aiuto(), 15))
	barra.add_child(_bottone("Salva online", _salva_online, 15))
	barra.add_child(_bottone("Menu", _menu, 15))
	# mappa
	mappa = MappaBersaglio.new()
	mappa.position = Vector2(8, 54)
	mappa.size = Vector2(850, 838)
	mappa.anchor_bottom = 1.0
	mappa.offset_bottom = -8
	ui.add_child(mappa)
	mappa.imposta(g, fonts)
	mappa.pedina_cliccata.connect(_clic_pedina)
	if is_volo():
		mappa_volo = MappaVolo.new()
		mappa_volo.position = mappa.position
		mappa_volo.size = mappa.size
		mappa_volo.anchor_bottom = 1.0
		mappa_volo.offset_bottom = -8
		ui.add_child(mappa_volo)
		mappa_volo.imposta(g, fonts)
		mappa_volo.pedina_cliccata.connect(_clic_pedina)
		vista_volo = fase_volo()
		ultima_fase_volo = vista_volo
		_applica_vista()
	else:
		mappa_volo = null
	# colonna destra
	var dx := VBoxContainer.new()
	dx.position = Vector2(866, 54)
	dx.size = Vector2(566, 838)
	dx.anchor_right = 1.0
	dx.anchor_bottom = 1.0
	dx.offset_right = -8
	dx.offset_bottom = -8
	dx.add_theme_constant_override("separation", 6)
	ui.add_child(dx)
	scheda_diga = Control.new()
	scheda_diga.custom_minimum_size = Vector2(0, 168)
	scheda_diga.draw.connect(_disegna_diga)
	scheda_diga.tooltip_text = "Scheda della diga: livello dell'acqua (e capacità di danno), difese, ricognizione e attività.\nGli Upkeep a sinistra hanno colpito la diga, quelli a destra l'hanno mancata."
	dx.add_child(scheda_diga)
	traccia = Control.new()
	traccia.custom_minimum_size = Vector2(0, 66)
	traccia.draw.connect(_disegna_traccia)
	dx.add_child(traccia)
	var mezzo := HBoxContainer.new()
	mezzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mezzo.add_theme_constant_override("separation", 6)
	dx.add_child(mezzo)
	# squadriglia
	var ps := PanelContainer.new()
	ps.custom_minimum_size = Vector2(196, 0)
	mezzo.add_child(ps)
	var sv := ScrollContainer.new()
	sv.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ps.add_child(sv)
	squadriglia = VBoxContainer.new()
	squadriglia.add_theme_constant_override("separation", 3)
	squadriglia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(squadriglia)
	# decisioni
	var pd := PanelContainer.new()
	pd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pd.add_theme_stylebox_override("panel", _stile(Color(0.15, 0.14, 0.12), Color(0.55, 0.45, 0.25), 1, 4))
	mezzo.add_child(pd)
	var vd := VBoxContainer.new()
	vd.add_theme_constant_override("separation", 5)
	pd.add_child(vd)
	titolo_scelta = _etichetta("", "titoli", 21, C_ORO)
	vd.add_child(titolo_scelta)
	testo_scelta = RichTextLabel.new()
	testo_scelta.bbcode_enabled = true
	testo_scelta.fit_content = true
	testo_scelta.scroll_active = false
	testo_scelta.add_theme_font_size_override("normal_font_size", 15)
	testo_scelta.add_theme_font_size_override("bold_font_size", 15)
	vd.add_child(testo_scelta)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vd.add_child(sc)
	pannello_scelte = VBoxContainer.new()
	pannello_scelte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pannello_scelte.add_theme_constant_override("separation", 4)
	sc.add_child(pannello_scelte)
	dadi = Control.new()
	dadi.custom_minimum_size = Vector2(0, 74)
	dadi.draw.connect(_disegna_dadi)
	vd.add_child(dadi)
	# registro
	var pr := PanelContainer.new()
	pr.custom_minimum_size = Vector2(0, 190)
	pr.add_theme_stylebox_override("panel", _stile(Color(0.86, 0.83, 0.75), Color(0.5, 0.45, 0.35), 1, 2))
	dx.add_child(pr)
	registro = RichTextLabel.new()
	registro.scroll_following = true
	registro.add_theme_font_override("normal_font", fonts["macchina"])
	registro.add_theme_font_size_override("normal_font_size", 14)
	registro.add_theme_color_override("default_color", Color(0.15, 0.13, 0.1))
	pr.add_child(registro)

func _cambia_vista() -> void:
	vista_volo = not vista_volo
	_applica_vista()

func _applica_vista() -> void:
	if mappa_volo == null:
		return
	mappa_volo.visible = vista_volo
	mappa.visible = not vista_volo
	bottone_vista.text = "Mappa del bersaglio" if vista_volo else "Mappa di volo"
	mappa_volo.queue_redraw()
	mappa.queue_redraw()

# ================================================================ aggiornamento
func _aggiorna() -> void:
	if g == null or ui == null:
		return
	if mappa_volo != null:
		var fv := fase_volo()
		if fv != ultima_fase_volo:
			vista_volo = fv
			ultima_fase_volo = fv
			_applica_vista()
		mappa_volo.queue_redraw()
	titolo_scen.text = "%s%s" % [g.nome_scenario(), " (prima partita)" if g.s["facile"] else ""]
	# registro
	var righe: Array = g.s["log"]
	if log_visti > righe.size():
		log_visti = 0
		registro.clear()
	for i in range(log_visti, righe.size()):
		var r: String = righe[i]
		if r.begins_with("--") or r.begins_with("=="):
			registro.append_text("\n" + r + "\n")
		else:
			registro.append_text(r + "\n")
	log_visti = righe.size()
	# eventi (lampi sulle pedine)
	var ev: Array = g.s["eventi"]
	for i in range(eventi_visti, ev.size()):
		var e: Dictionary = ev[i]
		if e.has("lanc"):
			mappa.colpisci(e["lanc"])
	eventi_visti = ev.size()
	_squadriglia()
	_scelte()
	scheda_diga.queue_redraw()
	traccia.queue_redraw()
	dadi.queue_redraw()
	mappa.queue_redraw()
	if g.s["fase"] == "concluso":
		_rapporto()

func _squadriglia() -> void:
	for c in squadriglia.get_children():
		c.queue_free()
	squadriglia.add_child(_etichetta("SQUADRIGLIA", "titoli", 16, C_ARANCIO))
	for l in g.s["lanc"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 5)
		var ic := TextureRect.new()
		ic.texture = load("res://assets/pedine/%s_f.png" % l["id"])
		ic.custom_minimum_size = Vector2(38, 38)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		if l["pos"] in ["distrutto", "perso"]:
			ic.modulate = Color(0.4, 0.25, 0.25)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -3)
		h.add_child(v)
		var col := C_TESTO if l["pos"] not in ["distrutto", "perso"] else Color(0.6, 0.35, 0.35)
		v.add_child(_etichetta("%s %s%s" % [l["id"], l["pilota"], "  · Upkeep" if int(l["upkeep"]) >= 0 else ""], "grassetto", 14, col))
		var stato := _stato_lanc(l)
		v.add_child(_etichetta(stato, "testo", 13, C_GRIGIO if not g.danneggiato(l) else Color(0.9, 0.55, 0.5)))
		h.tooltip_text = mappa.testo_lanc(l)
		h.mouse_filter = Control.MOUSE_FILTER_PASS
		squadriglia.add_child(h)

func _stato_lanc(l: Dictionary) -> String:
	var dove: String = {"vicino": "Cerchio vicino", "lontano": "Cerchio lontano", "avvicinamento": "all'attacco", "scorta": "di scorta",
		"sgancio": "sgancio", "salita": "in risalita", "distrutto": "abbattuto", "partito": "rientra alla base",
		"disperso": "disperso", "a casa": "a Scampton", "perso": "perso", "prosegue": "prosegue",
		"smarrito": "fuori rotta", "rtb": "rientra alla base", "attesa": "a Scampton", "acquisizione": "trova il bersaglio",
		"in_arrivo": "in arrivo sulla diga"}.get(l["pos"], l["pos"])
	if l["pos"] == "volo":
		dove = Dati.NOME_ZONA[l["zona"]]
		if l.get("onda", "") != "":
			dove += ", in onda"
	if l.get("diga", "") != "" and l["pos"] in ["vicino", "lontano", "avvicinamento", "scorta", "sgancio", "salita", "acquisizione", "in_arrivo"] and is_volo():
		dove += " (%s)" % Dati.DIGHE[l["diga"]]["nome"]
	var t: String = Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower() + " · " + dove
	if g.danneggiato(l) and l["pos"] not in ["distrutto", "perso"]:
		t += " · danneggiato"
	return t

func _scelte() -> void:
	for c in pannello_scelte.get_children():
		c.queue_free()
	var a: Dictionary = g.s["attesa"]
	mappa.evidenzia.clear()
	if a.is_empty():
		titolo_scelta.text = "Missione conclusa" if g.s["fase"] == "concluso" else ""
		testo_scelta.text = ""
		if g.s["fase"] == "concluso":
			pannello_scelte.add_child(_bottone("Rapporto della missione", _rapporto))
			pannello_scelte.add_child(_bottone("Torna al menu", _menu))
		return
	titolo_scelta.text = a["titolo"]
	testo_scelta.text = _arricchisci(a["testo"])
	var n := 0
	for c in a["scelte"]:
		n += 1
		var b := _bottone("%d · %s" % [n, c["testo"]] if n <= 9 else c["testo"], func(): _scegli(c["id"]), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if c["nota"] != "":
			b.tooltip_text = c["nota"]
		pannello_scelte.add_child(b)
		if c["nota"] != "" and a["tipo"] != "gettone":
			var nl := _etichetta("     " + c["nota"], "testo", 13, Color(0.66, 0.64, 0.58))
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			pannello_scelte.add_child(nl)
		for l in g.s["lanc"]:
			if c["id"] == l["id"] or c["id"].ends_with(":" + l["id"]) and not c["id"].begins_with("razzo") and not c["id"].begins_with("rientra"):
				mappa.evidenzia[l["id"]] = true
	if a["tipo"] == "sgancio" or a["tipo"] == "gettone" and a.get("sgancio", false):
		pass
	var aiuto := _bottone("Decidi tu (scelta automatica)", func(): _scegli(bot.scelta()), 13)
	aiuto.modulate = Color(1, 1, 1, 0.75)
	pannello_scelte.add_child(aiuto)

func _arricchisci(t: String) -> String:
	var r := t
	if g.s["avv"].has("lanc") and g.s["fase"] in ["sg_3", "sg_1", "sg_2"]:
		pass
	return r

func _scegli(id: String) -> void:
	if g == null or g.s["attesa"].is_empty():
		return
	g.scegli(id)
	_salva_locale()
	_aggiorna()

func _clic_pedina(id: String) -> void:
	var a: Dictionary = g.s["attesa"]
	if a.is_empty():
		return
	for c in a["scelte"]:
		if c["id"] == id or (c["id"].ends_with(":" + id) and (c["id"].begins_with("vicino") or c["id"].begins_with("lontano"))):
			_scegli(c["id"])
			return

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and g != null and finestra == null:
		var k: int = e.keycode
		if k >= KEY_1 and k <= KEY_9:
			var a: Dictionary = g.s["attesa"]
			var i: int = k - KEY_1
			if not a.is_empty() and i < a["scelte"].size():
				_scegli(a["scelte"][i]["id"])
		elif k == KEY_F1:
			_aiuto()

# ================================================================ scheda della diga
func _disegna_diga() -> void:
	if g == null:
		return
	var c := scheda_diga
	var w := c.size.x
	var nd := g.diga_corrente()
	var d := g.dg(nd)
	var info: Dictionary = Dati.DIGHE[nd]
	c.draw_rect(Rect2(0, 0, w, c.size.y), Color(0.09, 0.1, 0.115))
	c.draw_rect(Rect2(0, 0, w, c.size.y), C_BORDO, false, 1.0)
	var f: Font = fonts["titoli"]
	c.draw_string(f, Vector2(12, 28), "DIGA DELLA %s" % info["nome"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	c.draw_string(fonts["testo"], Vector2(12, 48), "zona %s · valore del bacino %d rv" % [info["zona"], int(info["rv"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_GRIGIO)
	var stato := ""
	if d["breccia"]:
		stato = "BRECCIA"
	c.draw_string(fonts["grassetto"], Vector2(w - 12 - 260, 28), "danni accertati: %d su %d" % [g.danni_diga(nd), g.capacita(nd)], HORIZONTAL_ALIGNMENT_RIGHT, 260, 17, C_ORO if not d["breccia"] else C_ROSSO)
	if stato != "":
		c.draw_string(fonts["titoli"], Vector2(w - 12 - 260, 50), stato, HORIZONTAL_ALIGNMENT_RIGHT, 260, 22, C_ROSSO)
	# traccia di stato 0-4
	var x0 := 60.0
	var cw := (w - x0 - 62) / 5.0
	var y0 := 62.0
	var hh := 74.0
	c.draw_rect(Rect2(8, y0, x0 - 12, hh), Color(0.16, 0.17, 0.19))
	_testo_verticale(c, "danno", Vector2(8 + (x0 - 12) * 0.5, y0 + hh * 0.5))
	c.draw_rect(Rect2(w - 58, y0, 50, hh), Color(0.16, 0.17, 0.19))
	_testo_verticale(c, "mancati", Vector2(w - 33, y0 + hh * 0.5))
	for i in 5:
		var r := Rect2(x0 + i * cw, y0, cw - 3, hh)
		c.draw_rect(r, Color(0.2, 0.21, 0.24))
		if i >= 2:
			c.draw_rect(Rect2(r.position, Vector2(r.size.x, 18)), Color(0.55, 0.78, 0.8, 0.85))
			var cap: int = int(info["capacita"][i])
			c.draw_string(fonts["grassetto"], r.position + Vector2(4, 14), "%d %s" % [cap, Dati.ACQUA[i]], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 13, Color(0.1, 0.2, 0.22))
		c.draw_string(fonts["grassetto"], r.position + Vector2(5, hh - 6), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.75, 0.76, 0.78))
	# segnalini sulla traccia
	var segn := [["acqua", int(d["acqua"]), C_ACQUA, Color(0.1, 0.2, 0.22)], ["ricogn.", int(d["recon"]), Color(0.38, 0.39, 0.41), Color.WHITE]]
	if int(d["flak"]) > 0 or int(d["flak_iniziale"]) > 0:
		segn.append(["FLAK", int(d["flak"]), Color(0.1, 0.1, 0.1), Color.WHITE])
	if int(d["fari"]) > 0:
		segn.append(["fari", int(d["fari"]), Color(0.9, 0.9, 0.85), Color(0.1, 0.1, 0.1)])
	if int(d["palloni"]) > 0:
		segn.append(["palloni", int(d["palloni"]), Color(0.3, 0.3, 0.32), Color.WHITE])
	var att: int = int(d["attivita"])
	segn.append(["attività" + (" +5" if att >= 5 else ""), att % 5 if att >= 5 else att, Color(0.78, 0.76, 0.86), Color(0.15, 0.12, 0.25)])
	var occ := {}
	for sgn in segn:
		var lv: int = clampi(sgn[1], 0, 4)
		var k: int = occ.get(lv, 0)
		occ[lv] = k + 1
		var r := Rect2(x0 + lv * cw + 4 + (k % 2) * (cw * 0.48), y0 + 21 + (k / 2) * 20, cw * 0.46, 18)
		c.draw_rect(r, sgn[2])
		c.draw_string(fonts["grassetto"], r.position + Vector2(0, 14), sgn[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, sgn[3])
	# Upkeep a destra (mancati) e a sinistra (colpito)
	var colpiti := 0
	var mancati := 0
	for u in d["upkeep"]:
		if u["esito"] == "colpito":
			colpiti += 1
		else:
			mancati += 1
	var yb := y0 + hh + 8
	var xs := 12.0
	c.draw_string(fonts["testo"], Vector2(xs, yb + 14), "Upkeep a segno:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_GRIGIO)
	xs += 104
	for u in d["upkeep"]:
		if u["esito"] != "colpito":
			continue
		var r := Rect2(xs, yb, 26, 20)
		c.draw_rect(r, Color(0.86, 0.82, 0.72))
		var tv := "?" if int(u["valore"]) < 0 else str(int(u["valore"]))
		c.draw_string(fonts["grassetto"], r.position + Vector2(0, 16), tv, HORIZONTAL_ALIGNMENT_CENTER, 26, 15, C_ROSSO if tv != "?" else Color(0.2, 0.2, 0.2))
		xs += 30
	if colpiti == 0:
		c.draw_string(fonts["testo"], Vector2(xs, yb + 14), "nessuno", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_GRIGIO)
		xs += 60
	c.draw_string(fonts["testo"], Vector2(xs + 20, yb + 14), "mancati: %d" % mancati, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_GRIGIO)
	if d["caccia_vicino"]:
		c.draw_string(fonts["grassetto"], Vector2(w - 230, yb + 14), "caccia notturno nei paraggi", HORIZONTAL_ALIGNMENT_RIGHT, 220, 14, Color(1, 0.55, 0.45))

func _testo_verticale(c: Control, t: String, centro: Vector2) -> void:
	var f: Font = fonts["testo"]
	var wv := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	c.draw_set_transform(centro, -PI / 2, Vector2.ONE)
	c.draw_string(f, Vector2(-wv / 2, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_GRIGIO)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ================================================================ traccia dei turni d'attacco
func _disegna_traccia() -> void:
	if g == null:
		return
	var c := traccia
	var w := c.size.x
	if fase_volo():
		c.draw_rect(Rect2(0, 0, w, c.size.y), Color(0.09, 0.1, 0.115))
		var tv: int = int(g.s["turno_volo"])
		c.draw_string(fonts["titoli"], Vector2(12, 30), "TURNO DI VOLO %d · ore %s" % [tv, Dati.ORA_VOLO[tv]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		var nomi := {"v_coord": "coordinamento", "v_radio": "radiotelegrafia", "v_movi": "movimento", "v_nav": "navigazione", "v_pericoli": "pericoli",
			"v_evita": "evitare i pericoli", "v_risolvi": "risolvere i pericoli", "v_acquis": "acquisizione del bersaglio", "v_bersagli": "mappe del bersaglio", "v_pulizia": "fine del turno"}
		c.draw_string(fonts["testo"], Vector2(12, 54), "fase: %s · allerta %d" % [nomi.get(g.s["fase"], "preparazione"), int(g.s["allerta"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_GRIGIO)
		return
	var lato := (w - 150) / 8.0
	c.draw_rect(Rect2(0, 0, w, c.size.y), Color(0.09, 0.1, 0.115))
	for i in 8:
		var t := i + 1
		var r := Rect2(4 + i * lato, 4, lato - 4, c.size.y - 8)
		var att := t == int(g.s["turno"])
		c.draw_rect(r, Color(0.3, 0.27, 0.18) if att else Color(0.17, 0.18, 0.2))
		c.draw_rect(r, C_ORO if att else Color(0.35, 0.36, 0.38), false, 2.0 if att else 1.0)
		c.draw_string(fonts["grassetto"], r.position + Vector2(0, 17), "Turno %d" % t, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, C_TESTO)
		c.draw_string(fonts["testo"], r.position + Vector2(0, r.size.y - 6), ["", ":00", ":07", ":16", ":23", ":30", ":37", ":45", ":53"][t], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, C_GRIGIO)
		if t in [3, 5, 7]:
			c.draw_string(fonts["testo"], r.position + Vector2(0, 32), "visibilità", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(0.55, 0.75, 0.8))
		var k := 0
		for rz in g.s["razzi"]:
			if int(rz["turno"]) == t:
				var cc := r.position + Vector2(9 + k * 13, r.size.y - 11)
				c.draw_circle(cc, 7, Color(1, 0.95, 0.75, 0.9))
				c.draw_circle(cc, 11, Color(1, 0.9, 0.5, 0.25))
				k += 1
	var x := 4 + 8 * lato + 4
	var nebbia: bool = g.s["visibilita"] == "nebbia"
	var rv := Rect2(x, 4, w - x - 4, 28)
	c.draw_rect(rv, Color(0.55, 0.6, 0.65) if nebbia else Color(0.12, 0.25, 0.35))
	c.draw_string(fonts["titoli"], rv.position + Vector2(0, 21), "nebbia" if nebbia else "sereno", HORIZONTAL_ALIGNMENT_CENTER, rv.size.x, 18, Color(0.1, 0.1, 0.12) if nebbia else Color(0.85, 0.92, 1))
	var ra := Rect2(x, 36, w - x - 4, 26)
	c.draw_rect(ra, Color(0.12, 0.12, 0.13) if int(g.s["allerta"]) < 4 else C_ROSSO)
	c.draw_string(fonts["grassetto"], ra.position + Vector2(0, 19), "allerta %d" % int(g.s["allerta"]), HORIZONTAL_ALIGNMENT_CENTER, ra.size.x, 15, C_TESTO)

# ================================================================ dadi
func _disegna_dadi() -> void:
	if g == null:
		return
	var c := dadi
	var d: Dictionary = g.s["dadi"]
	c.draw_rect(Rect2(0, 0, c.size.x, c.size.y), Color(0.1, 0.095, 0.085))
	if d.is_empty():
		c.draw_string(fonts["testo"], Vector2(10, 40), "I tiri di dado compaiono qui.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_GRIGIO)
		return
	c.draw_string(fonts["testo"], Vector2(10, 18), d["etichetta"], HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 20, 14, C_GRIGIO)
	var vals: Array = d["valori"]
	var ten: Array = d["tenuti"]
	for i in vals.size():
		var tenuto := ten.is_empty() or i in ten or float(i) in ten
		_dado(c, Vector2(12 + i * 48, 26), 40, int(vals[i]), tenuto)
	var es := str(d["esito"])
	var spazio: float = c.size.x - 30 - vals.size() * 48
	var fs := 22
	while fs > 11 and fonts["titoli"].get_string_size(es, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > spazio:
		fs -= 1
	c.draw_string(fonts["titoli"], Vector2(20 + vals.size() * 48, 56), es, HORIZONTAL_ALIGNMENT_LEFT, spazio, fs, C_ORO)

func _dado(c: Control, p: Vector2, s: float, v: int, tenuto: bool) -> void:
	var fondo := Color(0.93, 0.91, 0.86) if tenuto else Color(0.45, 0.44, 0.42)
	c.draw_rect(Rect2(p, Vector2(s, s)), fondo)
	c.draw_rect(Rect2(p, Vector2(s, s)), Color(0.2, 0.2, 0.2), false, 1.5)
	var pips := {1: [[0.5, 0.5]], 2: [[0.25, 0.25], [0.75, 0.75]], 3: [[0.25, 0.25], [0.5, 0.5], [0.75, 0.75]],
		4: [[0.25, 0.25], [0.75, 0.25], [0.25, 0.75], [0.75, 0.75]],
		5: [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
		6: [[0.25, 0.22], [0.75, 0.22], [0.25, 0.5], [0.75, 0.5], [0.25, 0.78], [0.75, 0.78]]}
	for q in pips.get(v, []):
		c.draw_circle(p + Vector2(q[0], q[1]) * s, s * 0.09, Color(0.1, 0.1, 0.1) if tenuto else Color(0.2, 0.2, 0.2))

# ================================================================ rapporto finale
func _rapporto() -> void:
	if finestra != null:
		return
	var e: Dictionary = g.s["esito"]
	var v := _finestra("Rapporto della missione", 1000 if is_volo() else 760, 760 if is_volo() else 600)
	v.add_child(_etichetta(g.nome_scenario(), "serif", 20, C_GRIGIO))
	var t := _etichetta(str(e.get("titolo", "")).to_upper(), "titoli", 44, C_ORO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var nd: String = g.s["diga"]
	var riass := "Diga della %s: %s. Danni %d su %d." % [Dati.DIGHE[nd]["nome"], "BRECCIA" if e.get("breccia", false) else "regge", int(e.get("danni", 0)), int(e.get("capacita", 0))]
	if int(g.s["scen"]) == 5:
		riass = "Ennepe: danni %d · Bever: danni %d." % [g.danni_diga("ennepe"), g.danni_diga("bever")]
	if is_volo():
		var rotte: Array = e.get("dighe_rotte", [])
		riass = ("Dighe aperte: %s (%d rv)." % [", ".join(rotte), int(e.get("rv", 0))]) if not rotte.is_empty() else "Nessuna diga aperta."
		riass += " Lancaster perduti: %d." % int(e.get("persi", 0))
	v.add_child(_etichetta(riass, "grassetto", 18, C_TESTO))
	if not is_volo():
		v.add_child(_etichetta("Lancaster rientrati: %d · che proseguono: %d · Upkeep ancora a bordo: %d" % [int(e.get("rientrati", 0)), int(e.get("proseguono", 0)), int(e.get("upkeep", 0))], "testo", 16, C_GRIGIO))
	var gr := GridContainer.new()
	gr.columns = 2 if e.get("righe", []).size() > 9 else 1
	gr.add_theme_constant_override("h_separation", 24)
	v.add_child(gr)
	for r in e.get("righe", []):
		gr.add_child(_etichetta("· " + str(r), "testo", 15 if gr.columns == 2 else 16, C_TESTO))
	var sp := _etichetta(str(e.get("spiega", "")), "serif", 18, Color(0.8, 0.78, 0.7))
	sp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sp)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_bottone("Rigioca lo scenario", func(): _nuova(int(g.s["scen"]), g.s["facile"])))
	h.add_child(_bottone("Menu", _menu))
	h.add_child(_bottone("Guarda la mappa", _chiudi))

# ================================================================ finestre
func _finestra(titolo: String, w: int, h: int) -> VBoxContainer:
	_chiudi()
	finestra = Control.new()
	finestra.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(finestra)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	finestra.add_child(velo)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	finestra.add_child(cc)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _stile(Color(0.12, 0.13, 0.15), C_ORO, 2, 6))
	pc.custom_minimum_size = Vector2(mini(w, int(radice.size.x) - 20), mini(h, int(radice.size.y) - 20))
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var testa := HBoxContainer.new()
	v.add_child(testa)
	var tt := _etichetta(titolo, "titoli", 24, C_ARANCIO)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	testa.add_child(tt)
	testa.add_child(_bottone("Chiudi", _chiudi, 14))
	return v

func _chiudi() -> void:
	if finestra != null:
		finestra.queue_free()
		finestra = null

func _aiuto() -> void:
	var v := _finestra("Regole e aiuto", 1080, 780)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tabs)
	var testi: Dictionary = Aiuto.CAPITOLI
	for k in testi:
		var r := RichTextLabel.new()
		r.name = k
		r.bbcode_enabled = true
		r.text = testi[k]
		r.add_theme_font_size_override("normal_font_size", 16)
		r.add_theme_font_size_override("bold_font_size", 16)
		tabs.add_child(r)

# ================================================================ salvataggi
func _salva_locale() -> void:
	if g == null:
		return
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(g.esporta()))

func _carica_locale() -> void:
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_da_dati(d)
		_avvia()

func _salva_online() -> void:
	if g == null:
		return
	var v := _finestra("Salva online", 560, 220)
	var l := _etichetta("Salvataggio in corso...", "testo", 17, C_TESTO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var dati := {"nome": g.nome_scenario().substr(0, 60), "turno": int(g.s["turno"]), "aggiornata": int(Time.get_unix_time_from_system())}
	dati.merge(g.esporta())
	var ok: bool = await net.salva_partita(g.s["codice"], dati)
	if ok:
		l.text = "Partita salvata. Codice: %s\nScrivilo nel menu («Riprendi online») per riprenderla da qualsiasi dispositivo." % g.s["codice"]
	else:
		if net.ultimo_errore.contains("401") or net.ultimo_errore.to_lower().contains("permission"):
			l.text = "Salvataggio online non riuscito: Firebase non ha ancora le regole per questo gioco (radice enemycoastahead). Vanno aggiornate incollando firebase/database.rules.json della ludoteca nella console di Firebase.\nLa partita resta salvata su questo dispositivo."
		else:
			l.text = "Salvataggio non riuscito: %s\nLa partita resta salvata su questo dispositivo." % net.ultimo_errore

func _carica_online(codice: String, esito: Label) -> void:
	if codice.length() != 6:
		esito.text = "Il codice ha 6 caratteri."
		return
	esito.text = "Caricamento..."
	var d = await net.carica_partita(codice)
	if d == null:
		esito.text = "Partita non trovata (%s)." % net.ultimo_errore
		return
	_da_dati(d)
	_avvia()
