## Scenari di volo 6-9 (regole 6.0-7.10): mappa di volo, onde, navigazione, pericoli, acquisizione del bersaglio
## e attacchi alle dighe con il motore degli scenari d'attacco (una diga alla volta, nella fase della mappa del bersaglio).
class_name PartitaVolo
extends Partita

const POS_BERSAGLIO := ["vicino", "lontano", "avvicinamento", "scorta", "sgancio", "salita"]

# ================================================================ nuova partita
func nuova_volo(scen: int, seme: int = 0) -> void:
	var sc: Dictionary = Dati.VOLI[scen]
	if seme == 0:
		seme = int(Time.get_unix_time_from_system() * 1000.0) % 2000000000 + 7
	s = {
		"versione": 1, "scen": scen, "volo": true, "facile": false, "seme": seme, "rng": seme * 2654435761 % 4294967296 + 1,
		"turno_volo": int(sc["turno"]), "turno": 1, "giri_8": 0, "turni": 0, "malus_rtb": 0,
		"visibilita": "sereno", "allerta": int(sc["allerta"]), "mod_visibilita": 0,
		"diga": "mohne", "dighe": {}, "razzi": [], "lanc": [], "coppe": {"q": [], "v": []},
		"avv": {}, "flak": {}, "rilasciati_turno": 0, "caccia_attacco": false, "nebbia_di_guerra": false,
		"fase": "specialisti", "attesa": {}, "log": [], "dadi": {}, "fine": "", "esito": {}, "codice": _codice(seme),
		"usati": {}, "tiro_ripetuto": {}, "eventi": [],
		"onde": {}, "recon_zone": {"costa_olandese": 2, "ruhr": 2, "weser": 2}, "riserva": sc["riserva"],
		"tazze": {}, "pendenti": [], "allarme_turno": false, "tm": {}, "brecce_turno": [], "caccia_volo": 0,
	}
	for d in Dati.DIGHE:
		s["dighe"][d] = {"acqua": 4, "recon": int(sc["dighe_recon"].get(d, 1)), "attivita": int(sc.get("attivita", {}).get(d, 0)),
			"flak": 3 if d == "mohne" else 0, "fari": 0, "palloni": 0, "upkeep": [], "breccia": false, "caccia_vicino": false,
			"flak_iniziale": 3 if d == "mohne" else 0, "visibilita": "sereno"}
	for g in Dati.GETTONI_QUOTA:
		s["coppe"]["q"].append(g["id"])
	for g in Dati.GETTONI_VELOCITA:
		s["coppe"]["v"].append(g["id"])
	for colore in Dati.TAZZE:
		var t := []
		for i in Dati.TAZZE[colore].size():
			t.append(i)
		s["tazze"][colore] = t
	var sacco := []
	for i in Dati.UPKEEP.size():
		sacco.append(i)
	_mescola(sacco)
	var forze: Array = sc["forze"]
	if scen == 9:
		forze = Dati.VOLI[6]["forze"] + Dati.VOLI[7]["forze"] + Dati.VOLI[8]["forze"]
		s["radio_turno"] = 5
	for f in forze:
		var oid := ""
		if f["onda"] != "":
			oid = "O%d" % s["onde"].size()
			s["onde"][oid] = {"nome": f["onda"], "capo": f["capo"], "buona": true, "membri": []}
		for x in f["lanc"]:
			var l := {"id": x[0], "pilota": Dati.LANCASTER[x[0]]["pilota"], "equip": x[1], "upkeep": sacco.pop_back(),
				"danni": 0, "pos": "attesa" if int(f["entra"]) > int(sc["turno"]) else "volo", "zona": "inghilterra",
				"elite": "", "candidati": x[2], "segnalino": "", "razzo": false, "inizio_vicino": false, "esito": "",
				"onda": oid, "primario": f["primario"], "secondario": f["secondario"], "guasti": [], "diga": "",
				"entra": int(f["entra"]), "entrata": "", "arrivo": 0}
			if f.get("bussola", false):
				l["guasti"].append("bussola")
			s["lanc"].append(l)
			if oid != "":
				s["onde"][oid]["membri"].append(x[0])
	if sc.get("danno_sorpe", false) or scen == 9:
		if sc.get("danno_sorpe", false):
			s["dighe"]["sorpe"]["upkeep"].append({"u": sacco.pop_back(), "esito": "colpito", "valore": -1, "lanc": "AJ-T", "rivelato": false, "precedente": true})
	s["sacco"] = sacco
	_log("== %s ==" % sc["titolo"])
	_log("Scampton, ore %s. Turno di volo %d. Allerta %d." % [sc["ora"], s["turno_volo"], s["allerta"]])
	avanza()

func importa(d: Dictionary) -> void:
	super.importa(d)

# ================================================================ interrogazioni
func scenario() -> Dictionary:
	return Dati.VOLI[int(s["scen"])]

func lanc_in(pos: String) -> Array:
	if pos in POS_BERSAGLIO:
		return s["lanc"].filter(func(l): return l["pos"] == pos and l.get("diga", "") == s["diga"])
	return s["lanc"].filter(func(l): return l["pos"] == pos)

func sulla_mappa() -> Array:
	return s["lanc"].filter(func(l): return in_mappa(l) and l.get("diga", "") == s["diga"])

func in_volo(l: Dictionary) -> bool:
	return l["pos"] in ["volo", "smarrito"]

func vivo(l: Dictionary) -> bool:
	return l["pos"] not in ["distrutto", "perso", "a casa"]

func zona_diga(d: String) -> String:
	return "ruhr" if Dati.DIGHE[d]["zona"] == "Ruhr" else "weser"

func ora() -> String:
	var h: String = String(Dati.ORA_VOLO[clampi(int(s["turno_volo"]), 1, Dati.ORA_VOLO.size() - 1)]).substr(0, 2)
	return h + super.ora()

func nav(l: Dictionary) -> int:
	return Dati.navigazione(livello(l, "nav"))

## Gruppi: le onde e i Lancaster indipendenti in volo (non nel rientro, non sulle mappe del bersaglio).
func gruppi() -> Array:
	var r := []
	for oid in s["onde"]:
		var o: Dictionary = s["onde"][oid]
		var m := membri(oid)
		if m.size() >= 1:
			r.append("O:" + oid)
	for l in s["lanc"]:
		if in_volo(l) and l["onda"] == "":
			r.append("L:" + l["id"])
	return r

func membri(oid: String) -> Array:
	return s["lanc"].filter(func(l): return l["onda"] == oid and in_volo(l))

func lanc_gruppo(g: String) -> Array:
	if g.begins_with("O:"):
		return membri(g.substr(2))
	var l := lanc(g.substr(2))
	return [l] if not l.is_empty() and in_volo(l) else []

func capo_gruppo(g: String) -> Dictionary:
	if g.begins_with("O:"):
		var o: Dictionary = s["onde"][g.substr(2)]
		var c := lanc(o["capo"])
		if not c.is_empty() and c["onda"] == g.substr(2) and in_volo(c):
			return c
		var m := membri(g.substr(2))
		return m[0] if not m.is_empty() else {}
	return lanc(g.substr(2))

func nome_gruppo(g: String) -> String:
	if g.begins_with("O:"):
		var o: Dictionary = s["onde"][g.substr(2)]
		return "%s (%s)" % [o["nome"], ", ".join(membri(g.substr(2)).map(func(x): return x["id"]))]
	return nome_l(lanc(g.substr(2)))

func zona_gruppo(g: String) -> String:
	var c := capo_gruppo(g)
	return c["zona"] if not c.is_empty() else ""

func onda_buona(g: String) -> bool:
	return g.begins_with("O:") and s["onde"][g.substr(2)]["buona"]

## Un'onda con meno di due Lancaster si scioglie (6.7.1); se manca il capo ne subentra un altro (6.7.5).
func _sistema_onde() -> void:
	for oid in s["onde"]:
		var o: Dictionary = s["onde"][oid]
		var m := membri(oid)
		if m.size() < 2:
			for l in m:
				l["onda"] = ""
			for l in s["lanc"]:
				if l["onda"] == oid and not in_volo(l):
					l["onda"] = ""
			continue
		var c := lanc(o["capo"])
		if c.is_empty() or c["onda"] != oid or not in_volo(c):
			o["capo"] = m[0]["id"]
			_log("%s guida ora la %s." % [m[0]["id"], o["nome"].to_lower()])

func _rendi_indipendente(l: Dictionary) -> void:
	l["onda"] = ""
	_sistema_onde()

