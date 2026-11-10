## Dati del gioco: tabelle dei Player Aid (A1-A14, E1-E3), dighe, gettoni, Upkeep, specialisti e scenari 1-5.
## I numeri vengono dalle tabelle e dalla mappa del gioco originale (modulo Tabletop Simulator).
class_name Dati
extends RefCounted

# ------------------------------------------------------------------ equipaggi
## Livelli di addestramento degli equipaggi negli scenari 1-9 (libro degli scenari).
const ADDESTRAMENTO := {"recluta": 2, "esperto": 3, "veterano": 5}
const NOME_EQUIPAGGIO := {"recluta": "Recluta", "esperto": "Esperto", "veterano": "Veterano"}
const NOME_EQUIPAGGIO_EN := {"recluta": "Green", "esperto": "Seasoned", "veterano": "Veteran"}

## Gettoni concessi dal livello Quota e Velocità (Mission Planning Blotter).
static func gettoni_da_livello(l: int) -> int:
	if l <= 0: return 0
	if l <= 2: return 1
	if l <= 4: return 2
	if l <= 6: return 3
	return 4

## Modificatore di sgancio dal livello Puntamento e Sgancio.
static func mod_puntamento(l: int) -> int:
	return [0, 0, 1, 1, 1, 2, 2, 3, 4][clampi(l, 0, 8)]

# ------------------------------------------------------------------ dighe
## capacita: danni necessari per la breccia secondo il livello dell'acqua (2 = in salita, 3 = alta, 4 = piena).
## mappa: la mappa del bersaglio usata; colonna: colonna della tabella del vettore d'avvicinamento.
const DIGHE := {
	"mohne":  {"nome": "Möhne",  "rv": 8, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "mohne", "colonna": "altra", "zona": "Ruhr"},
	"eder":   {"nome": "Eder",   "rv": 9, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "eder",  "colonna": "eder",  "zona": "Weser"},
	"sorpe":  {"nome": "Sorpe",  "rv": 5, "capacita": {2: 15, 3: 12, 4: 10}, "mappa": "sorpe", "colonna": "sorpe", "zona": "Ruhr"},
	"ennepe": {"nome": "Ennepe", "rv": 3, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "mohne", "colonna": "altra", "zona": "Ruhr"},
	"bever":  {"nome": "Bever",  "rv": 3, "capacita": {2: 14, 3: 11, 4: 9},  "mappa": "sorpe", "colonna": "sorpe", "zona": "Ruhr"},
	"lister": {"nome": "Lister", "rv": 4, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "mohne", "colonna": "altra", "zona": "Weser"},
	"diemel": {"nome": "Diemel", "rv": 4, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "mohne", "colonna": "altra", "zona": "Weser"},
	"henne":  {"nome": "Henne",  "rv": 2, "capacita": {2: 12, 3: 8, 4: 6},   "mappa": "mohne", "colonna": "altra", "zona": "Ruhr"},
}
const ACQUA := {2: "in salita", 3: "alta", 4: "piena"}

## Sorpe e Bever: niente zona vicina e luci Aldis senza effetto.
static func senza_zona_vicina(diga: String) -> bool:
	return diga == "sorpe" or diga == "bever"

# ------------------------------------------------------------------ A1: vettore d'avvicinamento
## Per colonna (eder / sorpe = Sorpe o Bever / altra), riga = livello di ricognizione 0-4, tre fasce di dado.
## Ogni casella: [risultati con tempo sereno, risultati aggiunti con la nebbia]. S = -1 gettone velocità,
## A = -1 gettone quota, M = modificatore Michelskopf.
const FASCE := {"eder": [[1, 3], [4, 5], [6, 6]], "sorpe": [[1, 2], [3, 5], [6, 6]], "altra": [[1, 2], [3, 4], [5, 6]]}
const VETTORE := {
	"eder": [
		[["SSM", "AA"], ["SM", "AA"], ["S", "A"]],
		[["SSM", "AA"], ["SM", "A"], ["", "A"]],
		[["SSM", "AA"], ["S", "A"], ["", "A"]],
		[["SSM", "AA"], ["", "A"], ["", "A"]],
		[["SM", "A"], ["", "A"], ["", ""]],
	],
	"sorpe": [
		[["SS", "SA"], ["SS", "SA"], ["S", "A"]],
		[["SS", "SA"], ["S", "SA"], ["S", "A"]],
		[["SS", "SA"], ["S", "A"], ["", "A"]],
		[["S", "SA"], ["S", "A"], ["", "A"]],
		[["S", "SA"], ["", "A"], ["", ""]],
	],
	"altra": [
		[["SSA", "AA"], ["SS", "AA"], ["S", "A"]],
		[["SS", "AA"], ["S", "AA"], ["S", "A"]],
		[["SS", "AA"], ["S", "AA"], ["", "A"]],
		[["SS", "AA"], ["", "A"], ["", "A"]],
		[["S", "AA"], ["", "A"], ["", ""]],
	],
}

