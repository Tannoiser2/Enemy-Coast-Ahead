## Gioca tutti gli scenari attraverso l'interfaccia (con la grafica): xvfb-run godot --path . --script res://tests/ui_flussi.gd
extends SceneTree

var main
var n := 0
var scen := 1
var fatte := 0
var errori := 0

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1440, 900)

func _process(_d: float) -> bool:
	n += 1
	if n < 4:
		return false
	if main.g == null:
		if scen > 6:
			print("partite completate: ", fatte)
			return true
		main._nuova(scen if scen <= 5 else 5, scen == 6)
		return false
	if main.g.s["fase"] == "concluso":
		if n % 3 == 0:
			var img: Image = root.get_texture().get_image()
			img.save_png("/tmp/eca_ui_%d.png" % scen)
			print("scenario %d: %s" % [scen, main.g.s["esito"]["titolo"]])
			fatte += 1
			scen += 1
			main._menu()
		return false
	if main.finestra == null and n % 2 == 0:
		# a volte clicca una pedina evidenziata, di solito sceglie come il bot
		var a: Dictionary = main.g.s["attesa"]
		if not main.mappa.evidenzia.is_empty() and n % 6 == 0:
			main._clic_pedina(main.mappa.evidenzia.keys()[0])
		elif not a.is_empty():
			main._scegli(main.bot.scelta())
	if n % 50 == 0 and main.finestra == null:
		main._aiuto()
	elif n % 50 == 2:
		main._chiudi()
	return false
