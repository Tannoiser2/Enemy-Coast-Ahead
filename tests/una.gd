extends SceneTree
func _init() -> void:
	var scen := int(OS.get_environment("SCEN")) if OS.get_environment("SCEN") != "" else 1
	var p := Partita.new()
	p.nuova(scen, int(OS.get_environment("SEME")) if OS.get_environment("SEME") != "" else 5)
	var bot := Bot.new(p)
	while not p.s["attesa"].is_empty():
		var a = p.s["attesa"]
		var c := bot.scelta()
		p.s["log"].append("    >> [%s] %s -> %s" % [a["tipo"], a["titolo"], c])
		p.scegli(c)
	for r in p.s["log"]: print(r)
	print(p.s["esito"])
	quit()
