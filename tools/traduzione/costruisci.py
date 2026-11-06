"""Costruisce la tavola tradotta: python3 costruisci.py [regione...]"""
import sys, json
import numpy as np, cv2
from PIL import Image, ImageDraw
import motore as M
import voci

REGIONI = {
    "lavagna": (60, 20, 1345, 3290),
    "volo": (1340, 20, 3200, 3240),
    "bersaglio": (3200, 20, 4290, 3240),
    "tracce": (4280, 20, 5100, 3240),
}

def grande(pil, r, testo, col):
    """Scritte dei pericoli nello stile della mappa: titolo grande, poi righe più piccole."""
    righe = testo.split("\n")
    stili = []
    for i, t in enumerate(righe):
        if i == 0:
            stili.append((66, 700))
        elif t in ("più",) or t.startswith("pericoli aggiuntivi") or t.startswith("(niente"):
            stili.append((40, 700))
        elif t == "":
            stili.append((16, 400))
        else:
            stili.append((34, 600))
    alt = sum(s * 1.06 for s, _ in stili)
    x0, y0, x1, y1 = r
    y = (y0 + y1) / 2 - alt / 2
    d = ImageDraw.Draw(pil)
    for t, (s, w) in zip(righe, stili):
        f = M.font("sans", s, w)
        lw = f.getlength(t)
        x = (x0 + x1) / 2 - lw / 2
        for dx, dy in ((2, 2), (-1, 1), (1, -1)):
            d.text((x + dx, y + dy), t, font=f, fill=(30, 30, 34, 160))
        d.text((x, y), t, font=f, fill=col + (255,))
        y += s * 1.06

def dentro_poli(o, pp):
    x0, y0, x1, y1 = M.bbox(o)
    c = ((x0 + x1) / 2, (y0 + y1) / 2)
    return cv2.pointPolygonTest(np.array(pp, np.float32), c, False) >= 0

def costruisci(nomi):
    board = cv2.imread("board.png")
    ocr = json.load(open("ocr.json"))
    voci_righe = []
    gruppi = [g for g in voci.GRUPPI]
    rect_gruppi = [g.get("c", g["r"]) for g in gruppi]
    for g in gruppi:
        if isinstance(g.get("tutto"), list):
            rect_gruppi += g["tutto"]
    poli_gruppi = [pp for g in gruppi for pp in g.get("poli", [])]
    zone = [REGIONI[n] for n in nomi]
    mancanti = []
    for o in ocr:
        x0, y0, x1, y1 = M.bbox(o)
        if not any(M.dentro(o, z) for z in zone):
            continue
        if any(M.dentro(o, rg) for rg in rect_gruppi):
            continue
        if any(dentro_poli(o, pp) for pp in poli_gruppi):
            continue
        k = M.norm(o["t"])
        reg = [n for n in nomi if M.dentro(o, REGIONI[n])][0]
        diz = dict(voci.DIZ); diz.update(voci.DIZ_REG.get(reg, {}))
        if k not in diz:
            if not k.isdigit() and len(k) > 1:
                mancanti.append(f"{x0},{y0},{x1},{y1}\t{o['t']}")
            continue
        it, op = diz[k]
        w, h = x1 - x0, y1 - y0
        if it is None:
            continue
        b = o["box"]
        import math
        e01 = math.dist(b[0], b[1]); e12 = math.dist(b[1], b[2])
        ang = math.degrees(math.atan2(b[1][1] - b[0][1], b[1][0] - b[0][0]))
        storto = abs(ang) > 4 and e01 > e12 and not op.get("dritto")
        verticale = e12 > e01 * 1.6 and len(k) > 2
        if it == "":
            v = {"r": (x0, y0, x1, y1), "c": (x0 - 1, y0 - 1, x1 + 1, y1 + 1), "it": None}
            if storto or verticale:
                v["c"] = (0, 0, 1, 1); v["poli"] = [b]
            voci_righe.append(v)
            continue
        v = dict(op)
        allarga = op.get("x", 1.0)
        if verticale and op.get("rot") is None:
            # testo che si legge dal basso verso l'alto (o storto quasi verticale)
            dx, dy = b[1][0] - b[2][0], b[1][1] - b[2][1]
            a = math.degrees(math.atan2(dy, dx))
            v["rot"] = -a
            cx = sum(p[0] for p in b) / 4; cy = sum(p[1] for p in b) / 4
            v["dim"] = (e12 * allarga, e01)
            if "add" in op:
                v["dim"] = (e12 * allarga, e01 + op["add"][2])
                cx += op["add"][2] / 2
            v["r"] = (cx - 1, cy - 1, cx + 1, cy + 1)
            v.setdefault("s", int(e01 * 0.95))
            v["c"] = (0, 0, 1, 1); v["poli"] = [b]
        elif storto:
            v["rot"] = -ang
            cx = sum(p[0] for p in b) / 4; cy = sum(p[1] for p in b) / 4
            v["dim"] = (e01 * allarga, e12)
            v["r"] = (cx - 1, cy - 1, cx + 1, cy + 1)
            v.setdefault("s", int(e12 * 0.98))
            v["c"] = (0, 0, 1, 1); v["poli"] = [b]
        elif h > 2.0 * w and len(k) > 2:
            cy = (y0 + y1) / 2
            r = (x0, cy - h * allarga / 2, x1, cy + h * allarga / 2)
            v.setdefault("rot", 90)
            v.setdefault("s", int(w * 0.95))
            if "add" in op:
                a = op["add"]; r = (r[0] + a[0], r[1] + a[1], r[2] + a[2], r[3] + a[3])
            v["r"] = r
            v["c"] = (x0 - 1, y0 - 1, x1 + 1, y1 + 1)
        else:
            cx = (x0 + x1) / 2
            al = op.get("al", "c")
            if al == "l":
                r = (x0, y0, x0 + w * allarga, y1)
            elif al == "r":
                r = (x1 - w * allarga, y0, x1, y1)
            else:
                r = (cx - w * allarga / 2, y0, cx + w * allarga / 2, y1)
            v.setdefault("s", int(h * 0.98))
            if "add" in op:
                a = op["add"]; r = (r[0] + a[0], r[1] + a[1], r[2] + a[2], r[3] + a[3])
            v["r"] = r
            v["c"] = (x0 - 1, y0 - 1, x1 + 1, y1 + 1)
        v["it"] = it
        v["a_capo"] = "\n" in it
        voci_righe.append(v)
    tutte = voci_righe + gruppi
    dbg = []
    # i gruppi "grande" si scrivono a parte
    norm_voci = []
    speciali = []
    for v in tutte:
        if v.get("grande"):
            vv = dict(v); it = vv.pop("it"); speciali.append((v["r"], it)); vv["it"] = None
            norm_voci.append(vv)
        else:
            norm_voci.append(v)
    pil = M.traduci(board, ocr, norm_voci, debug=dbg)
    # colore dei titoli grandi: dal pixel originale
    for r, it in speciali:
        c = v.get("c", r)
        cr = [g for g in gruppi if g["r"] == r][0].get("c", r)
        m, col, bg = M.maschera(board, cr, 42)
        grande(pil, r, it, col or (150, 210, 230))
    open("mancanti.txt", "w").write("\n".join(mancanti))
    print("righe tradotte:", len(voci_righe), "gruppi:", len(gruppi), "non tradotte:", len(mancanti))
    for x in dbg:
        print(" ", x)
    return pil

if __name__ == "__main__":
    nomi = sys.argv[1:] or list(REGIONI)
    pil = costruisci(nomi)
    pil.convert("RGB").save("tavola_it.png")
