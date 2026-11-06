"""Motore di traduzione delle immagini: cancella le scritte inglesi (maschera dei pixel del testo + inpainting)
e riscrive l'italiano con Source Sans 3 (variabile) o altri font, centrato nell'area originale."""
import json, re, math
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

FONT = {
    "sans": "/home/claude/fonts/SourceSans3%5Bwght%5D.ttf",
    "josefin": "/home/claude/fonts/JosefinSans%5Bwght%5D.ttf",
    "serif": "/home/claude/fonts/CrimsonPro%5Bwght%5D.ttf",
}
_cache = {}

def font(fam, size, w):
    k = (fam, int(size), int(w))
    if k not in _cache:
        f = ImageFont.truetype(FONT[fam], int(size))
        try:
            f.set_variation_by_axes([w])
        except Exception:
            pass
        _cache[k] = f
    return _cache[k]

def norm(t):
    return re.sub(r"[^a-z0-9]", "", t.lower())

def bbox(o):
    xs = [p[0] for p in o["box"]]; ys = [p[1] for p in o["box"]]
    return min(xs), min(ys), max(xs), max(ys)

def dentro(o, r):
    x0, y0, x1, y1 = bbox(o)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    return r[0] <= cx <= r[2] and r[1] <= cy <= r[3]

def maschera(img, r, soglia=42, pad=4, dil=2):
    """Maschera dei pixel di testo nel rettangolo r (sfondo = mediana del bordo)."""
    H, W = img.shape[:2]
    x0, y0 = max(0, int(r[0]) - pad), max(0, int(r[1]) - pad)
    x1, y1 = min(W, int(r[2]) + pad), min(H, int(r[3]) + pad)
    sub = img[y0:y1, x0:x1].astype(np.int32)
    bordo = np.concatenate([sub[0], sub[-1], sub[:, 0], sub[:, -1]])
    bg = np.median(bordo, axis=0)
    dist = np.abs(sub - bg).max(axis=2)
    m = (dist > soglia).astype(np.uint8)
    if dil:
        m = cv2.dilate(m, np.ones((3, 3), np.uint8), iterations=dil)
    out = np.zeros((H, W), np.uint8)
    out[y0:y1, x0:x1] = m
    forte = dist > soglia * 2.2
    col = None
    if forte.sum() > 5:
        col = tuple(int(c) for c in np.median(sub[forte], axis=0)[::-1])  # BGR -> RGB
    return out, col, tuple(int(c) for c in bg[::-1])

def maschera_poli(img, poli, modo="mediana", soglia=42, dil=2):
    H, W = img.shape[:2]
    pm = np.zeros((H, W), np.uint8)
    P = np.array(poli, np.float64)
    cen = P.mean(axis=0)
    dv = P - cen
    nn = np.linalg.norm(dv, axis=1, keepdims=True) + 1e-6
    P = P + dv / nn * 4
    cv2.fillPoly(pm, [np.round(P).astype(np.int32)], 1)
    sel = pm.astype(bool)
    pix = img[sel].astype(np.int32)
    if modo == "chiaro":
        m = (img.min(axis=2) > soglia).astype(np.uint8) & pm
    elif modo == "rosso":
        im = img.astype(np.int32)
        m = ((im[:, :, 2] - im[:, :, 1]) > soglia).astype(np.uint8) & pm
    else:
        bg = np.median(pix, axis=0)
        dist = np.abs(img.astype(np.int32) - bg).max(axis=2)
        m = (dist > soglia).astype(np.uint8) & pm
    col = None
    if m.sum() > 5:
        col = tuple(int(c) for c in np.median(img[m.astype(bool)], axis=0)[::-1])
    if dil:
        m = cv2.dilate(m, np.ones((3, 3), np.uint8), iterations=dil) & cv2.dilate(pm, np.ones((3, 3), np.uint8), iterations=dil)
    return m, col

