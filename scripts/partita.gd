## Motore delle regole di Enemy Coast Ahead: The Dambuster Raid, scenari d'attacco 1-5 (regole 1.0-5.0).
##
## Lo stato è un unico dizionario `s`, salvabile in JSON. Il motore procede da solo finché non serve una
## decisione del giocatore: allora riempie `s.attesa` (titolo, testo, scelte) e si ferma. `scegli(id)` applica
## la scelta e riparte. Tutti i tiri di dado passano dal generatore interno, salvato nello stato.
class_name Partita
extends RefCounted

var s: Dictionary = {}

# ================================================================ dadi
func _rng() -> int:
	var x: int = int(s["rng"]) & 0xFFFFFFFF
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= x >> 17
	x ^= (x << 5) & 0xFFFFFFFF
	x &= 0xFFFFFFFF
	if x == 0:
		x = 2463534242
	s["rng"] = x
	return x

func d6() -> int:
	return int(_rng() % 6) + 1

## Dadi stregati [13.0]: con il cane di Gibson a bordo, quando si tira un solo dado se ne tirano due e si tiene
## il peggiore. modo: "alto" (un numero alto è peggio), "basso" (basso è peggio), "pari" (dispari è peggio).
func d6_per(l: Dictionary, modo: String) -> int:
	var x := d6()
	if l.is_empty() or not l.get("jinx", false):
		return x
	var y := d6()
	var r := x
	match modo:
		"alto": r = maxi(x, y)
		"basso": r = mini(x, y)
		_: r = x if x % 2 == 1 else y
	_log("Il cane di Gibson è a bordo di %s: due dadi (%d e %d), si tiene il peggiore (%d)." % [l["id"], x, y, r])
	return r

func _dadi(n: int) -> Array:
	var r := []
	for i in n:
		r.append(d6())
	return r

## Ricorda il tiro per la grafica dei dadi.
func _mostra_dadi(etichetta: String, valori: Array, tenuti: Array = [], esito := "") -> void:
	s["dadi"] = {"etichetta": etichetta, "valori": valori, "tenuti": tenuti, "esito": esito, "n": int(s.get("n_tiri", 0)) + 1}
	s["n_tiri"] = int(s.get("n_tiri", 0)) + 1

