"""Traduzioni della mappa originale (coordinate della tavola 5100x3300).
DIZ: righe OCR tradotte sul posto (chiave = testo normalizzato); G: gruppi (paragrafi, scritte ruotate, ritocchi)."""
from motore import norm
import re

# opzioni: w peso, s dimensione, x allargamento consentito, rot, col, al
DIZ = {
    # ---------------- mappa di volo
    "returnto": ("Rientro\nalla base", {"w": 600, "add": (0, 0, 30, 0), "inter": 0.95, "s": 31}),
    "base": ("", {}),
    "nohazards": ("nessun pericolo", {"x": 1.45, "dil": 3, "soglia": 32}),
    "missing": ("dispersi", {"w": 600}),
    "movephase": ("Movimento:", {"x": 1.2, "al": "l"}),
    "maynotmove": ("non si muove", {"x": 1.2, "al": "l"}),
    "navcheckphase": ("Navigazione:", {"x": 1.2, "al": "l"}),
    "makenavcheck": ("controllo navigazione", {"x": 1.2, "al": "l"}),
    "dam": ("DIGA", {"w": 700}),
    "targetacquisition": ("Acquisizione bersaglio", {"x": 1.05}),
    "usemohnestargetmap": ("(mappa della Möhne)", {}),
    "usesorpestargetmap": ("(mappa della Sorpe)", {}),
    "mohne": ("MÖHNE", {"w": 700}),
    "flightturn": ("Turni di volo", {"w": 600, "x": 1.2}),
    "2visibility": ("visibilità -2", {"x": 1.0}),
    "1visibility": ("visibilità -1", {"x": 1.0}),
    "fog": ("nebbia", {"x": 1.4}),
    "rtb": ("rientro", {"x": 1.5}),
    "sequenceofphases": ("Sequenza delle fasi:", {"x": 1.05}),
    "cleanup710": ("Pulizia [7.10]", {"w": 700}),
    "increasealertlevel": ("aumenta l'allerta?", {}),
    "loweractivitylevel": ("cala l'attività?", {}),
    "targetmap": ("Mappa del bersaglio", {"w": 700, "x": 1.25}),
    "scenario10": ("(scenario 10:", {}),
    "surprisecheck120": ("controllo sorpresa [12.0])", {}),
    "target": ("Acquisizione", {"w": 700, "x": 1.4}),
    "acquisition": ("del bersaglio", {"w": 700, "x": 1.3}),
    "moveintotargetf8": ("entra nella casella F8", {}),
    "acquisitionbox": ("di acquisizione", {}),
    "resolve": ("Risolvi", {"w": 700, "x": 1.2}),
    "hazards": ("i pericoli", {"w": 700, "x": 1.2}),
    "remove": ("togli i razzi", {"x": 1.6}),
    "verylights": ("Very", {}),
    "evade": ("Evita", {"w": 700}),
    "hostileflight": ("solo nelle zone", {}),
    "zonesonly": ("di volo ostili", {"x": 1.2}),
    "place": ("Piazza", {"w": 700, "x": 1.3}),
    "navigation": ("Controllo di", {"w": 700}),
    "check": ("navigazione", {"w": 700, "x": 1.5}),
    "move": ("Movimento", {"w": 700, "x": 1.6}),
    "towards": ("verso il bersaglio", {"x": 1.8}),
    "primarytarget": ("principale", {}),
    "wireless": ("Radio", {"w": 700}),
    "coordination": ("Coordinamento", {"w": 700}),
    "coordinatewave": ("Coordina l'onda", {}),
    "joinwave": ("Unisciti all'onda", {"x": 1.6}),
    "createwave": ("Crea un'onda", {}),
    "nohazardsinthiszone": (None, {}),
}
for i in range(1, 11):
    DIZ["turn%d" % i] = ("Turno %d" % i, {"x": 1.25})
DIZ["6uni"] = ("Turno 9", {"x": 1.25})
DIZ["turn10"] = ("Turno 10", {"x": 1.25})

