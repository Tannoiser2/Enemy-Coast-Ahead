## Campagne automatiche: godot --headless --script res://tests/campagna_auto.gd
extends SceneTree

func _init() -> void:
	var conta := {}
	var errori := 0
	var semi := int(OS.get_environment("SEMI")) if OS.get_environment("SEMI") != "" else 20
	var mostra := OS.get_environment("MOSTRA") != ""
	for seme in range(1, semi + 1):
		var p := PartitaCampagna.new()
		p.nuova_campagna(seme * 7919 + 3)
		var bot := Bot.new(p)
		var mosse := 0
		while not p.s["attesa"].is_empty() and mosse < 30000:
			p.scegli(bot.scelta())
			mosse += 1
			if mosse % 97 == 0:
				var q := PartitaCampagna.new()
				q.importa(JSON.parse_string(JSON.stringify(p.esporta())))
				p = q
				bot = Bot.new(p)
		if p.s["fase"] != "concluso" or p.s["fine"] == "errore":
			errori += 1
			print("ERRORE seme %d: fase %s fine %s attesa %s mosse %d" % [seme, p.s["fase"], p.s["fine"], str(p.s["attesa"].get("tipo", "")), mosse])
			for r in p.s["log"].slice(-25): print("   ", r)
			continue
		if mostra and seme == 1:
			for r in p.s["log"]: print(r)
		var k: String = p.s["esito"]["titolo"]
		conta[k] = conta.get(k, 0) + 1
		var rotte: Array = p.s["esito"]["dighe_rotte"]
		var kk := "brecce: " + ",".join(rotte)
		conta[kk] = conta.get(kk, 0) + 1
		conta["partiti %d" % p.s["lanc"].size()] = conta.get("partiti %d" % p.s["lanc"].size(), 0) + 1
	var chiavi := conta.keys()
	chiavi.sort()
	for k in chiavi:
		print(k, ": ", conta[k])
	print("errori: ", errori)
	quit(1 if errori > 0 else 0)
