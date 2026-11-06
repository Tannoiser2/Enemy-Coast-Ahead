## Partite automatiche degli scenari di volo: godot --headless --script res://tests/voli_auto.gd
extends SceneTree

func _init() -> void:
	var conta := {}
	var errori := 0
	var semi := int(OS.get_environment("SEMI")) if OS.get_environment("SEMI") != "" else 15
	var mostra := OS.get_environment("MOSTRA") != ""
	for scen in [6, 7, 8, 9]:
		for seme in range(1, semi + 1):
			var p := PartitaVolo.new()
			p.nuova_volo(scen, seme * 104729 + scen)
			var bot := Bot.new(p)
			var mosse := 0
			while not p.s["attesa"].is_empty() and mosse < 20000:
				p.scegli(bot.scelta())
				mosse += 1
				if mosse == 40:
					var js := JSON.stringify(p.esporta())
					var q := PartitaVolo.new()
					q.importa(JSON.parse_string(js))
					p = q
					bot = Bot.new(p)
			if p.s["fase"] != "concluso" or p.s["fine"] == "errore":
				errori += 1
				print("ERRORE scen %d seme %d: fase %s fine %s attesa %s mosse %d" % [scen, seme, p.s["fase"], p.s["fine"], str(p.s["attesa"].get("tipo", "")), mosse])
				for r in p.s["log"].slice(-15): print("   ", r)
				continue
			if mostra and seme == 1:
				for r in p.s["log"]: print(r)
			var k := "S%d %s" % [scen, p.s["esito"]["titolo"]]
			conta[k] = conta.get(k, 0) + 1
			var rotte: Array = p.s["esito"]["dighe_rotte"]
			conta["S%d brecce: %s" % [scen, ",".join(rotte)]] = conta.get("S%d brecce: %s" % [scen, ",".join(rotte)], 0) + 1
	var chiavi := conta.keys()
	chiavi.sort()
	for k in chiavi:
		print(k, ": ", conta[k])
	print("errori: ", errori)
	quit(1 if errori > 0 else 0)