DIZ_REG = {
    "tracce": {
        "damsdamage": ("capacità di danno", {"x": 1.25}),
        "capacity": ("della diga", {"x": 1.3}),
        "nodamage": ("nessun danno", {"x": 1.0}),
        "damage": ("danni", {}),
        "421step1": ("[4.2.1, passo 1]", {"x": 1.1}),
        "approachvectorcheck": ("Vettore d'avvicinamento", {"w": 700, "x": 1.1}),
        "attackturn": ("Turni d'attacco", {"w": 700, "x": 1.25}),
        "recon": ("Ricogn.", {"w": 600, "x": 1.3}),
        "level": ("livello", {"w": 600, "x": 1.35}),
        "sorpe": ("Sorpe", {"w": 700}),
        "orbever": ("o Bever", {"x": 1.0}),
        "other": ("altra", {"w": 700, "x": 1.2}),
        "dam": ("diga", {"w": 700}),
        "dieroll": ("dado", {"x": 1.0}),
        "eder": ("Eder", {"w": 700}),
        "fog": ("NEBB.", {"w": 700, "x": 1.15}),
        "key": ("legenda", {"x": 1.5, "al": "l"}),
        "speed": ("Velocità", {"x": 1.3, "al": "l"}),
        "altitude": ("Quota", {"x": 1.0, "al": "l"}),
        "chit": ("gettone", {"x": 1.5, "al": "l"}),
        "modifier": ("modificatore", {"x": 1.3, "al": "l"}),
        "1verylightflare": ("1 razzo Very", {"x": 1.0, "al": "l"}),
        "nullifesia": ("annulla 1 A", {"x": 1.0, "al": "l"}),
        "visibility": ("controllo", {"x": 1.0}),
        "check": ("visibilità", {"x": 1.25}),
        "attackturnsequenceofphases": ("Turno d'attacco: sequenza delle fasi", {"w": 700, "x": 1.0, "al": "l"}),
        "run": ("Corsa", {"x": 1.3}),
        "approach": ("Avvicinamento", {"x": 1.25}),
        "release": ("e sgancio", {"x": 1.1}),
        "circling": ("Cerchio", {}),
        "statuscheck": ("Controllo stato", {"x": 1.1}),
        "5rv1ifmohnebreached": ("5 rv (+1 se la Möhne è aperta)", {"x": 1.15, "al": "l"}),
    },
    "bersaglio": {
        "targetmaps": (None, {}),
        "circlingnearr": ("cerchio vicino, o", {"x": 1.2}),
        "sorpedam": ("DIGA DELLA SORPE", {"w": 700, "x": 1.9}),
        "ederdam": ("DIGA DELLA EDER", {"w": 700, "x": 1.9}),
        "mohnedam": ("DIGA DELLA MÖHNE", {"w": 700, "x": 1.7}),
        "far": ("lontana", {"w": 700, "x": 2.2}),
        "near": ("vicina", {"w": 700, "x": 1.6}),
        "close": ("ravvicinata", {"w": 700, "x": 2.2}),
        "escort": ("scorta", {"x": 1.1}),
        "flak": ("contraerea", {"x": 1.9, "s": 20}),
        "flakthen": ("contraerea, poi", {"x": 1.6}),
        "gunnery": ("mitragliatrici", {"x": 1.5}),
        "late": ("sgancio", {"x": 1.8}),
        "release": ("sgancio", {"w": 700, "x": 1.2}),
        "release?": ("tardivo?", {"x": 1.1}),
        "approach": ("avvicinamento", {"w": 700, "x": 1.7}),
        "released": ("Upkeep", {}),
        "upkeep": ("sganciati", {"x": 1.2}),
        "climb": ("risalita", {"w": 700, "x": 1.5}),
        "circlephase": ("Fase cerchio:", {"x": 1.2}),
        "mustmove": ("muove per forza", {"x": 1.0}),
        "circlingnear": ("cerchio vicino", {"w": 700, "x": 1.15}),
        "circlingfar": ("cerchio lontano", {"w": 700, "x": 1.15}),
        "circlingphase": ("Fase cerchio:", {"w": 600}),
        "maymoveto": ("può passare al", {"x": 1.45}),
        "circlingfaror": ("cerchio lontano, o", {"x": 1.2}),
        "circlingfarr": ("cerchio lontano, o", {"x": 1.2}),
        "circlingnearor": ("cerchio vicino, o", {"x": 1.2}),
        "toflightzone": ("alla zona di volo", {"x": 1.2}),
        "mayfireverylightflare": ("può sparare un razzo Very", {"x": 1.1}),
        "thedam": ("la diga", {"x": 1.1}),
        "dnnd": ("richiamo", {"x": 1.3}),
        "dnjind": ("richiamo", {"x": 1.3}),
        "dnind": ("richiamo", {"x": 1.3}),
        "alsousethismapforresolving": ("Si usa anche per gli attacchi", {"al": "r", "x": 1.0}),
        "attacksondiemellisterhenne": ("alle dighe Diemel, Lister, Henne", {"al": "r", "x": 1.0}),
        "andennepedams": ("ed Ennepe.", {"al": "r", "x": 1.0}),
        "alsousethismapfor": ("Si usa anche per gli", {"al": "r"}),
        "resolvingattackson": ("attacchi alla diga", {"al": "r"}),
        "beverdam": ("della Bever.", {"al": "r", "x": 1.5}),
        "aldislights": ("Luci Aldis:", {"al": "r", "w": 700}),
        "noeffectonoroff": ("nessun effetto (accese", {"al": "r", "x": 1.05}),
        "onthistargetmap": ("o spente) su questa mappa", {"al": "r", "x": 1.05}),
        "423424": ("[4.2.3 e 4.2.4].", {"al": "r"}),
        "michelskopf": ("Michelskopf", {"w": 700}),
        "2dice3orless": ("2 dadi: 3 o meno", {"x": 1.0}),
        "impact": ("impatto", {"x": 1.3}),
        "modifers": ("modificatori", {"x": 1.4}),
        "1perm": ("-1 per M", {}),
        "4213step4": ("[4.2.13, passo 4]", {"x": 1.0}),
        "1perm": ("-1 per segno M", {"x": 1.3}),
    },
}

def G(x0, y0, x1, y1, it, **o):
    o["r"] = (x0, y0, x1, y1)
    o["it"] = it
    return o

