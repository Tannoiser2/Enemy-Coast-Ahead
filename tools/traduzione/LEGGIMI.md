# Traduzione della mappa originale

1. `ocr.py`: riconosce il testo della mappa del modulo TTS (5100x3300) con RapidOCR e salva `ocr.json`.
2. `voci.py`: traduzioni riga per riga (`DIZ`, `DIZ_REG` per zona) e gruppi (paragrafi, scritte ruotate, ritocchi).
3. `costruisci.py`: cancella le scritte inglesi (maschera dei pixel del testo + inpainting) e riscrive l'italiano
   con Source Sans 3; produce `tavola_it.png`.
4. `esporta.py`: ritaglia gli asset del gioco (`assets/mappe/`): volo, lavagna, mappe del bersaglio, tracce delle dighe.

Servono `opencv-python`, `pillow`, `rapidocr-onnxruntime` e i font in `/home/claude/fonts` (percorsi in `motore.py`).