# ================================================================ motore
## Il cane di Gibson non entra nei riquadri del rientro e dei dispersi: passa a un altro Lancaster in volo [13.0].
func _sposta_jinx() -> void:
	for l in s["lanc"]:
		if l.get("jinx", false) and l["pos"] in ["rtb", "smarrito", "distrutto", "perso"]:
			var altri: Array = s["lanc"].filter(func(x): return x["pos"] == "volo" and x["id"] != l["id"])
			l.erase("jinx")
			if altri.is_empty():
				_log("Il cane di Gibson resta a terra: nessun altro Lancaster in volo.")
			else:
				var n: Dictionary = altri[_rng() % altri.size()]
				n["jinx"] = true
				_log("Il cane di Gibson passa da %s a %s." % [l["id"], n["id"]])
			return

func _passo() -> void:
	if s["fase"].begins_with("v_"):
		_sposta_jinx()
	match s["fase"]:
		"specialisti":
			_f_specialisti()
			if s["fase"] == "inizio":
				s["fase"] = "v_inizio"
		"v_inizio": _v_inizio()
		"v_coord": _v_coord()
		"v_radio": _v_radio()
		"v_movi": _v_movimento()
		"v_nav": _v_navigazione()
		"v_pericoli": _v_piazza()
		"v_evita": _v_evita()
		"v_risolvi": _v_risolvi()
		"v_acquis": _v_acquisizione()
		"v_bersagli": _v_bersagli()
		"v_pulizia": _v_pulizia()
		_:
			super._passo()

func _applica(a: Dictionary, id: String) -> void:
	match a["tipo"]:
		"v_coord":
			if id == "fine":
				s["fase"] = "v_radio"
			else:
				_esegui_coord(id)
		"v_radio":
			if id == "fine":
				s["fase"] = "v_movi"
			else:
				s["radio_gruppo"] = id
		"v_radio_diga":
			_esegui_radio(a["gruppo"], id)
		"v_movi":
			if id == "fine":
				s["movi_scelto"] = true
			else:
				_scelta_movimento(id)
		"v_evita":
			if id == "fine":
				s["evita_zone_fatte"].append(a["zona"])
			else:
				_togli_pericolo(id, a["zona"])
		"v_flak_ea":
			s["flak_volo"]["ea"] = id
		"v_acquis":
			s["acq_scelta"] = {"gruppo": a["gruppo"], "id": id}
		"v_very":
			s["very_scelta"] = id
		_:
			super._applica(a, id)

# ================================================================ inizio del turno di volo
func _v_inizio() -> void:
	var t: int = int(s["turno_volo"])
	_log("== Turno di volo %d (ore %s) ==" % [t, Dati.ORA_VOLO[t]])
	s["allarme_turno"] = false
	s["brecce_turno"] = []
	s["radio_fatti"] = []
	s["coord_fatti"] = []
	for l in s["lanc"]:
		if l["pos"] == "attesa" and int(l["entra"]) <= t:
			l["pos"] = "volo"
			l["zona"] = "inghilterra"
			_log("%s decolla da Scampton." % nome_l(l))
	s["fase"] = "v_coord" if t > int(scenario()["turno"]) else "v_movi"

# ================================================================ 7.1 coordinamento (F1)
func _v_coord() -> void:
	if not s.get("vhf", true):
		s["fase"] = "v_radio"
		return
	var sc := []
	var per_zona := {}
	for g in gruppi():
		var c := capo_gruppo(g)
		if c.is_empty() or c["pos"] != "volo":
			continue
		per_zona[c["zona"]] = per_zona.get(c["zona"], []) + [g]
	for z in per_zona:
		var gs: Array = per_zona[z]
		var ostile: bool = Dati.PERICOLI_ZONA[z][2]
		for g in gs:
			if g.begins_with("O:") and not onda_buona(g) and not _radio_rotta(g):
				sc.append(_sc("coord:" + g, "Riordina la %s" % s["onde"][g.substr(2)]["nome"].to_lower(), "Se riesce l'onda torna in buon ordine."))
				sc.append(_sc("coord:" + g + ":v", "Riordina la %s con un razzo Very" % s["onde"][g.substr(2)]["nome"].to_lower(), "Il capo spara un razzo: +1 al tiro%s." % (", ma un pericolo in più in questa zona" if ostile else "")))
		var ind := gs.filter(func(x): return x.begins_with("L:") and not _radio_rotta(x))
		var onde := gs.filter(func(x): return x.begins_with("O:") and not _radio_rotta(x))
		for i in ind:
			var l := lanc(i.substr(2))
			if int(l["upkeep"]) < 0:
				continue
			for o in onde:
				if capo_gruppo(o)["primario"] == l["primario"]:
					sc.append(_sc("unisci:%s:%s" % [i, o], "%s si unisce alla %s" % [l["id"], s["onde"][o.substr(2)]["nome"].to_lower()]))
					sc.append(_sc("unisci:%s:%s:v" % [i, o], "%s si unisce alla %s, con un razzo Very" % [l["id"], s["onde"][o.substr(2)]["nome"].to_lower()], "Il capo dell'onda spara un razzo: +1 al tiro%s." % (", ma un pericolo in più in questa zona" if ostile else "")))
			for j in ind:
				if j > i:
					var m := lanc(j.substr(2))
					if int(m["upkeep"]) >= 0 and m["primario"] == l["primario"]:
						sc.append(_sc("crea:%s:%s" % [i, j], "%s e %s formano una nuova onda" % [l["id"], m["id"]]))
	sc = sc.filter(func(x): return not s.get("coord_fatti", []).has(x["id"].trim_suffix(":v")))
	if sc.is_empty():
		s["fase"] = "v_radio"
		return
	sc.append(_sc("fine", "Fine del coordinamento"))
	_chiedi("v_coord", "Coordinamento", "Si possono riordinare le onde, unire Lancaster isolati a un'onda o formarne una nuova: 2 dadi contro la peggiore abilità di navigazione dei Lancaster coinvolti.", sc)

func _radio_rotta(g: String) -> bool:
	for l in lanc_gruppo(g):
		if ha_guasto(l, "radio"):
			return true
	return false

func _esegui_coord(id: String) -> void:
	if not s.has("coord_fatti"):
		s["coord_fatti"] = []
	var very := id.ends_with(":v")
	id = id.trim_suffix(":v")
	s["coord_fatti"].append(id)
	var p := id.split(":")
	var coinvolti := []
	if p[0] == "coord":
		coinvolti = lanc_gruppo(p[1] + ":" + p[2])
	elif p[0] == "unisci":
		coinvolti = lanc_gruppo(p[1] + ":" + p[2]) + lanc_gruppo(p[3] + ":" + p[4])
	else:
		coinvolti = lanc_gruppo(p[1] + ":" + p[2]) + lanc_gruppo(p[3] + ":" + p[4])
	var peggiore := 0
	for l in coinvolti:
		peggiore = maxi(peggiore, nav(l))
	var mod := 0
	var capo: Dictionary = coinvolti[0]
	if p[0] != "crea":
		var g: String = (p[1] + ":" + p[2]) if p[0] == "coord" else (p[3] + ":" + p[4])
		capo = capo_gruppo(g)
	if capo["equip"] == "veterano":
		mod += 1
	if very:
		mod += 1
		s["very_volo"] = s.get("very_volo", []) + [capo["zona"]]
		_log("%s spara un razzo Very per radunare gli aerei." % capo["id"])
	var dd := _dadi(2)
	var ok: bool = dd[0] + dd[1] + mod >= peggiore
	_mostra_dadi("Coordinamento: serve %d" % peggiore, dd, [], "riuscito" if ok else "fallito")
	match p[0]:
		"coord":
			if ok:
				s["onde"][p[2]]["buona"] = true
			_log("Riordino della %s: %d+%d%s contro %d: %s." % [s["onde"][p[2]]["nome"].to_lower(), dd[0], dd[1], (" %+d" % mod) if mod else "", peggiore, "l'onda torna in buon ordine" if ok else "resta scompaginata"])
		"unisci":
			var l := lanc(p[2])
			if ok:
				l["onda"] = p[4]
				l["secondario"] = capo["secondario"]
			_log("%s cerca di unirsi alla %s: %s." % [l["id"], s["onde"][p[4]]["nome"].to_lower(), "ci riesce" if ok else "non la trova nel buio"])
		"crea":
			var a := lanc(p[2])
			var b := lanc(p[4])
			if ok:
				var oid := "O%d" % s["onde"].size()
				s["onde"][oid] = {"nome": "Onda di %s" % a["pilota"], "capo": a["id"], "buona": true, "membri": [a["id"], b["id"]]}
				a["onda"] = oid
				b["onda"] = oid
			_log("%s e %s cercano di volare insieme: %s." % [a["id"], b["id"], "nasce una nuova onda" if ok else "non si trovano"])
	s["fase"] = "v_coord"

