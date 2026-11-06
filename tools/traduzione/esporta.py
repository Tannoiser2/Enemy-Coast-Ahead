"""Ritaglia la tavola tradotta negli asset del gioco."""
from PIL import Image, ImageDraw
Image.MAX_IMAGE_PIXELS = None
T = Image.open("tavola_it.png").convert("RGB")
A = "/home/claude/enemy-coast-ahead/assets/mappe/"
# mappa di volo
v = T.crop((1340, 20, 3200, 3240))
v.resize((int(v.width * 0.75), int(v.height * 0.75)), Image.LANCZOS).save(A + "volo.jpg", quality=86)
# mappe del bersaglio (stessi ritagli 1050x1010 di prima)
for n, (ox, oy) in {"mohne": (3200, 2200), "eder": (3200, 1200), "sorpe": (3200, 150)}.items():
    c = T.crop((ox, oy, ox + 1050, oy + 1010))
    if n == "sorpe":
        ImageDraw.Draw(c).rectangle((150, 0, 800, 44), fill=(18, 16, 15))
    c.save(A + n + ".jpg", quality=88)
# tracce delle dighe: una striscia per diga
TIT = {"lister": 137, "diemel": 407, "eder": 667, "henne": 934, "sorpe": 1193, "bever": 1455, "ennepe": 1716, "mohne": 1971}
for n, y in TIT.items():
    T.crop((4292, y - 14, 5032, y + 216)).save(A + "traccia_" + n + ".jpg", quality=88)
# turni d'attacco, vettore d'avvicinamento, sequenza
T.crop((4290, 2200, 5040, 2990)).save(A + "attacco.jpg", quality=88)
T.crop((4290, 3005, 5040, 3225)).save(A + "sequenza_attacco.jpg", quality=88)
# lavagna: due colonne affiancate
L = T.crop((60, 20, 1345, 3290))
a = L.crop((0, 0, L.width, 1460)); b = L.crop((0, 1460, L.width, L.height))
c = Image.new("RGB", (L.width * 2, max(a.height, b.height)), (24, 22, 20))
c.paste(a, (0, 0)); c.paste(b, (L.width, 0))
c.resize((int(c.width * 0.7), int(c.height * 0.7)), Image.LANCZOS).save(A + "lavagna.jpg", quality=86)
print("ok", c.size)