# ------------------------------------------------------------------ A4: flak
const FLAK := {1: [2, 4], 2: [3, 5], 3: [4, 6], 4: [5, 7], 5: [6, 9]}

# ------------------------------------------------------------------ A6: caccia notturno
## Passo 1 (avvistato?): somma di 2 dadi nell'intervallo, per livello d'allerta 0-4.
const CACCIA_AVVISTA_FARI := [[2, 4], [3, 5], [4, 6], [5, 7], [6, 9]]
const CACCIA_AVVISTA := [[2, 3], [2, 4], [3, 5], [4, 6], [5, 7]]
## Passo 2 (mappa del bersaglio): per livello d'attività 0 / 1-3 / 4-6 / 7+: [svanisce da, vicino da, attacco fino a].
const CACCIA_NON_VICINO := [[5, 3, 2], [8, 3, 2], [9, 4, 3], [11, 5, 4]]
const CACCIA_VICINO := [[5, 4, 3], [6, 5, 4], [8, 6, 5], [9, 7, 6]]

# ------------------------------------------------------------------ A9: sgancio tardivo
## dado: [modificatore, segni Michelskopf, nome]
const TARDIVO := {1: [-2, 2, "«Un rimbalzo di troppo?»"], 2: [-1, 2, ""], 3: [-1, 2, ""], 4: [0, 1, ""], 5: [0, 1, ""], 6: [1, 0, "«Centrato!»"]}

# ------------------------------------------------------------------ gettoni di avvicinamento e sgancio
## 7 gettoni Quota e 7 Velocità. Lato avvicinamento: valore e numero di gettoni da pescare allo sgancio.
## Lato sgancio: valore, modificatore e segno Michelskopf (M).
const GETTONI_QUOTA := [
	{"id": "q1", "av": "53 ft", "n": 1, "sg": "64 ft", "mod": 3, "m": false},
	{"id": "q2", "av": "irregolare", "n": 0, "sg": "irregolare", "mod": 0, "m": true},
	{"id": "q3", "av": "60 ft", "n": 3, "sg": "70 ft", "mod": 1, "m": false},
	{"id": "q4", "av": "56 ft", "n": 2, "sg": "52 ft", "mod": 1, "m": true},
	{"id": "q5", "av": "65 ft", "n": 2, "sg": "67 ft", "mod": 2, "m": false},
	{"id": "q6", "av": "54 ft", "n": 1, "sg": "56 ft", "mod": 2, "m": true},
	{"id": "q7", "av": "70 ft", "n": 1, "sg": "60 ft", "mod": 4, "m": false},
]
const GETTONI_VELOCITA := [
	{"id": "v1", "av": "227 mph", "n": 2, "sg": "216 mph", "mod": 2, "m": true},
	{"id": "v2", "av": "irregolare", "n": 0, "sg": "irregolare", "mod": 0, "m": true},
	{"id": "v3", "av": "220 mph", "n": 3, "sg": "213 mph", "mod": 1, "m": true},
	{"id": "v4", "av": "216 mph", "n": 2, "sg": "228 mph", "mod": 1, "m": false},
	{"id": "v5", "av": "212 mph", "n": 1, "sg": "223 mph", "mod": 2, "m": false},
	{"id": "v6", "av": "210 mph", "n": 1, "sg": "218 mph", "mod": 3, "m": true},
	{"id": "v7", "av": "231 mph", "n": 1, "sg": "220 mph", "mod": 4, "m": false},
]

static func gettone(id: String) -> Dictionary:
	if id == "J":
		return {"id": "J", "av": "cane di Gibson (irregolare)", "sg": "cane di Gibson (irregolare)", "n": 0, "mod": 0, "m": true}
	for g in GETTONI_QUOTA + GETTONI_VELOCITA:
		if g["id"] == id:
			return g
	return {}