# ================================================================ 7.2 radiotelegrafia (F2)
func _radio_permessa() -> bool:
	var sc := scenario()
	if s.has("radio_turno") or sc.has("radio_turno"):
		return int(s["turno_volo"]) >= int(s.get("radio_turno", sc.get("radio_turno", 0)))
	if sc.has("radio_da"):
		return s["dighe"][sc["radio_da"]]["breccia"] or int(s["caccia_volo"]) > 0
	return true

func _v_radio() -> void:
	if not _radio_permessa():
		s["fase"] = "v_movi"
		return
	if s.has("radio_gruppo"):
		var g: String = s["radio_gruppo"]
		s.erase("radio_gruppo")
		var sc := []
		var cap := capo_gruppo(g)
		for d in Dati.DIGHE:
			if not s["dighe"][d]["breccia"] and d != cap.get("primario", ""):
				sc.append(_sc(d, "Nuovo bersaglio: %s" % Dati.DIGHE[d]["nome"], "zona %s, ricognizione %d" % [Dati.DIGHE[d]["zona"], int(s["dighe"][d]["recon"])]))
		sc.append(_sc("annulla", "Nessun messaggio"))
		_chiedi("v_radio_diga", "Radiotelegrafo", "Quale nuovo bersaglio principale trasmettere a %s?" % nome_gruppo(g), sc, {"gruppo": g})
		return
	var sc2 := []
	for g in gruppi():
		if _radio_rotta(g) or s.get("radio_fatti", []).has(g):
			continue
		var c := capo_gruppo(g)
		if c.is_empty() or int(c["upkeep"]) < 0 and g.begins_with("L:"):
			continue
		sc2.append(_sc(g, "Messaggio a %s" % nome_gruppo(g), "Bersaglio attuale: %s." % Dati.DIGHE[c["primario"]]["nome"] if c.get("primario", "") != "" else ""))
	if sc2.is_empty():
		s["fase"] = "v_movi"
		return
	sc2.append(_sc("fine", "Nessun altro messaggio"))
	_chiedi("v_radio", "Radiotelegrafia", "Da Grantham si può assegnare un nuovo bersaglio principale a un'onda o a un Lancaster: il messaggio può arrivare, essere disturbato o frainteso.", sc2)

func _esegui_radio(g: String, diga: String) -> void:
	if not s.has("radio_fatti"):
		s["radio_fatti"] = []
	s["radio_fatti"].append(g)
	if diga == "annulla":
		return
	if senza_vhf() and g.begins_with("O:") and lanc_gruppo(g).size() > 1:
		# senza VHF il messaggio va a ogni Lancaster singolarmente [10.4.4]: l'onda cambia rotta solo se lo ricevono tutti
		var esiti := []
		var tutti := true
		for l in lanc_gruppo(g):
			var dd := _dadi(3) if ruolo(l) == "marconista" else _dadi(2)
			if dd.size() == 3:
				dd.sort()
				dd = [dd[1], dd[2]]
			var r: int = dd[0] + dd[1]
			esiti.append("%s %d" % [l["id"], r])
			if r < 8:
				tutti = false
		_mostra_dadi("Radiotelegrafia senza VHF", [], [], "ricevuto" if tutti else "non da tutti")
		if tutti:
			_imposta_bersaglio(g, diga)
			_log("Senza VHF, messaggio a ogni Lancaster (%s): ricevuto da tutti, %s punta sulla %s." % [", ".join(esiti), nome_gruppo(g), Dati.DIGHE[diga]["nome"]])
		else:
			s["radio_fatti"].erase(g)
			_log("Senza VHF, messaggio a ogni Lancaster (%s): non tutti lo ricevono in chiaro, l'onda mantiene la rotta." % ", ".join(esiti))
		return
	var bonus := 0
	while true:
		var c := capo_gruppo(g)
		var dd := _dadi(3) if ruolo(c) == "marconista" else _dadi(2)
		if dd.size() == 3:
			dd.sort()
			dd = [dd[1], dd[2]]
		var r: int = dd[0] + dd[1] + bonus
		_mostra_dadi("Radiotelegrafia", dd, [], str(r))
		if r <= 4:
			_log("Messaggio a %s: %d, non ricevuto." % [nome_gruppo(g), r])
			s["radio_fatti"].erase(g)
			return
		if r == 7:
			_log("Messaggio a %s: %d, disturbato: si ritrasmette (+1)." % [nome_gruppo(g), r])
			bonus += 1
			continue
		if r <= 6:
			var x := d6()
			var nuova := ""
			if x == 1:
				for l in lanc_gruppo(g):
					l["pos"] = "rtb"
				_log("Messaggio frainteso (%d, dado %d): %s rientra alla base!" % [r, x, nome_gruppo(g)])
				return
			elif x <= 3:
				nuova = _diga_ricognizione(true)
			elif x <= 5:
				nuova = _diga_ricognizione(false)
			else:
				nuova = s["riserva"]
			_imposta_bersaglio(g, nuova)
			_log("Messaggio frainteso (%d, dado %d): %s punta sulla %s." % [r, x, nome_gruppo(g), Dati.DIGHE[nuova]["nome"]])
			return
		_imposta_bersaglio(g, diga)
		_log("Messaggio ricevuto (%d): %s punta sulla %s." % [r, nome_gruppo(g), Dati.DIGHE[diga]["nome"]])
		return

func _diga_ricognizione(minima: bool) -> String:
	var migliore := ""
	var v := 99 if minima else -1
	for d in Dati.DIGHE:
		if s["dighe"][d]["breccia"]:
			continue
		var r: int = int(s["dighe"][d]["recon"])
		if (minima and r < v) or (not minima and r > v):
			v = r
			migliore = d
	return migliore if migliore != "" else s["riserva"]

func _imposta_bersaglio(g: String, d: String) -> void:
	for l in lanc_gruppo(g):
		if l["primario"] != d:
			l["secondario"] = l["primario"] if l["secondario"] == "" and not s["dighe"][l["primario"]]["breccia"] else l["secondario"]
		l["primario"] = d

# ================================================================ 7.3 movimento (F3)
func _v_movimento() -> void:
	if not s.get("movi_scelto", false):
		var sc := []
		for l in s["lanc"]:
			if l["pos"] == "volo" and int(l["upkeep"]) >= 0:
				var motivo := ""
				if danneggiato(l): motivo = "danneggiato"
				elif ha_guasto(l, "merlin"): motivo = "motore Merlin guasto"
				elif ha_guasto(l, "no_aldis"): motivo = "luci Aldis guaste"
				elif ha_guasto(l, "radio"): motivo = "radio rotta"
				if motivo != "" and not l.get("rifiuta_rtb", false):
					sc.append(_sc("rtb:" + l["id"], "%s rientra alla base (%s)" % [l["id"], motivo], "Con l'Upkeep a bordo: torna verso l'Inghilterra."))
		if int(s["turno_volo"]) >= 7:
			for g in gruppi():
				var c := capo_gruppo(g)
				if not c.is_empty() and c["pos"] == "volo" and c["primario"] != s["riserva"] and int(c["upkeep"]) >= 0 and not s["dighe"][s["riserva"]]["breccia"]:
					sc.append(_sc("riserva:" + g, "%s punta sul bersaglio di riserva (%s)" % [nome_gruppo(g), Dati.DIGHE[s["riserva"]]["nome"]]))
				if not c.is_empty() and c["pos"] == "volo":
					sc.append(_sc("rientra:" + g, "%s rinuncia e rientra alla base" % nome_gruppo(g)))
		if not sc.is_empty():
			sc.append(_sc("fine", "Procedi con il movimento"))
			_chiedi("v_movi", "Movimento", "Prima di muovere: qualche Lancaster rientra o cambia rotta?", sc)
			return
	s["movi_scelto"] = false
	for l in s["lanc"]:
		l.erase("rifiuta_rtb")
	_muovi_tutti()
	s["fase"] = "v_nav"

