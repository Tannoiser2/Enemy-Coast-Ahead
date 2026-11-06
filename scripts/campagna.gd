## Campagna (scenario 10, regole 8.0-13.0 dalle tabelle P1-P10 e dal Mission Planning Blotter): quattro turni di
## pianificazione (requisizioni, sicurezza, addestramento, modifiche, ricognizione), preparazione del volo
## (controlli di aerei, Upkeep ed equipaggi, briefing e rischio per la sicurezza, sortita) e poi il raid con il motore
## degli scenari di volo, con la sorpresa alle dighe.
class_name PartitaCampagna
extends PartitaVolo

const PLURALE := {"recluta": "reclute", "esperto": "esperti", "veterano": "veterani"}
const BOX := {"requisizioni": "Requisizioni", "addestramento": "Addestramento", "riparazioni": "Riparazioni",
	"radio": "Radio VHF", "altimetro": "Altimetro (luci Aldis)", "cabina": "Cabina (mirino Dann)",
	"aerei": "Controllo degli aerei", "ordigni": "Controllo degli Upkeep"}

# ================================================================ nuova campagna
func nuova_campagna(seme: int = 0) -> void:
	if seme == 0:
		seme = int(Time.get_unix_time_from_system() * 1000.0) % 2000000000 + 7
	s = {
		"versione": 1, "scen": 10, "volo": true, "campagna": true, "facile": false, "seme": seme,
		"rng": seme * 2654435761 % 4294967296 + 1, "turno_volo": 1, "turno": 1, "giri_8": 0, "turni": 0, "malus_rtb": 0,
		"visibilita": "sereno", "allerta": 0, "mod_visibilita": 0, "diga": "mohne", "dighe": {}, "razzi": [], "lanc": [],
		"coppe": {"q": [], "v": []}, "avv": {}, "flak": {}, "rilasciati_turno": 0, "caccia_attacco": false,
		"nebbia_di_guerra": false, "fase": "p_inizio", "attesa": {}, "log": [], "dadi": {}, "fine": "", "esito": {},
		"codice": _codice(seme), "usati": {}, "tiro_ripetuto": {}, "eventi": [], "onde": {},
		"recon_zone": {"costa_olandese": 0, "ruhr": 0, "weser": 0}, "riserva": "sorpe", "tazze": {}, "pendenti": [],
		"allarme_turno": false, "tm": {}, "brecce_turno": [], "caccia_volo": 0,
		# pianificazione
		"piano": 1, "rp": 60, "richieste": 0, "extra": 0, "rischio": 0,
		"squadre": [], "squadre_libere": ["s1", "s2", "s3", "s4", "s5", "s6"],
		"equipaggi": {"recluta": 0, "esperto": 0, "veterano": 0}, "riposati": {"recluta": false, "esperto": false, "veterano": false},
		"addestramento": {"recluta": {"nav": 0, "quota": 0, "bomba": 0}, "esperto": {"nav": 1, "quota": 1, "bomba": 1}, "veterano": {"nav": 2, "quota": 2, "bomba": 2}},
		"aerei": [], "aerei_liberi": [], "upkeep_scorta": [], "elite": [], "elite_sacco": [],
		"vhf": false, "aldis": false, "dann": false, "sei": {"altimetro": 0, "cabina": 0},
		"sicurezza": [], "sicurezza_usati": [], "spia": false, "quarantena": false, "giri_extra": 0,
		"recon_dighe_fatte": [], "recon_zone_fatte": [], "dighe_viste": [], "sorpresa_fatta": [],
		"dediche": {}, "ultimo_turno_req": 0, "requisiti_turno": 0,
	}
	for d in Dati.DIGHE:
		s["dighe"][d] = {"acqua": 4, "recon": 0, "attivita": 0, "flak": 0, "fari": 0, "palloni": 0, "upkeep": [],
			"breccia": false, "caccia_vicino": false, "flak_iniziale": 0, "visibilita": "sereno", "vista": false}
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
	s["sacco"] = sacco
	var lanc_tutti := ["AJ-A", "AJ-B", "AJ-C", "AJ-E", "AJ-F", "AJ-G", "AJ-H", "AJ-J", "AJ-K", "AJ-L", "AJ-M", "AJ-N", "AJ-O",
		"AJ-P", "AJ-S", "AJ-T", "AJ-W", "AJ-Y", "AJ-Z"]
	s["aerei_liberi"] = lanc_tutti
	var el := []
	for e in Dati.SPECIALISTI:
		el.append(e)
	el.append_array(["spia", "jinx", "armiere"])
	_mescola(el)
	s["elite_sacco"] = el
	var rec := []
	for i in Dati.RETRO_RECON.size():
		rec.append(i)
	_mescola(rec)
	s["retro_recon"] = {}
	var k := 0
	for d in Dati.DIGHE:
		s["retro_recon"][d] = rec[k]
		k += 1
	_log("== %s ==" % Dati.CAMPAGNA["titolo"])
	_log("Scampton, marzo 1943. Il 617° Squadron ha 60 punti risorsa (RP) per cominciare.")
	avanza()

func scenario() -> Dictionary:
	return Dati.CAMPAGNA

func nome_scenario() -> String:
	return "Scenario 10: %s" % Dati.CAMPAGNA["titolo"]

# ================================================================ addestramento negli scontri
func livello(l: Dictionary, cat: String) -> int:
	var v := int(s["addestramento"][l["equip"]][cat])
	if ha_guasto(l, "inabile"):
		v -= 3
	return maxi(v, 0)

func addestramento(l: Dictionary) -> int:
	return livello(l, "quota")

# ================================================================ squadre di terra
func squadra(id: String) -> Dictionary:
	for q in s["squadre"]:
		if q["id"] == id:
			return q
	return {}

func dati_squadra(id: String) -> Dictionary:
	for q in Dati.SQUADRE:
		if q["id"] == id:
			return q
	return {}

func valori(id: String) -> Array:
	var q := squadra(id)
	var d := dati_squadra(id)
	return d["stanco"] if q.get("stanca", false) else d["fresco"]

func squadre_libere_turno() -> Array:
	return s["squadre"].filter(func(q): return q.get("dedicata", "") == "")

func dedicate(box: String) -> Array:
	return s["squadre"].filter(func(q): return q.get("dedicata", "") == box)

func maneggio_box(box: String) -> int:
	var t := 0
	for q in dedicate(box):
		t += int(valori(q["id"])[0])
	return t

func erk_box(box: String) -> int:
	var t := 0
	for q in dedicate(box):
		t += int(valori(q["id"])[1])
	return t

func _sc_dediche(box: String) -> Array:
	var sc := []
	for q in s["squadre"]:
		var v := valori(q["id"])
		if q.get("dedicata", "") == "":
			sc.append(_sc("dedica:%s:%s" % [q["id"], box], "%s: dedica la %s" % [BOX[box], dati_squadra(q["id"])["nome"]], _desc_squadra(q["id"]).capitalize() + "."))
		elif q["dedicata"] != box and not q.get("stanca", false):
			sc.append(_sc("trasferisci:%s:%s" % [q["id"], box], "%s: trasferisci la %s" % [BOX[box], dati_squadra(q["id"])["nome"]], "Ora dedicata a: %s. Il trasferimento la affatica per sempre." % _min(BOX.get(q["dedicata"], q["dedicata"]))))
	return sc