# ------------------------------------------------------------------ Upkeep
## I 25 segnalini Upkeep: il retro ha un numero dispari e uno pari; il dado della detonazione sceglie quello
## con la stessa parità (A14).
const UPKEEP := [[3, 2], [1, 2], [2, 3], [2, 3], [5, 4], [1, 2], [3, 2], [4, 3], [1, 2], [3, 4], [1, 2], [5, 6], [3, 2],
	[4, 3], [1, 2], [3, 2], [3, 4], [2, 3], [4, 3], [7, 6], [3, 4], [5, 6], [5, 4], [3, 4], [3, 4]]

static func danno_upkeep(u: int, dado: int) -> int:
	var c: Array = UPKEEP[u]
	return c[0] if (c[0] % 2) == (dado % 2) else c[1]

# ------------------------------------------------------------------ Lancaster
const LANCASTER := {
	"AJ-A": {"pilota": "Young", "paese": "GB"}, "AJ-B": {"pilota": "Astell", "paese": "GB"},
	"AJ-E": {"pilota": "Barlow", "paese": "AUS"}, "AJ-F": {"pilota": "Brown", "paese": "CAN"},
	"AJ-G": {"pilota": "Gibson", "paese": "GB"}, "AJ-J": {"pilota": "Maltby", "paese": "GB"},
	"AJ-L": {"pilota": "Shannon", "paese": "AUS"}, "AJ-M": {"pilota": "Hopgood", "paese": "GB"},
	"AJ-N": {"pilota": "Knight", "paese": "AUS"}, "AJ-O": {"pilota": "Townsend", "paese": "GB"},
	"AJ-P": {"pilota": "Martin", "paese": "AUS"}, "AJ-T": {"pilota": "McCarthy", "paese": "USA"},
	"AJ-Z": {"pilota": "Maudslay", "paese": "GB"},
	"AJ-C": {"pilota": "Ottley", "paese": "GB"}, "AJ-H": {"pilota": "Rice", "paese": "GB"},
	"AJ-K": {"pilota": "Byers", "paese": "CAN"}, "AJ-S": {"pilota": "Burpee", "paese": "CAN"},
	"AJ-W": {"pilota": "Munro", "paese": "NZ"}, "AJ-Y": {"pilota": "Anderson", "paese": "USA"},
}

