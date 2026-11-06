## Base delle mappe: disegno in coordinate della tela (W x H), adattato al controllo, con zoom (rotella),
## trascinamento (tasto destro o centrale, o sinistro sullo sfondo) e doppio clic per tornare alla vista della fase.
class_name Tavola
extends Control

var W := 1000.0
var H := 1000.0
var scala := 1.0
var origine := Vector2.ZERO
var vista := Rect2()          # parte della tela da inquadrare (vuota = tutta)
var zoom := 1.0
var spost := Vector2.ZERO
var _trascina := false
var _da := Vector2.ZERO
var _mosso := false
var fonts := {}
var tex := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "
	clip_contents = true
	resized.connect(queue_redraw)

func _tex(nome: String) -> Texture2D:
	if not tex.has(nome):
		var path := "res://assets/" + nome
		tex[nome] = load(path) if ResourceLoader.exists(path) else null
	return tex[nome]

func imposta_vista(r: Rect2) -> void:
	if r != vista:
		vista = r
		zoom = 1.0
		spost = Vector2.ZERO
		queue_redraw()

func azzera_zoom() -> void:
	zoom = 1.0
	spost = Vector2.ZERO
	queue_redraw()

func calcola() -> void:
	var v := vista if vista.size != Vector2.ZERO else Rect2(0, 0, W, H)
	var s0 := minf(size.x / v.size.x, size.y / v.size.y)
	scala = s0 * zoom
	# centro della vista al centro del controllo, più lo spostamento dell'utente
	origine = size * 0.5 - (v.position + v.size * 0.5) * scala + spost
	# non lasciare uscire la tela dal riquadro
	var tw := W * scala
	var th := H * scala
	if tw <= size.x:
		origine.x = clampf(origine.x, 0, size.x - tw) if zoom > 1.0 else origine.x
	else:
		origine.x = clampf(origine.x, size.x - tw, 0)
	if th <= size.y:
		origine.y = clampf(origine.y, 0, size.y - th) if zoom > 1.0 else origine.y
	else:
		origine.y = clampf(origine.y, size.y - th, 0)

func a_tela(pt: Vector2) -> Vector2:
	return (pt - origine) / scala

func inizia() -> void:
	calcola()
	draw_set_transform(origine, 0.0, Vector2(scala, scala))

func finisci() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Testo con transform locale (centro c in coordinate tela, rotazione in gradi).
func testo(f: String, t: String, c: Vector2, sz: int, col: Color, gradi := 0.0, centrato := true, ombra := true) -> void:
	var fo: Font = fonts[f]
	var w := fo.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var off := Vector2(-w * 0.5 if centrato else 0.0, sz * 0.35)
	draw_set_transform(origine + c * scala, deg_to_rad(gradi), Vector2(scala, scala))
	if ombra:
		draw_string(fo, off + Vector2(1.5, 1.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.65 * col.a))
	draw_string(fo, off, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform(origine, 0.0, Vector2(scala, scala))

## Segnalino quadrato in stile cartoncino, con una o due righe di testo.
func segnalino(c: Vector2, lato: float, righe: Array, fondo: Color, inchiostro: Color, gradi := 0.0) -> void:
	draw_set_transform(origine + c * scala, deg_to_rad(gradi), Vector2(scala, scala))
	var r := Rect2(-Vector2(lato, lato) * 0.5, Vector2(lato, lato))
	draw_rect(Rect2(r.position + Vector2(lato * 0.05, lato * 0.07), r.size), Color(0, 0, 0, 0.5))
	draw_rect(r, fondo)
	draw_rect(r.grow(-lato * 0.04), inchiostro.lerp(fondo, 0.55), false, maxf(1.0, lato * 0.03))
	var n := righe.size()
	var sz := int(lato * (0.3 if n <= 1 else 0.24))
	for i in n:
		var t: String = righe[i]
		var s2 := sz
		while s2 > 6 and fonts["grassetto"].get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x > lato * 0.9:
			s2 -= 1
		var y := (i - (n - 1) * 0.5) * sz * 1.1 + s2 * 0.36
		draw_string(fonts["grassetto"], Vector2(-lato * 0.5, y), t, HORIZONTAL_ALIGNMENT_CENTER, lato, s2, inchiostro)
	draw_set_transform(origine, 0.0, Vector2(scala, scala))

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var prima := a_tela(mb.position)
			var f := 1.15 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
			zoom = clampf(zoom * f, 1.0, 6.0)
			calcola()
			# il punto sotto il cursore resta fermo
			var dopo := origine + prima * scala
			spost += mb.position - dopo
			if zoom <= 1.0:
				spost = Vector2.ZERO
			queue_redraw()
			accept_event()
			return
		if mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] or (mb.button_index == MOUSE_BUTTON_LEFT and zoom > 1.0):
			if mb.pressed:
				_trascina = true
				_mosso = false
				_da = mb.position
			else:
				_trascina = false
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			azzera_zoom()
	elif e is InputEventMouseMotion and _trascina:
		var mm := e as InputEventMouseMotion
		if mm.position.distance_to(_da) > 3:
			_mosso = true
		spost += mm.relative
		queue_redraw()
	elif e is InputEventMagnifyGesture:
		zoom = clampf(zoom * (e as InputEventMagnifyGesture).factor, 1.0, 6.0)
		queue_redraw()
	elif e is InputEventPanGesture:
		spost -= (e as InputEventPanGesture).delta * 12.0
		queue_redraw()

## Vero se l'ultimo clic sinistro era un trascinamento (per non cliccare per sbaglio le pedine).
func era_trascinamento() -> bool:
	return _mosso