def adatta(testo, fam, w, larg, alt, smax, smin=9, a_capo=True, inter=1.08):
    """Trova la dimensione più grande che fa stare il testo nel riquadro (con a capo automatico)."""
    s = smax
    while s >= smin:
        f = font(fam, s, w)
        righe = []
        for par in testo.split("\n"):
            if not a_capo:
                righe.append(par); continue
            parole = par.split(" "); r = ""
            for p in parole:
                prova = (r + " " + p).strip()
                if f.getlength(prova) <= larg or r == "":
                    r = prova
                else:
                    righe.append(r); r = p
            righe.append(r)
        lw = max(f.getlength(x) for x in righe)
        lh = s * inter
        if lw <= larg and lh * len(righe) <= alt + s * 0.25:
            return s, righe
        s -= 1
    f = font(fam, smin, w)
    return smin, testo.split("\n")

def scrivi(pil, r, testo, col, fam="sans", w=400, s=None, al="c", rot=0, a_capo=True, inter=1.08, ombra=None, margine=0, va="c", dim=None):
    x0, y0, x1, y1 = r
    larg, alt = (x1 - x0) - 2 * margine, (y1 - y0) - 2 * margine
    if dim:
        larg, alt = dim
    elif rot in (90, -90, 270):
        larg, alt = alt, larg
    smax = s if s else max(10, int(alt * 0.9))
    size, righe = adatta(testo, fam, w, larg, alt, smax, a_capo=a_capo, inter=inter)
    f = font(fam, size, w)
    lh = size * inter
    tot = lh * len(righe)
    strato = Image.new("RGBA", (int(larg + 8), int(max(alt, tot) + 8)), (0, 0, 0, 0))
    d = ImageDraw.Draw(strato)
    if va == "c":
        y = (strato.height - tot) / 2
    elif va == "t":
        y = 4
    else:
        y = strato.height - tot - 4
    for riga in righe:
        lw = f.getlength(riga)
        x = 4 if al == "l" else (strato.width - lw - 4 if al == "r" else (strato.width - lw) / 2)
        asc = f.getmetrics()[0]
        yy = y + (lh - size) / 2 + size * 0.02
        if ombra:
            d.text((x + 2, yy + 2), riga, font=f, fill=ombra)
        d.text((x, yy), riga, font=f, fill=col)
        y += lh
    if rot:
        strato = strato.rotate(rot, expand=True, resample=Image.BICUBIC)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    pil.alpha_composite(strato, (int(cx - strato.width / 2), int(cy - strato.height / 2)))

def blocco(pil, xy, righe, col, fam="sans", larg=9999, inter=1.04):
    """Righe con stili diversi, allineate a sinistra a partire da xy (angolo in alto a sinistra)."""
    d = ImageDraw.Draw(pil)
    x, y = xy
    for r in righe:
        t, s, w = r[0], r[1], r[2]
        c = r[3] if len(r) > 3 else col
        if isinstance(c, str):
            c = tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
        while s > 8 and font(fam, s, w).getlength(t) > larg:
            s -= 1
        d.text((x, y), t, font=font(fam, s, w), fill=c)
        y += r[1] * inter

def segmenti(pil, r, segs, s, fam="sans"):
    """Una riga con pezzi di stile diverso, centrata nel rettangolo."""
    d = ImageDraw.Draw(pil)
    x0, y0, x1, y1 = r
    while True:
        lw = sum(font(fam, s, w).getlength(t) for t, w, c in segs)
        if lw <= (x1 - x0) or s <= 9:
            break
        s -= 1
    x = (x0 + x1) / 2 - lw / 2
    y = (y0 + y1) / 2 - s * 0.62
    for t, w, c in segs:
        if isinstance(c, str):
            c = tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
        d.text((x, y), t, font=font(fam, s, w), fill=c)
        x += font(fam, s, w).getlength(t)