# ------------------------------------------------------------------ specialisti (Elite Crewmen)
## ruolo: bombardiere (+1 sgancio), motorista (+1 gettone velocità), mitragliere_ant (-1 tiro mitragliatrice
## anteriore), mitragliere_post (-1 tiro mitragliatrice posteriore), comandante (un tiro ripetuto a partita),
## navigatore_q (+1 gettone quota), navigatore (+1 navigazione: solo voli), pilota_vettore (2 dadi per il
## vettore d'avvicinamento), pilota_danno (ignora un danno, una volta), pilota_evasione e pilota_mappa (solo voli),
## marconista (solo voli).
const SPECIALISTI := {
	"gibson":       {"nome": "Gibson",       "ruolo": "comandante"},
	"trevor_roper": {"nome": "Trevor-Roper", "ruolo": "mitragliere_post"},
	"deering":      {"nome": "Deering",      "ruolo": "mitragliere_ant"},
	"spafford":     {"nome": "Spafford",     "ruolo": "bombardiere"},
	"pulford":      {"nome": "Pulford",      "ruolo": "motorista"},
	"gregory":      {"nome": "Gregory",      "ruolo": "mitragliere_ant"},
	"hopgood":      {"nome": "Hopgood",      "ruolo": "pilota_mappa"},
	"martin":       {"nome": "Martin",       "ruolo": "pilota_danno"},
	"leggo":        {"nome": "Leggo",        "ruolo": "navigatore"},
	"chambers":     {"nome": "Chambers",     "ruolo": "marconista"},
	"shannon":      {"nome": "Shannon",      "ruolo": "pilota_vettore"},
	"walker":       {"nome": "Walker",       "ruolo": "navigatore_q"},
	"sumpter":      {"nome": "Sumpter",      "ruolo": "bombardiere"},
	"knight":       {"nome": "Knight",       "ruolo": "pilota_evasione"},
	"hobday":       {"nome": "Hobday",       "ruolo": "navigatore"},
	"urquhart":     {"nome": "Urquhart",     "ruolo": "navigatore_q"},
	"tytherleigh":  {"nome": "Tytherleigh",  "ruolo": "mitragliere_ant"},
	"johnson":      {"nome": "G. Johnson",   "ruolo": "bombardiere"},
	"mccarthy":     {"nome": "McCarthy",     "ruolo": "pilota_evasione"},
	"oancia":       {"nome": "Oancia",       "ruolo": "bombardiere"},
	"franklin":     {"nome": "Franklin",     "ruolo": "bombardiere"},
	"townsend":     {"nome": "Townsend",     "ruolo": "pilota_mappa"},
	"nicholson":    {"nome": "Nicholson",    "ruolo": "navigatore"},
	"gillespie":    {"nome": "Gillespie",    "ruolo": "bombardiere"},
	"marriott":     {"nome": "Marriott",     "ruolo": "motorista"},
	"chambers_r":   {"nome": "Chambers",     "ruolo": "marconista"},
}
const RUOLI := {
	"comandante":       ["Comandante di stormo", "Un tiro ripetuto per partita."],
	"mitragliere_post": ["Mitragliere di coda", "-1 ai tiri della mitragliatrice posteriore."],
	"mitragliere_ant":  ["Mitragliere di prua", "-1 ai tiri della mitragliatrice anteriore."],
	"bombardiere":      ["Puntatore", "+1 al tiro di sgancio."],
	"motorista":        ["Motorista", "+1 gettone Velocità nell'avvicinamento."],
	"navigatore_q":     ["Navigatore", "+1 gettone Quota nell'avvicinamento."],
	"navigatore":       ["Navigatore", "+1 ai controlli di navigazione (solo negli scenari di volo)."],
	"pilota_vettore":   ["Pilota", "Tira 2 dadi per il vettore d'avvicinamento e sceglie."],
	"pilota_danno":     ["Pilota", "Ignora un danno (una volta per partita)."],
	"pilota_evasione":  ["Pilota", "Schiva e zigzaga (solo negli scenari di volo)."],
	"pilota_mappa":     ["Pilota", "Ignora un errore di rotta (solo negli scenari di volo)."],
	"marconista":       ["Marconista", "3 dadi per la radiotelegrafia (solo negli scenari di volo)."],
}