func _desc_squadra(id: String) -> String:
	var v := valori(id)
	return "maneggio %d, erk %d, sortita %d%s" % [v[0], v[1], v[2], ", affaticata" if squadra(id).get("stanca", false) else ""]

func _applica_dedica(id: String) -> bool:
	var p := id.split(":")
	if p[0] == "dedica":
		squadra(p[1])["dedicata"] = p[2]
		_log("La %s si dedica a: %s." % [dati_squadra(p[1])["nome"], _min(BOX[p[2]])])
		return true
	if p[0] == "trasferisci":
		var q := squadra(p[1])
		_affatica(q)
		q["dedicata"] = p[2]
		_log("La %s passa a: %s." % [dati_squadra(p[1])["nome"], _min(BOX[p[2]])])
		return true
	return false

func _affatica(q: Dictionary) -> void:
	if "armiere" in s["elite"] and not s["usati"].has("armiere"):
		s["usati"]["armiere"] = true
		_log("L'armiere evita la fatica alla %s." % dati_squadra(q["id"])["nome"])
		return
	q["stanca"] = true

# ================================================================ motore
func _passo() -> void:
	match s["fase"]:
		"p_inizio": _p_inizio()
		"p_req": _p_requisizioni()
		"p_sic": _p_sicurezza()
		"p_add": _p_addestramento()
		"p_mod": _p_modifiche()
		"p_rec": _p_ricognizione()
		"p_lancio": _p_lancio()
		"f_aerei": _f_controllo("aerei")
		"f_ordigni": _f_controllo("ordigni")
		"f_equip": _f_equipaggi()
		"f_brief": _f_briefing()
		"f_sortita": _f_sortita()
		_:
			super._passo()

func _applica(a: Dictionary, id: String) -> void:
	if a["tipo"].begins_with("p_") or a["tipo"].begins_with("f_"):
		s["scelta"] = {"tipo": a["tipo"], "id": id, "dati": a.get("dati", {})}
		return
	super._applica(a, id)

func _prendi_scelta(tipo: String) -> String:
	if s.has("scelta") and s["scelta"]["tipo"] == tipo:
		var id: String = s["scelta"]["id"]
		s.erase("scelta")
		return id
	return ""

func _min(t: String) -> String:
	return t.substr(0, 1).to_lower() + t.substr(1) if t != "" else t

func rp_testo() -> String:
	return "RP disponibili: %d." % int(s["rp"])

# ================================================================ inizio del turno di pianificazione
func _p_inizio() -> void:
	var t: int = int(s["piano"])
	_log("== Turno di pianificazione %d: %s ==" % [t, Dati.LUNA[t]])
	if t == 2:
		s["rp"] = int(s["rp"]) + 60
		_log("Arrivano altri 60 RP (ora %d)." % int(s["rp"]))
	for q in s["squadre"]:
		q["dedicata"] = ""
	s["recon_dighe_fatte"] = []
	s["recon_zone_fatte"] = []
	s["requisiti_turno"] = 0
	s["sic_passo"] = 0
	s["add_scelte"] = []
	s["mod_dadi"] = {"radio": 0, "altimetro": 0, "cabina": 0}
	s["fase"] = "p_req"

# ================================================================ P1 requisizioni
func _p_requisizioni() -> void:
	var id := _prendi_scelta("p_req")
	if id != "":
		if id == "fine":
			s["fase"] = "p_sic"
			return
		_esegui_requisizione(id)
	var sc := []
	var rp: int = int(s["rp"])
	if not s["quarantena"]:
		sc.append(_sc("rp", "Chiedi altri RP al Comando", "Un dado: pari 30 RP, dispari 20 RP. +1 al rischio per la sicurezza."))
		for q in Dati.SQUADRE:
			if q["id"] in s["squadre_libere"] and rp >= int(q["costo"]):
				sc.append(_sc("squadra:" + q["id"], "Requisisci la %s (%d RP)" % [q["nome"], int(q["costo"])], "Maneggio %d, erk %d, sortita %d." % q["fresco"]))
	if int(s["piano"]) == 1:
		var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
		if tot < 21:
			for e in ["recluta", "esperto", "veterano"]:
				if rp >= int(Dati.COSTO_EQUIPAGGIO[e]):
					sc.append(_sc("equip:" + e, "Recluta un equipaggio %s (%d RP)" % [Dati.NOME_EQUIPAGGIO[e].to_lower(), int(Dati.COSTO_EQUIPAGGIO[e])], "Equipaggi: %d. Ogni 6 equipaggi arriva uno specialista." % tot))
	var limite := maneggio_box("requisizioni")
	if limite > int(s["requisiti_turno"]) and rp >= 1:
		if not s["aerei_liberi"].is_empty():
			sc.append(_sc("lanc", "Requisisci un Lancaster (1 RP)", "Limite di maneggio: ancora %d in questo turno." % (limite - int(s["requisiti_turno"]))))
		if not s["sacco"].is_empty():
			sc.append(_sc("upkeep", "Requisisci un Upkeep (1 RP)", "Limite di maneggio: ancora %d in questo turno." % (limite - int(s["requisiti_turno"]))))
	sc.append_array(_sc_dediche("requisizioni"))
	sc.append(_sc("fine", "Fine delle requisizioni"))
	_chiedi("p_req", "Requisizioni (turno %d)" % int(s["piano"]), "%s Lancaster e Upkeep si requisiscono fino al maneggio delle squadre dedicate alle requisizioni (ora %d). Gli equipaggi solo nel primo turno." % [rp_testo(), limite], sc)

func _esegui_requisizione(id: String) -> void:
	if _applica_dedica(id):
		return
	var p := id.split(":")
	match p[0]:
		"rp":
			var d := d6()
			var v := 30 if d % 2 == 0 else 20
			s["rp"] = int(s["rp"]) + v
			s["richieste"] = int(s["richieste"]) + 1
			_mostra_dadi("Richiesta di RP", [d], [], "+%d RP" % v)
			_log("Il Comando concede %d RP (dado %d). Rischio per la sicurezza +1." % [v, d])
		"squadra":
			var q := dati_squadra(p[1])
			s["rp"] = int(s["rp"]) - int(q["costo"])
			s["squadre_libere"].erase(p[1])
			s["squadre"].append({"id": p[1], "stanca": false, "dedicata": ""})
			_log("Arriva la %s (%d RP)." % [q["nome"], int(q["costo"])])
		"equip":
			s["rp"] = int(s["rp"]) - int(Dati.COSTO_EQUIPAGGIO[p[1]])
			s["equipaggi"][p[1]] = int(s["equipaggi"][p[1]]) + 1
			var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
			_log("Arriva un equipaggio %s (totale %d)." % [Dati.NOME_EQUIPAGGIO[p[1]].to_lower(), tot])
			if tot % 6 == 0:
				_pesca_elite("ogni sei equipaggi")
		"lanc":
			s["rp"] = int(s["rp"]) - 1
			s["requisiti_turno"] = int(s["requisiti_turno"]) + 1
			var a: String = s["aerei_liberi"].pop_front()
			s["aerei"].append({"id": a, "danni": 0})
			_log("Arriva il Lancaster %s." % a)
		"upkeep":
			s["rp"] = int(s["rp"]) - 1
			s["requisiti_turno"] = int(s["requisiti_turno"]) + 1
			s["upkeep_scorta"].append(s["sacco"].pop_back())
			_log("Arriva un Upkeep (ora %d)." % s["upkeep_scorta"].size())

