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
	if a["tipo"].begins_with("p_") or a["tipo"].begins_with("f_"):
		return _campagna(a["tipo"], ids, s)
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
		"v_coord":
			for id in ids:
				if (id.begins_with("coord:") or id.begins_with("unisci:")) and not id.ends_with(":v"):
					return id
			return "fine"
		"v_very":
			return "si"
		"v_radio":
			for id in ids:
				if id == "fine":
					continue
				var c: Dictionary = p.capo_gruppo(id)
				if not c.is_empty() and s["dighe"][c["primario"]]["breccia"]:
					return id
			return "fine"
		"v_radio_diga":
			var c: Dictionary = p.capo_gruppo(a["gruppo"])
			if c.get("secondario", "") in ids:
				return c["secondario"]
			if s["riserva"] in ids:
				return s["riserva"]
			return ids[0]
		"v_movi":
			return "fine"
		"v_evita":
			for pref in ["aereo", "cannone", "tralicci", "città", "palloni", "fari", "pericolo"]:
				for c in a["scelte"]:
					if c["id"].begins_with("t:") and c["testo"].contains(pref):
						return c["id"]
			return "fine"
		"v_flak_ea":
			var l: Dictionary = p.lanc(s["flak_volo"]["l"])
			return "si" if p.danneggiato(l) else "no"
		"v_acquis":
			return "ostinato" if int(s["turno_volo"]) >= 6 else "aspetta"
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

## Campagna: un piano semplice (tre o quattro squadre, una quindicina di equipaggi, radio e mirino, foto delle dighe).
func _campagna(tipo: String, ids: Array, s: Dictionary) -> String:
	var rp: int = int(s["rp"])
	var ded := func(box: String) -> String:
		for id in ids:
			if id.begins_with("dedica:") and id.ends_with(":" + box):
				return id
		return ""
	match tipo:
		"p_req":
			for q in ["s5", "s6", "s3", "s1"]:
				if ("squadra:" + q) in ids and s["squadre"].size() < 4 and rp >= 15:
					return "squadra:" + q
			var d: String = ded.call("requisizioni")
			if d != "" and p.dedicate("requisizioni").is_empty():
				return d
			var eq: Dictionary = s["equipaggi"]
			var tot: int = int(eq["recluta"]) + int(eq["esperto"]) + int(eq["veterano"])
			if tot < 14:
				var voglio := "veterano" if int(eq["veterano"]) < 5 else ("esperto" if int(eq["esperto"]) < 6 else "recluta")
				if ("equip:" + voglio) in ids and rp >= 12:
					return "equip:" + voglio
			var integri: int = s["aerei"].filter(func(x): return int(x["danni"]) == 0).size()
			var up: int = s["upkeep_scorta"].size()
			if "upkeep" in ids and up < integri + 3 and up <= integri and rp >= 3:
				return "upkeep"
			if "lanc" in ids and integri < maxi(tot, 6) + 2 and rp >= 4:
				return "lanc"
			if "upkeep" in ids and up < integri + 3 and rp >= 3:
				return "upkeep"
			if "rp" in ids and rp < 20 and int(s["richieste"]) < 2:
				return "rp"
			return "fine"
		"p_sic":
			if "gira:polizia" in ids and s["spia"] and rp >= 5:
				return "gira:polizia"
			if "gioca:polizia" in ids and rp >= 15:
				return "gioca:polizia"
			if "gioca:tirpitz" in ids:
				return "gioca:tirpitz"
			return "fine"
		"p_add":
			var d: String = ded.call("addestramento")
			if d != "" and p.dedicate("addestramento").is_empty():
				return d
			if "via" in ids:
				return "via"
			var meglio := ""
			var basso := 99
			for c in ["quota", "bomba", "nav"]:
				if c in ids:
					var v := 0
					for e in s["addestramento"]:
						v += int(s["addestramento"][e][c])
					if v < basso:
						basso = v
						meglio = c
			return meglio if meglio != "" else ids[0]
		"p_mod":
			for box in ["radio", "cabina", "altimetro", "riparazioni"]:
				var d: String = ded.call(box)
				if d != "" and p.dedicate(box).is_empty():
					return d
			for box in ["cabina", "radio", "altimetro"]:
				if ("dado:" + box) in ids and rp >= 25 and int(s["mod_dadi"][box]) < 3:
					return "dado:" + box
			return "via"
		"p_mod_rit":
			for id in ids:
				if id.begins_with("ritira:") and int(s["piano"]) >= 3:
					return id
			return "tieni"
		"p_rec":
			for z in ["costa_olandese", "ruhr", "weser"]:
				if ("zona:" + z) in ids and rp >= 22 and int(s["recon_zone"][z]) < 2:
					return "zona:" + z
			for dg in ["mohne", "eder", "sorpe"]:
				if ("diga:" + dg) in ids and rp >= 4 and int(s["dighe"][dg]["recon"]) < 3:
					return "diga:" + dg
			return "fine"
		"p_lancio":
			return "lancia" if int(s["piano"]) >= 3 else "attendi"
		"f_aerei", "f_ordigni":
			var box := tipo.substr(2)
			if p.dedicate(box).size() < (s["squadre"].size() + 1) / 2:
				for id in ids:
					if id.begins_with("dedica:"):
						return id
			return "via"
		"f_sortita":
			if "auto" in ids:
				return "auto"
			if "decolla" in ids:
				return "decolla"
	if "via" in ids:
		return "via"
	if "fine" in ids:
		return "fine"
	return ids[ids.size() - 1]
