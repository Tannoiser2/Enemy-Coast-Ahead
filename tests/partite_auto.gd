## Partite automatiche complete: godot --headless --script res://tests/partite_auto.gd
extends SceneTree

func _init() -> void:
	var conta := {}
	var errori := 0
	var semi := int(OS.get_environment("SEMI")) if OS.get_environment("SEMI") != "" else 40
	for scen in [1, 2, 3, 4, 5]:
		for facile in ([false, true] if scen == 5 else [false]):
			for seme in range(1, semi + 1):
				var p := Partita.new()
				p.nuova(scen, seme * 7919 + scen, facile)
				var bot := Bot.new(p)
				var mosse := 0
				# a metà partita: salvataggio in JSON e ricarica
				while not p.s["attesa"].is_empty() and mosse < 4000:
					p.scegli(bot.scelta())
					mosse += 1
					if mosse == 25:
						var js := JSON.stringify(p.esporta())
						var q := Partita.new()
						q.importa(JSON.parse_string(js))
						p = q
						bot = Bot.new(p)
				if p.s["fase"] != "concluso" or p.s["fine"] == "errore":
					errori += 1
					print("ERRORE scen %d seme %d: fase %s fine %s attesa %s" % [scen, seme, p.s["fase"], p.s["fine"], str(p.s["attesa"].get("tipo", ""))])
					for r in p.s["log"].slice(-12): print("   ", r)
					continue
				var k := "S%d%s %s" % [scen, " facile" if facile else "", p.s["esito"]["titolo"]]
				conta[k] = conta.get(k, 0) + 1
	var chiavi := conta.keys()
	chiavi.sort()
	for k in chiavi:
		print(k, ": ", conta[k])
	print("errori: ", errori)
	quit(1 if errori > 0 else 0)
