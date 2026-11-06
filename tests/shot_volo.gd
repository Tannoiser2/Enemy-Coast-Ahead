## xvfb-run godot --path . --script res://tests/shot_volo.gd
extends SceneTree
var main
var n := 0
var fatto_bersaglio := false
func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1440, 900)
func _scatta(nome: String) -> void:
	root.get_texture().get_image().save_png("/tmp/ecav_%s.png" % nome)
	print("screenshot ", nome)
func _process(_d: float) -> bool:
	n += 1
	var scen := int(OS.get_environment("SCEN")) if OS.get_environment("SCEN") != "" else 7
	if n == 5: _scatta("menu")
	if n == 7:
		var v := PartitaVolo.new()
		v.nuova_volo(scen, 777)
		main.g = v
		main._avvia()
	if n == 12: _scatta("inizio")
	if n > 14 and n < 400 and main.g.s["fase"] != "concluso":
		if not main.g.s["attesa"].is_empty():
			main._scegli(main.bot.scelta())
		if n == 40: _scatta("volo")
		if not fatto_bersaglio and not main.fase_volo() and main.g.s["fase"] != "concluso" and int(main.g.s["turno"]) >= 3:
			fatto_bersaglio = true
			_scatta("bersaglio")
	if n == 400 or (n > 14 and main.g.s["fase"] == "concluso" and not has_meta("fine")):
		set_meta("fine", n)
	if has_meta("fine") and n == int(get_meta("fine")) + 6:
		_scatta("fine")
		return true
	return false