func _log(t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > 400:
		s["log"] = s["log"].slice(s["log"].size() - 400)

# ================================================================ nuova partita
func nuova(scen: int, seme: int = 0, facile := false) -> void:
	var sc: Dictionary = Dati.SCENARI[scen]
	if seme == 0:
		seme = int(Time.get_unix_time_from_system() * 1000.0) % 2000000000 + 7
	s = {
		"versione": 1, "scen": scen, "facile": facile, "seme": seme, "rng": seme * 2654435761 % 4294967296 + 1,
		"turno": int(sc["turno"]), "giri_8": 0, "turni": 0, "malus_rtb": 0,
		"visibilita": "sereno" if facile else sc["visibilita"], "allerta": 1 if facile else int(sc["allerta"]),
		"mod_visibilita": 0 if facile else int(sc["mod_visibilita"]),
		"diga": sc["diga"], "dighe": {}, "razzi": [], "lanc": [], "coppe": {"q": [], "v": []},
		"avv": {}, "flak": {}, "rilasciati_turno": 0, "caccia_attacco": false, "nebbia_di_guerra": sc.get("nebbia_di_guerra", false) and not facile,
		"fase": "specialisti", "attesa": {}, "log": [], "dadi": {}, "fine": "", "esito": {}, "codice": _codice(seme),
		"usati": {}, "tiro_ripetuto": {}, "eventi": [],
	}
	for d in sc["dighe"]:
		var x: Dictionary = sc["dighe"][d]
		s["dighe"][d] = {"acqua": int(x["acqua"]), "recon": int(x["recon"]), "attivita": int(x["attivita"]),
			"flak": int(x.get("flak", 0)), "fari": int(x.get("fari", 0)), "palloni": int(x.get("palloni", 0)),
			"upkeep": [], "breccia": false, "caccia_vicino": false, "flak_iniziale": int(x.get("flak", 0))}
	for t in sc["razzi"]:
		s["razzi"].append({"turno": int(t), "giro": 0, "assoluto": int(t) - int(sc["turno"])})
	for g in Dati.GETTONI_QUOTA:
		_rimetti("q", g["id"])
	for g in Dati.GETTONI_VELOCITA:
		_rimetti("v", g["id"])
	# Upkeep pescati a caso e coperti
	var sacco := []
	for i in Dati.UPKEEP.size():
		sacco.append(i)
	_mescola(sacco)
	for l in sc["lanc"]:
		var equip: String = l[1]
		if facile and scen == 5:
			equip = "veterano"
		var ul := {"id": l[0], "pilota": Dati.LANCASTER[l[0]]["pilota"], "equip": equip,
			"upkeep": sacco.pop_back() if l[2] else -1, "danni": 1 if l[4] else 0, "pos": l[3],
			"elite": "", "candidati": l[5], "segnalino": "", "razzo": false, "inizio_vicino": false, "esito": ""}
		s["lanc"].append(ul)
	if sc.get("danno_precedente", false):
		var d: String = sc["diga"]
		s["dighe"][d]["upkeep"].append({"u": sacco.pop_back(), "esito": "colpito", "valore": -1, "lanc": "AJ-T", "rivelato": false, "precedente": true})
	s["sacco"] = sacco
	_log("== %s ==" % sc["titolo"])
	_log("Ore %s. Turno d'attacco %d, visibilità: %s." % [sc["ora"], s["turno"], s["visibilita"]])
	if facile:
		_log("Prima partita: equipaggio veterano, cielo sereno, allerta 1, nessuna incertezza sulla diga.")
	avanza()

func _codice(seme: int) -> String:
	var lettere := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var c := ""
	var x: int = seme
	for i in 6:
		x = (x * 1103515245 + 12345) % 2147483648
		c += lettere[x % lettere.length()]
	return c

func _mescola(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = _rng() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

# ================================================================ interrogazioni
func scenario() -> Dictionary:
	return Dati.SCENARI[int(s["scen"])] if Dati.SCENARI.has(int(s["scen"])) else Dati.VOLI[int(s["scen"])]

func nome_scenario() -> String:
	return "Scenario %d: %s" % [int(s["scen"]), scenario()["titolo"]]

func lanc(id: String) -> Dictionary:
	for l in s["lanc"]:
		if l["id"] == id:
			return l
	return {}

func in_mappa(l: Dictionary) -> bool:
	return l["pos"] in ["vicino", "lontano", "avvicinamento", "scorta", "sgancio", "salita"]

func lanc_in(pos: String) -> Array:
	return s["lanc"].filter(func(l): return l["pos"] == pos)

func sulla_mappa() -> Array:
	return s["lanc"].filter(func(l): return in_mappa(l))

func diga_corrente() -> String:
	if s["avv"].has("diga"):
		return s["avv"]["diga"]
	return s["diga"]

func dg(d := "") -> Dictionary:
	return s["dighe"][d if d != "" else diga_corrente()]

func capacita(d: String) -> int:
	return int(Dati.DIGHE[d]["capacita"][int(s["dighe"][d]["acqua"])])

func danni_diga(d: String, anche_nascosti := false) -> int:
	var t := 0
	for u in s["dighe"][d]["upkeep"]:
		if u["esito"] == "colpito" and int(u["valore"]) >= 0:
			t += int(u["valore"])
	return t

func addestramento(l: Dictionary) -> int:
	var v := int(Dati.ADDESTRAMENTO[l["equip"]])
	if ha_guasto(l, "inabile"):
		v -= 3
	return maxi(v, 0)

## Livello di addestramento per specialità (nav, quota, bomba): negli scenari 1-9 è uguale per tutte.
func livello(l: Dictionary, _cat: String) -> int:
	return addestramento(l)

## Pericoli attaccati al Lancaster negli scenari di volo (lista vuota negli scenari d'attacco).
func ha_guasto(l: Dictionary, g: String) -> bool:
	return g in l.get("guasti", [])

func conta_guasti(l: Dictionary, g: String) -> int:
	return l.get("guasti", []).count(g)

func ruolo(l: Dictionary) -> String:
	if l["elite"] == "":
		return ""
	return Dati.SPECIALISTI[l["elite"]]["ruolo"]

func danneggiato(l: Dictionary) -> bool:
	return int(l["danni"]) >= 1

func nome_l(l: Dictionary) -> String:
	return "%s (%s)" % [l["id"], l["pilota"]]

func ha_comandante() -> bool:
	for l in sulla_mappa():
		if ruolo(l) == "comandante" and not s["usati"].has(l["elite"]):
			return true
	return false

func _usa_comandante() -> void:
	for l in s["lanc"]:
		if ruolo(l) == "comandante":
			s["usati"][l["elite"]] = true

# ================================================================ motore
func avanza() -> void:
	var giri := 0
	while s["attesa"].is_empty() and s["fine"] == "" and giri < 2000:
		giri += 1
		_passo()
	if s["fine"] != "" and s["attesa"].is_empty() and s["fase"] != "concluso":
		_concludi()

func _chiedi(tipo: String, titolo: String, testo: String, scelte: Array, extra := {}) -> void:
	var a := {"tipo": tipo, "titolo": titolo, "testo": testo, "scelte": scelte}
	a.merge(extra)
	s["attesa"] = a

func _sc(id: String, testo: String, nota := "") -> Dictionary:
	return {"id": id, "testo": testo, "nota": nota}

func scegli(id: String) -> void:
	var a: Dictionary = s["attesa"]
	if a.is_empty():
		return
	var ok := false
	for c in a["scelte"]:
		if c["id"] == id:
			ok = true
	if not ok:
		return
	s["attesa"] = {}
	_applica(a, id)
	avanza()

func _passo() -> void:
	match s["fase"]:
		"specialisti": _f_specialisti()
		"inizio": _f_inizio()
		"corsa": _f_corsa()
		"avv_1": _f_vettore()
		"avv_2": _f_pesca("v", "avv_3")
		"avv_3": _f_pesca("q", "avv_4")
		"avv_4": _f_flak("avv_5")
		"avv_5": _f_decisione("lontana")
		"avv_6": _f_regola("avv_7")
		"avv_7": _f_flak("avv_8")
		"avv_8": _f_mitragliatrici("avv_9", false)
		"avv_9": _f_decisione("vicina")
		"avv_10": _f_regola("avv_10b")
		"avv_10b": _f_flak("avv_11")
		"avv_11": _f_mitragliatrici("avv_12", false)
		"avv_12": _f_decisione("ravvicinata")
		"sg_1": _f_pesca_sgancio("q", "sg_2")
		"sg_2": _f_pesca_sgancio("v", "sg_3")
		"sg_3": _f_sgancio()
		"sg_4": _f_salita()
		"sg_5": _f_flak("sg_6")
		"sg_6": _f_mitragliatrici("giro", true)
		"flak": _f_flak_passo()
		"giro": _f_giro()
		"st_1": _f_visibilita()
		"st_2": _f_logoramento()
		"st_3": _f_caccia()
		"st_4": _f_detonazione()
		"st_5": _f_razzi()
		"fine_turno": _f_fine_turno()
		_:
			s["fine"] = "errore"

func _applica(a: Dictionary, id: String) -> void:
	match a["tipo"]:
		"specialista":
			var l := lanc(a["lanc"])
			l["elite"] = "" if id == "nessuno" else id
			if id != "nessuno":
				_log("%s porta con sé %s (%s)." % [nome_l(l), Dati.SPECIALISTI[id]["nome"], Dati.RUOLI[ruolo(l)][0].to_lower()])
		"corsa":
			if id == "nessuno":
				_log("Nessun Lancaster inizia l'avvicinamento in questo turno.")
				s["fase"] = "giro"
			else:
				_inizia_avvicinamento(id)
		"scorta":
			if id == "basta":
				_dopo_scorte()
			else:
				var l := lanc(id)
				l["pos"] = "scorta"
				s["avv"]["scorte"].append(id)
				_log("%s fa da scorta." % nome_l(l))
				_chiedi_scorte()
		"luci":
			s["avv"]["luci"] = id == "si"
			_log("Luci Aldis %s." % ("accese: si possono pescare gettoni Quota, ma la contraerea tira 3 dadi" if id == "si" else "spente: niente gettoni Quota"))
			s["fase"] = "avv_1"
		"vettore":
			_applica_vettore(int(id))
			s["fase"] = "avv_2"
		"segnalino":
			s["avv"]["extra"] = 1 if id == "si" else 0
			s["avv"]["chiesto_segnalino"] = true
			if id == "si":
				var l := lanc(s["avv"]["lanc"])
				_log("%s usa il segnalino «%s»: un gettone in più." % [nome_l(l), _nome_segnalino(l["segnalino"])])
				l["segnalino"] = ""
		"gettone":
			_tieni_gettone(a["tipo_g"], id, a["pescati"], a.get("sgancio", false))
			s["fase"] = a["dopo"]
			s["avv"].erase("chiesto_segnalino")
		"regola":
			s["avv"]["regola"] = id if id != "no" else ""
			if id == "no":
				_log("Nessuna regolazione.")
				s["fase"] = a["dopo"]
				s["avv"].erase("chiesto_segnalino")
		"decisione":
			_applica_decisione(id, a["zona"])
		"flak_bersaglio":
			s["flak"]["bersaglio"] = id
			s["flak"]["passo"] = "evasione"
		"flak_evasione":
			_applica_evasione(id)
		"martin":
			s["flak"]["martin"] = id
		"comandante":
			s["tiro_ripetuto"][a["chiave"]] = id == "si"
			s["ripeti"] = id == "si"
			if id == "si":
				_usa_comandante()
				_log("Gibson ordina di ripetere: il tiro si rifà.")
		"mitragliatrici":
			s["mitra_bersaglio"] = id
		"giro":
			_applica_giro(id)
		_:
			pass

# ================================================================ preparazione
func _f_specialisti() -> void:
	for l in s["lanc"]:
		if l["elite"] == "" and not l.get("elite_scelto", false):
			var c: Array = l["candidati"]
			l["elite_scelto"] = true
			if c.size() == 1:
				l["elite"] = c[0]
				_log("%s porta con sé %s (%s)." % [nome_l(l), Dati.SPECIALISTI[c[0]]["nome"], Dati.RUOLI[ruolo(l)][0].to_lower()])
			elif c.size() > 1:
				var sc := []
				for e in c:
					var r: Array = Dati.RUOLI[Dati.SPECIALISTI[e]["ruolo"]]
					sc.append(_sc(e, "%s · %s" % [Dati.SPECIALISTI[e]["nome"], r[0]], r[1]))
				_chiedi("specialista", "Specialista di %s" % l["id"], "Ogni Lancaster può avere un solo specialista. Chi porta %s in questa missione?" % l["pilota"], sc, {"lanc": l["id"]})
				return
	s["fase"] = "inizio"

func _f_inizio() -> void:
	s["rilasciati_turno"] = 0
	for l in s["lanc"]:
		l["razzo"] = false
		l["inizio_vicino"] = l["pos"] == "vicino"
	_log("-- Turno d'attacco %d (ore %s) --" % [s["turno"], ora()])
	s["fase"] = "corsa"

func ora() -> String:
	return ["", ":00", ":07", ":16", ":23", ":30", ":37", ":45", ":53"][int(s["turno"])]

# ================================================================ fase di corsa (4.1)
func _f_corsa() -> void:
	var ok := []
	for l in lanc_in("vicino"):
		if int(l["upkeep"]) >= 0:
			ok.append(l)
	if ok.is_empty():
		s["fase"] = "giro"
		return
	var sc := []
	for l in ok:
		sc.append(_sc(l["id"], "Avvicinamento: %s" % nome_l(l), _descrivi(l)))
	sc.append(_sc("nessuno", "Nessun avvicinamento in questo turno", "Si passa alla fase di volo in cerchio."))
	_chiedi("corsa", "Fase di corsa", "Un solo Lancaster con l'Upkeep può lasciare il Cerchio vicino e iniziare l'avvicinamento nella zona lontana.", sc)

func _descrivi(l: Dictionary) -> String:
	var t := "Equipaggio %s" % Dati.NOME_EQUIPAGGIO[l["equip"]].to_lower()
	if l["elite"] != "":
		t += ", %s (%s)" % [Dati.SPECIALISTI[l["elite"]]["nome"], Dati.RUOLI[ruolo(l)][0].to_lower()]
	if danneggiato(l):
		t += ", danneggiato"
	if l["segnalino"] != "":
		t += ", segnalino «%s»" % _nome_segnalino(l["segnalino"])
	return t + "."

func _nome_segnalino(x: String) -> String:
	return "Passaggio a vuoto" if x == "passaggio" else "Avvicinamento osservato"

func _inizia_avvicinamento(id: String) -> void:
	var l := lanc(id)
	var diga: String = s["diga"]
	if s["nebbia_di_guerra"]:
		var d := d6()
		diga = "ennepe" if d % 2 == 0 else "bever"
		_mostra_dadi("Nebbia di guerra", [d], [], "Ennepe" if diga == "ennepe" else "Bever")
		_log("Nebbia di guerra: dado %d, la diga sotto %s è la %s." % [d, l["pilota"], Dati.DIGHE[diga]["nome"]])
	s["avv"] = {"lanc": id, "diga": diga, "zona": "lontana", "scorte": [], "luci": false, "v": "", "q": "",
		"blocca_v": false, "blocca_q": false, "m": 0, "anticipato": false, "tardivo": 0, "S": 0, "A": 0}
	l["pos"] = "avvicinamento"
	_log("%s entra nella zona lontana dell'avvicinamento." % nome_l(l))
	_chiedi_scorte()

func _chiedi_scorte() -> void:
	var cand := lanc_in("vicino").filter(func(x): return int(x["upkeep"]) < 0)
	if s["avv"]["scorte"].size() >= 2 or cand.is_empty():
		_dopo_scorte()
		return
	var sc := []
	for c in cand:
		sc.append(_sc(c["id"], "Scorta: %s" % nome_l(c), "Mitragliatrici in più e un bersaglio in più per la contraerea."))
	sc.append(_sc("basta", "Nessun'altra scorta" if s["avv"]["scorte"].size() > 0 else "Nessuna scorta"))
	_chiedi("scorta", "Scorte", "Fino a due Lancaster senza Upkeep dal Cerchio vicino possono accompagnare l'attacco.", sc)

func _dopo_scorte() -> void:
	var l := lanc(s["avv"]["lanc"])
	if Dati.senza_zona_vicina(s["avv"]["diga"]):
		s["avv"]["luci"] = false
		_log("Sulla %s le luci Aldis non servono: si pescano comunque i gettoni Quota." % Dati.DIGHE[s["avv"]["diga"]]["nome"])
		s["fase"] = "avv_1"
		return
	_chiedi("luci", "Luci Aldis", "Le due luci Aldis sotto la fusoliera indicano la quota sull'acqua. Accese permettono di pescare i gettoni Quota, ma rendono %s un bersaglio migliore: la contraerea tira 3 dadi e tiene i due più letali." % l["id"],
		[_sc("si", "Accendi le luci Aldis", "Gettoni Quota, contraerea con 3 dadi."), _sc("no", "Luci spente", "Niente gettoni Quota: sgancio senza modificatore di quota.")])

# ================================================================ avvicinamento
## Passo 1: vettore d'avvicinamento (A1, tabella sulla mappa).
func _f_vettore() -> void:
	var l := lanc(s["avv"]["lanc"])
	if ruolo(l) == "pilota_vettore":
		var dd := _dadi(2)
		_mostra_dadi("Vettore d'avvicinamento (Shannon: 2 dadi)", dd)
		if dd[0] != dd[1]:
			var sc := []
			for v in dd:
				sc.append(_sc(str(v), "Usa il %d" % v, _testo_vettore(_vettore(v))))
			_chiedi("vettore", "Vettore d'avvicinamento", "%s tira due dadi e sceglie quale usare." % l["pilota"], sc)
			return
		_applica_vettore(dd[0])
	else:
		var d := d6()
		_mostra_dadi("Vettore d'avvicinamento", [d])
		_applica_vettore(d)
	s["fase"] = "avv_2"

func _vettore(d: int) -> Dictionary:
	var diga: String = s["avv"]["diga"]
	var col: String = Dati.DIGHE[diga]["colonna"]
	var riga: int = clampi(int(s["dighe"][diga]["recon"]), 0, 4)
	var fasce: Array = Dati.FASCE[col]
	var f := 0
	for i in 3:
		if d >= fasce[i][0] and d <= fasce[i][1]:
			f = i
	var cas: Array = Dati.VETTORE[col][riga][f]
	var r: String = cas[0]
	if s["visibilita"] == "nebbia":
		r += cas[1]
	var S := r.count("S")
	var A := r.count("A")
	var M := r.count("M")
	var annullati: int = mini(A, s["razzi"].size())
	return {"S": S, "A": A - annullati, "M": M, "annullati": annullati}

func _testo_vettore(v: Dictionary) -> String:
	var p := []
	if v["S"] > 0: p.append("-%d gettone Velocità" % v["S"])
	if v["A"] > 0: p.append("-%d gettone Quota" % v["A"])
	if v["M"] > 0: p.append("+%d Michelskopf" % v["M"])
	if v["annullati"] > 0: p.append("%d effetto Quota annullato dai razzi" % v["annullati"])
	return "nessun effetto" if p.is_empty() else ", ".join(p)

func _applica_vettore(d: int) -> void:
	var v := _vettore(d)
	s["avv"]["S"] = v["S"]
	s["avv"]["A"] = v["A"]
	s["avv"]["m"] += v["M"]
	_log("Vettore d'avvicinamento (dado %d, ricognizione %d, %s): %s." % [d, dg()["recon"], s["visibilita"], _testo_vettore(v)])

func _quanti(tipo: String) -> int:
	var l := lanc(s["avv"]["lanc"])
	var n := Dati.gettoni_da_livello(livello(l, "quota"))
	if tipo == "v":
		if ruolo(l) == "motorista": n += 1
		if ha_guasto(l, "comandi_v"): n -= 1
		n -= int(s["avv"]["S"])
	else:
		if ruolo(l) == "navigatore_q": n += 1
		if ha_guasto(l, "comandi_q"): n -= 1
		n -= int(s["avv"]["A"])
	return n

func _puo_quota() -> bool:
	if Dati.senza_zona_vicina(s["avv"]["diga"]):
		return true
	if not s.get("aldis", true):
		return false
	return s["avv"]["luci"] and not ha_guasto(lanc(s["avv"]["lanc"]), "no_aldis")

## Passi 2 e 3: controllo della velocità e della quota (A2, A3).
func _f_pesca(tipo: String, dopo: String) -> void:
	var l := lanc(s["avv"]["lanc"])
	var nome := "Velocità" if tipo == "v" else "Quota"
	if tipo == "q" and not _puo_quota():
		s["avv"]["blocca_q"] = true
		_log("Luci Aldis spente: nessun gettone Quota.")
		s["fase"] = dopo
		return
	var n := _quanti(tipo)
	if l["segnalino"] != "" and not s["avv"].has("chiesto_segnalino"):
		_chiedi("segnalino", "Controllo %s" % nome.to_lower(), "%s pesca %d gettoni %s. Usare il segnalino «%s» per pescarne uno in più?" % [l["id"], maxi(n, 0), nome, _nome_segnalino(l["segnalino"])],
			[_sc("si", "Usa il segnalino (+1 gettone)"), _sc("no", "Tienilo per dopo")])
		return
	n += int(s["avv"].get("extra", 0))
	s["avv"]["extra"] = 0
	if n <= 0:
		s["avv"]["blocca_" + tipo] = true
		_log("Controllo %s: nessun gettone da pescare (%s resta senza gettone fino allo sgancio)." % [nome.to_lower(), l["id"]])
		s["avv"].erase("chiesto_segnalino")
		s["fase"] = dopo
		return
	var pescati := _pesca(tipo, n)
	if pescati.size() == 1:
		_tieni_gettone(tipo, pescati[0], pescati, false)
		s["avv"].erase("chiesto_segnalino")
		s["fase"] = dopo
		return
	var sc := []
	for g in pescati:
		var x := Dati.gettone(g)
		sc.append(_sc(g, "%s · %d gettoni allo sgancio" % [x["av"], int(x["n"])] if int(x["n"]) != 1 else "%s · 1 gettone allo sgancio" % x["av"], "Il numero indica quanti gettoni %s si pescheranno allo sgancio." % nome))
	_chiedi("gettone", "Controllo %s" % nome.to_lower(), "Pescati %d gettoni %s: tienine uno, gli altri tornano nella tazza." % [pescati.size(), nome], sc, {"tipo_g": tipo, "pescati": pescati, "dopo": dopo})

func _pesca(tipo: String, n: int) -> Array:
	var coppa: Array = s["coppe"][tipo]
	_mescola(coppa)
	var r := []
	# il cane di Gibson finisce nella tazza con i gettoni del suo Lancaster: se esce vale 0 [13.0]
	var l := lanc(s["avv"].get("lanc", ""))
	if not l.is_empty() and l.get("jinx", false) and n > 0 and int(_rng() % (coppa.size() + 1)) < n:
		r.append("J")
		n -= 1
		_log("Dalla tazza esce il cane di Gibson: quel gettone vale 0.")
	for i in mini(n, coppa.size()):
		r.append(coppa.pop_back())
	return r

## Rimette un gettone nella tazza (il cane di Gibson non ci resta).
func _rimetti(tipo: String, g: String) -> void:
	if g != "" and g != "J":
		s["coppe"][tipo].append(g)

func _tieni_gettone(tipo: String, id: String, pescati: Array, sgancio: bool) -> void:
	for g in pescati:
		if g != id:
			_rimetti(tipo, g)
	var x := Dati.gettone(id)
	var nome := "Velocità" if tipo == "v" else "Quota"
	if sgancio:
		s["avv"]["sg_" + tipo] = id
		_log("Gettone %s allo sgancio: %s (%+d%s)." % [nome, x["sg"], int(x["mod"]), ", segno M" if x["m"] else ""])
	else:
		var vecchio: String = s["avv"][tipo]
		if vecchio != "":
			_rimetti(tipo, vecchio)
		s["avv"][tipo] = id
		_log("Gettone %s: %s (allo sgancio se ne pescheranno %d)." % [nome, x["av"], int(x["n"])])

## Passi 6 e 10: regolazione di velocità o quota (un gettone nuovo sostituisce il vecchio).
func _f_regola(dopo: String) -> void:
	var l := lanc(s["avv"]["lanc"])
	var reg: String = s["avv"].get("regola", "")
	if reg == "":
		var sc := []
		var puo_v: bool = not s["avv"]["blocca_v"] or l["segnalino"] != ""
		var puo_q: bool = _puo_quota() and (not s["avv"]["blocca_q"] or l["segnalino"] != "")
		if puo_v:
			sc.append(_sc("v", "Regola la velocità", "Peschi un gettone Velocità che sostituisce quello attuale (%s)." % _att("v")))
		if puo_q:
			sc.append(_sc("q", "Regola la quota", "Peschi un gettone Quota che sostituisce quello attuale (%s)." % _att("q")))
		sc.append(_sc("no", "Nessuna regolazione"))
		if sc.size() == 1:
			s["fase"] = dopo
			return
		_chiedi("regola", "Regolazione", "Nella zona %s si può correggere la velocità oppure la quota (non entrambe)." % ("ravvicinata" if s["avv"]["zona"] == "ravvicinata" else "vicina"), sc, {"dopo": dopo})
		return
	var tipo := reg
	var bloccato: bool = s["avv"]["blocca_" + tipo]
	if l["segnalino"] != "" and not s["avv"].has("chiesto_segnalino"):
		_chiedi("segnalino", "Regolazione", "Usare il segnalino «%s» per pescare un gettone in più?" % _nome_segnalino(l["segnalino"]), [_sc("si", "Usa il segnalino"), _sc("no", "No")])
		return
	var n := (0 if bloccato else 1) + int(s["avv"].get("extra", 0))
	s["avv"]["extra"] = 0
	s["avv"]["regola"] = ""
	s["avv"].erase("chiesto_segnalino")
	if n <= 0:
		_log("Regolazione impossibile: nessun gettone disponibile.")
		s["fase"] = dopo
		return
	var pescati := _pesca(tipo, n)
	if pescati.size() == 1:
		_tieni_gettone(tipo, pescati[0], pescati, false)
		s["fase"] = dopo
		return
	var sc2 := []
	for g in pescati:
		var x := Dati.gettone(g)
		sc2.append(_sc(g, "%s · %d allo sgancio" % [x["av"], int(x["n"])]))
	_chiedi("gettone", "Regolazione", "Tieni uno dei gettoni pescati: sostituirà quello attuale.", sc2, {"tipo_g": tipo, "pescati": pescati, "dopo": dopo})

func _att(tipo: String) -> String:
	var g: String = s["avv"][tipo]
	return "nessuno" if g == "" else Dati.gettone(g)["av"]

## Passi 5, 9 e 12: sganciare, proseguire o richiamare.
func _f_decisione(zona: String) -> void:
	var l := lanc(s["avv"]["lanc"])
	var sc := []
	var diga: String = s["avv"]["diga"]
	if zona == "lontana":
		sc.append(_sc("sgancia", "Sgancia ora (anticipato)", "-2 al tiro di sgancio."))
		if Dati.senza_zona_vicina(diga):
			sc.append(_sc("avanti", "Prosegui nella zona ravvicinata", "Regolazione, contraerea, mitragliatrici, poi lo sgancio."))
		else:
			sc.append(_sc("avanti", "Prosegui nella zona vicina", "Regolazione, contraerea e mitragliatrici." + (" Sulla Eder: +1 Michelskopf." if diga == "eder" else "")))
	elif zona == "vicina":
		sc.append(_sc("sgancia", "Sgancia ora", "Dalla zona vicina, senza penalità."))
		sc.append(_sc("avanti", "Prosegui nella zona ravvicinata", "Ultima regolazione, contraerea e mitragliatrici; poi sgancio tardivo."))
	else:
		sc.append(_sc("sgancia", "Sgancia (controllo dello sgancio tardivo)", "Un dado: da -2 a +1 allo sgancio."))
	sc.append(_sc("richiama", "Richiama: torna al Cerchio vicino", "%s riceve il segnalino «Passaggio a vuoto» e conserva l'Upkeep." % l["id"]))
	var t := "%s è nella zona %s. Velocità: %s. Quota: %s." % [nome_l(l), zona, _att("v"), _att("q")]
	t += " " + _riepilogo_mod()
	if diga == "eder":
		t += " Segni M raccolti: %d (Michelskopf: impatto con 2 dadi -%d pari o sotto 3)." % [int(s["avv"]["m"]), int(s["avv"]["m"])]
	_chiedi("decisione", "Zona %s" % zona, t, sc, {"zona": zona})

func _applica_decisione(id: String, zona: String) -> void:
	var l := lanc(s["avv"]["lanc"])
	if id == "richiama":
		_log("%s richiama: torna al Cerchio vicino con il segnalino «Passaggio a vuoto»." % nome_l(l))
		l["segnalino"] = "passaggio"
		_fine_avvicinamento()
		s["fase"] = "giro"
		return
	if id == "avanti":
		if zona == "lontana" and not Dati.senza_zona_vicina(s["avv"]["diga"]):
			s["avv"]["zona"] = "vicina"
			if s["avv"]["diga"] == "eder":
				s["avv"]["m"] += 1
			_log("%s entra nella zona vicina." % l["id"])
			s["fase"] = "avv_6"
		else:
			s["avv"]["zona"] = "ravvicinata"
			_log("%s entra nella zona ravvicinata." % l["id"])
			s["fase"] = "avv_10"
		return
	# sgancio
	if zona == "lontana":
		s["avv"]["anticipato"] = true
		_log("%s sgancia dalla zona lontana: sgancio anticipato (-2)." % l["id"])
	elif zona == "ravvicinata":
		var d := d6_per(l, "basso")
		var t: Array = Dati.TARDIVO[d]
		s["avv"]["tardivo"] = int(t[0])
		s["avv"]["m"] += int(t[1])
		_mostra_dadi("Sgancio tardivo", [d], [], "%+d" % int(t[0]))
		_log("Sgancio tardivo: dado %d, %+d allo sgancio%s%s." % [d, int(t[0]), (" " + t[2]) if t[2] != "" else "", (", +%d Michelskopf" % int(t[1])) if s["avv"]["diga"] == "eder" and int(t[1]) > 0 else ""])
	for e in s["avv"]["scorte"]:
		lanc(e)["pos"] = "vicino"
	if not s["avv"]["scorte"].is_empty():
		_log("Le scorte tornano al Cerchio vicino.")
	s["avv"]["scorte"] = []
	l["pos"] = "sgancio"
	s["avv"]["zona"] = "sgancio"
	s["fase"] = "sg_1"

func _fine_avvicinamento() -> void:
	for e in s["avv"].get("scorte", []):
		var x := lanc(e)
		if x["pos"] == "scorta":
			x["pos"] = "vicino"
	var l := lanc(s["avv"]["lanc"])
	if l["pos"] in ["avvicinamento", "sgancio", "salita"]:
		l["pos"] = "vicino"
	for t in ["q", "v"]:
		if s["avv"].get(t, "") != "":
			_rimetti(t, s["avv"][t])
		if s["avv"].get("sg_" + t, "") != "":
			_rimetti(t, s["avv"]["sg_" + t])
	var diga: String = s["avv"]["diga"]
	s["avv"] = {"fatto": true, "diga": diga}

# ================================================================ contraerea (A4)
func _f_flak(dopo: String) -> void:
	var d := dg()
	if int(d["flak"]) <= 0:
		s["fase"] = dopo
		return
	s["flak"] = {"dopo": dopo, "passo": "tira", "ripeti": false, "bersaglio": "", "giri": 0}
	s["fase"] = "flak"

func _tre_dadi_flak() -> bool:
	if int(dg()["fari"]) >= 1:
		return true
	return s["avv"].get("luci", false) and not Dati.senza_zona_vicina(s["avv"]["diga"])

func _scegli_coppia(dd: Array, lo: int, hi: int) -> Array:
	# I due dadi più letali: prima un colpo (meglio se critico e doppio), poi un doppio.
	var migliore := [0, 1]
	var punti := -1
	for i in dd.size():
		for j in range(i + 1, dd.size()):
			var somma: int = dd[i] + dd[j]
			var p := 0
			if somma >= lo and somma <= hi:
				p += 100
				if somma == 7: p += 20
			if dd[i] == dd[j]: p += 10
			if p > punti:
				punti = p
				migliore = [i, j]
	return migliore

func _f_flak_passo() -> void:
	var f: Dictionary = s["flak"]
	var d := dg()
	var livello: int = clampi(int(d["flak"]), 0, 5)
	var l := lanc(s["avv"]["lanc"])
	match f["passo"]:
		"tira":
			if livello <= 0 or not in_mappa(l) or l["pos"] == "distrutto":
				s["fase"] = f["dopo"]
				return
			f["giri"] = int(f["giri"]) + 1
			var n := 3 if _tre_dadi_flak() else 2
			var dd := _dadi(n)
			var r: Array = Dati.FLAK[livello]
			var c := _scegli_coppia(dd, r[0], r[1])
			var a: int = dd[c[0]]
			var b: int = dd[c[1]]
			var somma := a + b
			var colpo: bool = somma >= r[0] and somma <= r[1]
			var critico: bool = colpo and livello >= 4 and somma == 7
			f["doppio"] = a == b
			var chiave := "flak_%d_%d" % [int(s["n_tiri"]), int(f["giri"])]
			_mostra_dadi("Contraerea livello %d (colpisce con %d-%d)" % [livello, r[0], r[1]], dd, c, "COLPITO" if colpo else "mancato")
			_log("Contraerea (livello %d, %d dadi: %s, tenuti %d+%d): %s%s%s." % [livello, n, _lista(dd), a, b, "colpito" if colpo else "mancato", " CRITICO" if critico else "", ", doppio: si ritira" if a == b and int(f["giri"]) < 12 else ""])
			if colpo and ha_comandante() and not s["tiro_ripetuto"].has(chiave):
				f["chiave"] = chiave
				f["passo"] = "comandante"
				_chiedi("comandante", "Contraerea", "%s è colpito. Gibson può far ripetere il tiro (una volta sola per partita)." % l["id"], [_sc("si", "Ripeti il tiro"), _sc("no", "Accetta il risultato")], {"chiave": chiave})
				return
			if not colpo:
				f["passo"] = "tira" if (f["doppio"] and int(f["giri"]) < 12) else "fine"
				return
			f["colpi"] = 2 if critico else 1
			f["passo"] = "bersaglio"
		"comandante":
			if s["tiro_ripetuto"].get(f["chiave"], false):
				f["passo"] = "tira"
				f["giri"] = int(f["giri"]) - 1
				return
			# accettato: rifà il calcolo dal tiro mostrato
			var dd: Array = s["dadi"]["valori"]
			var c: Array = s["dadi"]["tenuti"]
			var somma: int = dd[c[0]] + dd[c[1]]
			f["colpi"] = 2 if (livello >= 4 and somma == 7) else 1
			f["passo"] = "bersaglio"
		"bersaglio":
			var scorte: Array = s["avv"].get("scorte", []).filter(func(e): return lanc(e)["pos"] == "scorta")
			if s["avv"]["zona"] in ["lontana", "vicina", "ravvicinata"] and not scorte.is_empty():
				var sc := [_sc(l["id"], "Colpisce %s (all'attacco)" % nome_l(l))]
				for e in scorte:
					sc.append(_sc(e, "Colpisce la scorta %s" % nome_l(lanc(e))))
				f["passo"] = "evasione"
				_chiedi("flak_bersaglio", "Contraerea: colpito!", "Sulla mappa del bersaglio il colpo può essere assegnato a una scorta.", sc)
				return
			f["bersaglio"] = l["id"]
			f["passo"] = "evasione"
		"evasione":
			var t := lanc(f["bersaglio"])
			var sc := []
			if f["bersaglio"] == l["id"] and s["avv"]["zona"] in ["lontana", "vicina", "ravvicinata"]:
				if s["avv"]["v"] != "":
					sc.append(_sc("v", "Azione evasiva: rinuncia al gettone Velocità", "Poi un dado: pari il colpo è annullato."))
				if s["avv"]["q"] != "":
					sc.append(_sc("q", "Azione evasiva: rinuncia al gettone Quota", "Poi un dado: pari il colpo è annullato."))
			elif f["bersaglio"] != l["id"]:
				sc.append(_sc("scorta", "Azione evasiva: la scorta si sgancia nel Cerchio vicino", "Poi un dado: pari il colpo è annullato."))
			if sc.is_empty():
				f["passo"] = "danno"
				return
			sc.append(_sc("subisci", "Nessuna azione evasiva", "Il colpo va a segno."))
			f["passo"] = "esito_evasione"
			_chiedi("flak_evasione", "Azione evasiva?", "%s è stato colpito%s." % [nome_l(t), " due volte (colpo critico)" if int(f["colpi"]) == 2 else ""], sc)
		"esito_evasione":
			f["passo"] = "danno"
		"danno":
			var t := lanc(f["bersaglio"])
			if ruolo(t) == "pilota_danno" and not s["usati"].has(t["elite"]) and not f.has("martin"):
				_chiedi("martin", "Martin", "%s può ignorare questo danno (una volta per partita)." % t["pilota"], [_sc("si", "Ignora il danno"), _sc("no", "Tienilo per un'altra volta")])
				return
			var colpi: int = int(f["colpi"])
			if f.get("martin", "") == "si":
				s["usati"][t["elite"]] = true
				colpi -= 1
				_log("%s ignora un danno con la sua abilità." % t["pilota"])
			f.erase("martin")
			for i in colpi:
				_danneggia(t, "contraerea")
			if t["pos"] == "distrutto" and t["id"] == l["id"]:
				_fine_avvicinamento()
				s["fase"] = "giro"
				return
			f["passo"] = "tira" if (f["doppio"] and t["pos"] != "distrutto" and not f.get("evaso", false) and int(f["giri"]) < 12) else "fine"
			f.erase("evaso")
		"fine":
			s["fase"] = f["dopo"]

func _applica_evasione(id: String) -> void:
	var f: Dictionary = s["flak"]
	if id == "subisci":
		return
	f["evaso"] = true
	var t := lanc(f["bersaglio"])
	if id == "v" or id == "q":
		_rimetti(id, s["avv"][id])
		s["avv"][id] = ""
		s["avv"]["blocca_" + id] = true
		_log("%s rinuncia al gettone %s per l'azione evasiva." % [t["id"], "Velocità" if id == "v" else "Quota"])
	else:
		t["pos"] = "vicino"
		s["avv"]["scorte"].erase(t["id"])
		_log("La scorta %s si sgancia verso il Cerchio vicino." % t["id"])
	var d := d6_per(t, "pari")
	_mostra_dadi("Azione evasiva", [d], [], "annullato" if d % 2 == 0 else "a segno")
	if d % 2 == 0:
		_log("Azione evasiva riuscita (dado %d): il colpo è annullato." % d)
		f["passo"] = "fine"
	else:
		_log("Azione evasiva fallita (dado %d): il colpo va a segno." % d)
		f["passo"] = "danno"

func _danneggia(t: Dictionary, causa: String) -> void:
	t["danni"] = int(t["danni"]) + 1
	if int(t["danni"]) >= 2:
		t["pos"] = "distrutto"
		t["esito"] = "abbattuto (%s)" % causa
		if in_mappa(t) or s.get("fase", "").begins_with("avv") or s.get("fase", "") in ["flak", "sg_3", "sg_4", "sg_5"]:
			dg()["attivita"] = int(dg()["attivita"]) + 1
		_log("%s è abbattuto! (%s)" % [nome_l(t), causa])
		s["eventi"].append({"tipo": "abbattuto", "lanc": t["id"]})
		if int(t["upkeep"]) >= 0:
			t["upkeep"] = -1
	else:
		_log("%s è danneggiato." % nome_l(t))
		s["eventi"].append({"tipo": "danneggiato", "lanc": t["id"]})

func _lista(a: Array) -> String:
	return ", ".join(a.map(func(x): return str(x)))

# ================================================================ mitragliatrici (A5)
## Palloni di sbarramento sulla mappa del bersaglio (solo campagna): zona ravvicinata e risalita.
## Palloni di sbarramento [7.9.5]: i segnalini stanno nella zona ravvicinata o nella casella della risalita
## (con livello 2 o più uno in ciascuna); si scoprono quando i Lancaster arrivano sulla mappa del bersaglio.
func prepara_palloni(d: String) -> void:
	var x: Dictionary = s["dighe"][d]
	var n: int = int(x.get("palloni", 0))
	var box := []
	if n >= 2:
		box = ["ravvicinata", "salita"]
	elif n == 1:
		box = [["ravvicinata", "salita"][_rng() % 2]]
	x["palloni_box"] = box
	if not box.is_empty():
		_log("Palloni di sbarramento alla %s: %s." % [Dati.DIGHE[d]["nome"], " e ".join(box.map(func(b): return "nella zona ravvicinata" if b == "ravvicinata" else "sulla risalita"))])

func palloni_in(box: String) -> bool:
	return box in dg().get("palloni_box", [])

## Toglie un segnalino dei palloni (preferendo quello della casella indicata) e abbassa il livello.
func _togli_pallone(box := "") -> void:
	var d := dg()
	var bx: Array = d.get("palloni_box", [])
	if box != "" and box in bx:
		bx.erase(box)
	elif not bx.is_empty():
		bx.remove_at(_rng() % bx.size())
	d["palloni_box"] = bx
	d["palloni"] = maxi(int(d.get("palloni", 0)) - 1, 0)

## Pericolo dei palloni: dado pari danneggiato, dispari distrutto (salvataggio del veterano o del pilota).
func _controllo_palloni(box: String) -> void:
	var l := lanc(s["avv"].get("lanc", ""))
	if not palloni_in(box) or l.is_empty() or not in_mappa(l):
		return
	if l["equip"] == "veterano" or ruolo(l).begins_with("pilota"):
		var v := d6_per(l, "basso")
		if v == 6:
			_mostra_dadi("Palloni: salvataggio del veterano", [v], [], "salvo")
			_log("Palloni di sbarramento: %s schiva il cavo all'ultimo istante (salvataggio, dado 6)." % l["id"])
			return
	var y := d6_per(l, "pari")
	_mostra_dadi("Palloni di sbarramento", [y], [], "danneggiato" if y % 2 == 0 else "distrutto")
	_log("Palloni di sbarramento: %s urta un cavo (dado %d): %s." % [l["id"], y, "danneggiato" if y % 2 == 0 else "distrutto"])
	if y % 2 == 0:
		_danneggia(l, "cavo dei palloni")
	else:
		_distruggi_diretto(l, "cavo dei palloni")

func _distruggi_diretto(l: Dictionary, causa: String) -> void:
	_danneggia(l, causa)
	if l["pos"] != "distrutto":
		_danneggia(l, causa)

func _f_mitragliatrici(dopo: String, posteriore: bool) -> void:
	# risalita: prima il mitragliere anteriore può sparare ai palloni della risalita, poi il pericolo dei palloni
	if posteriore and palloni_in("salita") and not s["avv"].get("pal_salita", false):
		s["avv"]["pal_salita"] = true
		var la := lanc(s["avv"]["lanc"])
		var x := d6_per(la, "alto")
		var mod := -1 if ruolo(la) == "mitragliere_ant" else 0
		_mostra_dadi("Mitragliatrice anteriore contro i palloni della risalita (riesce con 1 o meno)", [x], [], "colpiti!" if x + mod <= 1 else "nessun effetto")
		if x + mod <= 1:
			_togli_pallone("salita")
			dg()["attivita"] = int(dg()["attivita"]) + 1
			_log("La mitragliatrice anteriore di %s abbatte i palloni della risalita." % la["id"])
		_controllo_palloni("salita")
		if la["pos"] == "distrutto":
			s["avv"].erase("pal_salita")
			_fine_avvicinamento()
			s["fase"] = "giro"
			return
	var d := dg()
	var cat := []
	for c in ["flak", "fari"]:
		if int(d[c]) >= 1:
			cat.append(c)
	if palloni_in("salita" if posteriore else "ravvicinata") and s["avv"].get("zona", "") in ["ravvicinata", "salita", ""] and (posteriore or s["avv"].get("zona", "") == "ravvicinata"):
		cat.append("palloni")
	var l := lanc(s["avv"]["lanc"])
	if cat.is_empty() or not in_mappa(l):
		s.erase("mitra_bersaglio")
		if _dopo_mitragliatrici(posteriore):
			return
		s["fase"] = dopo
		return
	if not s.has("mitra_bersaglio"):
		if cat.size() == 1:
			s["mitra_bersaglio"] = cat[0]
		else:
			var sc := []
			for c in cat:
				sc.append(_sc(c, "Spara su: %s (livello %d)" % [_nome_dif(c), int(d[c])]))
			_chiedi("mitragliatrici", "Mitragliatrici", "Tutti gli aerei sparano sulla stessa difesa.", sc)
			return
	var bersaglio: String = s["mitra_bersaglio"]
	s.erase("mitra_bersaglio")
	var tiratori := [l]
	if not posteriore:
		for e in s["avv"].get("scorte", []):
			if lanc(e)["pos"] == "scorta":
				tiratori.append(lanc(e))
	var livello: int = int(d[bersaglio]) if bersaglio != "palloni" else 1
	var ridotto := false
	var dd := []
	for t in tiratori:
		var x := d6_per(t, "alto")
		dd.append(x)
		var mod := -1 if ruolo(t) == ("mitragliere_post" if posteriore else "mitragliere_ant") else 0
		if x + mod <= livello and not ridotto:
			ridotto = true
	_mostra_dadi("Mitragliatrice %s contro %s (riesce con %d o meno)" % ["posteriore" if posteriore else "anteriore", _nome_dif(bersaglio), livello], dd, [], "colpita!" if ridotto else "nessun effetto")
	if ridotto:
		if bersaglio == "palloni":
			_togli_pallone("salita" if posteriore else "ravvicinata")
		else:
			d[bersaglio] = int(d[bersaglio]) - 1
		d["attivita"] = int(d["attivita"]) + 1
		_log("Mitragliatrice %s (%s): la difesa %s scende a %d." % ["posteriore" if posteriore else "anteriore", _lista(dd), _nome_dif(bersaglio), int(d[bersaglio])])
	else:
		_log("Mitragliatrice %s (%s): nessun effetto su %s." % ["posteriore" if posteriore else "anteriore", _lista(dd), _nome_dif(bersaglio)])
	if _dopo_mitragliatrici(posteriore):
		return
	s["fase"] = dopo

## Dopo le mitragliatrici: nella zona ravvicinata si risolvono i palloni; nella risalita finisce l'avvicinamento.
## Vero se il Lancaster è stato distrutto (la fase è già stata cambiata).
func _dopo_mitragliatrici(posteriore: bool) -> bool:
	if not posteriore and s["avv"].get("zona", "") == "ravvicinata":
		_controllo_palloni("ravvicinata")
		var l := lanc(s["avv"].get("lanc", ""))
		if l.is_empty() or l["pos"] == "distrutto":
			_fine_avvicinamento()
			s["fase"] = "giro"
			return true
	if posteriore:
		s["avv"].erase("pal_salita")
		_fine_avvicinamento()
	return false

func _nome_dif(c: String) -> String:
	return {"flak": "contraerea", "fari": "fotoelettriche", "palloni": "palloni"}[c]

# ================================================================ sgancio (4.2.13)
func _f_pesca_sgancio(tipo: String, dopo: String) -> void:
	var l := lanc(s["avv"]["lanc"])
	var nome := "Quota" if tipo == "q" else "Velocità"
	var att: String = s["avv"][tipo]
	var n := 0 if att == "" else int(Dati.gettone(att)["n"])
	if l["segnalino"] != "" and not s["avv"].has("chiesto_segnalino"):
		_chiedi("segnalino", "Controllo finale: %s" % nome.to_lower(), "Usare il segnalino «%s» per pescare un gettone %s in più?" % [_nome_segnalino(l["segnalino"]), nome], [_sc("si", "Usa il segnalino"), _sc("no", "No")])
		return
	n += int(s["avv"].get("extra", 0))
	s["avv"]["extra"] = 0
	s["avv"].erase("chiesto_segnalino")
	if n <= 0:
		_log("Controllo finale %s: nessun gettone (nessun modificatore)." % nome.to_lower())
		s["fase"] = dopo
		return
	var pescati := _pesca(tipo, n)
	if pescati.size() == 1:
		_tieni_gettone(tipo, pescati[0], pescati, true)
		s["fase"] = dopo
		return
	var sc := []
	for g in pescati:
		var x := Dati.gettone(g)
		sc.append(_sc(g, "%s · %+d%s" % [x["sg"], int(x["mod"]), " · M" if x["m"] else ""], "M: segno Michelskopf (-1 al controllo dopo lo sgancio sulla Eder)." if x["m"] and s["avv"]["diga"] == "eder" else ""))
	_chiedi("gettone", "Controllo finale: %s" % nome.to_lower(), "Pescati %d gettoni %s (lato rosa dello sgancio): tienine uno. %s Al tiro di sgancio servono 15 con due dadi." % [pescati.size(), nome, _riepilogo_mod()], sc, {"tipo_g": tipo, "pescati": pescati, "dopo": dopo, "sgancio": true})

## Testo con i modificatori di sgancio già noti (per aiutare la decisione).
func _riepilogo_mod() -> String:
	var m := modificatori_sgancio()
	if m.is_empty():
		return "Modificatori di sgancio finora: nessuno."
	var tot := 0
	var p := []
	for x in m:
		tot += int(x[1])
		p.append("%s %+d" % [x[0].to_lower(), int(x[1])])
	return "Modificatori di sgancio finora: %s (totale %+d)." % [", ".join(p), tot]

func modificatori_sgancio() -> Array:
	var l := lanc(s["avv"]["lanc"])
	var m := []
	for t in ["q", "v"]:
		var g: String = s["avv"].get("sg_" + t, "")
		if g != "":
			m.append(["Gettone %s %s" % ["Quota" if t == "q" else "Velocità", Dati.gettone(g)["sg"]], int(Dati.gettone(g)["mod"])])
	var p := Dati.mod_puntamento(livello(l, "bomba")) if s.get("dann", true) else 0
	if p != 0:
		m.append(["Addestramento al puntamento", p])
	if s.get("senza_luna", false):
		m.append(["Notte senza luna", -1])
	if ruolo(l) == "bombardiere":
		m.append(["Puntatore %s" % Dati.SPECIALISTI[l["elite"]]["nome"], 1])
	if s["avv"]["anticipato"]:
		m.append(["Sgancio anticipato", -2])
	if int(s["avv"]["tardivo"]) != 0:
		m.append(["Sgancio tardivo", int(s["avv"]["tardivo"])])
	if int(dg()["fari"]) >= 1:
		m.append(["Fotoelettriche", -4])
	if danneggiato(l):
		m.append(["Lancaster danneggiato", -1])
	if ha_guasto(l, "sgancio_dif"):
		m.append(["Sgancio difettoso", -1])
	return m

func _f_sgancio() -> void:
	var l := lanc(s["avv"]["lanc"])
	var mods := modificatori_sgancio()
	var tot := 0
	for x in mods:
		tot += int(x[1])
	var dd := _tiro_pendente("sgancio", 2)
	var somma: int = dd[0] + dd[1] + tot
	var esito := "successo" if somma >= 15 else ("concussione" if somma <= 10 else "fallito")
	_mostra_dadi("Sgancio: 2 dadi %+d, serve 15" % tot, dd, [], "%d: %s" % [somma, esito.to_upper()])
	_log("SGANCIO di %s: dadi %d+%d, modificatori %+d = %d: %s." % [l["id"], dd[0], dd[1], tot, somma, {"successo": "l'Upkeep colpisce la diga", "fallito": "l'Upkeep manca la diga", "concussione": "l'Upkeep manca la diga e l'esplosione scuote il Lancaster"}[esito]])
	if esito != "successo" and _offri_comandante("sgancio", dd, "Sgancio", "Gibson può far ripetere il tiro di sgancio (una volta sola per partita)."):
		return
	var d := dg()
	var u: int = int(l["upkeep"])
	l["upkeep"] = -1
	d["attivita"] = int(d["attivita"]) + 1
	s["rilasciati_turno"] = int(s["rilasciati_turno"]) + 1
	d["upkeep"].append({"u": u, "esito": "colpito" if esito == "successo" else "mancato", "valore": -1, "lanc": l["id"], "rivelato": false, "t": int(s["turni"])})
	s["eventi"].append({"tipo": "sgancio", "lanc": l["id"], "esito": esito})
	if esito != "successo":
		var oss := lanc_in("vicino").filter(func(x): return x["segnalino"] == "")
		if not oss.is_empty():
			oss[0]["segnalino"] = "osservato"
			_log("%s ha osservato l'avvicinamento: riceve il segnalino «Avvicinamento osservato»." % oss[0]["id"])
	if esito == "concussione":
		_danneggia(l, "esplosione dell'Upkeep")
		if l["pos"] == "distrutto":
			_fine_avvicinamento()
			s["fase"] = "giro"
			return
	s["fase"] = "sg_4"

## Tiro che Gibson può far ripetere: se c'è un tiro in sospeso lo riusa (risultato accettato) o lo rifà.
func _tiro_pendente(nome: String, n: int) -> Array:
	var k := "pend_" + nome
	if s.has(k):
		var p: Array = s[k]
		s.erase(k)
		if s.get("ripeti", false):
			s["ripeti"] = false
			return _dadi(n)
		return p.map(func(x): return int(x))
	return _dadi(n)

## Se Gibson è disponibile, propone di ripetere il tiro e lascia il risultato in sospeso.
func _offri_comandante(nome: String, dd: Array, titolo: String, testo: String) -> bool:
	if not ha_comandante():
		return false
	s["pend_" + nome] = dd
	_chiedi("comandante", titolo, testo, [_sc("si", "Ripeti il tiro"), _sc("no", "Accetta il risultato")], {"chiave": nome})
	return true

## Passo 4: risalita (e Michelskopf sulla Eder).
func _f_salita() -> void:
	var l := lanc(s["avv"]["lanc"])
	for t in ["q", "v"]:
		var g: String = s["avv"].get("sg_" + t, "")
		if g != "" and Dati.gettone(g)["m"]:
			s["avv"]["m"] += 1
	for t in ["q", "v"]:
		if s["avv"].get(t, "") != "":
			_rimetti(t, s["avv"][t])
			s["avv"][t] = ""
		if s["avv"].get("sg_" + t, "") != "":
			_rimetti(t, s["avv"]["sg_" + t])
			s["avv"]["sg_" + t] = ""
	if s["avv"]["diga"] == "eder":
		var m: int = int(s["avv"]["m"])
		var dd := _tiro_pendente("michel", 2)
		var somma: int = dd[0] + dd[1] - m
		_mostra_dadi("Michelskopf: 2 dadi -%d, impatto con 3 o meno" % m, dd, [], "IMPATTO" if somma <= 3 else "risale")
		_log("Michelskopf: dadi %d+%d -%d (segni M) = %d: %s." % [dd[0], dd[1], m, somma, "impatto contro il costone!" if somma <= 3 else "il Lancaster supera il costone"])
		if somma <= 3 and _offri_comandante("michel", dd, "Michelskopf", "Gibson può far ripetere il tiro (una volta sola per partita)."):
			return
		if somma <= 3:
			l["danni"] = 2
			l["pos"] = "distrutto"
			l["esito"] = "schiantato contro il Michelskopf"
			dg()["attivita"] = int(dg()["attivita"]) + 1
			s["eventi"].append({"tipo": "abbattuto", "lanc": l["id"]})
			_log("%s si schianta contro il Michelskopf." % nome_l(l))
			_fine_avvicinamento()
			s["fase"] = "giro"
			return
	l["pos"] = "salita"
	_log("%s risale." % l["id"])
	s["fase"] = "sg_5"

# ================================================================ volo in cerchio (4.3)
func _f_giro() -> void:
	if s["avv"].has("lanc"):
		_fine_avvicinamento()
	for l in lanc_in("salita"):
		l["pos"] = "vicino"
		_log("%s dalla risalita torna al Cerchio vicino." % l["id"])
	var sc := _scelte_giro()
	if sc.size() <= 1 or sulla_mappa().is_empty():
		_chiudi_giro()
		return
	_chiedi("giro", "Fase di volo in cerchio", "Si possono spostare i Lancaster fra i due cerchi, far rientrare quelli senza Upkeep e sparare razzi Very dal Cerchio vicino.", sc)

func _scelte_giro() -> Array:
	var sc := []
	for l in s["lanc"]:
		if l["pos"] == "vicino" and not l["razzo"]:
			sc.append(_sc("lontano:" + l["id"], "%s al Cerchio lontano" % l["id"], ""))
			if not l["razzo"] and l["inizio_vicino"]:
				sc.append(_sc("razzo:" + l["id"], "%s spara un razzo Very" % l["id"], "Ogni razzo annulla un effetto Quota del vettore d'avvicinamento, ma alza di 1 l'attività."))
		elif l["pos"] == "lontano":
			sc.append(_sc("vicino:" + l["id"], "%s al Cerchio vicino" % l["id"], ""))
		if l["pos"] in ["vicino", "lontano"] and int(l["upkeep"]) < 0:
			sc.append(_sc("rientra:" + l["id"], "%s lascia il bersaglio e rientra" % l["id"], "Senza Upkeep: farà il controllo del rientro alla base a fine partita."))
	sc.append(_sc("fine", "Fine della fase di volo in cerchio"))
	return sc

func _applica_giro(id: String) -> void:
	if id == "fine":
		_chiudi_giro()
		return
	var p := id.split(":")
	var l := lanc(p[1])
	match p[0]:
		"lontano":
			l["pos"] = "lontano"
			_log("%s passa al Cerchio lontano." % l["id"])
		"vicino":
			l["pos"] = "vicino"
			_log("%s passa al Cerchio vicino." % l["id"])
		"razzo":
			l["razzo"] = true
			s["razzi"].append({"turno": int(s["turno"]), "giro": int(s["giri_8"]), "assoluto": int(s["turni"])})
			dg()["attivita"] = int(dg()["attivita"]) + 1
			_log("%s spara un razzo Very sul lago (attività %d)." % [l["id"], int(dg()["attivita"])])
		"rientra":
			l["pos"] = "partito"
			_log("%s lascia la diga e rientra verso l'Inghilterra." % nome_l(l))
	if s["fine"] == "":
		var sc := _scelte_giro()
		if sc.size() <= 1:
			_chiudi_giro()
		else:
			_chiedi("giro", "Fase di volo in cerchio", "Altri movimenti? Quando hai finito, chiudi la fase.", sc)

func _chiudi_giro() -> void:
	for l in s["lanc"]:
		if l["razzo"] and l["pos"] != "vicino":
			pass
	s["fase"] = "st_1"

# ================================================================ fase di stato (4.4)
func _f_visibilita() -> void:
	if sulla_mappa().is_empty():
		s["fase"] = "fine_turno"
		return
	if int(s["turno"]) in [3, 5, 7]:
		_controllo_visibilita()
	s["fase"] = "st_2"

func _controllo_visibilita() -> void:
	var dd := _dadi(2)
	var tot: int = dd[0] + dd[1] + int(s["mod_visibilita"])
	var prima: String = s["visibilita"]
	s["visibilita"] = "nebbia" if tot <= 5 else "sereno"
	if s["facile"]:
		s["visibilita"] = "sereno"
	_mostra_dadi("Visibilità%s" % (" (%+d)" % int(s["mod_visibilita"]) if int(s["mod_visibilita"]) != 0 else ""), dd, [], s["visibilita"])
	_log("Controllo della visibilità: %d+%d%s = %d: %s%s." % [dd[0], dd[1], (" %+d" % int(s["mod_visibilita"])) if int(s["mod_visibilita"]) != 0 else "", tot, s["visibilita"], "" if prima == s["visibilita"] else " (cambia)"])

func _f_logoramento() -> void:
	if int(s["rilasciati_turno"]) > 0:
		var d := dg()
		for c in ["flak", "fari", "palloni"]:
			if int(d[c]) >= 1:
				var x := d6()
				var liv: int = int(d[c]) if c != "palloni" else 1
				if x <= liv:
					if c == "palloni":
						_togli_pallone()
					else:
						d[c] = int(d[c]) - 1
					_log("Logoramento delle difese: dado %d, %s scende a %d." % [x, _nome_dif(c), int(d[c])])
				else:
					_log("Logoramento delle difese: dado %d, %s resta a %d." % [x, _nome_dif(c), int(d[c])])
				_mostra_dadi("Logoramento: %s (riesce con %d o meno)" % [_nome_dif(c), liv], [x], [], "scende" if x <= liv else "resta")
	s["fase"] = "st_3"

func _f_caccia() -> void:
	var d := dg()
	if not s.has("pend_caccia"):
		var dd := _dadi(2)
		var somma: int = dd[0] + dd[1]
		var al: int = clampi(int(s["allerta"]), 0, 4)
		var r: Array = (Dati.CACCIA_AVVISTA_FARI if int(d["fari"]) >= 1 else Dati.CACCIA_AVVISTA)[al]
		var avvistato: bool = somma >= r[0] and somma <= r[1]
		_mostra_dadi("Caccia notturno: avvistato con %d-%d (allerta %d)" % [r[0], r[1], al], dd, [], "avvistato!" if avvistato else "nessuno")
		if not avvistato:
			_log("Controllo del caccia notturno: %d, nessun caccia avvistato." % somma)
			s["fase"] = "st_4"
			return
		_log("Controllo del caccia notturno: %d, un caccia notturno è avvistato!" % somma)
	var att: int = int(d["attivita"])
	var col := 0 if att <= 0 else (1 if att <= 3 else (2 if att <= 6 else 3))
	var t: Array = (Dati.CACCIA_VICINO if d["caccia_vicino"] else Dati.CACCIA_NON_VICINO)[col]
	var dd2 := _tiro_pendente("caccia", 2)
	var s2: int = dd2[0] + dd2[1]
	var esito := "attacco" if s2 <= int(t[2]) else ("svanisce" if s2 >= int(t[0]) else "vicino")
	_mostra_dadi("Caccia avvistato: attacca? (attività %d)" % att, dd2, [], esito.to_upper())
	_log("Secondo tiro %d con attività %d: il caccia %s." % [s2, att, {"attacco": "ATTACCA", "svanisce": "si allontana", "vicino": "resta nei paraggi"}[esito]])
	if esito == "attacco" and _offri_comandante("caccia", dd2, "Caccia notturno", "Un caccia attacca: Gibson può far ripetere il tiro (una volta sola per partita)."):
		return
	match esito:
		"svanisce":
			d["caccia_vicino"] = false
		"vicino":
			d["caccia_vicino"] = true
		"attacco":
			var vicini := lanc_in("vicino")
			if not vicini.is_empty():
				var vitt: Dictionary = vicini[_rng() % vicini.size()]
				vitt["danni"] = 2
				vitt["pos"] = "distrutto"
				vitt["esito"] = "abbattuto da un caccia notturno"
				_log("%s è abbattuto dal caccia notturno!" % nome_l(vitt))
				s["eventi"].append({"tipo": "abbattuto", "lanc": vitt["id"]})
			_caccia_attacca()
			return
	s["fase"] = "st_4"

## Il caccia ha attaccato: negli scenari d'attacco la partita finisce (i Lancaster si disperdono).
func _caccia_attacca() -> void:
	for l in sulla_mappa():
		l["pos"] = "disperso"
	_log("Gli altri Lancaster si disperdono: l'attacco alla diga è finito.")
	s["caccia_attacco"] = true
	s["fine"] = "caccia"
	s["fase"] = "concludi"

func _f_detonazione() -> void:
	if lanc_in("vicino").is_empty():
		s["fase"] = "st_5"
		return
	for nd in s["dighe"]:
		var d: Dictionary = s["dighe"][nd]
		for u in d["upkeep"]:
			if u["esito"] == "colpito" and int(u["valore"]) < 0:
				_rivela(nd, u, "Detonazione")
		if not d["breccia"] and danni_diga(nd) >= capacita(nd) and _ha_colpi(nd):
			d["breccia"] = true
			_log("BRECCIA! La diga della %s cede: %d danni su %d." % [Dati.DIGHE[nd]["nome"], danni_diga(nd), capacita(nd)])
			s["eventi"].append({"tipo": "breccia", "diga": nd})
	s["fase"] = "st_5"

func _ha_colpi(nd: String) -> bool:
	for u in s["dighe"][nd]["upkeep"]:
		if u["esito"] == "colpito":
			return true
	return false

func _rivela(nd: String, u: Dictionary, perche: String) -> void:
	var x := d6()
	u["valore"] = Dati.danno_upkeep(int(u["u"]), x)
	if s.get("wallis", false):
		u["valore"] = maxi(int(Dati.UPKEEP[int(u["u"])][0]), int(Dati.UPKEEP[int(u["u"])][1]))
	u["rivelato"] = true
	_mostra_dadi("%s: Upkeep %s" % [perche, "precedente" if u.get("precedente", false) else "di " + str(u["lanc"])], [x], [], "%d danni" % int(u["valore"]))
	_log("%s: l'Upkeep di %s esplode contro la %s (dado %d, %s): %d danni. Totale %d su %d." % [perche, u["lanc"], Dati.DIGHE[nd]["nome"], x, "pari" if x % 2 == 0 else "dispari", int(u["valore"]), danni_diga(nd), capacita(nd)])

func _f_razzi() -> void:
	var resta := []
	for r in s["razzi"]:
		var trascorsi: int = int(s["turni"]) - int(r["assoluto"])
		if trascorsi <= 0:
			resta.append(r)
			continue
		var x := d6()
		if x - trascorsi <= 0:
			_log("Il razzo Very del turno %d si spegne (dado %d -%d)." % [int(r["turno"]), x, trascorsi])
		else:
			resta.append(r)
	s["razzi"] = resta
	s["fase"] = "fine_turno"

func _distanza(t: int) -> int:
	var c: int = int(s["turno"])
	return (c - t + 8) % 8

func _f_fine_turno() -> void:
	s["turni"] = int(s["turni"]) + 1
	var nd: String = diga_corrente()
	for d in s["dighe"]:
		if s["dighe"][d]["breccia"]:
			s["fine"] = "breccia"
	if s["fine"] == "":
		var vivi := sulla_mappa()
		if vivi.is_empty():
			s["fine"] = "nessuno"
		elif vivi.filter(func(l): return int(l["upkeep"]) >= 0).is_empty():
			s["fine"] = "esaurito"
	if s["fine"] == "" and int(s["turno"]) == 8:
		s["giri_8"] = int(s["giri_8"]) + 1
		if int(s["scen"]) == 4 and int(s["giri_8"]) == 1:
			s["malus_rtb"] = -1
			_log("Il carburante cala: -1 al controllo del rientro alla base.")
		if int(s["giri_8"]) >= int(scenario()["giri"]):
			s["fine"] = "carburante"
			_log("Il carburante è agli sgoccioli: tutti i Lancaster devono rientrare.")
	if s["fine"] != "":
		s["fase"] = "concludi"
		return
	s["turno"] = int(s["turno"]) % 8 + 1
	if int(s["turno"]) == 1:
		_log("Ricomincia il giro dei turni d'attacco.")
		_controllo_visibilita()
	s["fase"] = "inizio"

# ================================================================ fine della partita (5.0)
func _concludi() -> void:
	s["fase"] = "concluso"
	var sc := scenario()
	var motivi := {"breccia": "La diga ha ceduto.", "caccia": "Un caccia notturno ha disperso i Lancaster.",
		"esaurito": "Nessun Lancaster sulla diga ha più un Upkeep.", "nessuno": "Non resta nessun Lancaster sulla diga.",
		"carburante": "Il carburante impone il rientro."}
	_log("== Fine dell'attacco: %s ==" % motivi.get(s["fine"], s["fine"]))
	var zona: String = Dati.DIGHE[s["diga"]]["zona"]
	var proseguono := 0
	var rientrati := 0
	var upkeep_rimasti := 0
	for l in s["lanc"]:
		if l["pos"] == "distrutto":
			continue
		if int(l["upkeep"]) >= 0 and sc["seguente"] != "":
			l["pos"] = "prosegue"
			l["esito"] = "prosegue verso la %s con l'Upkeep" % sc["seguente"]
			proseguono += 1
			upkeep_rimasti += 1
			continue
		if int(l["upkeep"]) >= 0:
			upkeep_rimasti += 1
		_rientro(l, zona)
		if l["pos"] == "a casa":
			rientrati += 1
	# ricognizione del mattino
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
				if var_ != 0:
					_log("Ricognizione del mattino: dado %d, l'Upkeep di %s vale %+d (ora %d)." % [x, u["lanc"], var_, int(u["valore"])])
		if not d["breccia"] and _ha_colpi(nd) and danni_diga(nd) >= capacita(nd):
			d["breccia"] = true
			_log("Le foto del mattino mostrano la breccia nella %s!" % Dati.DIGHE[nd]["nome"])
	s["esito"] = _rapporto(rientrati, proseguono, upkeep_rimasti)
	_log("Esito: %s" % s["esito"]["titolo"])

func _mod_rientro(l: Dictionary, zona: String) -> Array:
	var m := []
	if l["equip"] == "recluta": m.append(["equipaggio recluta", -1])
	if l["equip"] == "veterano": m.append(["equipaggio veterano", 1])
	if l["elite"] != "": m.append(["specialista a bordo", 1])
	if danneggiato(l): m.append(["danneggiato", -1])
	if ha_guasto(l, "merlin"): m.append(["motore Merlin guasto", -1])
	if ha_guasto(l, "bussola") and int(l["upkeep"]) >= 0: m.append(["bussola deviata", -1])
	if zona == "Ruhr": m.append(["zona della Ruhr", -1])
	if zona == "Weser": m.append(["zona del Weser", -2])
	if zona == "Costa": m.append(["costa inglese o Mare del Nord", 2])
	if int(s["allerta"]) >= 4: m.append(["allarme", -1])
	if int(s["malus_rtb"]) != 0: m.append(["carburante", int(s["malus_rtb"])])
	return m

func _rientro(l: Dictionary, zona: String) -> void:
	var mods := _mod_rientro(l, zona)
	var tot := 0
	for x in mods:
		tot += int(x[1])
	var dd := _dadi(2)
	var r: int = dd[0] + dd[1] + tot
	if r >= 7:
		l["pos"] = "a casa"
		l["esito"] = "rientrato a Scampton" + (" (danneggiato)" if danneggiato(l) else "")
		_log("Rientro di %s: %d+%d %+d = %d: torna a Scampton." % [l["id"], dd[0], dd[1], tot, r])
		return
	var dd2 := _dadi(2)
	var r2: int = dd2[0] + dd2[1] + tot
	_log("Rientro di %s: %d+%d %+d = %d: disperso! Tabella dei dispersi: %d." % [l["id"], dd[0], dd[1], tot, r, r2])
	if r2 <= 4:
		l["pos"] = "perso"
		l["esito"] = "disperso in azione (M.I.A.)"
	elif r2 == 5:
		l["pos"] = "a casa"
		l["esito"] = "rientrato a Scampton dopo una lunga deviazione"
	elif r2 <= 9:
		if danneggiato(l):
			var x := d6_per(l, "basso")
			if x <= 4:
				l["pos"] = "perso"
				l["esito"] = "precipitato sulla via del ritorno"
			else:
				l["pos"] = "a casa"
				l["esito"] = "rientrato a Scampton (danneggiato)"
		else:
			l["danni"] = 1
			l["pos"] = "a casa"
			l["esito"] = "rientrato a Scampton danneggiato"
	else:
		l["pos"] = "a casa"
		l["esito"] = "rientrato a Scampton"
	_log("%s: %s." % [l["id"], l["esito"]])

## Rapporto finale (Debriefing Chart). Le etichette sono quelle del libro degli scenari, tradotte.
func _rapporto(rientrati: int, proseguono: int, upkeep: int) -> Dictionary:
	var scen: int = int(s["scen"])
	var nd: String = s["diga"]
	var d: Dictionary = s["dighe"][nd]
	var breccia: bool = d["breccia"]
	var danni := danni_diga(nd)
	var vivi := rientrati + proseguono
	var t := ""
	var spiega := ""
	match scen:
		1:
			if breccia:
				if upkeep >= 4:
					t = ["Vittoria schiacciante", "Lavoro ben fatto", "Successo costoso"][0 if vivi >= 6 else (1 if vivi >= 4 else 2)]
				elif upkeep >= 1:
					t = ["Successo", "Valeva il prezzo?", "Un lavoro caro"][0 if vivi >= 6 else (1 if vivi >= 4 else 2)]
				else:
					t = "Per un soffio"
			else:
				if upkeep >= 4:
					t = "Occasione sprecata" if vivi >= 6 else "Esperimento costoso"
				elif upkeep >= 1:
					t = "Fallimento magnifico" if vivi >= 5 else "Esperimento inutile"
				else:
					t = ["Follia oltraggiosa", "Esperimento sanguinoso", "Catastrofe"][0 if vivi >= 4 else (1 if vivi >= 2 else 2)]
			spiega = "Storicamente la Möhne cedette dopo cinque Upkeep; AJ-M fu abbattuto e tre Upkeep proseguirono verso la Eder."
		2:
			if breccia:
				if vivi >= 4:
					t = "Applausi a scena aperta" if upkeep >= 1 else "Operazione condotta brillantemente"
				elif vivi >= 3:
					t = "Bombardamento perfetto" if upkeep >= 1 else "Colpo da titani"
				else:
					t = "Eroismo"
			else:
				if danni >= capacita(nd) - 2 and danni > 0:
					t = "Sull'orlo della vittoria"
				elif vivi >= 4:
					t = "Occasione perduta" if upkeep >= 1 else "Grande esperimento"
				elif vivi >= 2:
					t = "Delusione" if upkeep >= 1 else "Tutto storto"
				else:
					t = "Una diga di troppo" if upkeep >= 1 else "Disastro a ovest"
			spiega = "Storicamente la Eder cedette all'Upkeep di Knight, il terzo sganciato; Maudslay fu travolto dalla sua stessa esplosione."
		3:
			var danneggiata := _ha_colpi(nd)
			var casa: bool = lanc("AJ-T")["pos"] == "a casa"
			var caccia: bool = s["caccia_attacco"] or d["caccia_vicino"]
			if danneggiata:
				t = ("Un colpo solo" if caccia else "Missione compiuta") if casa else ("Successo amaro" if caccia else "Eroismo")
			else:
				var sganciato := false
				for u in d["upkeep"]:
					if u["lanc"] == "AJ-T": sganciato = true
				t = ("Frustrazione amara" if sganciato else "Sopravvissuti") if casa else "Fallimento"
			spiega = "Storicamente McCarthy fece nove passaggi a vuoto prima di sganciare: l'Upkeep colpì il coronamento senza aprire la diga, e AJ-T rientrò."
		4:
			var l := lanc("AJ-F")
			var casa: bool = l["pos"] == "a casa"
			var mio := ""
			for u in d["upkeep"]:
				if u["lanc"] == "AJ-F": mio = u["esito"]
			if breccia:
				t = "Vittoria strategica!" if casa else "Eroi postumi?"
			elif mio == "colpito":
				if danni >= 7:
					t = "Missione compiuta" if casa else "Eroi postumi?"
				else:
					t = "Lavoro completato" if casa else "Pacco consegnato"
			elif mio == "mancato":
				t = "Non è bastato" if casa else "Disfatta"
			else:
				t = "Missione annullata" if casa else "Disfatta"
			spiega = "Storicamente Brown sganciò nella nebbia dopo diversi passaggi: la Sorpe fu danneggiata ma resse, e AJ-F rientrò."
		5:
			var l := lanc("AJ-O")
			var casa: bool = l["pos"] == "a casa"
			var colpita := ""
			var mancato := false
			for k in s["dighe"]:
				for u in s["dighe"][k]["upkeep"]:
					if u["esito"] == "colpito": colpita = k
					else: mancato = true
			var rotta := false
			for k in s["dighe"]:
				if s["dighe"][k]["breccia"]: rotta = true
			if rotta:
				t = "Vittoria inattesa!" if casa else "Vincitori abbattuti"
			elif colpita != "":
				if colpita == "bever" and casa:
					t = "Un nuovo aneddoto"
				else:
					t = "Ben fatto" if casa else "Vincitori abbattuti"
			elif mancato:
				t = "Un enigma" if casa else "Svaniti"
			else:
				t = "Una notte confusa" if casa else "Dispersi (M.I.A.)"
			if not casa:
				var x := d6()
				var sorte: String = ["", "la sorte dell'equipaggio resta un mistero", "il luogo dello schianto viene segnato decenni dopo", "il luogo dello schianto viene segnato decenni dopo", "due uomini si lanciano col paracadute", "due uomini si lanciano col paracadute", ""][x]
				if x == 6:
					var y := d6()
					sorte = "un sopravvissuto gravemente ferito viene " + ("catturato e sopravvive alla guerra" if y % 2 == 0 else "ritrovato senza vita")
				spiega = "Sorte dell'equipaggio (dado %d): %s. " % [x, sorte]
			spiega += "Storicamente Townsend sganciò dopo tre passaggi: l'Upkeep esplose senza danni, forse sulla Bever invece che sulla Ennepe."
	var righe := []
	for l in s["lanc"]:
		righe.append("%s %s: %s" % [l["id"], l["pilota"], l["esito"] if l["esito"] != "" else "?"])
	return {"titolo": t, "spiega": spiega, "breccia": breccia, "danni": danni, "capacita": capacita(nd),
		"rientrati": rientrati, "proseguono": proseguono, "upkeep": upkeep, "righe": righe}

# ================================================================ salvataggio
func esporta() -> Dictionary:
	return s.duplicate(true)

func importa(d: Dictionary) -> void:
	s = d
	# i numeri del JSON tornano come float: nei dizionari dove servono interi li convertiamo all'uso
	if not s.has("eventi"):
		s["eventi"] = []
