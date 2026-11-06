extends SceneTree
func _init() -> void:
	var p := PartitaVolo.new()
	p.nuova_volo(int(OS.get_environment("SCEN")) if OS.get_environment("SCEN") != "" else 6, 104735)
	var bot := Bot.new(p)
	var n := 0
	var ultimo := 0
	while not p.s["attesa"].is_empty() and n < 400:
		var a = p.s["attesa"]
		var c := bot.scelta()
		print("[%s/%s] %s -> %s" % [p.s["fase"], a["tipo"], a["titolo"], c])
		p.scegli(c)
		for i in range(ultimo, p.s["log"].size()): print("   ", p.s["log"][i])
		ultimo = p.s["log"].size()
		n += 1
	print("FINE fase=", p.s["fase"], " fine=", p.s["fine"])
	quit()