# ------------------------------------------------------------------ scenari
## lanc: [id, equipaggio, upkeep, posizione iniziale, danneggiato, specialisti possibili (il primo è quello storico)]
const SCENARI := {
	1: {
		"titolo": "Attacco alla diga della Möhne", "ora": "00:20 del 17 maggio 1943",
		"diga": "mohne", "turno": 4, "razzi": [3], "visibilita": "sereno", "mod_visibilita": 0,
		"allerta": 1, "dighe": {"mohne": {"acqua": 4, "recon": 2, "attivita": 1, "flak": 3}},
		"giri": 3, "seguente": "Eder",
		"lanc": [
			["AJ-G", "veterano", true, "vicino", false, ["gibson", "trevor_roper", "deering"]],
			["AJ-M", "veterano", true, "lontano", true, ["gregory"]],
			["AJ-P", "veterano", true, "lontano", false, ["martin"]],
			["AJ-A", "veterano", true, "lontano", false, []],
			["AJ-J", "esperto", true, "lontano", false, []],
			["AJ-L", "veterano", true, "lontano", false, ["shannon", "walker"]],
			["AJ-Z", "veterano", true, "lontano", false, []],
			["AJ-N", "esperto", true, "lontano", false, []],
		],
		"storia": "Mezzanotte e venti. La prima ondata è sopra il lago della Möhne: le torri della diga sono punteggiate di contraerea. Gibson scende per primo, gli altri girano al largo in attesa del loro turno. Le Upkeep che restano a bordo proseguiranno verso la Eder.",
	},
	2: {
		"titolo": "Attacco alla diga della Eder", "ora": "01:30 del 17 maggio 1943",
		"diga": "eder", "turno": 5, "razzi": [], "visibilita": "nebbia", "mod_visibilita": 0,
		"allerta": 2, "dighe": {"eder": {"acqua": 4, "recon": 2, "attivita": 0, "flak": 0}},
		"giri": 2, "seguente": "Sorpe",
		"lanc": [
			["AJ-G", "veterano", false, "vicino", false, ["gibson", "trevor_roper", "deering"]],
			["AJ-L", "veterano", true, "vicino", false, ["shannon", "walker"]],
			["AJ-N", "esperto", true, "vicino", false, []],
			["AJ-Z", "veterano", true, "vicino", false, []],
		],
		"storia": "La Eder non ha contraerea: la difende la valle stessa. La nebbia riempie le anse del lago e dietro la diga si alza lo sperone del Michelskopf: chi sgancia deve risalire subito, o ci finisce contro.",
	},
	3: {
		"titolo": "Primo attacco alla diga della Sorpe", "ora": "00:15 del 17 maggio 1943",
		"diga": "sorpe", "turno": 3, "razzi": [], "visibilita": "nebbia", "mod_visibilita": 0,
		"allerta": 1, "dighe": {"sorpe": {"acqua": 4, "recon": 2, "attivita": 0, "flak": 0}},
		"giri": 2, "seguente": "",
		"lanc": [["AJ-T", "esperto", true, "vicino", true, ["johnson"]]],
		"storia": "McCarthy è partito in ritardo con un aereo di riserva, già danneggiato. La Sorpe è una diga di terra: l'Upkeep non si lancia perpendicolare, ma lungo il coronamento, a motori quasi spenti, nella foschia che sale dalla valle.",
	},
	4: {
		"titolo": "Secondo attacco alla diga della Sorpe", "ora": "03:14 del 17 maggio 1943",
		"diga": "sorpe", "turno": 3, "razzi": [2], "visibilita": "nebbia", "mod_visibilita": -2,
		"allerta": 3, "dighe": {"sorpe": {"acqua": 4, "recon": 2, "attivita": 2, "flak": 0}},
		"giri": 2, "seguente": "", "danno_precedente": true,
		"lanc": [["AJ-F", "esperto", true, "vicino", false, ["oancia"]]],
		"storia": "Brown arriva sulla Sorpe con la riserva mobile, nella nebbia ormai fitta. La diga porta già il segno dell'Upkeep di McCarthy: un secondo colpo potrebbe bastare.",
	},
	5: {
		"titolo": "Attacco alla diga della Ennepe?", "ora": "03:30 del 17 maggio 1943",
		"diga": "ennepe", "turno": 5, "razzi": [], "visibilita": "nebbia", "mod_visibilita": -2,
		"allerta": 3, "dighe": {"ennepe": {"acqua": 4, "recon": 1, "attivita": 0, "flak": 0},
			"bever": {"acqua": 4, "recon": 1, "attivita": 0, "flak": 0}},
		"giri": 2, "seguente": "", "nebbia_di_guerra": true,
		"lanc": [["AJ-O", "recluta", true, "vicino", false, ["franklin"]]],
		"storia": "Townsend vola da solo con la riserva mobile, nella foschia dell'alba. La diga che vede sotto di sé è la Ennepe... o forse la Bever, pochi chilometri più in là: anche oggi gli storici ne discutono.",
	},
}

# ================================================================== scenari di volo (Parte 2)
const ZONE := ["inghilterra", "costa_inglese", "mare", "costa_olandese", "ruhr", "weser"]
const NOME_ZONA := {"inghilterra": "Inghilterra", "costa_inglese": "Costa inglese", "mare": "Mare del Nord",
	"costa_olandese": "Costa olandese", "ruhr": "Ruhr", "weser": "Weser"}
## Pericoli di base per zona: [numero, tazza, ostile (pericoli in più e schivabili)]
const PERICOLI_ZONA := {"inghilterra": [0, "", false], "costa_inglese": [1, "giallo", false], "mare": [2, "giallo", false],
	"costa_olandese": [3, "azzurro", true], "ruhr": [2, "azzurro", true], "weser": [2, "blu", true]}
const ORA_VOLO := ["", "21:00", "22:00", "23:00", "00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00"]
## Modificatore della visibilità per turno di volo (il turno 9 è sempre nebbia).
const VIS_VOLO := [0, 0, 0, 0, 0, 0, -2, -2, -2, -99, 0]
## Abilità di navigazione dal livello di addestramento (Mission Planning Blotter).
static func navigazione(l: int) -> int:
	return [10, 9, 8, 7, 7, 6, 5, 4][clampi(l, 0, 7)]
## Acquisizione del bersaglio (F8): somma delle ricognizioni di zona e diga -> tiro minimo con la luna.
static func acquisizione(r: int) -> int:
	if r <= 1: return 11
	return [11, 11, 10, 9, 7, 6, 4][mini(r, 6)]
