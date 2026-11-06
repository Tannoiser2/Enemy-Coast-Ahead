extends SceneTree
func _init() -> void:
	for f in ["res://scripts/dati.gd", "res://scripts/partita.gd", "res://scripts/bot.gd", "res://scripts/aiuto.gd", "res://scripts/mappa.gd", "res://scripts/net.gd", "res://scripts/main.gd"]:
		var sc = load(f)
		print(f, " ", sc != null)
	quit()