func _scelta_movimento(id: String) -> void:
	var p := id.split(":")
	match p[0]:
		"rtb":
			var l := lanc(p[1])
			l["pos"] = "rtb"
			_rendi_indipendente(l)
			_log("%s rientra alla base con l'Upkeep a bordo." % nome_l(l))
		"riserva":
			_imposta_bersaglio(p[1] + ":" + p[2], s["riserva"])
			_log("%s punta sulla %s." % [nome_gruppo(p[1] + ":" + p[2]), Dati.DIGHE[s["riserva"]]["nome"]])
		"rientra":
			for l in lanc_gruppo(p[1] + ":" + p[2]):
				l["pos"] = "rtb"
			_log("%s rientra alla base." % nome_gruppo(p[1] + ":" + p[2]))

func _muovi_tutti() -> void:
	# chi non ha più l'Upkeep rientra (tranne il capo di un'onda)
	for l in s["lanc"]:
		if l["pos"] == "volo" and int(l["upkeep"]) < 0:
			var capo: bool = l["onda"] != "" and s["onde"][l["onda"]]["capo"] == l["id"] and membri(l["onda"]).size() >= 2
			if not capo:
				l["pos"] = "rtb"
				_rendi_indipendente(l)
				_log("%s, senza Upkeep, entra nel rientro alla base." % l["id"])
	for g in gruppi():
		var m := lanc_gruppo(g)
		if m.is_empty():
			continue
		var c := capo_gruppo(g)
		if c["pos"] != "volo":
			continue
		# partenza ritardata: resta fermo (e lascia l'onda)
		for l in m:
			if ha_guasto(l, "ritardo"):
				l["guasti"].erase("ritardo")
				l["fermo"] = true
				if l["onda"] != "":
					_rendi_indipendente(l)
				_log("%s, partenza ritardata: non si muove in questo turno." % l["id"])
		if c.get("fermo", false):
			c = capo_gruppo(g)
			if c.is_empty() or c.get("fermo", false):
				continue
		var dest := zona_diga(c["primario"])
		var i: int = Dati.ZONE.find(c["zona"])
		var j: int = Dati.ZONE.find(dest)
		var nuovo := i + (1 if j > i else (-1 if j < i else 0))
		if nuovo == i:
			continue
		var z: String = Dati.ZONE[nuovo]
		var mossi := []
		for l in m:
			if l["pos"] == "volo" and not l.get("fermo", false):
				l["zona"] = z
				mossi.append(l["id"])
		if not mossi.is_empty():
			_log("%s: %s." % [", ".join(mossi), Dati.NOME_ZONA[z]])
	for l in s["lanc"]:
		l.erase("fermo")

# ================================================================ 7.4 navigazione (F4)
func _mod_navigazione(g: String) -> int:
	var m := 0
	var c := capo_gruppo(g)
	if ruolo(c) == "navigatore":
		m += 1
	var fari := 0
	if s.get("senza_luna", false):
		m -= 1
	for l in lanc_gruppo(g):
		m -= conta_guasti(l, "errore")
		if ha_guasto(l, "bussola") and int(l["upkeep"]) >= 0:
			m -= 1
		fari = maxi(fari, int(l.get("fari_n", 0)))
	return m - fari

func _controllo_nav(g: String, perche: String) -> bool:
	var c := capo_gruppo(g)
	var mod := _mod_navigazione(g)
	var dd := _dadi(2)
	var ok: bool = dd[0] + dd[1] + mod >= nav(c)
	_mostra_dadi("Navigazione di %s: serve %d" % [c["id"], nav(c)], dd, [], "in rotta" if ok else "fuori rotta")
	_log("%s di %s: %d+%d%s contro %d: %s." % [perche, nome_gruppo(g), dd[0], dd[1], (" %+d" % mod) if mod else "", nav(c), "riuscito" if ok else "fallito"])
	return ok

func _esito_nav(g: String, ok: bool) -> void:
	var m := lanc_gruppo(g)
	if m.is_empty():
		return
	if g.begins_with("O:"):
		var o: Dictionary = s["onde"][g.substr(2)]
		if ok:
			return
		if o["buona"]:
			o["buona"] = false
			_log("La %s perde la formazione." % o["nome"].to_lower())
		else:
			var x: Dictionary = m[_rng() % m.size()]
			_rendi_indipendente(x)
			_log("%s si perde e vola da solo." % x["id"])
		return
	var l: Dictionary = m[0]
	if l["pos"] == "smarrito":
		if ok:
			l["pos"] = "volo"
			_log("%s ritrova la rotta." % l["id"])
		else:
			_tabella_dispersi(l)
	elif not ok:
		l["pos"] = "smarrito"
		_log("%s è fuori rotta: finisce tra i dispersi della zona." % l["id"])

func _tabella_dispersi(l: Dictionary) -> void:
	var mods := _mod_rientro(l, _zona_rtb(l["zona"]))
	var tot := 0
	for x in mods:
		tot += int(x[1])
	var dd := _dadi(2)
	var r: int = dd[0] + dd[1] + tot
	_mostra_dadi("Tabella dei dispersi: %s" % l["id"], dd, [], str(r))
	if r <= 4:
		l["pos"] = "perso"
		l["esito"] = "disperso in azione (M.I.A.)"
		_log("%s non ritrova la rotta (%d): disperso in azione." % [l["id"], r])
	elif r == 5:
		l["pos"] = "volo"
		_log("%s ritrova la rotta per caso (%d)." % [l["id"], r])
	elif r <= 9:
		if danneggiato(l):
			if d6() <= 4:
				l["pos"] = "perso"
				l["esito"] = "precipitato"
				_log("%s, già danneggiato, precipita (%d)." % [l["id"], r])
				return
		l["danni"] = 1
		l["pos"] = "rtb"
		_log("%s rinuncia e rientra danneggiato (%d)." % [l["id"], r])
	else:
		l["pos"] = "rtb"
		_log("%s rinuncia e rientra (%d)." % [l["id"], r])

func _v_navigazione() -> void:
	for g in gruppi():
		var c := capo_gruppo(g)
		if c.is_empty() or c["zona"] == "inghilterra":
			continue
		_esito_nav(g, _controllo_nav(g, "Navigazione"))
	_sistema_onde()
	s["fase"] = "v_pericoli"

# ================================================================ 7.5 pericoli (F5)
func _pesca_pericolo(colore: String) -> int:
	var t: Array = s["tazze"][colore]
	if t.is_empty():
		for i in Dati.TAZZE[colore].size():
			var in_uso := false
			for p in s["pendenti"]:
				if p["colore"] == colore and int(p["i"]) == i:
					in_uso = true
			if not in_uso:
				t.append(i)
	_mescola(t)
	return t.pop_back()

func _v_piazza() -> void:
	s["pendenti"] = []
	for z in Dati.ZONE:
		var info: Array = Dati.PERICOLI_ZONA[z]
		if int(info[0]) == 0:
			continue
		var gs := gruppi().filter(func(g): return zona_gruppo(g) == z)
		if gs.is_empty():
			continue
		var n: int = int(info[0])
		if info[2]:
			n += gs.size() + int(s["allerta"])
			var nv: int = s.get("very_volo", []).count(z)
			if nv > 0:
				n += nv
				_log("%s: %d pericolo in più per i razzi Very." % [Dati.NOME_ZONA[z], nv])
		if z == "costa_inglese" and int(s.get("extra_costa", 0)) > 0 and int(s.get("turno_volo", 1)) == 1:
			n += int(s["extra_costa"])
			_log("Aerei poco pronti: %d pericoli in più sulla costa inglese." % int(s["extra_costa"]))
		for k in n:
			var i := _pesca_pericolo(info[1])
			s["pendenti"].append({"g": gs[k % gs.size()], "colore": info[1], "i": i, "zona": z})
		for g in gs:
			for l in lanc_gruppo(g):
				if l.get("jinx", false):
					s["pendenti"].append({"g": g, "colore": info[1], "i": _pesca_pericolo(info[1]), "zona": z, "diretto": l["id"]})
					_log("Il cane di Gibson è a bordo di %s: un pericolo in più." % l["id"])
		_log("%s: %d pericoli." % [Dati.NOME_ZONA[z], n])
	s["evita_zone_fatte"] = []
	s["fase"] = "v_evita"

func fronte(p: Dictionary) -> String:
	return Dati.TAZZE[p["colore"]][int(p["i"])][0]

func tipo(p: Dictionary) -> String:
	return Dati.TAZZE[p["colore"]][int(p["i"])][1]

func valore(p: Dictionary) -> int:
	return int(Dati.TAZZE[p["colore"]][int(p["i"])][2])