## Caccia sulla mappa di volo (A6 passo 2): intervallo d'attacco per tipo.
const CACCIA_VOLO := {"Me 109": [2, 5], "Me 110": [4, 6], "Ju 88": [5, 7]}

## Le tre tazze dei pericoli: [fronte visibile, tipo, valore]. Fronte: ? (mistero), aereo, cannone, fari,
## palloni, tralicci, città. Tipi: vedi PERICOLI.
const TAZZE := {
	"giallo": [["?", "comandi_v", 0], ["?", "comandi_v", 0], ["?", "nessuno", 0], ["?", "inabile", 0], ["?", "bussola", 0],
		["?", "uccelli", 0], ["?", "merlin", 0], ["?", "merlin", 0], ["?", "ritardo", 0], ["?", "ritardo", 0],
		["?", "sgancio_dif", 0], ["?", "errore", 0], ["?", "errore", 0], ["?", "no_aldis", 0], ["?", "comandi_q", 0], ["?", "radio", 0]],
	"azzurro": [["?", "errore", 0], ["?", "flak", 5], ["?", "flak", 4], ["?", "palloni", 0], ["?", "fari", 0], ["?", "fari", 0],
		["?", "caccia", 109], ["?", "fari", 0], ["?", "flak", 2], ["?", "errore", 0], ["?", "errore", 0], ["?", "fari", 0],
		["?", "schianto", 0], ["?", "schianto", 0], ["?", "errore", 0], ["?", "errore", 0], ["?", "errore", 0],
		["aereo", "caccia", 110], ["aereo", "caccia", 110],
		["cannone", "flak", 4], ["cannone", "flak", 5], ["cannone", "flak", 4], ["cannone", "flak", 3], ["cannone", "flak", 3], ["cannone", "flak", 1],
		["fari", "fari", 0], ["fari", "fari", 0], ["fari", "fari", 0], ["palloni", "palloni", 0], ["tralicci", "schianto", 0]],
	"blu": [["?", "fari", 0], ["?", "errore", 0], ["?", "caccia", 110], ["?", "flak", 5], ["?", "flak", 1], ["?", "fari", 0],
		["?", "schianto", 0], ["?", "flak", 2], ["?", "fari", 0],
		["cannone", "flak", 4], ["cannone", "flak", 4], ["cannone", "flak", 4], ["cannone", "flak", 5], ["cannone", "flak", 3],
		["fari", "fari", 0], ["fari", "fari", 0], ["aereo", "caccia", 88], ["città", "schianto", 0]],
}
const PERICOLI := {
	"comandi_v": "Comandi difettosi (-1 gettone Velocità)", "comandi_q": "Comandi difettosi (-1 gettone Quota)",
	"nessuno": "Nessun pericolo", "inabile": "Equipaggio inabile (-3 all'addestramento)", "bussola": "Bussola deviata",
	"uccelli": "Uccelli o pipistrelli", "merlin": "Motore Merlin guasto", "ritardo": "Partenza ritardata",
	"sgancio_dif": "Sgancio difettoso (-1)", "errore": "Errore di rotta", "no_aldis": "Luci Aldis guaste",
	"radio": "Radio rotta", "flak": "Contraerea", "palloni": "Palloni di sbarramento", "fari": "Fotoelettriche",
	"caccia": "Caccia notturno", "schianto": "Schianto (linee elettriche, alberi)",
}
## Pericoli che restano attaccati al Lancaster.
const ATTACCATI := ["comandi_v", "comandi_q", "inabile", "bussola", "merlin", "ritardo", "sgancio_dif", "errore", "no_aldis", "radio"]
## Pericoli con il salvataggio del veterano (V).
const CON_V := ["uccelli", "palloni", "schianto"]