func _pesca_elite(perche: String) -> void:
	if s["elite_sacco"].is_empty():
		return
	var e: String = s["elite_sacco"].pop_back()
	s["elite"].append(e)
	match e:
		"spia":
			s["spia"] = true
			_log("Pescato uno specialista (%s)... ma è una spia infiltrata a Scampton!" % perche)
		"jinx":
			_log("Pescato uno specialista (%s): arriva il cane di Gibson, la mascotte (porta guai)." % perche)
		"armiere":
			_log("Pescato uno specialista (%s): un armiere esperto (evita una volta la fatica di una squadra)." % perche)
		_:
			_log("Nuovo specialista (%s): %s, %s." % [perche, Dati.SPECIALISTI[e]["nome"], Dati.RUOLI[Dati.SPECIALISTI[e]["ruolo"]][0].to_lower()])

# ================================================================ P3 sicurezza
const SEGNALINI_SIC := {
	"tirpitz": ["Voce sulla Tirpitz", 0, "Rischio -1. Si potrà girare in «Inganno Tirpitz»."],
	"polizia": ["Polizia in più", 5, "Rischio -2. Si potrà girare in «Trasferire la barista»."],
	"57sqn": ["Trasferire il 57° Squadron", 15, "Costa anche una squadra di terra. Rischio -2/-4. Si potrà girare in «Quarantena»."],
}
const GIRATI := {"tirpitz": ["Inganno Tirpitz", 5, "Rischio -1/-3 in più."], "polizia": ["Trasferire la barista", 5, "Rischio -1 in più; allontana la spia."],
	"57sqn": ["Quarantena di Scampton", 0, "Rischio +1/-3/-5. Niente più RP né squadre, allontana la spia, niente bonus Wallis."]}

func _p_sicurezza() -> void:
	var id := _prendi_scelta("p_sic")
	if id != "":
		if id == "fine":
			s["sic_passo"] = int(s["sic_passo"]) + 1
		else:
			_esegui_sicurezza(id)
			s["sic_passo"] = int(s["sic_passo"]) + 1
	if int(s["sic_passo"]) >= 2:
		s["fase"] = "p_add"
		return
	var sc := []
	var rp: int = int(s["rp"])
	if int(s["sic_passo"]) == 0:
		for m in s["sicurezza"]:
			if not m.get("girato", false) and int(m["turno"]) < int(s["piano"]):
				var g: Array = GIRATI[m["id"]]
				if rp >= int(g[1]):
					sc.append(_sc("gira:" + m["id"], "Gira: %s (%d RP)" % [g[0], int(g[1])], g[2]))
		if sc.is_empty():
			s["sic_passo"] = 1
		else:
			sc.append(_sc("fine", "Non girare nessun segnalino"))
			_chiedi("p_sic", "Sicurezza: girare un segnalino", "Prima si può girare un segnalino già in gioco (dal turno successivo a quello in cui è stato giocato).", sc)
			return
	for k in SEGNALINI_SIC:
		if k in s["sicurezza_usati"]:
			continue
		var m: Array = SEGNALINI_SIC[k]
		if rp >= int(m[1]) and (k != "57sqn" or not s["squadre"].is_empty()):
			sc.append(_sc("gioca:" + k, "Gioca: %s (%d RP)" % [m[0], int(m[1])], m[2]))
	sc.append(_sc("fine", "Non giocare segnalini"))
	_chiedi("p_sic", "Sicurezza: nuovo segnalino", "Il rischio per la sicurezza si calcola al briefing: più è alto, più l'allerta tedesca e la sorpresa alle dighe peggiorano.", sc)

func _esegui_sicurezza(id: String) -> void:
	var p := id.split(":")
	if p[0] == "gioca":
		var m: Array = SEGNALINI_SIC[p[1]]
		s["rp"] = int(s["rp"]) - int(m[1])
		s["sicurezza"].append({"id": p[1], "turno": int(s["piano"]), "girato": false})
		s["sicurezza_usati"].append(p[1])
		if p[1] == "57sqn":
			var q: Dictionary = s["squadre"][s["squadre"].size() - 1]
			s["squadre"].erase(q)
			_log("Il 57° Squadron viene trasferito: la %s se ne va con lui." % dati_squadra(q["id"])["nome"])
		_log("Sicurezza: %s." % _min(m[0]))
	else:
		for m in s["sicurezza"]:
			if m["id"] == p[1]:
				m["girato"] = true
		var g: Array = GIRATI[p[1]]
		s["rp"] = int(s["rp"]) - int(g[1])
		_log("Sicurezza: %s." % _min(g[0]))
		if p[1] == "polizia" or p[1] == "57sqn":
			if s["spia"]:
				s["spia"] = false
				_log("La spia viene allontanata da Scampton.")
		if p[1] == "57sqn":
			s["quarantena"] = true

# ================================================================ addestramento (10.3)
func _p_addestramento() -> void:
	var id := _prendi_scelta("p_add")
	var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
	if tot == 0:
		_log("Nessun equipaggio da addestrare.")
		s["fase"] = "p_mod"
		return
	if id != "":
		if _applica_dedica(id):
			pass
		elif id == "extra":
			s["rp"] = int(s["rp"]) - 5
			s["add_extra"] = true
			s["giri_extra"] = int(s["giri_extra"]) + 1
			_log("Addestramento extra (5 RP): una specialità in più e un nuovo specialista; rischio +1.")
			_pesca_elite("addestramento extra")
		elif id == "via":
			_esegui_addestramento()
			s["fase"] = "p_mod"
			return
		else:
			s["add_scelte"].append(id)
	var n_scelte: int = 2 + (1 if s.get("add_extra", false) else 0)
	var sc := []
	if s["add_scelte"].size() < n_scelte:
		for c in Dati.SPECIALITA:
			if c in s["add_scelte"] and not s.get("add_extra", false):
				continue
			if s["add_scelte"].count(c) >= 2:
				continue
			sc.append(_sc(c, "Addestra: %s" % Dati.SPECIALITA[c], _livelli_testo(c)))
	else:
		sc.append(_sc("via", "Addestra (%s)" % ", ".join(s["add_scelte"].map(func(x): return Dati.SPECIALITA[x].to_lower())), "Un dado per ogni tipo di equipaggio e specialità."))
	if not s.get("add_extra", false) and int(s["rp"]) >= 5:
		sc.append(_sc("extra", "Addestramento extra (5 RP)", "Una terza specialità (o la stessa due volte) e uno specialista pescato a caso. Rischio +1, -1 al controllo degli equipaggi."))
	sc.append_array(_sc_dediche("addestramento"))
	var mod := _mod_addestramento_testo()
	_chiedi("p_add", "Addestramento (turno %d)" % int(s["piano"]), "Scegli %d specialità (%d scelte). %s" % [n_scelte, s["add_scelte"].size(), mod], sc)

