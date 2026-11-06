#!/usr/bin/env python3
"""Prepara le immagini del gioco a partire dal modulo Tabletop Simulator.

Uso: python3 tools/estrazione/prepara_asset.py CARTELLA_MODULO_ESTRATTO
  CARTELLA_MODULO_ESTRATTO  la cartella con Mods/Images e Mods/Workshop (il file .ttsmod è uno zip)

Cosa produce (in assets/):
- mappe/mohne.jpg, eder.jpg, sorpe.jpg: le tre mappe del bersaglio senza le scritte inglesi
  (cancellate con inpainting e una leggera sfocatura); caselle e scritte italiane le disegna il gioco;
- pedine/AJ-x_f.png e AJ-x_r.png: fronte e retro dei Lancaster;
- ritratti/<nome>.png: i ritratti degli specialisti (retro dei segnalini Elite Crewman);
- pedine/upkeep.png, flak.png, fari.png, palloni.png, ricognizione.png;
- ui/copertina.jpg (menu), ui/icona.png.
"""
import json, os, re, sys
import cv2
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

SRC = sys.argv[1] if len(sys.argv) > 1 else '/home/claude/src_mod/x'
R = os.path.join(os.path.dirname(__file__), '..', '..')
IMG = os.path.join(SRC, 'Mods', 'Images')
imgs = os.listdir(IMG)


def file_di(url):
    f = re.sub(r'[^A-Za-z0-9]', '', url)
    for i in imgs:
        if i.startswith(f):
            return os.path.join(IMG, i)
    raise SystemExit('immagine mancante: ' + url)


d = json.load(open(os.path.join(SRC, 'Mods', 'Workshop', '1195146540.json')))
pezzi = []


def visita(oggetti):
    for o in oggetti:
        if o['Name'] == 'Custom_Tile':
            ci = o['CustomImage']
            pezzi.append((ci.get('ImageURL'), ci.get('ImageSecondaryURL')))
            for s in (o.get('States') or {}).values():
                c2 = s['CustomImage']
                pezzi.append((c2.get('ImageURL'), c2.get('ImageSecondaryURL')))
        if o.get('ContainedObjects'):
            visita(o['ContainedObjects'])


visita(d['ObjectStates'])

# ------------------------------------------------------------------ mappe del bersaglio
MAPPA = 'https://i.imgur.com/TiIUW8x.jpg'
mappa = cv2.imread(file_di(MAPPA))
FONDO = (18, 15, 13)  # BGR del bordo scuro
mappe = {
    # origine del ritaglio nella mappa originale, scritte da cancellare (x0,y0,x1,y1), zone da riempire di scuro
    'mohne': ((3200, 2200), [(335, 100, 690, 200), (185, 212, 275, 245), (430, 200, 560, 250), (975, 485, 1025, 565),
                             (595, 462, 700, 508), (715, 440, 768, 545), (815, 550, 858, 635), (432, 442, 562, 528),
                             (617, 517, 738, 598), (857, 582, 943, 648)], [(290, 25, 710, 92)]),
    'eder': ((3200, 1200), [(392, 225, 498, 262), (515, 75, 645, 140), (978, 430, 1025, 505), (636, 415, 748, 460),
                            (770, 436, 818, 525), (876, 425, 918, 510), (502, 372, 622, 463), (677, 477, 788, 553),
                            (906, 576, 984, 634)], [(355, 0, 665, 44)]),
    'sorpe': ((3200, 150), [(742, 58, 1032, 340), (686, 396, 795, 430), (30, 430, 70, 485), (176, 390, 228, 485),
                            (306, 420, 358, 505), (455, 730, 590, 790), (300, 50, 390, 120), (426, 126, 548, 218)],
              [(190, 0, 760, 42)]),
}
os.makedirs(R + '/assets/mappe', exist_ok=True)
for nome, ((ox, oy), scritte, scure) in mappe.items():
    c = mappa[oy:oy + 1010, ox:ox + 1050].copy()
    mask = np.zeros(c.shape[:2], np.uint8)
    for (x0, y0, x1, y1) in scritte:
        mask[y0:y1, x0:x1] = 255
    c = cv2.inpaint(c, mask, 9, cv2.INPAINT_TELEA)
    for (x0, y0, x1, y1) in scure:
        c[y0:y1, x0:x1] = FONDO
    im = Image.fromarray(cv2.cvtColor(c, cv2.COLOR_BGR2RGB)).filter(ImageFilter.GaussianBlur(2.2))
    im = ImageEnhance.Brightness(im).enhance(0.82)
    im.save(R + f'/assets/mappe/{nome}.jpg', quality=88)
    print('mappa', nome, im.size)

# ------------------------------------------------------------------ pedine
mp = json.load(open('/home/claude/mappa_pedine.json')) if os.path.exists('/home/claude/mappa_pedine.json') else None
os.makedirs(R + '/assets/pedine', exist_ok=True)
os.makedirs(R + '/assets/ritratti', exist_ok=True)
lanc = "A B C D E F G H J K L M N O P Q R S T W X Y Z".split()
for i, c in enumerate(lanc):
    f, b = pezzi[i]
    Image.open(file_di(f)).convert('RGBA').save(R + f'/assets/pedine/AJ-{c}_f.png')
    Image.open(file_di(b)).convert('RGBA').save(R + f'/assets/pedine/AJ-{c}_r.png')
ELITE = {'hobday': 26, 'gregory': 28, 'gillespie': 29, 'gibson': 30, 'franklin': 31, 'deering': 32, 'chambers': 33,
         'hopgood': 34, 'johnson': 35, 'knight': 36, 'leggo': 37, 'marriott': 38, 'martin': 39, 'mccarthy': 40,
         'nicholson': 41, 'townsend': 44, 'sumpter': 45, 'spafford': 46, 'shannon': 47, 'pulford': 48, 'oancia': 49,
         'trevor_roper': 50, 'tytherleigh': 51, 'urquhart': 52, 'walker': 53}
for nome, i in ELITE.items():
    Image.open(file_di(pezzi[i][1])).convert('RGBA').save(R + f'/assets/ritratti/{nome}.png')


def primo(pred):
    for f, b in pezzi:
        if pred(f, b):
            return f, b


# Upkeep (fronte), Flak, Fari, Palloni, Ricognizione: riconosciuti dalle immagini note
def salva(url, nome):
    Image.open(file_di(url)).convert('RGBA').save(R + f'/assets/pedine/{nome}.png')


salva(pezzi[57][0], 'upkeep')
print('ok pedine')

# copertina e icona
cop = Image.open(file_di('https://i.imgur.com/cD8Qe0a.jpg')).convert('RGB')
cop.save(R + '/assets/ui/copertina.jpg', quality=90)
ic = cop.crop((60, 60, 600, 470)).resize((256, 194))
q = Image.new('RGB', (256, 256), (12, 18, 26))
q.paste(ic, (0, 31))
q.save(R + '/assets/ui/icona.png')
cop.resize((480, int(480 * cop.height / cop.width)), Image.LANCZOS).save(R + '/ludoteca/copertina.webp', quality=88)
print('ok copertina')