## Scenari di volo. onde: [nome, capo, [membri]]; lanc: [id, equipaggio, specialisti, upkeep];
## primario/secondario/riserva: dighe; turno: turno di volo d'inizio; entra: turno in cui il gruppo parte.
const VOLI := {
	6: {"titolo": "Il volo della forza diversiva", "ora": "21:00 del 16 maggio 1943", "turno": 1, "allerta": 1,
		"storia": "Cinque Lancaster partono per la rotta settentrionale, sopra le isole olandesi: devono attaccare la Sorpe e attirare su di sé l'attenzione della difesa tedesca. AJ-T di McCarthy, partito in ritardo con l'aereo di riserva, vola da solo.",
		"forze": [
			{"onda": "Forza diversiva", "capo": "AJ-E", "primario": "sorpe", "secondario": "", "entra": 1,
			 "lanc": [["AJ-E", "esperto", ["gillespie"]], ["AJ-H", "recluta", []], ["AJ-K", "esperto", []], ["AJ-W", "esperto", []]]},
			{"onda": "", "capo": "", "primario": "sorpe", "secondario": "", "entra": 1, "bussola": true,
			 "lanc": [["AJ-T", "esperto", ["mccarthy", "johnson"]]]},
		],
		"riserva": "ennepe", "radio_da": "sorpe", "dighe_recon": {"mohne": 2, "eder": 2, "sorpe": 2}},
	7: {"titolo": "Il volo della forza principale", "ora": "21:30 del 16 maggio 1943", "turno": 1, "allerta": 1,
		"storia": "Le tre ondate di Gibson attraversano il Mare del Nord a bassissima quota verso la Möhne. Le Upkeep che avanzeranno sono per la Eder; la Sorpe è il bersaglio di riserva.",
		"forze": [
			{"onda": "Prima ondata", "capo": "AJ-G", "primario": "mohne", "secondario": "eder", "entra": 1,
			 "lanc": [["AJ-G", "veterano", ["gibson", "trevor_roper", "deering"]], ["AJ-M", "veterano", ["gregory", "hopgood"]], ["AJ-P", "veterano", ["martin", "leggo"]]]},
			{"onda": "Seconda ondata", "capo": "AJ-A", "primario": "mohne", "secondario": "eder", "entra": 1,
			 "lanc": [["AJ-A", "veterano", ["nicholson"]], ["AJ-J", "esperto", []], ["AJ-L", "veterano", ["shannon", "walker"]]]},
			{"onda": "Terza ondata", "capo": "AJ-N", "primario": "mohne", "secondario": "eder", "entra": 1,
			 "lanc": [["AJ-N", "esperto", ["knight"]], ["AJ-B", "veterano", []], ["AJ-Z", "veterano", ["urquhart"]]]},
		],
		"riserva": "sorpe", "radio_da": "mohne", "attivita": {"mohne": 1}, "dighe_recon": {"mohne": 2, "eder": 2, "sorpe": 2}},
	8: {"titolo": "Il volo della riserva mobile", "ora": "23:00 del 16 maggio 1943", "turno": 3, "allerta": 3,
		"storia": "Quando la riserva mobile decolla le difese sono già in allarme. Gli ordini arriveranno per radio: Möhne ed Eder, se servono ancora, altrimenti la Sorpe e le dighe minori.",
		"forze": [
			{"onda": "Riserva mobile", "capo": "AJ-C", "primario": "mohne", "secondario": "eder", "entra": 3,
			 "lanc": [["AJ-C", "esperto", []], ["AJ-F", "esperto", ["oancia"]], ["AJ-O", "recluta", ["townsend", "franklin"]], ["AJ-S", "esperto", []], ["AJ-Y", "recluta", []]]},
		],
		"riserva": "ennepe", "radio_turno": 5, "attivita": {"sorpe": 1}, "danno_sorpe": true, "dighe_recon": {"mohne": 2, "eder": 2, "sorpe": 2}},
	9: {"titolo": "Il raid delle dighe (tutte le forze)", "ora": "21:00 del 16 maggio 1943", "turno": 1, "allerta": 1,
		"storia": "Diciannove Lancaster: la forza diversiva verso la Sorpe, le tre ondate verso la Möhne e la Eder, la riserva mobile che decolla due ore dopo. Tutta l'Operazione Chastise.",
		"forze": [],
		"riserva": "ennepe", "radio_turno": 5, "dighe_recon": {"mohne": 2, "eder": 2, "sorpe": 2}},
}