func _nome_fronte(f: String) -> String:
	return {"?": "pericolo ignoto", "aereo": "sagoma d'aereo", "cannone": "cannone", "fari": "fascio di luce", "palloni": "palloni", "tralicci": "tralicci", "città": "tetti"}.get(f, f)

## 7.6: si tolgono tanti pericoli quanto la ricognizione della zona (solo zone ostili, non i gialli).
func _v_evita() -> void:
	# caccia e contraerea noti sullo stesso gruppo: il caccia si ritira
	var con_flak := {}
	for p in s["pendenti"]:
		if fronte(p) == "cannone":
			con_flak[p["g"]] = true
	var resta := []
	for p in s["pendenti"]:
		if fronte(p) == "aereo" and con_flak.has(p["g"]):
			s["tazze"][p["colore"]].append(int(p["i"]))
			_log("Contraerea amica: il caccia segnalato su %s si tiene alla larga." % nome_gruppo(p["g"]))
		else:
			resta.append(p)
	s["pendenti"] = resta
	for z in ["costa_olandese", "ruhr", "weser"]:
		if z in s["evita_zone_fatte"]:
			continue
		var qui := []
		for k in s["pendenti"].size():
			if s["pendenti"][k]["zona"] == z:
				qui.append(k)
		var tolti: int = int(s.get("tolti_" + z, 0))
		var rec: int = int(s["recon_zone"].get(z, 0))
		var sc := []
		if tolti < rec:
			for k in qui:
				var p: Dictionary = s["pendenti"][k]
				sc.append(_sc("t:%d" % k, "Evita: %s su %s" % [_nome_fronte(fronte(p)), nome_gruppo(p["g"])]))
		for k in qui:
			var p: Dictionary = s["pendenti"][k]
			for l in lanc_gruppo(p["g"]):
				if ruolo(l) == "pilota_evasione" and not s["usati"].has(l["elite"]):
					sc.append(_sc("j:%d:%s" % [k, l["id"]], "%s schiva e zigzaga: %s su %s" % [l["pilota"], _nome_fronte(fronte(p)), nome_gruppo(p["g"])], "Una volta per partita."))
		if sc.is_empty():
			s["evita_zone_fatte"].append(z)
			continue
		sc.append(_sc("fine", "Nessun'altra evasione in %s" % Dati.NOME_ZONA[z]))
		_chiedi("v_evita", "Evitare i pericoli: %s" % Dati.NOME_ZONA[z], "La ricognizione della zona (livello %d) permette di evitare %d pericoli: ne restano %d. Si vede solo il fronte dei segnalini." % [rec, rec, maxi(0, rec - tolti)], sc, {"zona": z})
		return
	for z in ["costa_olandese", "ruhr", "weser"]:
		s.erase("tolti_" + z)
	s["coda"] = []
	s["fase"] = "v_risolvi"

func _togli_pericolo(id: String, z: String) -> void:
	var p := id.split(":")
	var k := int(p[1])
	var x: Dictionary = s["pendenti"][k]
	s["tazze"][x["colore"]].append(int(x["i"]))
	s["pendenti"].remove_at(k)
	if p[0] == "j":
		s["usati"][lanc(p[2])["elite"]] = true
		_log("%s schiva un pericolo (%s)." % [lanc(p[2])["pilota"], _nome_fronte(fronte(x))])
	else:
		s["tolti_" + z] = int(s.get("tolti_" + z, 0)) + 1
		_log("Evitato un pericolo in %s (%s)." % [Dati.NOME_ZONA[z], _nome_fronte(fronte(x))])

# ================================================================ 7.7 risoluzione (F7)
func _v_risolvi() -> void:
	s["very_volo"] = []
	if s.has("flak_volo"):
		_flak_volo_passo()
		return
	if s["coda"].is_empty() and not s.get("coda_pronta", false):
		# distribuzione: per ogni gruppo, i pericoli si dividono fra i suoi Lancaster (al massimo 3 a testa)
		var per_g := {}
		for p in s["pendenti"]:
			per_g[p["g"]] = per_g.get(p["g"], []) + [p]
		for g in per_g:
			var m := lanc_gruppo(g)
			if m.is_empty():
				for p in per_g[g]:
					s["tazze"][p["colore"]].append(int(p["i"]))
				continue
			var conta := {}
			var k := 0
			for p in per_g[g]:
				if p.has("diretto") and vivo(lanc(p["diretto"])):
					# il pericolo del cane di Gibson va dritto al suo Lancaster, fuori dai limiti [13.0]
					s["coda"].append({"l": p["diretto"], "colore": p["colore"], "i": p["i"], "g": g})
					continue
				var l: Dictionary = m[k % m.size()]
				k += 1
				if conta.get(l["id"], 0) >= 3:
					s["tazze"][p["colore"]].append(int(p["i"]))
					continue
				conta[l["id"]] = conta.get(l["id"], 0) + 1
				s["coda"].append({"l": l["id"], "colore": p["colore"], "i": p["i"], "g": g})
		# le fotoelettriche valgono per tutto il gruppo durante la fase
		var nfari := {}
		for q in s["coda"]:
			if tipo(q) == "fari":
				nfari[q["g"]] = nfari.get(q["g"], 0) + 1
		for g in nfari:
			for l in lanc_gruppo(g):
				l["fari"] = true
				l["fari_n"] = nfari[g]
		s["pendenti"] = []
		s["coda_pronta"] = true
	while not s["coda"].is_empty():
		var q: Dictionary = s["coda"].pop_front()
		var l := lanc(q["l"])
		if not vivo(l) or not in_volo(l):
			s["tazze"][q["colore"]].append(int(q["i"]))
			continue
		_risolvi_pericolo(l, q)
		if s.has("flak_volo") or not s["attesa"].is_empty():
			return
	for l in s["lanc"]:
		l.erase("fari")
		l.erase("fari_n")
	s["coda_pronta"] = false
	_sistema_onde()
	s["fase"] = "v_acquis"

func _salvataggio_veterano(l: Dictionary, cosa: String) -> bool:
	if l["equip"] != "veterano" and not ruolo(l).begins_with("pilota"):
		return false
	var x := d6_per(l, "basso")
	_mostra_dadi("Salvataggio del veterano (%s): serve 6" % l["id"], [x], [], "salvo!" if x == 6 else "niente")
	if x == 6:
		_log("%s: l'esperienza dell'equipaggio evita il peggio (%s)." % [l["id"], cosa])
	return x == 6

func _risolvi_pericolo(l: Dictionary, q: Dictionary) -> void:
	var t := tipo(q)
	var torna := true
	var nome: String = Dati.PERICOLI[t]
	match t:
		"nessuno":
			_log("%s: nessun pericolo." % l["id"])
		"uccelli":
			var x := d6_per(l, "basso")
			if x == 1 and not _salvataggio_veterano(l, nome):
				_log("%s: uccelli contro il parabrezza (dado 1)." % l["id"])
				_danneggia(l, "uccelli")
			else:
				_log("%s: uccelli e pipistrelli, nessun danno (dado %d)." % [l["id"], x])
		"palloni":
			var x := d6_per(l, "pari")
			if _salvataggio_veterano(l, nome):
				pass
			elif x % 2 == 0:
				_log("%s sfiora un cavo dei palloni (dado %d)." % [l["id"], x])
				_danneggia(l, "palloni")
			else:
				_log("%s urta un cavo dei palloni (dado %d)." % [l["id"], x])
				_distruggi(l, "palloni di sbarramento")
		"schianto":
			var x := d6_per(l, "pari")
			if x % 2 == 1:
				if _salvataggio_veterano(l, nome):
					_danneggia(l, "schianto evitato per un soffio")
					if not _salvataggio_veterano(l, "Upkeep"):
						_perde_upkeep(l)
				else:
					_log("%s colpisce i cavi dell'alta tensione (dado %d)." % [l["id"], x])
					_distruggi(l, "schianto a bassa quota")
			else:
				_log("%s tocca un ostacolo a bassa quota (dado %d)." % [l["id"], x])
				_danneggia(l, "ostacolo a bassa quota")
				if not _salvataggio_veterano(l, "Upkeep"):
					_perde_upkeep(l)
		"fari":
			_log("%s è inquadrato dalle fotoelettriche." % l["id"])
			var g: String = "O:" + l["onda"] if l["onda"] != "" else "L:" + l["id"]
			_esito_nav(g, _controllo_nav(g, "Fotoelettriche, navigazione"))
		"flak":
			s["flak_volo"] = {"l": l["id"], "liv": valore(q), "giri": 0, "colore": q["colore"], "i": q["i"]}
			_log("%s sotto la contraerea (livello %d)." % [l["id"], valore(q)])
			torna = false
			s["tazze"][q["colore"]].append(int(q["i"]))
			_flak_volo_passo()
			return
		"caccia":
			_caccia_volo(l, valore(q))
		"bussola":
			if int(l["upkeep"]) >= 0:
				l["guasti"].append(t)
				_log("%s: %s." % [l["id"], nome.to_lower()])
		_:
			if t in Dati.ATTACCATI:
				l["guasti"].append(t)
				_log("%s: %s." % [l["id"], nome.to_lower()])
				if t == "radio" and l["onda"] != "":
					pass
	if torna:
		s["tazze"][q["colore"]].append(int(q["i"]))

