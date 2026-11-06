## Giocatore automatico: decisioni semplici e ragionevoli. Serve per le prove senza grafica
## e per il pulsante «Decidi tu» dell'interfaccia.
class_name Bot
extends RefCounted

var p: Partita

func _init(partita: Partita) -> void:
	p = partita

func scelta() -> String:
	var a: Dictionary = p.s["attesa"]
	if a.is_empty():
		return ""
	var ids: Array = a["scelte"].map(func(c): return c["id"])
	var s: Dictionary = p.s
	match a["tipo"]:
		"corsa":
			var migliore := ""
			var punti := -99
			for id in ids:
				if id == "nessuno":
					continue
				var l := p.lanc(id)
				var v: int = p.addestramento(l) - (3 if p.danneggiato(l) else 0)
				if v > punti:
					punti = v
					migliore = id
			return migliore if migliore != "" else ids[0]
		"scorta":
			if int(p.dg()["flak"]) >= 2 and ids.size() > 1 and s["avv"]["scorte"].size() < 1:
				return ids[0]
			return "basta"
		"luci":
			return "si" if int(p.dg()["flak"]) <= 3 else "no"
		"vettore":
			var migliore: String = ids[0]
			var meno := 99
			for id in ids:
				var v: Dictionary = p._vettore(int(id))
				if int(v["S"]) + int(v["A"]) < meno:
					meno = int(v["S"]) + int(v["A"])
					migliore = id
			return migliore
		"gettone":
			var migliore: String = ids[0]
			var punti := -99
			for id in ids:
				var g := Dati.gettone(id)
				var v: int = int(g["mod"]) * 2 - (3 if g["m"] and p.s["avv"]["diga"] == "eder" else 0) if a.get("sgancio", false) else int(g["n"])
				if v > punti:
					punti = v
					migliore = id
			return migliore
		"regola":
			for t in ["q", "v"]:
				if t in ids:
					var g: String = s["avv"][t]
					if g == "" or int(Dati.gettone(g)["n"]) <= 1:
						return t
			return "no"
		"decisione":
			if a["zona"] == "lontana":
				return "avanti"
			if a["zona"] == "vicina":
				if p.s["avv"]["diga"] == "eder":
					return "sgancia"
				return "avanti" if int(p.dg()["flak"]) <= 2 or p.s["avv"]["v"] == "" else "sgancia"
			return "sgancia"
		"flak_bersaglio":
			return ids[ids.size() - 1]
		"flak_evasione":
			var t := p.lanc(s["flak"]["bersaglio"])
			if p.danneggiato(t):
				for x in ["scorta", "v", "q"]:
					if x in ids:
						return x
			return "subisci"
		"giro":
			for id in ids:
				if id.begins_with("vicino:"):
					return id
			for id in ids:
				if id.begins_with("razzo:") and s["razzi"].is_empty() and p.s["visibilita"] == "nebbia":
					return id
			return "fine"
	if "si" in ids:
		return "si"
	return ids[0]

## Gioca da solo fino alla fine (o fino a un massimo di decisioni).
func gioca(max_mosse := 3000) -> int:
	var n := 0
	while not p.s["attesa"].is_empty() and n < max_mosse:
		p.scegli(scelta())
		n += 1
	return n