func _livelli_testo(c: String) -> String:
	var p := []
	for e in ["recluta", "esperto", "veterano"]:
		if int(s["equipaggi"][e]) > 0:
			p.append("%s %d" % [Dati.NOME_EQUIPAGGIO[e].to_lower(), int(s["addestramento"][e][c])])
	return "Livelli attuali: " + (", ".join(p) if not p.is_empty() else "nessun equipaggio")

func _aerei_integri() -> int:
	return s["aerei"].filter(func(a): return int(a["danni"]) == 0).size()

func _mod_addestramento(c: String) -> int:
	var m := 0
	var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
	if tot >= 2 * maxi(_aerei_integri(), 0) and tot > 0:
		m -= 1
	if dedicate("addestramento").is_empty():
		m -= 1
	if c == "nav" and int(s["recon_zone"]["costa_olandese"]) >= 1 and int(s["recon_zone"]["ruhr"]) >= 1 and int(s["recon_zone"]["weser"]) >= 1:
		m += 1
	if c == "quota" and s["aldis"]:
		m += 1
	if c == "bomba" and s["dann"]:
		m += 1
	return m

func _mod_addestramento_testo() -> String:
	var p := []
	var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
	if tot >= 2 * _aerei_integri():
		p.append("-1 troppi equipaggi per gli aerei integri")
	if dedicate("addestramento").is_empty():
		p.append("-1 senza squadra dedicata")
	return "Modificatori: " + (", ".join(p) if not p.is_empty() else "nessuno") + " (+1 navigazione con ricognizione in tutte le zone ostili, +1 quota con le luci Aldis, +1 puntamento con il mirino Dann)."

func _esegui_addestramento() -> void:
	for c in s["add_scelte"]:
		for e in ["recluta", "esperto", "veterano"]:
			if int(s["equipaggi"][e]) <= 0:
				continue
			var x := d6()
			if s["riposati"][e] and x <= 2:
				var y := d6()
				_log("Equipaggi %s riposati: ritirano il %d (nuovo %d)." % [PLURALE[e], x, y])
				x = y
				s["riposati"][e] = false
			var r: int = clampi(x + _mod_addestramento(c), 1, 7)
			var t: Array = Dati.ADDESTRA[e][r - 1]
			var prima := int(s["addestramento"][e][c])
			var mx := 7 if c != "bomba" else 8
			s["addestramento"][e][c] = mini(prima + int(t[0]), mx)
			_mostra_dadi("Addestramento %s, %s" % [Dati.NOME_EQUIPAGGIO[e].to_lower(), Dati.SPECIALITA[c].to_lower()], [x], [], "+%d" % int(t[0]))
			_log("Addestramento %s (%s): dado %d, risultato %d: +%d (ora %d)." % [Dati.SPECIALITA[c].to_lower(), PLURALE[e], x, r, int(t[0]), int(s["addestramento"][e][c])])
			_effetti_addestramento(String(t[1]), e)
	s["add_scelte"] = []
	s["add_extra"] = false
	_controlla_wallis()

func _effetti_addestramento(ef: String, e: String) -> void:
	if ef.contains("x"):
		ef = ef.replace("x", "d" if d6() % 2 == 0 else "c")
	if ef.contains("R"):
		s["riposati"][e] = true
		_log("Gli equipaggi %s sono stanchi: riposo (potranno ritirare un dado basso, +1 al controllo degli equipaggi)." % PLURALE[e])
	if ef.contains("d"):
		for a in s["aerei"]:
			if int(a["danni"]) == 0:
				a["danni"] = 1
				_log("Incidente in addestramento: il Lancaster %s è danneggiato." % a["id"])
				break
	if ef.contains("c"):
		for a in s["aerei"]:
			if int(a["danni"]) == 0:
				s["aerei"].erase(a)
				_log("Schianto in addestramento: il Lancaster %s è perduto." % a["id"])
				break
		if d6() % 2 == 0:
			_pesca_elite("dopo lo schianto")
		elif int(s["equipaggi"][e]) > 0:
			s["equipaggi"][e] = int(s["equipaggi"][e]) - 1
			_log("Un equipaggio %s non c'è più." % Dati.NOME_EQUIPAGGIO[e].to_lower())
	if ef.contains("E"):
		_pesca_elite("addestramento")

func _controlla_wallis() -> void:
	var t := 0
	for e in ["recluta", "esperto", "veterano"]:
		t += int(s["addestramento"][e]["quota"])
	if t >= 12 and not s["quarantena"] and not s.get("bonus_wallis", false):
		s["bonus_wallis"] = true
		_log("Bonus Wallis! L'addestramento a quota e velocità convince il Ministero: gli Upkeep varranno il danno più alto.")

# ================================================================ P5 modifiche
func _p_modifiche() -> void:
	var id := _prendi_scelta("p_mod")
	if id != "":
		if _applica_dedica(id):
			pass
		elif id.begins_with("dado:"):
			var m := id.split(":")[1]
			s["rp"] = int(s["rp"]) - 1
			s["mod_dadi"][m] = int(s["mod_dadi"][m]) + 1
		elif id == "via":
			_esegui_modifiche()
			s["fase"] = "p_rec"
			return
	var sc := []
	var danneggiati: int = s["aerei"].filter(func(a): return int(a["danni"]) > 0).size()
	for box in ["riparazioni", "radio", "altimetro", "cabina"]:
		if box == "radio" and s["vhf"]: continue
		if box == "altimetro" and s["aldis"]: continue
		if box == "cabina" and s["dann"]: continue
		if box == "riparazioni" and danneggiati == 0: continue
		for x in _sc_dediche(box):
			sc.append(x)
		if box != "riparazioni" and int(s["rp"]) >= 1 and not dedicate(box).is_empty():
			sc.append(_sc("dado:" + box, "+1 dado per %s (1 RP)" % BOX[box], "Ora %d dadi." % (erk_box(box) + int(s["mod_dadi"][box]))))
	sc.append(_sc("via", "Esegui le modifiche", _riassunto_modifiche()))
	_chiedi("p_mod", "Modifiche (turno %d)" % int(s["piano"]), "%s Ogni squadra dedicata dà tanti dadi quanti i suoi erk. Radio VHF: basta un 6. Altimetro (luci Aldis) e cabina (mirino Dann): servono due 6 (anche in turni diversi). Riparazioni: tanti aerei quanti gli erk, 1 RP l'uno." % rp_testo(), sc)

func _riassunto_modifiche() -> String:
	var p := []
	for box in ["riparazioni", "radio", "altimetro", "cabina"]:
		var n := erk_box(box) + (int(s["mod_dadi"][box]) if box != "riparazioni" else 0)
		if n > 0:
			p.append("%s %d" % [_min(BOX[box]), n])
	return "Dadi: " + (", ".join(p) if not p.is_empty() else "nessuno")