func _perde_upkeep(l: Dictionary) -> void:
	if int(l["upkeep"]) >= 0:
		l["upkeep"] = -1
		_log("%s perde l'Upkeep." % l["id"])

func _distruggi(l: Dictionary, causa: String) -> void:
	if ruolo(l) == "pilota_danno" and not s["usati"].has(l["elite"]) and not danneggiato(l):
		s["usati"][l["elite"]] = true
		_log("%s riesce a tenere in volo l'aereo: solo danneggiato." % l["pilota"])
		l["danni"] = 1
		return
	l["danni"] = 2
	l["pos"] = "distrutto"
	l["esito"] = "abbattuto (%s)" % causa
	if int(l["upkeep"]) >= 0:
		l["upkeep"] = -1
	s["eventi"].append({"tipo": "abbattuto", "lanc": l["id"]})
	_log("%s è perduto! (%s)" % [nome_l(l), causa])

func _caccia_volo(l: Dictionary, tipo_c: int) -> void:
	var al: int = clampi(int(s["allerta"]), 0, 4)
	var r: Array = (Dati.CACCIA_AVVISTA_FARI if l.get("fari", false) else Dati.CACCIA_AVVISTA)[al]
	var dd := _dadi(2)
	var somma: int = dd[0] + dd[1]
	var nome := "Me %d" % tipo_c if tipo_c != 88 else "Ju 88"
	_mostra_dadi("Caccia notturno (%s): avvistato con %d-%d" % [nome, r[0], r[1]], dd, [], "avvistato!" if somma >= r[0] and somma <= r[1] else "nessuno")
	if somma < r[0] or somma > r[1]:
		_log("Un %s pattuglia la zona di %s ma non lo vede (%d)." % [nome, l["id"], somma])
		return
	var att: Array = Dati.CACCIA_VOLO[nome]
	var dd2 := _dadi(2)
	var s2: int = dd2[0] + dd2[1]
	var attacca: bool = s2 >= att[0] and s2 <= att[1]
	_mostra_dadi("%s: attacca con %d-%d" % [nome, att[0], att[1]], dd2, [], "ATTACCA" if attacca else "svanisce")
	if not attacca:
		_log("Un %s avvista %s ma lo perde nel buio (%d)." % [nome, l["id"], s2])
		return
	s["caccia_volo"] = int(s["caccia_volo"]) + 1
	s["allarme_turno"] = true
	_log("Un %s attacca %s (%d)!" % [nome, l["id"], s2])
	_distruggi(l, "caccia notturno")

## Contraerea sulla mappa di volo: colpi, critici e doppi come sulla mappa del bersaglio; l'azione evasiva
## porta il Lancaster tra i dispersi.
func _flak_volo_passo() -> void:
	var f: Dictionary = s["flak_volo"]
	var l := lanc(f["l"])
	if f.has("ea"):
		var scelta: String = f["ea"]
		f.erase("ea")
		if scelta == "si":
			l["pos"] = "smarrito"
			_rendi_indipendente(l)
			var x := d6_per(l, "pari")
			_mostra_dadi("Azione evasiva", [x], [], "annullato" if x % 2 == 0 else "a segno")
			_log("%s scarta e scende tra i dispersi: dado %d, %s." % [l["id"], x, "il colpo è annullato" if x % 2 == 0 else "il colpo va a segno"])
			if x % 2 == 1:
				for k in int(f["colpi"]):
					_danneggia(l, "contraerea")
			s.erase("flak_volo")
			return
		for k in int(f["colpi"]):
			if vivo(l):
				_danneggia(l, "contraerea")
		if f["doppio"] and vivo(l) and int(f["giri"]) < 12:
			f.erase("colpi")
		else:
			s.erase("flak_volo")
			return
	var liv: int = clampi(int(f["liv"]), 1, 5)
	var n := 3 if l.get("fari", false) else 2
	var dd := _dadi(n)
	var r: Array = Dati.FLAK[liv]
	var c := _scegli_coppia(dd, r[0], r[1])
	var somma: int = dd[c[0]] + dd[c[1]]
	var colpo: bool = somma >= r[0] and somma <= r[1]
	f["doppio"] = dd[c[0]] == dd[c[1]]
	f["giri"] = int(f["giri"]) + 1
	_mostra_dadi("Contraerea livello %d su %s" % [liv, l["id"]], dd, c, "COLPITO" if colpo else "mancato")
	_log("Contraerea su %s (%s): %s." % [l["id"], _lista(dd), "colpito" if colpo else "mancato"])
	if not colpo:
		if f["doppio"] and int(f["giri"]) < 12:
			return
		s.erase("flak_volo")
		return
	f["colpi"] = 2 if (liv >= 4 and somma == 7) else 1
	if l["pos"] == "smarrito":
		f["ea"] = "no"
		return
	_chiedi("v_flak_ea", "Contraerea: %s colpito" % l["id"], "Azione evasiva? Il Lancaster scende tra i dispersi della zona e tira un dado: pari, il colpo è annullato.", [_sc("si", "Azione evasiva (tra i dispersi)"), _sc("no", "Tieni la rotta e subisci il colpo")])

# ================================================================ 7.8 acquisizione del bersaglio (F8)
func _v_acquisizione() -> void:
	if s.has("acq_scelta"):
		var x: Dictionary = s["acq_scelta"]
		s.erase("acq_scelta")
		var g: String = x["gruppo"]
		if x["id"] == "ostinato":
			var ok := _controllo_nav(g, "Tentativo ostinato")
			if ok:
				_acquisito(g)
			else:
				_esito_nav(g, false)
		if not s.has("acq_fatti"):
			s["acq_fatti"] = []
		s["acq_fatti"].append(g)
	for g in gruppi():
		if s.get("acq_fatti", []).has(g):
			continue
		var c := capo_gruppo(g)
		if c.is_empty() or c["pos"] != "volo" or c.get("primario", "") == "" or int(c["upkeep"]) < 0:
			continue
		if c["zona"] != zona_diga(c["primario"]):
			continue
		if not s.has("acq_fatti"):
			s["acq_fatti"] = []
		s["acq_fatti"].append(g)
		var d: String = c["primario"]
		var rec: int = int(s["recon_zone"].get(c["zona"], 0)) + int(s["dighe"][d]["recon"])
		var serve := Dati.acquisizione(rec)
		if s.get("senza_luna", false):
			serve = [12, 12, 11, 10, 9, 8, 6][mini(rec, 6)]
		var dd := _dadi(2)
		var ok: bool = dd[0] + dd[1] >= serve
		_mostra_dadi("Acquisizione della %s: serve %d" % [Dati.DIGHE[d]["nome"], serve], dd, [], "bersaglio trovato" if ok else "non trovato")
		_log("%s cerca la diga della %s: %d+%d contro %d: %s." % [nome_gruppo(g), Dati.DIGHE[d]["nome"], dd[0], dd[1], serve, "la trova" if ok else "non la trova"])
		if ok:
			_acquisito(g)
			continue
		_chiedi("v_acquis", "Acquisizione del bersaglio", "%s non trova la diga della %s. Insistere con un controllo di navigazione (se fallisce, conseguenze di un errore di navigazione) o riprovare al prossimo turno?" % [nome_gruppo(g), Dati.DIGHE[d]["nome"]],
			[_sc("ostinato", "Tentativo ostinato"), _sc("aspetta", "Riprova al prossimo turno")], {"gruppo": g})
		return
	s.erase("acq_fatti")
	s["tm"] = {}
	s["fase"] = "v_bersagli"

