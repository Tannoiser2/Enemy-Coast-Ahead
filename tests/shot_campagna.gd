## xvfb-run godot --path . --script res://tests/shot_campagna.gd
extends SceneTree
var main
var n := 0
var foto := {}
func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1440, 900)
func _scatta(nome: String) -> void:
	root.get_texture().get_image().save_png("/tmp/ecac_%s.png" % nome)
	print("screenshot ", nome)
func _process(_d: float) -> bool:
	n += 1
	if n == 5: _scatta("menu")
	if n == 7:
		var v := PartitaCampagna.new()
		v.nuova_campagna(4242)
		main.g = v
		main._avvia()
	if n == 12: _scatta("inizio")
	if n > 14 and main.g.s["fase"] != "concluso" and n < 3000:
		var f: String = main.g.s["fase"]
		for k in ["p_add", "p_mod", "p_rec", "f_sortita", "v_movi"]:
			if f == k and not foto.has(k) and int(main.g.s.get("piano", 1)) >= 2:
				foto[k] = true
				_scatta(k)
		if not main.g.s["attesa"].is_empty():
			main._scegli(main.bot.scelta())
	if (n >= 3000 or (n > 14 and main.g.s["fase"] == "concluso")) and not has_meta("fine"):
		set_meta("fine", n)
	if has_meta("fine") and n == int(get_meta("fine")) + 6:
		_scatta("fine")
		return true
	return false