func _esegui_modifiche() -> void:
	var n := erk_box("riparazioni")
	for a in s["aerei"]:
		if n > 0 and int(a["danni"]) > 0 and int(s["rp"]) >= 1:
			a["danni"] = 0
			n -= 1
			s["rp"] = int(s["rp"]) - 1
			_log("Il Lancaster %s è riparato (1 RP)." % a["id"])
	for box in ["radio", "altimetro", "cabina"]:
		var dadi := erk_box(box) + int(s["mod_dadi"][box])
		if dadi <= 0:
			continue
		var dd := _dadi(dadi)
		var sei := dd.count(6)
		_mostra_dadi(BOX[box], dd, [], "%d sei" % sei)
		if box == "radio":
			if sei >= 1:
				s["vhf"] = true
				_log("Radio: %s. Tutti i Lancaster hanno la radio VHF." % _lista(dd))
			else:
				_log("Radio: %s, niente sei: la radio VHF non è ancora pronta." % _lista(dd))
		else:
			s["sei"][box] = int(s["sei"][box]) + sei
			var ok := int(s["sei"][box]) >= 2
			if box == "altimetro":
				s["aldis"] = ok
			else:
				s["dann"] = ok
			_log("%s: %s, %d sei (%d su 2)%s" % [BOX[box], _lista(dd), sei, mini(int(s["sei"][box]), 2), ": modifica completata!" if ok else "."])

# ================================================================ P7-P8 ricognizione
func _p_ricognizione() -> void:
	var id := _prendi_scelta("p_rec")
	if id != "":
		if id == "fine":
			s["fase"] = "p_lancio"
			return
		_esegui_recon(id)
	var sc := []
	if int(s["rp"]) >= 5:
		for z in ["costa_olandese", "ruhr", "weser"]:
			if not z in s["recon_zone_fatte"] and int(s["recon_zone"][z]) < 3:
				sc.append(_sc("zona:" + z, "Ricognizione: %s (5 RP)" % Dati.NOME_ZONA[z], "Livello %d: ogni livello fa evitare un pericolo in più." % int(s["recon_zone"][z])))
	if int(s["rp"]) >= 1:
		for d in ["mohne", "eder", "sorpe", "ennepe", "bever", "lister", "diemel", "henne"]:
			if not d in s["recon_dighe_fatte"] and int(s["dighe"][d]["recon"]) < 4:
				sc.append(_sc("diga:" + d, "Ricognizione della %s (1 RP)" % Dati.DIGHE[d]["nome"], _info_diga(d)))
	sc.append(_sc("fine", "Fine della ricognizione"))
	_chiedi("p_rec", "Ricognizione (turno %d)" % int(s["piano"]), "%s Una volta per zona e per diga in ogni turno." % rp_testo(), sc)

func _info_diga(d: String) -> String:
	var x: Dictionary = s["dighe"][d]
	if not x["vista"]:
		return "Mai fotografata: difese e acqua sconosciute (%d rv)." % int(Dati.DIGHE[d]["rv"])
	return "Ricognizione %d, acqua %s, contraerea %d, fotoelettriche %d, palloni %d." % [int(x["recon"]), Dati.ACQUA[int(x["acqua"])], int(x["flak"]), int(x["fari"]), int(x["palloni"])]

func _esegui_recon(id: String) -> void:
	var p := id.split(":")
	if p[0] == "zona":
		s["rp"] = int(s["rp"]) - 5
		s["recon_zone"][p[1]] = int(s["recon_zone"][p[1]]) + 1
		s["recon_zone_fatte"].append(p[1])
		_log("Ricognizione su %s: livello %d." % [Dati.NOME_ZONA[p[1]], int(s["recon_zone"][p[1]])])
		return
	s["rp"] = int(s["rp"]) - 1
	s["recon_dighe_fatte"].append(p[1])
	_recon_diga(p[1], true)

func _recon_diga(d: String, aumenta: bool) -> void:
	var x: Dictionary = s["dighe"][d]
	var dd := _dadi(4)
	var nuovo := {"flak": Dati.RECON_DIFESE["flak"][dd[0] - 1], "fari": Dati.RECON_DIFESE["fari"][dd[1] - 1], "palloni": Dati.RECON_DIFESE["palloni"][dd[2] - 1]}
	var acqua_v: int = dd[3] + int(s["piano"])
	var acqua := 2 if acqua_v <= 3 else (3 if acqua_v <= 5 else 4)
	if not x["vista"]:
		for k in nuovo:
			x[k] = nuovo[k]
		x["acqua"] = acqua
		x["flak_iniziale"] = x["flak"]
		x["vista"] = true
	else:
		for k in nuovo:
			if int(nuovo[k]) < int(x[k]):
				x[k] = nuovo[k]
		if acqua > int(x["acqua"]):
			x["acqua"] = acqua
	if aumenta:
		x["recon"] = mini(int(x["recon"]) + 1, 4)
	_mostra_dadi("Ricognizione della %s" % Dati.DIGHE[d]["nome"], dd, [], "ricognizione %d" % int(x["recon"]))
	_log("Foto della %s (dadi %s): contraerea %d, fotoelettriche %d, palloni %d, acqua %s; ricognizione %d." % [Dati.DIGHE[d]["nome"], _lista(dd), int(x["flak"]), int(x["fari"]), int(x["palloni"]), Dati.ACQUA[int(x["acqua"])], int(x["recon"])])