func _acquisito(g: String) -> void:
	var c := capo_gruppo(g)
	var d: String = c["primario"]
	var coord := onda_buona(g)
	_log("%s entra nel riquadro di acquisizione della %s (ingresso %s)." % [nome_gruppo(g), Dati.DIGHE[d]["nome"], "coordinato" if coord else "scoordinato"])
	for l in lanc_gruppo(g):
		l["pos"] = "acquisizione"
		l["diga"] = d
		l["entrata"] = "coordinata" if coord else "scoordinata"
		l["capo_entrata"] = l["id"] == c["id"]

# ================================================================ 7.9 mappe del bersaglio (F9)
func _dighe_attive() -> Array:
	var r := []
	for l in s["lanc"]:
		if (l["pos"] in POS_BERSAGLIO or l["pos"] in ["acquisizione", "in_arrivo"]) and l.get("diga", "") != "" and not r.has(l["diga"]):
			r.append(l["diga"])
	return r

func _v_bersagli() -> void:
	var fatte: Array = s["tm"].get("fatte", [])
	for d in _dighe_attive():
		if d in fatte:
			continue
		# il capo di un'onda scompaginata può sparare un razzo Very: -1 al dado d'arrivo dei suoi aerei
		var capi: Array = s["lanc"].filter(func(l): return l["pos"] == "acquisizione" and l["diga"] == d and l["entrata"] == "scoordinata" and l.get("capo_entrata", false) and l["onda"] != "")
		if not capi.is_empty() and not s["tm"].has("very_" + d):
			var id := _prendi_very()
			if id == "":
				var c: Dictionary = capi[0]
				_chiedi("v_very", "Ingresso scoordinato alla %s" % Dati.DIGHE[d]["nome"], "La %s arriva scompaginata. %s può sparare un razzo Very: -1 al dado d'arrivo di ogni aereo dell'onda, ma il razzo resta sul turno d'attacco 1 (e conta per l'attività dei caccia)." % [s["onde"][c["onda"]]["nome"].to_lower(), c["id"]],
					[_sc("si", "Spara il razzo Very"), _sc("no", "Niente razzo")], {"diga": d})
				return
			s["tm"]["very_" + d] = id == "si"
		fatte.append(d)
		s["tm"]["fatte"] = fatte
		_entra_diga(d)
		return
	s["tm"] = {}
	s["fase"] = "v_pulizia"

func _prendi_very() -> String:
	var id: String = s.get("very_scelta", "")
	s.erase("very_scelta")
	return id

func _entra_diga(d: String) -> void:
	s["diga"] = d
	s["avv"] = {}
	s["turno"] = 1
	s["giri_8"] = 0
	s["razzi"] = s["dighe"][d].get("razzi", [])
	_log("-- Diga della %s --" % Dati.DIGHE[d]["nome"])
	# visibilità con il modificatore del turno di volo
	var mv: int = Dati.VIS_VOLO[int(s["turno_volo"])]
	s["mod_visibilita"] = mv if mv > -50 else 0
	if mv <= -50:
		s["visibilita"] = "nebbia"
		_log("Alle 05:00 la nebbia copre ogni cosa.")
	else:
		_controllo_visibilita()
	s["dighe"][d]["visibilita"] = s["visibilita"]
	_arrivo_diga(d)
	if not s["dighe"][d].has("palloni_box"):
		prepara_palloni(d)
	var onde_very := []
	if s["tm"].get("very_" + d, false):
		for l in s["lanc"]:
			if l["pos"] == "acquisizione" and l["diga"] == d and l.get("capo_entrata", false) and l["entrata"] == "scoordinata":
				onde_very.append(l["onda"])
				_log("%s spara un razzo Very sulla %s per guidare l'onda." % [l["id"], Dati.DIGHE[d]["nome"]])
		s["razzi"].append({"turno": 1, "giro": 0, "assoluto": int(s["turni"])})
	for l in s["lanc"]:
		if l["pos"] == "acquisizione" and l["diga"] == d:
			if l["entrata"] == "coordinata":
				var x := d6_per(l, "pari")
				l["pos"] = "vicino" if (x % 2 == 0 or l.get("capo_entrata", false)) else "lontano"
				_log("%s arriva in formazione: %s." % [l["id"], "Cerchio vicino" if l["pos"] == "vicino" else "Cerchio lontano"])
			else:
				var x := d6_per(l, "alto") + conta_guasti(l, "errore") + (1 if ha_guasto(l, "bussola") else 0) - (1 if l["onda"] != "" and l["onda"] in onde_very else 0)
				l["arrivo"] = clampi(x, 1, 8)
				l["pos"] = "in_arrivo" if l["arrivo"] > 1 else "lontano"
				_log("%s arriva da solo al turno d'attacco %d." % [l["id"], l["arrivo"]])
			l["onda"] = ""
	_sistema_onde()
	s["fase"] = "inizio"

## Negli scenari 6-9 non succede nulla di speciale quando si arriva a una diga (la campagna controlla la sorpresa).
func _arrivo_diga(_d: String) -> void:
	pass

func _f_inizio() -> void:
	super._f_inizio()
	if s.get("volo", false):
		for l in s["lanc"]:
			if l["pos"] == "in_arrivo" and l["diga"] == s["diga"] and int(l["arrivo"]) <= int(s["turno"]):
				l["pos"] = "lontano"
				_log("%s raggiunge la diga: Cerchio lontano." % l["id"])

func _caccia_attacca() -> void:
	s["allarme_turno"] = true
	s["caccia_volo"] = int(s["caccia_volo"]) + 1
	var z := zona_diga(s["diga"])
	for l in sulla_mappa():
		l["pos"] = "volo"
		l["zona"] = z
		l["onda"] = ""
		l["diga"] = ""
	_log("I Lancaster si disperdono nella zona: l'attacco alla %s è interrotto." % Dati.DIGHE[s["diga"]]["nome"])
	_chiudi_diga()

func _f_fine_turno() -> void:
	s["turni"] = int(s["turni"]) + 1
	var d: String = s["diga"]
	var con_upkeep: Array = s["lanc"].filter(func(l): return l.get("diga", "") == d and (l["pos"] in POS_BERSAGLIO or l["pos"] == "in_arrivo") and int(l["upkeep"]) >= 0)
	if s["dighe"][d]["breccia"] or con_upkeep.is_empty() or int(s["turno"]) == 8:
		if int(s["turno"]) == 8 and not con_upkeep.is_empty() and not s["dighe"][d]["breccia"]:
			_log("Turno d'attacco 8: l'azione alla %s riprende nel prossimo turno di volo." % Dati.DIGHE[d]["nome"])
		_chiudi_diga()
		return
	s["turno"] = int(s["turno"]) + 1
	s["fase"] = "inizio"

## Fine dell'azione a una diga in questo turno di volo: chi ha finito torna sulla mappa di volo.
func _chiudi_diga() -> void:
	var d: String = s["diga"]
	var breccia: bool = s["dighe"][d]["breccia"]
	s["dighe"][d]["razzi"] = s["razzi"]
	var z := zona_diga(d)
	for l in s["lanc"]:
		if l.get("diga", "") != d:
			continue
		if l["pos"] == "partito":
			l["pos"] = "rtb"
			l["zona"] = z
			l["diga"] = ""
			continue
		if not (l["pos"] in POS_BERSAGLIO or l["pos"] == "in_arrivo"):
			continue
		if int(l["upkeep"]) < 0:
			l["pos"] = "rtb"
			l["zona"] = z
			l["diga"] = ""
			_log("%s lascia la %s e rientra." % [l["id"], Dati.DIGHE[d]["nome"]])
		elif breccia:
			var nuovo := _prossimo_bersaglio(l)
			l["pos"] = "volo"
			l["zona"] = z
			l["diga"] = ""
			if nuovo == "":
				l["pos"] = "rtb"
				_log("%s vede la breccia e rientra con l'Upkeep." % l["id"])
			else:
				l["primario"] = nuovo
				_log("%s vede la breccia e punta sulla %s." % [l["id"], Dati.DIGHE[nuovo]["nome"]])
		elif l["pos"] in ["sgancio", "salita", "avvicinamento", "scorta"]:
			l["pos"] = "vicino"
	if breccia:
		for l in s["lanc"]:
			if l["primario"] == d and vivo(l) and l["pos"] in ["volo", "smarrito", "attesa", "acquisizione"]:
				var nuovo := _prossimo_bersaglio(l)
				if nuovo != "":
					l["primario"] = nuovo
	s["avv"] = {}
	s["fase"] = "v_bersagli"

