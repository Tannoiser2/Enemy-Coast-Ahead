## Screenshot di prova: xvfb-run godot --path . --script res://tests/screenshot.gd
extends SceneTree

var main
var n := 0

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1440, 900)

func _scatta(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("/tmp/eca_%s.png" % nome)
	print("screenshot ", nome)

func _process(_d: float) -> bool:
	n += 1
	var scen := int(OS.get_environment("SCEN")) if OS.get_environment("SCEN") != "" else 1
	var passi := int(OS.get_environment("PASSI")) if OS.get_environment("PASSI") != "" else 4
	if n == 6: _scatta("menu")
	if n == 8:
		main.g = Partita.new()
		main.g.nuova(scen, 12345, false)
		main._avvia()
	if n == 14: _scatta("inizio")
	if n == 16:
		for i in passi:
			if not main.g.s["attesa"].is_empty():
				main._scegli(main.bot.scelta())
	if n == 40: _scatta("gioco")
	if n == 42: main._aiuto()
	if n == 46: _scatta("aiuto")
	if n == 48:
		main._chiudi()
		main.bot.gioca()
		main._aggiorna()
	if n == 56: _scatta("fine")
	if n == 58: return true
	return false