def traduci(src_bgr, ocr, voci, ox=0, oy=0, debug=None):
    """voci: lista di dict con r (rettangolo nelle coordinate dell'immagine), it (testo), e opzioni.
    Le righe OCR con il centro nel rettangolo di cancellazione (c, di default r) vengono cancellate."""
    img = src_bgr.copy()
    H, W = img.shape[:2]
    tot = np.zeros((H, W), np.uint8)
    lavori = []
    for v in voci:
        cr = v.get("c", v["r"])
        righe = [o for o in ocr if dentro(o, cr) and not re.fullmatch(r"[a-z][0-9]{1,2}", norm(o["t"]))] if not v.get("tutto") else []
        colori = []
        bgs = []
        for o in righe:
            b = bbox(o)
            b = (max(b[0], cr[0]), max(b[1], cr[1]), min(b[2], cr[2]), min(b[3], cr[3]))
            m, col, bg = maschera(img, b, v.get("soglia", 42), dil=v.get("dil", 2))
            tot |= m
            if col: colori.append(col)
            bgs.append(bg)
        if v.get("tutto"):
            for rr in (v["tutto"] if isinstance(v["tutto"], list) else [cr]):
                m, col, bg = maschera(img, rr, v.get("soglia", 42), dil=v.get("dil", 2))
                tot |= m
                if col: colori.append(col)
                bgs.append(bg)
        for poli in v.get("poli", []):
            m, col = maschera_poli(img, poli, v.get("modo", "mediana"), v.get("soglia", 42), v.get("dil", 2))
            tot |= m
            if col: colori.append(col)
        if v.get("pieno"):
            x0, y0, x1, y1 = [int(a) for a in v["pieno"]]
            tot[y0:y1, x0:x1] = 1
        col = v.get("col")
        if col is None:
            col = tuple(int(np.median([c[i] for c in colori])) for i in range(3)) if colori else (240, 240, 240)
        elif isinstance(col, str):
            col = tuple(int(col[i:i + 2], 16) for i in (1, 3, 5))
        lavori.append((v, col, len(righe)))
        if debug is not None and not righe and not v.get("tutto") and not v.get("pieno") and v.get("it"):
            debug.append("nessuna riga OCR per: " + v["it"][:40])
    if tot.any():
        img = cv2.inpaint(img, tot * 255, 4, cv2.INPAINT_TELEA)
    for v in voci:
        if v.get("fondo"):
            x0, y0, x1, y1 = [int(a) for a in v["fondo"]]
            sub = src_bgr[y0:y1, x0:x1].reshape(-1, 3).astype(np.int32)
            # colore di fondo: il più frequente (quantizzato)
            q = (sub // 12) * 12 + 6
            vals, cnt = np.unique(q, axis=0, return_counts=True)
            img[y0:y1, x0:x1] = vals[cnt.argmax()]
    pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB)).convert("RGBA")
    for v, col, n in lavori:
        if v.get("segmenti"):
            segmenti(pil, v["r"], v["segmenti"], v.get("s", 20), v.get("f", "sans"))
            continue
        if v.get("righe"):
            blocco(pil, v["xy"], v["righe"], col + (255,), v.get("f", "sans"), v.get("larg", 9999), v.get("inter", 1.04))
            continue
        if not v.get("it"):
            continue
        scrivi(pil, v["r"], v["it"], col + (255,), v.get("f", "sans"), v.get("w", 400), v.get("s"), v.get("al", "c"),
               v.get("rot", 0), v.get("a_capo", True), v.get("inter", 1.08), v.get("ombra"), v.get("m", 0), v.get("va", "c"), v.get("dim"))
    return pil

def carica_ocr(path, ox, oy, rect):
    d = json.load(open(path))
    out = []
    for o in d:
        x0, y0, x1, y1 = bbox(o)
        if rect[0] <= x0 and x1 <= rect[2] and rect[1] <= y0 and y1 <= rect[3]:
            out.append({"box": [[p[0] - ox, p[1] - oy] for p in o["box"]], "t": o["t"]})
    return out