func _prossimo_bersaglio(l: Dictionary) -> String:
	if l["secondario"] != "" and not s["dighe"][l["secondario"]]["breccia"] and l["secondario"] != l["primario"]:
		var x: String = l["secondario"]
		l["secondario"] = ""
		return x
	if not s["dighe"][s["riserva"]]["breccia"]:
		return s["riserva"]
	for d in ["sorpe", "ennepe", "lister", "diemel", "henne", "bever"]:
		if not s["dighe"][d]["breccia"]:
			s["riserva"] = d
			return d
	return ""

# ================================================================ 7.10 pulizia
func _v_pulizia() -> void:
	for d in s["dighe"]:
		if s["dighe"][d]["breccia"] and not s.get("brecce_note", []).has(d):
			if not s.has("brecce_note"):
				s["brecce_note"] = []
			s["brecce_note"].append(d)
			s["allarme_turno"] = true
	if s["allarme_turno"] and int(s["allerta"]) < 4:
		s["allerta"] = int(s["allerta"]) + 1
		_log("L'allerta della difesa sale a %d." % int(s["allerta"]))
	for d in s["dighe"]:
		if int(s["dighe"][d]["attivita"]) > 0:
			s["dighe"][d]["attivita"] = int(s["dighe"][d]["attivita"]) - 1
	var ancora: Array = s["lanc"].filter(func(l): return l["pos"] in ["volo", "smarrito", "attesa", "acquisizione", "in_arrivo"] or l["pos"] in POS_BERSAGLIO)
	if ancora.is_empty():
		s["fine"] = "rientro"
		s["fase"] = "concludi"
		return
	if int(s["turno_volo"]) >= 9:
		_log("Sta per albeggiare: tutti i Lancaster rientrano.")
		for l in ancora:
			l["pos"] = "rtb"
			if l.get("diga", "") != "":
				l["zona"] = zona_diga(l["diga"])
		s["fine"] = "alba"
		s["fase"] = "concludi"
		return
	s["turno_volo"] = int(s["turno_volo"]) + 1
	s["fase"] = "v_inizio"

# ================================================================ fine (5.0)
func _zona_rtb(z: String) -> String:
	match z:
		"ruhr": return "Ruhr"
		"weser": return "Weser"
		"costa_olandese": return "Olanda"
	return "Costa"

func _concludi() -> void:
	s["fase"] = "concluso"
	_log("== Fine del raid ==")
	var rientrati := 0
	for l in s["lanc"]:
		if l["pos"] in ["distrutto", "perso"]:
			continue
		_rientro(l, _zona_rtb(l["zona"]))
		if l["pos"] == "a casa":
			rientrati += 1
	for nd in s["dighe"]:
		var d: Dictionary = s["dighe"][nd]
		for u in d["upkeep"]:
			if u["esito"] == "colpito" and int(u["valore"]) < 0:
				_rivela(nd, u, "Ricognizione del mattino")
		for u in d["upkeep"]:
			if u["esito"] == "colpito":
				var x := d6()
				var var_ := -1 if x == 1 else (1 if x == 6 else 0)
				u["valore"] = maxi(0, int(u["valore"]) + var_)
		if not d["breccia"] and _ha_colpi(nd) and danni_diga(nd) >= capacita(nd):
			d["breccia"] = true
			_log("Le foto del mattino mostrano la breccia nella %s!" % Dati.DIGHE[nd]["nome"])
	s["esito"] = _rapporto_volo(rientrati)
	_log("Esito: %s" % s["esito"]["titolo"])

func _rapporto_volo(rientrati: int) -> Dictionary:
	var scen: int = int(s["scen"])
	var rotte := []
	var rv := 0
	var danneggiate := []
	for d in s["dighe"]:
		if s["dighe"][d]["breccia"]:
			rotte.append(d)
			rv += int(Dati.DIGHE[d]["rv"])
		else:
			for u in s["dighe"][d]["upkeep"]:
				if u["esito"] == "colpito" and not u.get("precedente", false) and int(u["valore"]) > 0 and not danneggiate.has(d):
					danneggiate.append(d)
	var persi: int = s["lanc"].filter(func(l): return l["pos"] in ["distrutto", "perso"]).size()
	var t := ""
	var spiega := ""
	match scen:
		6:
			if "sorpe" in rotte:
				t = ["Perfezione!", "Svolta decisiva", "Sacrificio eroico"][0 if rientrati >= 4 else (1 if rientrati >= 2 else 2)]
			elif "sorpe" in danneggiate:
				t = ["Missione compiuta", "Diversione costosa", "Notte memorabile"][0 if rientrati >= 4 else (1 if rientrati >= 2 else 2)]
			elif rientrati >= 4:
				t = "Frustrati" if s["dighe"]["sorpe"]["upkeep"].size() > 0 else "Rientro sicuro"
			elif rientrati >= 2:
				t = "Uova sprecate"
			elif rientrati == 1:
				t = "Mistero"
			else:
				t = "Carneficina" if int(s["caccia_volo"]) > 0 else "Svaniti"
			spiega = "Storicamente solo McCarthy raggiunse la Sorpe: Byers e Barlow furono abbattuti, Munro e Rice rientrarono danneggiati."
		7:
			var n := 0
			for d in ["mohne", "eder", "sorpe"]:
				if d in rotte: n += 1
			if n == 3:
				t = "Successo brillante" if rientrati >= 5 else "Vittoria terribile"
			elif "mohne" in rotte and "eder" in rotte:
				t = ["Vittoria schiacciante", "Successo", "Successo pagato caro"][0 if rientrati >= 6 else (1 if rientrati >= 4 else 2)]
			elif n == 1:
				t = ["Successo marginale", "Combattuta", "Diversione sanguinosa"][0 if rientrati >= 6 else (1 if rientrati >= 3 else 2)]
			else:
				t = ["Esperimento", "Inutilità", "Massacro", "Catastrofe"][0 if rientrati >= 6 else (1 if rientrati >= 3 else (2 if rientrati >= 1 else 3))]
			spiega = "Storicamente Möhne ed Eder cedettero; Hopgood, Astell e Maudslay non tornarono."
		8:
			var altre := rotte.filter(func(d): return d != "mohne" and d != "eder")
			var dan := danneggiate.filter(func(d): return d != "mohne" and d != "eder")
			if not altre.is_empty():
				t = ["Vittoria decisiva", "Prezzo alto", "L'ultima Victoria Cross?"][0 if rientrati >= 3 else (1 if rientrati >= 1 else 2)]
			elif not dan.is_empty():
				t = ["Sopravvissuti", "Lanciarsi col paracadute?", "Lettere a casa"][0 if rientrati >= 3 else (1 if rientrati >= 1 else 2)]
			else:
				t = ["Fallimento innocuo", "Volo inutile", "Crociata dei ragazzi"][0 if rientrati >= 3 else (1 if rientrati >= 1 else 2)]
				if rientrati == 0 and persi == 5 and int(s["caccia_volo"]) == 0:
					t = "Scomparsi"
			spiega = "Storicamente Burpee e Ottley furono abbattuti, Anderson rientrò con l'Upkeep, Brown colpì la Sorpe e Townsend forse la Bever."
		_:
			if rv >= 17:
				t = "Trionfo" if persi <= 4 else ("Come nella storia: le dighe sono cadute" if persi <= 8 else "Vittoria pagata col sangue")
			elif rv >= 8:
				t = "Successo parziale" if persi <= 8 else "Successo amaro"
			elif rv > 0:
				t = "Danni minori"
			else:
				t = "Fallimento" if persi <= 8 else "Disastro"
			spiega = "Storicamente caddero Möhne ed Eder (17 rv) e otto Lancaster su diciannove non tornarono."
	if persi > 0 and scen != 9:
		var x := d6()
		spiega += " Sorte degli equipaggi abbattuti (dado %d): %s." % [x, "nessuno sopravvive" if x <= 2 else ("i sopravvissuti vengono catturati" if x <= 5 else "uno sfugge con la resistenza olandese")]
	var righe := []
	for l in s["lanc"]:
		righe.append("%s %s: %s" % [l["id"], l["pilota"], l["esito"] if l["esito"] != "" else "?"])
	var nomi := rotte.map(func(d): return Dati.DIGHE[d]["nome"])
	return {"titolo": t, "spiega": spiega, "breccia": not rotte.is_empty(), "danni": rv, "capacita": 0,
		"rientrati": rientrati, "proseguono": 0, "upkeep": 0, "righe": righe, "dighe_rotte": nomi, "persi": persi, "rv": rv}