GRUPPI = [
    G(1800, 60, 2330, 200, "Mappa di volo", w=300, s=104),
    # zone
    G(1362, 250, 1422, 620, "Weser", w=700, rot=90, s=48, c=(1362, 300, 1422, 470)),
    G(1362, 700, 1422, 1100, "Ruhr", w=700, rot=90, s=48, c=(1362, 830, 1422, 960)),
    G(1362, 1250, 1422, 1660, "Costa olandese", w=700, rot=90, s=46, c=(1362, 1310, 1422, 1600)),
    G(1362, 1760, 1422, 2080, "Mare del Nord", w=700, rot=90, s=46, c=(1362, 1800, 1422, 2030)),
    G(1362, 2180, 1422, 2600, "Costa inglese", w=700, rot=90, s=46, c=(1362, 2225, 1422, 2540)),
    G(1362, 2800, 1422, 3110, "Inghilterra", w=700, rot=90, s=46, c=(1362, 2850, 1422, 3050)),
    # livello di ricognizione (la scritta verticale nella colonna)
    G(1524, 252, 1561, 520, "LIV. RICOGNIZIONE", w=700, rot=90, s=31, tutto=True, soglia=30),
    G(1524, 770, 1561, 1030, "LIV. RICOGNIZIONE", w=700, rot=90, s=31, tutto=True, soglia=30),
    G(1524, 1318, 1561, 1582, "LIV. RICOGNIZIONE", w=700, rot=90, s=31, tutto=True, soglia=30),
    # pericoli delle zone
    G(1900, 290, 2520, 600, "due pericoli\npiù\npericoli aggiuntivi:\n\n+1 per onda e aereo isolato\n+1 per razzo Very\n+ livello d'allerta", grande=True, c=(1960, 290, 2460, 600)),
    G(1880, 800, 2520, 1150, "due pericoli\npiù\npericoli aggiuntivi:\n\n+1 per onda e aereo isolato\n+1 per razzo Very\n+ livello d'allerta", grande=True, c=(1940, 800, 2460, 1150)),
    G(1990, 1420, 2620, 1750, "tre pericoli\npiù\npericoli aggiuntivi:\n\n+1 per onda e aereo isolato\n+1 per razzo Very\n+ livello d'allerta", grande=True, c=(2040, 1420, 2560, 1750)),
    G(1900, 2020, 2420, 2140, "due pericoli\n(niente evasione)", grande=True, c=(1930, 2020, 2420, 2140)),
    G(1850, 2450, 2380, 2770, "un pericolo\n(niente evasione)\n\n(scenario 10, turno 1:\n+ pericoli aggiuntivi\ndal controllo degli aerei\nnella preparazione del volo)", grande=True, c=(1880, 2450, 2350, 2770)),
    # allerta
    G(1800, 1690, 2050, 1760, "Livello d'allerta", w=700, s=58, rot=-10.8, c=(0, 0, 1, 1), poli=[[(1798, 1668), (2052, 1708), (2052, 1764), (1798, 1722)]], col="#ea5a3c", ombra=(40, 34, 30, 200)),
    G(1480, 1820, 2030, 1880, "Allerta +1 (al massimo un livello per turno): breccia, attacco del caccia notturno", s=26, rot=-10.2, a_capo=False,
      c=(0, 0, 1, 1), poli=[[(1476, 1792), (2032, 1892), (2030, 1916), (1476, 1820)]], modo="chiaro", soglia=150),
    G(1950, 1785, 2025, 1880, "ALLARME", w=700, s=23, rot=-62, c=(0, 0, 1, 1), poli=[[(1948, 1782), (2004, 1786), (2026, 1884), (1984, 1888), (1960, 1828)]], modo="rosso", soglia=80, col="#e0201c"),
    # limite di sortita e Inghilterra
    G(1440, 2740, 1830, 2930, "Limite di sortita: in ogni turno di volo decollano tanti aerei quanto il limite di sortita (contando tutte le squadre di terra, dedicate o no).", s=30, al="l", c=(1440, 2740, 1830, 2930)),
    # sequenza delle fasi del turno di volo
    G(2890, 2020, 3150, 2100, None, c=(2890, 2018, 3150, 2100), xy=(2898, 2020), righe=[("Turno di volo", 42, 700), ("Sequenza delle fasi:", 29, 400)], larg=250),
    G(2950, 2108, 3150, 2192, None, c=(2950, 2108, 3150, 2192), xy=(2958, 2108), righe=[("Pulizia [7.10]", 30, 700), ("aumenta l'allerta?", 22, 400), ("cala l'attività?", 22, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2200, 3112, 2290, None, c=(2950, 2200, 3150, 2290), xy=(2958, 2200), righe=[("Mappa del", 29, 700), ("bersaglio", 29, 700), ("(scen. 10: sorpresa [12.0])", 21, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2298, 3104, 2420, None, c=(2950, 2298, 3150, 2420), xy=(2958, 2300), righe=[("Acquisizione", 30, 700), ("del bersaglio", 30, 700), ("entra nella casella", 22, 400), ("di acquisizione", 22, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2430, 3104, 2545, None, c=(2950, 2430, 3104, 2545), xy=(2958, 2432), righe=[("Risolvi", 30, 700), ("i pericoli", 30, 700), ("togli i razzi Very", 22, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2555, 3104, 2665, None, c=(2950, 2555, 3104, 2665), xy=(2958, 2557), righe=[("Evita", 30, 700), ("i pericoli", 30, 700), ("solo nelle zone", 22, 400), ("di volo ostili", 22, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2668, 3104, 2738, None, c=(2950, 2668, 3104, 2738), xy=(2958, 2670), righe=[("Piazza", 30, 700), ("i pericoli", 30, 700)], larg=185, col="#f4f4f4"),
    G(2950, 2762, 3104, 2830, None, c=(2950, 2762, 3104, 2830), xy=(2958, 2764), righe=[("Controllo di", 30, 700), ("navigazione", 30, 700)], larg=185, col="#f4f4f4"),
    G(2950, 2870, 3104, 2958, None, c=(2950, 2870, 3104, 2958), xy=(2958, 2872), righe=[("Movimento", 30, 700), ("verso il bersaglio", 22, 400), ("principale", 22, 400)], larg=185, col="#f4f4f4"),
    G(2950, 2955, 3104, 2995, None, c=(2950, 2955, 3104, 2995), xy=(2958, 2957), righe=[("Radio", 30, 700)], larg=185, col="#f4f4f4"),
    G(2950, 3058, 3104, 3180, None, c=(2950, 3058, 3150, 3180), xy=(2958, 3060), righe=[("Coordinamento", 30, 700), ("Coordina l'onda", 22, 400), ("Unisciti a un'onda", 22, 400), ("Crea un'onda", 22, 400)], larg=185, col="#f4f4f4"),
    G(2000, 3030, 2240, 3100, "nessun pericolo\nin questa zona", s=27, c=(2040, 3030, 2190, 3100)),
]

# ---------------------------------------------------------------- blocchi ruotati delle mappe del bersaglio
import math, json as _json
_OCR = _json.load(open("/home/claude/traduzione/ocr.json"))
_TAG = [o["box"] for o in _OCR if norm(o["t"]) in ("a4", "a5", "a9", "a2", "a3")]

def _frame(q):
    a = math.atan2(q[1][1] - q[0][1], q[1][0] - q[0][0])
    return (math.cos(a), math.sin(a)), (-math.sin(a), math.cos(a)), math.degrees(a)

def blocco(p0, ang, wd, h_top, h_bot, testo, **o):
    a = math.radians(ang)
    u = (math.cos(a), math.sin(a)); n = (-math.sin(a), math.cos(a))
    P = lambda s, t: (p0[0] + u[0] * s + n[0] * t, p0[1] + u[1] * s + n[1] * t)
    poli = [P(0, -h_top), P(wd, -h_top), P(wd, h_bot), P(0, h_bot)]
    c = P(wd / 2, (h_bot - h_top) / 2)
    g = dict(r=(c[0] - 1, c[1] - 1, c[0] + 1, c[1] + 1), it=testo, c=(0, 0, 1, 1), dim=(wd, h_top + h_bot), rot=-ang,
             poli=[poli], a_capo=False)
    g.update(o)
    return g

def _fino_ai_tag(p0, u, n, lung):
    """Lunghezza utile della riga prima delle caselle A4/A5/A9 vicine."""
    m = lung
    for t in _TAG:
        d = (t[0][0] - p0[0], t[0][1] - p0[1])
        al = d[0] * u[0] + d[1] * u[1]; tr = d[0] * n[0] + d[1] * n[1]
        if -10 < al < lung + 40 and -60 < tr < 60:
            # angolo più vicino del tag lungo la riga
            als = [(p[0] - p0[0]) * u[0] + (p[1] - p0[1]) * u[1] for p in t]
            m = min(m, min(als) - 4)
    return m

def FG(gq, h_top=30, testo="contraerea, poi\nmitragliatrici", **o):
    u, n, ang = _frame(gq)
    lung = math.dist(gq[0], gq[1])
    wd = _fino_ai_tag(gq[0], u, n, lung + 6)
    h_bot = math.dist(gq[1], gq[2]) + 2
    return blocco(gq[0], ang, wd, h_top, h_bot, testo, **o)

def LR(lq, testo="sgancio\ntardivo?", **o):
    """late / release? : 'release?' sta sotto e parte circa 42 px prima."""
    u, n, ang = _frame(lq)
    lung = math.dist(lq[0], lq[1])
    p0 = (lq[0][0] - u[0] * 44, lq[0][1] - u[1] * 44)
    wd = _fino_ai_tag(p0, u, n, lung + 44 + 4)
    h = math.dist(lq[1], lq[2])
    return blocco(p0, ang, wd, 2, h + 26, testo, **o)

def Q(quad, it, x=1.0, **op):
    """Scritta ruotata: cancella il quadrilatero originale, scrive su una striscia lunga x volte."""
    u, n, ang = _frame(quad)
    lung = math.dist(quad[0], quad[1]); h = math.dist(quad[1], quad[2])
    g = blocco(quad[0], ang, lung, 0, h, it, **op)
    wd = lung * x
    c = (quad[0][0] + u[0] * lung / 2 + n[0] * h / 2, quad[0][1] + u[1] * lung / 2 + n[1] * h / 2)
    g["r"] = (c[0] - 1, c[1] - 1, c[0] + 1, c[1] + 1)
    g["dim"] = (wd, h)
    return g

GRUPPI += [
    # Möhne
    G(3480, 2228, 3930, 2302, "DIGA DELLA MÖHNE", w=700, s=56, tutto=[(3500, 2226, 3910, 2302)], c=(0, 0, 1, 1), col="#ffffff"),
    G(3222, 2366, 3322, 2428, "contraerea, poi\nmitragliatrici", s=19, inter=1.0, c=(3222, 2366, 3322, 2428), col="#1a1a1c", a_capo=False),
    FG([[3604, 2766], [3695, 2811], [3681, 2839], [3590, 2794]], col="#1a1a1c"),
    FG([[3758, 2874], [3847, 2917], [3836, 2942], [3746, 2899]], col="#1a1a1c"),
    LR([[3635, 2829], [3672, 2844], [3663, 2866], [3626, 2851]], col="#1a1a1c"),
    # Eder
    G(3420, 1342, 3518, 1402, "contraerea, poi\nmitragliatrici", s=19, inter=1.0, c=(3420, 1342, 3518, 1402), col="#1a1a1c", a_capo=False),
    FG([[3659, 1682], [3741, 1738], [3723, 1764], [3641, 1709]], col="#1a1a1c"),
    FG([[3798, 1807], [3881, 1863], [3862, 1891], [3779, 1835]], col="#1a1a1c"),
    LR([[3683, 1751], [3716, 1772], [3703, 1792], [3670, 1771]], col="#1a1a1c"),
    # Sorpe
    G(3968, 676, 4066, 732, "contraerea, poi\nmitragliatrici", s=19, inter=1.0, c=(3968, 676, 4066, 732), col="#1a1a1c", a_capo=False),
    FG([[3576, 387], [3667, 431], [3656, 455], [3564, 411]], col="#1a1a1c"),
    LR([[3603, 460], [3634, 474], [3626, 494], [3594, 479]], col="#1a1a1c"),
]

GRUPPI += [
    # Sorpe: scritte vicine, più piccole
    Q([[3522, 200], [3584, 245], [3558, 281], [3497, 237]], "lontana", x=1.9, w=700, s=30),
    Q([[3648, 271], [3753, 330], [3731, 371], [3625, 312]], "ravvicinata", x=1.6, w=700, s=34),
    G(3985, 258, 4224, 486, "Si usa anche per gli attacchi\nalla diga della Bever.\nLuci Aldis: nessun effetto\n(accese o spente) su questa\nmappa [4.2.3 e 4.2.4].", s=23, al="r", a_capo=False, c=(3990, 262, 4226, 484), inter=1.12),
    blocco((3240, 672), -90, 60, 0, 26, "corsa", s=24, w=600),
    # corse e richiami mancati dall'OCR
    blocco((4214, 2684), 90, 62, 0, 27, "corsa", s=24, w=600),
    blocco((3799, 2666), 10, 72, 0, 27, "richiamo", s=24, w=600),
    blocco((4214, 1656), 90, 62, 0, 27, "corsa", s=24, w=600),
    blocco((3724, 1300), -21, 116, 0, 34, "obbligatorio", s=30, w=700),
    blocco((3722, 1636), 26, 80, 4, 32, "scorta", s=22, soglia=30),
]

_DIGHE_T = [("LISTER", 4344, 137, 4617, 170, "4 rv"), ("DIEMEL", 4342, 407, 4632, 437, "4 rv"), ("EDER", 4343, 667, 4598, 700, "9 rv"),
    ("HENNE", 4342, 934, 4619, 965, "2 rv"), ("SORPE", 4341, 1193, 4575, 1225, None), ("BEVER", 4341, 1455, 4622, 1488, "3 rv"),
    ("ENNEPE", 4340, 1716, 4634, 1751, "3 rv"), ("MÖHNE", 4339, 1971, 4612, 2012, "8 rv")]
for n, x0, y0, x1, y1, rv in _DIGHE_T:
    GRUPPI.append(G(x0, y0 - 4, x1 + 6, y1 + 6, None, c=(x0, y0 - 4, x1 + 6 if rv else 4575, y1 + 6), xy=(x0, y0 - 4),
                    righe=[("DIGA DELLA " + n + ("  " + rv if rv else ""), 36, 700)], larg=(4640 - x0) if n == "LISTER" else 420, col="#ffffff"))
GRUPPI.append(G(4690, 1190, 5010, 1232, "5 rv (+1 se la Möhne è aperta)", s=24, al="l", c=(4576, 1190, 4845, 1232), col="#ffffff"))

# celle del livello dell'acqua nelle tracce delle dighe: fondo pieno, numero scuro e parola bianca
_CELLE = []
for _o in _OCR:
    _k = norm(_o["t"])
    _m = re.fullmatch(r"(\d+)(rising|high|full)", _k)
    if _m and _o["box"][0][0] > 4600:
        xs = [p[0] for p in _o["box"]]; ys = [p[1] for p in _o["box"]]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        # la cella: larghezza fissa a partire dall'inizio del numero
        cx0 = x0 - 6; cx1 = {"rising": x0 + 118, "high": x0 + 101, "full": x0 + 90}[_m.group(2)]
        parola = {"rising": "in salita", "high": "alta", "full": "piena"}[_m.group(2)]
        GRUPPI.append(dict(r=(cx0 + 2, y0 - 2, cx1, y1 + 2), c=(x0 - 2, y0 - 2, x1 + 2, y1 + 2), fondo=(cx0 + 4, y0 - 3, cx1 - 2, y1 + 3), it=None,
                           segmenti=[(_m.group(1) + " ", 700, "#41464b"), (parola, 700, "#ffffff")], s=int((y1 - y0) * 0.95)))

# ================================================================ lavagna di pianificazione
DIZ_REG["lavagna"] = {
    "designmapartby": ("progetto e grafica di", {"x": 1.0, "al": "l"}),
    "may16171943": ("16-17 maggio 1943", {"x": 1.15, "al": "l"}),
    "missionplanningblotter": ("LAVAGNA DI PIANIFICAZIONE", {"w": 600, "x": 1.05}),
    "planningturn": ("Turno di pianificazione", {"w": 700, "x": 1.22, "al": "l"}),
    "turn1": ("Turno 1", {"w": 700, "x": 1.25}), "turn2": ("Turno 2", {"w": 700, "x": 1.25}),
    "turn3": ("Turno 3", {"w": 700, "x": 1.25}), "turn4": ("Turno 4", {"w": 700, "x": 1.25}),
    "moon": ("luna", {"x": 1.2}), "nomoon": ("senza luna", {"x": 1.15}),
    "marchapril": ("marzo/aprile", {"x": 1.0}), "april": ("aprile", {"x": 1.3}), "may": ("maggio", {"x": 1.5}),
    "securityrisklevellow": ("Rischio per la sicurezza = BASSO", {"x": 1.35}),
    "medium": ("MEDIO", {"w": 700, "x": 1.1}),
    "60rp": ("60 RP", {}), "atstart": ("all'inizio", {"x": 1.4}),
    "reguisitions": ("Requisizioni", {"w": 700, "x": 1.0, "al": "l"}),
    "requisitions": ("REQUISIZIONI", {"w": 700, "x": 1.0}),
    "groundcrew": ("SQUADRE DI TERRA", {"w": 600, "x": 1.25}),
    "maybeusedimmediately": ("Si usano subito.", {"x": 1.0}),
    "aircrew": ("EQUIPAGGI", {"w": 600, "x": 1.3}),
    "aircraftordnance": ("AEREI E ORDIGNI", {"w": 600, "x": 1.0}),
    "lancaster": (None, {}), "upkeep": (None, {}),
    "rpcost": ("costo in RP", {"x": 1.5, "al": "l"}),
    "security": ("Sicurezza", {"w": 700, "x": 1.05, "al": "l"}),
    "donotdedicategroundcrew": ("non si dedicano squadre", {"x": 1.05, "al": "l"}),
    "training": (None, {}),
    "dieroll": ("dado", {"x": 1.0}),
    "orless": ("o meno", {"x": 1.3}),
    "green": ("reclute", {"w": 700, "x": 1.6, "al": "r", "s": 30}),
    "seasoned": ("esperti", {"w": 700, "x": 1.2, "al": "r", "s": 30}),
    "veteran": ("veterani", {"w": 700, "x": 1.3, "al": "r", "s": 30}),
    "key1032": ("legenda [10.3.2]", {"x": 1.4, "al": "l"}),
    "levelsgained": ("= livelli guadagnati", {"x": 1.1, "al": "l", "s": 24}),
    "rrestedflipmarker": ("R = a riposo (gira il segnalino)", {"x": 1.15, "al": "l"}),
    "damagedaircraft": ("= aereo danneggiato", {"x": 1.0, "al": "l"}),
    "flip1undamagedlancaster": ("(gira un Lancaster integro)", {"x": 1.0, "al": "l"}),
    "rollagainevendodd": ("ritira: PARI = d, DISPARI = c", {"x": 1.1, "al": "l"}),
    "eelitecrewman": ("E = specialista", {"x": 1.0, "al": "l"}),
    "draw1randomly": ("(uno a caso)", {"x": 1.0, "al": "l"}),
    "crash": ("= schianto", {"x": 1.2, "al": "l"}),
    "destroy1undamagedlancasterandrolldie": ("(distruggi un Lancaster integro e tira un dado:", {"x": 1.0, "al": "l"}),
    "evendraw1elitecrewman": ("PARI = pesca uno specialista;", {"x": 1.05, "al": "l"}),
    "oddremoveaircrew": ("DISPARI = togli un equipaggio)", {"x": 1.2, "al": "l"}),
    "airface": (None, {}),
    "navigation": ("NAVIGAZIONE", {"w": 600, "x": 1.15, "al": "l", "ombra": (50, 34, 24, 255)}),
    "navskill": ("Navigazione", {"x": 1.0, "al": "l"}),
    "altitudespeed": ("QUOTA E VELOCITÀ", {"w": 600, "x": 1.05, "al": "l", "ombra": (50, 34, 24, 255)}),
    "bombaimingrelease": ("PUNTAMENTO E SGANCIO", {"w": 600, "x": 1.0, "al": "l", "ombra": (50, 34, 24, 255)}),
    "1chit": ("1 gettone", {"x": 1.6}), "2chits": ("2 gettoni", {"x": 1.3}),
    "3chits": ("3 gettoni", {"x": 1.3}), "4chits": ("4 gettoni", {"x": 1.3}),
    "wallisbonus": ("BONUS WALLIS", {"w": 700, "x": 1.1}),
    "modifications": (None, {}),
    "dedicategroundcrewandrp": ("Dedica squadre di terra e RP.", {"x": 1.05, "al": "l"}),
    "automaticsuccess": ("successo automatico", {"x": 1.15}),
    "repair": ("RIPARA I", {"w": 700, "x": 1.2}),
    "lancasters": ("LANCASTER", {"x": 1.1}),
    "radio": ("RADIO", {"w": 700, "x": 1.2}),
    "altimeter": ("ALTIMETRO", {"w": 700, "x": 1.1}),
    "cockpit": ("CABINA", {"w": 700, "x": 1.1}),
    "placededicated": ("squadre dedicate", {"x": 1.1}),
    "here": ("qui", {}), "herep2": ("qui", {"x": 0.55, "al": "l"}),
    "vhf": ("VHF?", {}), "aldislights": ("Luci Aldis?", {"x": 1.0}), "dannbombsight": ("Mirino Dann?", {"x": 1.0}),
    "recon105": ("Ricognizione [10.5]", {"w": 700, "x": 1.0, "al": "l"}),
    "zone": ("ZONA", {"w": 700, "x": 1.2, "al": "r"}),
    "targetmap": ("DIGA", {"w": 700, "x": 1.0, "al": "r"}),
    "increasereconlevelby1": ("ricognizione +1", {"x": 1.0, "al": "l"}),
    "donotdedicategrouncrew": ("non si dedicano squadre", {"x": 1.0, "al": "l"}),
    "flightprep": ("Preparazione del volo", {"w": 700, "x": 1.0, "al": "l"}),
    "toconcludetheplanningsegmentperformthefollowingsteps": ("per chiudere la pianificazione, esegui questi passi:", {"x": 1.05, "al": "l"}),
    "aircraftcheck111": ("CONTROLLO DEGLI AEREI [11.1]", {"w": 700, "x": 1.25, "al": "l", "col": "#2a2420"}),
    "ordnancecheck112": ("CONTROLLO DEGLI UPKEEP [11.2]", {"w": 700, "x": 1.15, "al": "l", "col": "#2a2420"}),
    "aircrewcheck113": ("CONTROLLO DEGLI EQUIPAGGI [11.3]", {"w": 700, "x": 1.35, "al": "l", "col": "#2a2420"}),
    "briefing114": ("BRIEFING [11.4]", {"w": 700, "x": 1.0, "al": "l"}),
    "sortie115": ("SORTITA [11.5]", {"w": 700, "x": 1.0, "al": "l", "col": "#2a2420"}),
    "sortie115x": ("", {}),
    "step": ("Passo 1", {"x": 1.6, "al": "l"}), "step2": ("Passo 2", {"x": 1.3, "al": "l"}),
    "step3": ("Passo 3", {"x": 1.3, "al": "l"}), "step4": ("Passo 4", {"x": 1.3, "al": "l"}), "step5": ("Passo 5", {"x": 1.3, "al": "l"}),
    "somelancastersmaynotbereadytofly": ("Qualche Lancaster potrebbe non essere pronto.", {"x": 1.05}),
    "someupkeepminesmightnotbeinstalled": ("Qualche Upkeep potrebbe non essere montato.", {"x": 1.05}),
    "someaircrewmaybeunfittofly": ("Qualche equipaggio potrebbe non essere idoneo.", {"x": 1.15}),
    "sumof2dice24": ("2 dadi:  2-4", {"x": 1.0}),
    "5aircraft": ("5 aerei", {}), "3aircraft": ("3 aerei", {}), "2aircraft": ("2 aerei", {}), "1aircraft": ("1 aereo", {}),
    "4upkeep": ("4 Upkeep", {}), "3upkeep": ("3 Upkeep", {}), "2upkeep": ("2 Upkeep", {}), "1upkeep": ("1 Upkeep", {}),
    "4aircrew": ("4 equipaggi", {"x": 1.05}), "3aircrew": ("3 equipaggi", {"x": 1.05}), "2aircrew": ("2 equipaggi", {"x": 1.05}), "1aircrew": ("1 equipaggio", {"x": 1.05}),
    "grounded": ("a terra", {}), "allmay": ("tutti", {"x": 1.0}), "fly": ("volano", {"x": 2.6}),
    "2hazardsenglishcoast": ("+2 pericoli costa inglese", {"x": 1.0}),
    "1hazardenglishcoast": ("+1 pericolo costa inglese", {"x": 1.0}),
    "launch": ("DECOLLO", {"w": 700, "x": 1.1}),
    "mage": (None, {}),
}

GRUPPI += [
    G(112, 284, 668, 357, "Puoi chiudere la pianificazione alla fine di qualsiasi turno: allora esegui la sequenza di preparazione del volo in fondo a questa lavagna.", s=23, al="l", va="t", c=(110, 284, 668, 357)),
    G(116, 364, 770, 392, "Su questa traccia segna RP, richieste di RP, addestramenti extra e livello di rischio per la sicurezza:", s=20, al="l", a_capo=False, c=(116, 364, 770, 392)),
    G(345, 560, 1050, 652, "Il turno 1 comincia con 60 RP; nel turno 2 ne arrivano altri 60. In qualsiasi turno, anche nel 1 e nel 2, puoi chiedere (e ricevere) altri RP tirando un dado: PARI = 30 RP, DISPARI = 20 RP. (Puoi fare più richieste nello stesso turno.)", s=23, al="l", va="t", c=(345, 562, 1040, 652)),
    G(1088, 598, 1224, 690, "serve una squadra di terra dedicata per requisire aerei e ordigni", s=20, c=(1090, 598, 1222, 712), m=2),
    G(440, 696, 762, 764, "Solo nel turno 1 (ogni 6 equipaggi requisiti si pesca uno specialista).", s=21, c=(440, 696, 762, 764)),
    G(796, 700, 1052, 770, "In ogni turno, fino al limite di maneggio delle squadre dedicate.", s=21, c=(796, 700, 1052, 770)),
    G(180, 924, 400, 1000, "Puoi girare un segnalino, poi giocarne uno.", s=23, al="r", c=(180, 924, 400, 1000)),
    G(866, 900, 1228, 948, "TRASFERIRE IL 57° SQN: 15 RP e una squadra di terra (tolta per sempre).", s=20, al="l", c=(866, 900, 1228, 948)),
    G(866, 958, 1228, 1006, "QUARANTENA: niente più richieste di RP né squadre di terra; niente bonus Wallis.", s=20, al="l", c=(866, 958, 1228, 1006)),
    G(112, 1036, 340, 1092, "Addestramento", s=46, w=700, al="l", c=(112, 1036, 288, 1092), col="#b0281e"),
    G(1084, 1046, 1226, 1094, "ADDESTRAMENTO", s=20, w=700, c=(1084, 1046, 1226, 1094)),
    G(345, 1044, 1060, 1096, "In ogni turno aumenta il livello di due specialità (NAVIGAZIONE, QUOTA E VELOCITÀ, PUNTAMENTO E SGANCIO). Un dado per ogni tipo di equipaggio (6 tiri in tutto, senza costo in RP).", s=21, al="l", c=(290, 1044, 1060, 1096)),
    G(1084, 1096, 1226, 1166, "-1 se nessuna squadra è dedicata", s=21, c=(1084, 1096, 1226, 1166)),
    G(155, 1318, 760, 1420, None, c=(155, 1318, 760, 1420), xy=(158, 1318), righe=[("Modificatori: -1 se gli equipaggi sono almeno il doppio degli aerei integri", 22, 400), ("+1 bonus di ricognizione (navigazione)", 21, 400), ("+1 luci Aldis (quota e velocità)", 21, 400), ("+1 mirino Dann (puntamento e sgancio)", 21, 400)], larg=600, inter=1.12),
    G(150, 1424, 1225, 1480, "ADDESTRAMENTO EXTRA: con 5 RP aumenti il livello di una terza specialità (o della stessa due volte), poi peschi a caso uno specialista.", s=24, al="l", c=(150, 1424, 1225, 1480)),
    G(426, 1490, 1000, 1540, "(+1 al dado se tutte e 3 le zone ostili hanno ricognizione 1 o più)", s=21, al="l", c=(426, 1490, 1000, 1540)),
    G(508, 1704, 990, 1740, "(+1 al dado con le luci Aldis)", s=22, al="l", c=(508, 1704, 990, 1740)),
    G(672, 1892, 1035, 1940, "(+1 al dado con il mirino Dann)", s=22, al="l", c=(672, 1892, 1035, 1940)),
    G(995, 1556, 1220, 1872, None, c=(995, 1556, 1220, 1872), xy=(1002, 1558), righe=[("Ministero della", 25, 700, "#3a2c22"), ("produzione aeronautica", 25, 700, "#3a2c22"),
        ("Ottieni il bonus Wallis", 21, 400), ("quando i 3 tipi di", 21, 400), ("equipaggio sommano", 21, 400), ("12 o più livelli di quota", 21, 400), ("e velocità. [10.3.3]", 21, 400),
        ("", 10, 400), ("EFFETTO: invece di tirare", 20, 400, "#ffffff"), ("pari o dispari [4.4.4], si", 20, 400, "#ffffff"), ("applica il danno più alto.", 20, 400, "#ffffff"),
        ("", 8, 400), ("La quarantena annulla", 20, 400, "#ffffff"), ("il bonus Wallis [10.2].", 20, 400, "#ffffff")], larg=212, col="#7a3c22"),
    G(620, 2072, 1090, 2160, None, c=(500, 2072, 1215, 2160), xy=(560, 2072), righe=[("punti erk = dadi, +1 dado per ogni RP speso", 27, 400, "#ffffff"), ("le modifiche si completano con i 6", 22, 400, "#ffffff"),
        ("puoi ritirare i dadi erk girando la squadra sul lato affaticato (per sempre) [10.4.3]", 18, 400, "#ffffff")], larg=650),
    G(166, 2228, 296, 2352, "1 RP per riparare ogni bombardiere danneggiato, fino al limite erk delle squadre dedicate", s=18, c=(166, 2228, 296, 2352)),
    G(306, 2266, 446, 2312, "squadre dedicate", s=20, c=(306, 2266, 446, 2312)),
    G(550, 2266, 690, 2312, "squadre dedicate", s=20, c=(550, 2266, 690, 2312)),
    G(796, 2266, 936, 2312, "squadre dedicate", s=20, c=(796, 2266, 936, 2312)),
    G(1040, 2266, 1180, 2312, "squadre dedicate", s=20, c=(1040, 2266, 1180, 2312)),
    G(600, 2416, 1150, 2452, "5 RP per zona di volo ostile (una volta per zona per turno)", s=24, al="l", c=(600, 2416, 1150, 2452)),
    G(604, 2454, 992, 2490, "1 RP per diga (una volta per diga per turno)", s=24, al="l", c=(604, 2454, 992, 2490)),
    G(884, 2655, 1035, 2772, None, c=(884, 2655, 1035, 2772), xy=(890, 2658), righe=[("Per ogni squadra", 19, 400, "#2b2420"), ("dedicata:", 19, 700, "#2b2420"), ("+1 affaticata", 21, 700, "#2b2420"), ("+2 fresca", 21, 700, "#2b2420")], larg=140),
    G(884, 2776, 1035, 2866, None, c=(884, 2776, 1035, 2866), xy=(890, 2780), righe=[("Spia:", 21, 700, "#2b2420"), ("-1 se in gioco", 21, 700, "#2b2420")], larg=140),
    G(876, 2954, 1045, 3082, None, c=(876, 2954, 1045, 3082), xy=(884, 2958), righe=[("Modificatori:", 19, 400, "#2b2420"), ("-1 per ogni turno", 19, 700, "#2b2420"), ("di addestramento extra;", 18, 400, "#2b2420"), ("+1 per ogni segnalino", 19, 700, "#2b2420"), ("di riposo", 18, 400, "#2b2420")], larg=156),
    G(1072, 2584, 1222, 2742, None, c=(1072, 2584, 1222, 2742), xy=(1080, 2592), righe=[("CONTROLLO", 22, 700, "#6a3a24"), ("AEREI", 22, 700, "#6a3a24"), ("squadre dedicate", 18, 400, "#6a3a24"), ("qui; per ritirare", 18, 400, "#6a3a24"), ("girale sul lato", 18, 400, "#6a3a24"), ("affaticato [11.0]", 18, 400, "#6a3a24")], larg=140),
    G(1072, 2760, 1222, 2910, None, c=(1072, 2760, 1222, 2910), xy=(1080, 2766), righe=[("CONTROLLO", 22, 700, "#6a3a24"), ("UPKEEP", 22, 700, "#6a3a24"), ("squadre dedicate", 18, 400, "#6a3a24"), ("qui; per ritirare", 18, 400, "#6a3a24"), ("girale sul lato", 18, 400, "#6a3a24"), ("affaticato [11.0]", 18, 400, "#6a3a24")], larg=140),
    G(322, 3100, 1150, 3132, "Ultima ricognizione delle dighe (NON delle zone di volo); poi il controllo del rischio per la sicurezza.", s=22, al="l", a_capo=False, c=(322, 3100, 1150, 3132)),
    G(318, 3152, 1200, 3212, "Assegna equipaggi, specialisti e Upkeep agli aerei, forma le onde e assegna i bersagli. Metti onde e aerei isolati nella zona Inghilterra della mappa di volo e comincia il primo turno di volo.", s=22, al="l", c=(318, 3152, 1200, 3212)),
]

GRUPPI += [
    G(108, 752, 208, 784, "Squadra", s=19, w=700, c=(108, 752, 208, 784), col="#8a2a1c"),
    G(216, 752, 316, 784, "Squadra", s=19, w=700, c=(216, 752, 316, 784), col="#8a2a1c"),
    G(326, 752, 426, 784, "Squadra", s=19, w=700, c=(326, 752, 426, 784), col="#8a2a1c"),
    G(480, 782, 540, 824, "Reclute", s=17, w=700, c=(480, 782, 540, 824)),
    G(566, 782, 632, 824, "Esperti", s=17, w=700, c=(566, 782, 632, 824)),
    G(652, 782, 720, 824, "Veterani", s=17, w=700, c=(652, 782, 720, 824)),
    G(440, 925, 500, 985, "Voce su\nTirpitz", s=21, w=700, rot=45, dim=(104, 50), poli=[[(432, 914), (510, 914), (510, 994), (432, 994)]], c=(0, 0, 1, 1), col="#5a3a22", a_capo=False, inter=0.95),
    G(610, 925, 670, 985, "in più\nPolizia", s=22, w=700, rot=45, dim=(104, 52), poli=[[(598, 914), (680, 914), (680, 964), (652, 964), (652, 994), (598, 994)]], c=(0, 0, 1, 1), col="#5a3a22", a_capo=False, inter=0.95),
    G(775, 925, 835, 985, "trasferire\n57° Sqn", s=21, w=700, rot=45, dim=(104, 52), poli=[[(764, 914), (846, 914), (846, 964), (814, 964), (814, 994), (764, 994)]], c=(0, 0, 1, 1), col="#5a3a22", a_capo=False, inter=0.95),
]

GRUPPI += [
    G(112, 2066, 400, 2120, "Modifiche", s=48, w=700, al="l", c=(112, 2066, 390, 2120), col="#b0281e"),
    G(306, 2244, 446, 2270, "modifica", s=19, tutto=[(310, 2244, 442, 2270)], c=(0, 0, 1, 1), col="#6a3a24"),
    G(550, 2244, 690, 2270, "modifica", s=19, c=(550, 2244, 690, 2270), col="#6a3a24"),
    G(796, 2244, 936, 2270, "modifica", s=19, c=(796, 2244, 936, 2270), col="#6a3a24"),
    G(1040, 2244, 1180, 2270, "modifica", s=19, c=(1040, 2244, 1180, 2270), col="#6a3a24"),
]