# ================================================================ lancio?
func _p_lancio() -> void:
	var id := _prendi_scelta("p_lancio")
	if int(s["piano"]) >= 4:
		id = "lancia"
		_log("Fine della pianificazione: il raid parte con la luna di maggio... o senza.")
	if id == "lancia":
		_log("== Preparazione del volo (turno di pianificazione %d, %s) ==" % [int(s["piano"]), Dati.LUNA[int(s["piano"])]])
		s["senza_luna"] = int(s["piano"]) % 2 == 0
		for q in s["squadre"]:
			q["dedicata"] = ""
		s["fase"] = "f_aerei"
		return
	if id == "attendi":
		s["piano"] = int(s["piano"]) + 1
		s["fase"] = "p_inizio"
		return
	var pronti := mini(mini(s["aerei"].filter(func(a): return int(a["danni"]) == 0).size(), s["upkeep_scorta"].size()), int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"]))
	_chiedi("p_lancio", "Lanciare il raid?", "Fine del turno di pianificazione %d (%s). Aerei integri con equipaggio e Upkeep: circa %d. Il prossimo turno è %s." % [int(s["piano"]), Dati.LUNA[int(s["piano"])], pronti, Dati.LUNA[int(s["piano"]) + 1]],
		[_sc("lancia", "Lancia il raid ora", "Preparazione del volo, poi il decollo. %s" % ("Senza luna: -1 a sgancio e navigazione, acquisizione più difficile." if int(s["piano"]) % 2 == 0 else "Con la luna.")),
		 _sc("attendi", "Ancora due settimane di preparazione", "Più addestramento e ricognizione, ma il rischio per la sicurezza cresce e l'acqua delle dighe può calare.")])

# ================================================================ preparazione del volo (11.0)
func _f_controllo(box: String) -> void:
	var id := _prendi_scelta("f_" + box)
	if id != "" and id != "via":
		_applica_dedica(id)
	if id != "via":
		var sc := _sc_dediche(box).filter(func(x): return x["id"].begins_with("dedica"))
		sc.append(_sc("via", "Esegui il controllo"))
		var t := "Controllo degli aerei: qualche Lancaster potrebbe non essere pronto." if box == "aerei" else "Controllo degli Upkeep: qualche Upkeep potrebbe non essere montato."
		_chiedi("f_" + box, BOX[box], t + " +2 per ogni squadra fresca dedicata, +1 per ogni squadra affaticata%s." % (", -1 per la spia" if s["spia"] else ""), sc)
		return
	var mod := 0
	for q in dedicate(box):
		mod += 1 if q.get("stanca", false) else 2
	if s["spia"]:
		mod -= 1
	var dd := _dadi(2)
	var r: int = dd[0] + dd[1] + mod
	var fermi := 5 if r <= 4 else (3 if r <= 6 else (2 if r <= 9 else (1 if r <= 11 else 0)))
	if box == "ordigni":
		fermi = 4 if r <= 4 else (3 if r <= 6 else (2 if r <= 9 else (1 if r <= 11 else 0)))
	_mostra_dadi(BOX[box], dd, [], "%d: %d fermi" % [r, fermi])
	if box == "aerei":
		var integri: Array = s["aerei"].filter(func(a): return int(a["danni"]) == 0)
		_mescola(integri)
		for i in mini(fermi, integri.size()):
			integri[i]["fermo"] = true
		for a in s["aerei"]:
			if int(a["danni"]) > 0:
				a["fermo"] = true
		s["extra_costa"] = 2 if r <= 6 else (1 if r <= 11 else 0)
		_log("Controllo degli aerei (%d%+d = %d): %d Lancaster restano a terra%s." % [dd[0] + dd[1], mod, r, fermi, (", %d pericoli in più sulla costa inglese" % int(s["extra_costa"])) if int(s["extra_costa"]) > 0 else ""])
		s["fase"] = "f_ordigni"
	else:
		for i in mini(fermi, s["upkeep_scorta"].size()):
			s["upkeep_scorta"].pop_back()
		_log("Controllo degli Upkeep (%d%+d = %d): %d Upkeep non sono montati (restano %d)." % [dd[0] + dd[1], mod, r, fermi, s["upkeep_scorta"].size()])
		s["fase"] = "f_equip"

func _f_equipaggi() -> void:
	var mod := -int(s["giri_extra"])
	for e in s["riposati"]:
		if s["riposati"][e]:
			mod += 1
	var dd := _dadi(2)
	var r: int = dd[0] + dd[1] + mod
	var fermi := 4 if r <= 4 else (3 if r <= 6 else (2 if r <= 8 else (1 if r <= 10 else 0)))
	_mostra_dadi("Controllo degli equipaggi", dd, [], "%d: %d fermi" % [r, fermi])
	for i in fermi:
		var tipi := ["recluta", "esperto", "veterano"].filter(func(e): return int(s["equipaggi"][e]) > 0)
		if tipi.is_empty():
			break
		var e: String = tipi[_rng() % tipi.size()]
		s["equipaggi"][e] = int(s["equipaggi"][e]) - 1
	_log("Controllo degli equipaggi (%d%+d = %d): %d equipaggi non possono volare." % [dd[0] + dd[1], mod, r, fermi])
	s["fase"] = "f_brief"

func _f_briefing() -> void:
	var id := _prendi_scelta("f_brief")
	if id.begins_with("diga:"):
		s["rp"] = int(s["rp"]) - 1
		s["recon_dighe_fatte"].append(id.substr(5))
		_recon_diga(id.substr(5), true)
	if id != "via":
		var sc := []
		if int(s["rp"]) >= 1:
			for d in Dati.DIGHE:
				if not d in s["recon_dighe_fatte"] and int(s["dighe"][d]["recon"]) < 4:
					sc.append(_sc("diga:" + d, "Ultima ricognizione della %s (1 RP)" % Dati.DIGHE[d]["nome"], _info_diga(d)))
		sc.append(_sc("via", "Calcola il rischio per la sicurezza"))
		_chiedi("f_brief", "Briefing", "Ultime foto delle dighe (non delle zone), poi il controllo del rischio per la sicurezza. %s" % rp_testo(), sc)
		return
	_rischio_sicurezza()
	s["fase"] = "f_sortita"

func _rischio_sicurezza() -> void:
	var v := 0
	var p := []
	v += int(s["piano"]); p.append("%d turni" % int(s["piano"]))
	v += int(s["richieste"]); if int(s["richieste"]) > 0: p.append("%d richieste di RP" % int(s["richieste"]))
	v += int(s["giri_extra"]); if int(s["giri_extra"]) > 0: p.append("%d addestramenti extra" % int(s["giri_extra"]))
	for q in s["squadre"]:
		v += 2 if q.get("stanca", false) else 1
	p.append("%d squadre a Scampton" % s["squadre"].size())
	for d in s["dighe"]:
		if int(s["dighe"][d]["recon"]) >= 3:
			v += 1
	for z in s["recon_zone"]:
		if int(s["recon_zone"][z]) >= 3:
			v += 1
	if s.get("bonus_wallis", false) and not s["quarantena"]:
		v += 1
		p.append("bonus Wallis")
	var tot: int = int(s["equipaggi"]["recluta"]) + int(s["equipaggi"]["esperto"]) + int(s["equipaggi"]["veterano"])
	if tot > 0 and int(s["equipaggi"]["veterano"]) * 2 >= tot:
		v += 1
		p.append("molti veterani")
	if s["spia"]:
		var x := d6()
		v += x
		p.append("spia (+%d)" % x)
	for m in s["sicurezza"]:
		match m["id"]:
			"tirpitz":
				v -= 1
				if m["girato"]:
					v -= [1, 1, 2, 2, 3, 3][d6() - 1]
			"polizia":
				v -= 2
				if m["girato"]:
					v -= 1
			"57sqn":
				v -= [2, 2, 3, 3, 4, 4][d6() - 1]
				if m["girato"]:
					var y := d6()
					v += 1 if y <= 2 else (-3 if y <= 4 else -5)
	v = maxi(v, 0)
	s["rischio"] = v
	var r := Dati.rischio(v)
	s["allerta"] = int(r[2])
	s["mod_sorpresa"] = int(r[3])
	s["wallis"] = s.get("bonus_wallis", false) and not s["quarantena"]
	_log("Rischio per la sicurezza: %d (%s): allerta iniziale %d, modificatore della sorpresa %d. (%s)" % [v, r[1], s["allerta"], s["mod_sorpresa"], ", ".join(p)])

# ================================================================ sortita (11.5)
func _f_sortita() -> void:
	if not s.has("sortita"):
		_prepara_sortita()
		if s["lanc"].is_empty():
			_log("Nessun Lancaster è pronto a partire: l'operazione Chastise è annullata.")
			s.erase("sortita")
			_concludi()
			return
	var id := _prendi_scelta("f_sortita")
	var st: Dictionary = s["sortita"]
	if id != "":
		_scelta_sortita(id)
		if s["fase"] != "f_sortita":
			return
	var liberi: Array = st["pronti"].filter(func(x): return not st["assegnati"].has(x))
	var sc := []
	match st["passo"]:
		"menu":
			if liberi.size() >= 2:
				sc.append(_sc("onda", "Forma un'onda", "Almeno due Lancaster con lo stesso bersaglio; volano insieme e possono entrare coordinati."))
			if not liberi.is_empty():
				sc.append(_sc("isolato", "Manda un Lancaster da solo"))
				sc.append(_sc("auto", "Piano automatico per i restanti", "Onde da tre verso le dighe con più rv e meno difese note."))
			sc.append(_sc("riserva", "Bersaglio di riserva: %s" % Dati.DIGHE[s["riserva"]]["nome"], "Cambia il bersaglio di riserva della squadriglia."))
			if not st["assegnati"].is_empty():
				sc.append(_sc("decolla", "Decollo!", "Partono %d Lancaster; %d restano a Scampton. Capacità di sortita: %d aerei per turno di volo." % [st["assegnati"].size(), liberi.size(), _capacita_sortita()]))
			_chiedi("f_sortita", "Sortita", "Lancaster pronti: %d. %s" % [liberi.size(), _riassunto_onde()], sc)
		"primario", "secondario", "riserva", "isolato_primario":
			var titolo: String = {"primario": "Bersaglio principale dell'onda", "secondario": "Bersaglio secondario dell'onda", "riserva": "Bersaglio di riserva", "isolato_primario": "Bersaglio del Lancaster"}[st["passo"]]
			for d in ["mohne", "eder", "sorpe", "ennepe", "bever", "lister", "diemel", "henne"]:
				sc.append(_sc("diga:" + d, Dati.DIGHE[d]["nome"], "%d rv. %s" % [int(Dati.DIGHE[d]["rv"]), _info_diga(d)]))
			if st["passo"] == "secondario":
				sc.append(_sc("diga:", "Nessun secondario"))
			_chiedi("f_sortita", titolo, "Le dighe valgono rv diversi: Möhne 8, Eder 9, Sorpe 5, Diemel e Lister 4, Ennepe e Bever 3, Henne 2.", sc)
		"membri":
			for x in liberi:
				sc.append(_sc("lanc:" + x, "Aggiungi %s" % _desc_aereo(x)))
			if st["onda"]["membri"].size() >= 2 or liberi.is_empty():
				sc.append(_sc("chiudi", "Onda completa (%d Lancaster)" % st["onda"]["membri"].size()))
			_chiedi("f_sortita", "Componi l'onda", "Il primo Lancaster scelto guida l'onda: la navigazione dell'onda usa il suo equipaggio.", sc)
		"isolato":
			for x in liberi:
				sc.append(_sc("lanc:" + x, _desc_aereo(x)))
			_chiedi("f_sortita", "Lancaster isolato", "Quale Lancaster vola da solo?", sc)

func _desc_aereo(id: String) -> String:
	var l := lanc(id)
	var t := "%s (%s), equipaggio %s" % [l["id"], l["pilota"], Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower()]
	if l["elite"] != "":
		t += ", " + Dati.SPECIALISTI[l["elite"]]["nome"]
	if l.get("jinx", false):
		t += ", con il cane di Gibson"
	return t

func _riassunto_onde() -> String:
	var st: Dictionary = s["sortita"]
	if st["gruppi"].is_empty():
		return "Nessuna onda formata."
	var p := []
	for g in st["gruppi"]:
		p.append("%s verso la %s" % [", ".join(g["membri"]), Dati.DIGHE[g["primario"]]["nome"]])
	return "Già pronti: " + "; ".join(p) + "."

func _capacita_sortita() -> int:
	var t := 0
	for q in s["squadre"]:
		t += int(valori(q["id"])[2])
	return maxi(t, 2)

## Equipaggi, specialisti e Upkeep si assegnano ai Lancaster pronti (i migliori equipaggi agli aerei integri).
func _prepara_sortita() -> void:
	var aerei: Array = s["aerei"].filter(func(a): return int(a["danni"]) == 0 and not a.get("fermo", false))
	var equip := []
	for e in ["veterano", "esperto", "recluta"]:
		for i in int(s["equipaggi"][e]):
			equip.append(e)
	var n := mini(mini(aerei.size(), equip.size()), s["upkeep_scorta"].size())
	var elite: Array = s["elite"].filter(func(e): return Dati.SPECIALISTI.has(e))
	var pronti := []
	s["lanc"] = []
	for i in n:
		var a: Dictionary = aerei[i]
		var l := {"id": a["id"], "pilota": Dati.LANCASTER[a["id"]]["pilota"], "equip": equip[i], "upkeep": s["upkeep_scorta"].pop_back(),
			"danni": 0, "pos": "attesa", "zona": "inghilterra", "elite": "", "candidati": [], "segnalino": "", "razzo": false,
			"inizio_vicino": false, "esito": "", "onda": "", "primario": "", "secondario": "", "guasti": [], "diga": "",
			"entra": 1, "entrata": "", "arrivo": 0, "elite_scelto": true}
		if i < elite.size():
			l["elite"] = elite[i]
		s["lanc"].append(l)
		pronti.append(a["id"])
	if "jinx" in s["elite"] and not s["lanc"].is_empty():
		s["lanc"][0]["jinx"] = true
	s["sortita"] = {"passo": "menu", "pronti": pronti, "assegnati": [], "gruppi": [], "onda": {}}
	_log("Sortita: %d Lancaster pronti con equipaggio e Upkeep." % n)
	for l in s["lanc"]:
		_log("%s: equipaggio %s%s." % [nome_l(l), Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower(), (", con %s" % Dati.SPECIALISTI[l["elite"]]["nome"]) if l["elite"] != "" else ""])

func _scelta_sortita(id: String) -> void:
	var st: Dictionary = s["sortita"]
	match st["passo"]:
		"menu":
			match id:
				"onda":
					st["onda"] = {"membri": [], "primario": "", "secondario": ""}
					st["passo"] = "primario"
				"isolato":
					st["passo"] = "isolato"
				"riserva":
					st["passo"] = "riserva"
				"auto":
					_piano_automatico()
				"decolla":
					_decolla()
		"primario":
			st["onda"]["primario"] = id.substr(5)
			st["passo"] = "secondario"
		"secondario":
			st["onda"]["secondario"] = id.substr(5)
			st["passo"] = "membri"
		"riserva":
			s["riserva"] = id.substr(5)
			st["passo"] = "menu"
		"membri":
			if id == "chiudi":
				st["gruppi"].append(st["onda"])
				st["passo"] = "menu"
			else:
				st["onda"]["membri"].append(id.substr(5))
				st["assegnati"].append(id.substr(5))
		"isolato":
			st["onda"] = {"membri": [id.substr(5)], "primario": "", "secondario": ""}
			st["assegnati"].append(id.substr(5))
			st["passo"] = "isolato_primario"
		"isolato_primario":
			st["onda"]["primario"] = id.substr(5)
			st["gruppi"].append(st["onda"])
			st["passo"] = "menu"

func _piano_automatico() -> void:
	var st: Dictionary = s["sortita"]
	var liberi: Array = st["pronti"].filter(func(x): return not st["assegnati"].has(x))
	var ordine := ["mohne", "eder", "sorpe", "ennepe", "lister", "diemel", "bever", "henne"]
	ordine.sort_custom(func(a, b): return float(Dati.DIGHE[a]["rv"]) - 1.5 * float(s["dighe"][a]["flak"] + s["dighe"][a]["fari"] * 2) > float(Dati.DIGHE[b]["rv"]) - 1.5 * float(s["dighe"][b]["flak"] + s["dighe"][b]["fari"] * 2))
	var k := 0
	while liberi.size() >= 2:
		var n := mini(3, liberi.size())
		if liberi.size() == 4:
			n = 2
		var m: Array = liberi.slice(0, n)
		liberi = liberi.slice(n)
		var prim: String = ordine[k % 3]
		var sec: String = ordine[(k + 1) % 3]
		st["gruppi"].append({"membri": m, "primario": prim, "secondario": sec})
		st["assegnati"].append_array(m)
		k += 1
	for x in liberi:
		st["gruppi"].append({"membri": [x], "primario": ordine[k % 3], "secondario": ordine[(k + 1) % 3]})
		st["assegnati"].append(x)
	_log("Piano automatico: %s" % _riassunto_onde())

func _decolla() -> void:
	var st: Dictionary = s["sortita"]
	var cap := _capacita_sortita()
	var turno := 1
	var usati := 0
	var nomi := ["Prima ondata", "Seconda ondata", "Terza ondata", "Quarta ondata", "Quinta ondata", "Sesta ondata", "Settima ondata", "Ottava ondata"]
	var ko := 0
	for g in st["gruppi"]:
		var m: Array = g["membri"]
		if usati + m.size() > cap and usati > 0:
			turno += 1
			usati = 0
		usati += m.size()
		var oid := ""
		if m.size() >= 2:
			oid = "O%d" % s["onde"].size()
			s["onde"][oid] = {"nome": nomi[mini(ko, nomi.size() - 1)], "capo": m[0], "buona": true, "membri": m.duplicate()}
			ko += 1
		for x in m:
			var l := lanc(x)
			l["onda"] = oid
			l["primario"] = g["primario"]
			l["secondario"] = g.get("secondario", "")
			l["entra"] = turno
			l["pos"] = "volo" if turno == 1 else "attesa"
	# chi non è assegnato resta a terra
	var a_terra: Array = s["lanc"].filter(func(l): return l["primario"] == "")
	for l in a_terra:
		s["lanc"].erase(l)
	for d in s["dighe"]:
		s["dighe"][d]["flak_iniziale"] = int(s["dighe"][d]["flak"])
	s.erase("sortita")
	_log("== Decollo: %d Lancaster verso le dighe (capacità di sortita %d per turno di volo) ==" % [s["lanc"].size(), cap])
	s["turno_volo"] = 1
	s["fase"] = "v_inizio"

# ================================================================ sorpresa alle dighe (P10)
func _arrivo_diga(d: String) -> void:
	if d in s["sorpresa_fatta"]:
		return
	s["sorpresa_fatta"].append(d)
	var x: Dictionary = s["dighe"][d]
	var rec: int = int(x["recon"])
	if rec <= 1:
		var dd := _dadi(4)
		if rec == 0 or not x["vista"]:
			x["flak"] = Dati.RECON_DIFESE["flak"][dd[0] - 1]
			x["fari"] = Dati.RECON_DIFESE["fari"][dd[1] - 1]
			x["palloni"] = Dati.RECON_DIFESE["palloni"][dd[2] - 1]
		var av: int = dd[3] + int(s["piano"])
		x["acqua"] = 2 if av <= 3 else (3 if av <= 5 else 4)
		x["vista"] = true
		_log("Prima vista della %s: contraerea %d, fotoelettriche %d, palloni %d, acqua %s." % [Dati.DIGHE[d]["nome"], int(x["flak"]), int(x["fari"]), int(x["palloni"]), Dati.ACQUA[int(x["acqua"])]])
	var retro: Array = Dati.RETRO_RECON[int(s["retro_recon"][d])]
	if int(x["acqua"]) == 4:
		var y := d6() + int(retro[3])
		if y < int(s["piano"]):
			x["acqua"] = 2
			_log("Il livello dell'acqua della %s è sceso: ora in salita." % Dati.DIGHE[d]["nome"])
	var icona: String = Dati.ICONE[d][clampi(rec, 0, 4)]
	var numero: int = int(retro[0]) if icona == "" else (int(retro[1]) if icona == "r" else int(retro[2]))
	var dd2 := _dadi(2)
	var somma: int = dd2[0] + dd2[1] + int(s.get("mod_sorpresa", 0))
	_mostra_dadi("Sorpresa alla %s: sorpresa sotto %d" % [Dati.DIGHE[d]["nome"], numero], dd2, [], "SORPRESA" if somma < numero else "nessuna")
	if somma >= numero:
		_log("Controllo della sorpresa alla %s: %d contro %d, nessuna sorpresa." % [Dati.DIGHE[d]["nome"], somma, numero])
		return
	_log("Sorpresa alla %s (%d contro %d): le difese sono state rinforzate!" % [Dati.DIGHE[d]["nome"], somma, numero])
	for c in ["flak", "fari", "palloni"]:
		var z := d6()
		var inc: int = Dati.SORPRESA_DIFESE[c][z - 1]
		x[c] = mini(int(x[c]) + inc, 4)
		if Dati.SORPRESA_CACCIA.has(c) and z in Dati.SORPRESA_CACCIA[c]:
			x["caccia_vicino"] = true
		if inc > 0:
			_log("%s +%d (ora %d)." % [_nome_dif(c).capitalize(), inc, int(x[c])])
	x["flak_iniziale"] = int(x["flak"])

# ================================================================ rapporto
func _rapporto_volo(rientrati: int) -> Dictionary:
	var r := super._rapporto_volo(rientrati)
	var rv: int = int(r["rv"])
	if s["dighe"]["mohne"]["breccia"] and s["dighe"]["sorpe"]["breccia"]:
		rv += 1
	var persi: int = int(r["persi"])
	var tot: int = s["lanc"].size()
	var t := ""
	if rv >= 17:
		t = "Trionfo" if persi * 4 <= tot else ("Le dighe sono cadute" if persi * 2 <= tot else "Vittoria pagata col sangue")
	elif rv >= 8:
		t = "Successo parziale" if persi * 2 <= tot else "Successo amaro"
	elif rv > 0:
		t = "Danni minori"
	else:
		t = "Fallimento" if persi * 2 <= tot else "Disastro"
	r["titolo"] = t
	r["rv"] = rv
	r["spiega"] = ("Nessun Lancaster è partito." if tot == 0 else "") + "Campagna conclusa con %d rv di dighe aperte su %d Lancaster partiti. Storicamente: Möhne ed Eder aperte (17 rv), 8 Lancaster su 19 perduti." % [rv, tot] + (String(r["spiega"]).substr(String(r["spiega"]).find(" Sorte")) if String(r["spiega"]).contains(" Sorte") else "")
	return r