# ================================================================== campagna (scenario 10)
const CAMPAGNA := {
	"titolo": "Operazione Chastise (campagna)", "ora": "marzo-maggio 1943", "turno": 1, "allerta": 0, "giri": 4,
	"storia": "Il 617° Squadron nasce a marzo a Scampton. Hai quattro turni di pianificazione, due settimane ciascuno, per requisire uomini, aerei e Upkeep, addestrare gli equipaggi, modificare i Lancaster e fotografare le dighe senza farti scoprire. Poi, quando vuoi, il raid.",
}
## Personale di terra: [nome, maneggio, erk, sortita, costo] fresco e affaticato.
const SQUADRE := [
	{"id": "s1", "nome": "Squadra Dixon", "fresco": [10, 5, 5], "stanco": [8, 4, 3], "costo": 6},
	{"id": "s2", "nome": "Squadra Hellier", "fresco": [10, 5, 5], "stanco": [8, 4, 3], "costo": 6},
	{"id": "s3", "nome": "Squadra Powell", "fresco": [8, 4, 4], "stanco": [7, 3, 3], "costo": 5},
	{"id": "s4", "nome": "Squadra Caple", "fresco": [8, 4, 4], "stanco": [7, 3, 3], "costo": 5},
	{"id": "s5", "nome": "Squadra Munro", "fresco": [7, 4, 4], "stanco": [6, 3, 3], "costo": 3},
	{"id": "s6", "nome": "Squadra Lloyd", "fresco": [7, 4, 4], "stanco": [6, 3, 3], "costo": 3},
]
const LUNA := ["", "luna (marzo-aprile)", "senza luna (aprile)", "luna (maggio)", "senza luna (maggio)"]
const COSTO_EQUIPAGGIO := {"recluta": 1, "esperto": 2, "veterano": 3}
## Tabella dell'addestramento: per tipo d'equipaggio e risultato (1 o meno ... 7+): [livelli, effetti]
## Effetti: c schianto, d danno a un aereo, x ritira (pari danno, dispari schianto), R riposato, E specialista.
const ADDESTRA := {
	"recluta":  [[0, "c"], [0, ""], [1, ""], [1, ""], [1, ""], [1, "d"], [2, "Ed"]],
	"esperto":  [[0, "xR"], [0, ""], [1, ""], [1, ""], [2, ""], [2, "dE"], [2, "E"]],
	"veterano": [[1, "dR"], [1, ""], [1, ""], [2, ""], [2, ""], [2, "E"], [3, "Ed"]],
}
const SPECIALITA := {"nav": "Navigazione", "quota": "Quota e velocità", "bomba": "Puntamento e sgancio"}
## Ricognizione delle dighe (P8): per difesa, risultato del dado 1-6.
const RECON_DIFESE := {"flak": [4, 3, 2, 1, 0, 0], "fari": [2, 1, 1, 0, 0, 0], "palloni": [2, 1, 1, 0, 0, 0]}
## Miglioramento per sorpresa (P6): incremento per dado 1-6; * = caccia nei paraggi.
const SORPRESA_DIFESE := {"flak": [3, 2, 1, 1, 1, 0], "fari": [3, 2, 1, 1, 0, 0], "palloni": [2, 1, 1, 1, 1, 0]}
const SORPRESA_CACCIA := {"fari": [4, 5, 6], "palloni": [6]}
## Icone della sorpresa sulla traccia di ogni diga, per livello di ricognizione 0-4 ("" nessuna, "o" cerchio, "r" rombo).
const ICONE := {
	"lister": ["", "", "", "o", "r"], "diemel": ["", "", "", "o", "r"], "eder": ["", "o", "o", "r", "r"],
	"henne": ["", "", "", "", "o"], "sorpe": ["", "", "o", "r", "r"], "bever": ["", "", "", "o", "r"],
	"ennepe": ["", "", "", "o", "r"], "mohne": ["", "", "o", "r", "r"],
}
## Retro degli 11 segnalini Ricognizione: [numero semplice, rombo, cerchio, modificatore dell'acqua]
const RETRO_RECON := [[3, 4, 2, 2], [4, 3, 4, 3], [3, 3, 4, 2], [3, 3, 4, 1], [3, 4, 3, 0], [3, 4, 2, 1], [4, 3, 5, 1],
	[2, 5, 3, 2], [2, 5, 3, 2], [2, 6, 3, 3], [4, 3, 5, 4]]
## Livelli di rischio per la sicurezza: [massimo, nome, allerta iniziale, modificatore della sorpresa]
const RISCHIO := [[7, "basso", 0, 0], [9, "medio", 0, -1], [14, "alto", 1, -3], [19, "molto alto", 1, -5], [999, "pericoloso", 2, -6]]
static func rischio(v: int) -> Array:
	for r in RISCHIO:
		if v <= int(r[0]):
			return r
	return RISCHIO[4]
