# Enemy Coast Ahead: The Dambuster Raid - versione digitale

Versione digitale per uso personale di **Enemy Coast Ahead: The Dambuster Raid** di Jeremy White (GMT Games, 2014):
il solitario sull'Operazione Chastise, l'attacco del 617° Squadron della RAF alle dighe della Ruhr nella notte del
16-17 maggio 1943 con la bomba rimbalzante *Upkeep*. Tutto in italiano.

Si gioca nel browser: https://tannoiser2.github.io/Enemy-Coast-Ahead/ (e nella ludoteca privata, se ci sono i segreti di Cloudflare).

## Scenari

Gli scenari d'attacco del libro degli scenari, con le regole 1.0-5.0 complete:

- **Prima partita**: lo scenario 5 semplificato (equipaggio veterano, sereno, allerta 1, solo la Ennepe), consigliato dal regolamento per imparare.
- **1 · Attacco alla Möhne**: otto Lancaster, contraerea 3, gli Upkeep rimasti proseguono verso la Eder.
- **2 · Attacco alla Eder**: niente contraerea ma il costone del Michelskopf dietro la diga; Gibson senza Upkeep fa da scorta.
- **3 · Primo attacco alla Sorpe**: McCarthy da solo, danneggiato, su una diga di terra senza zona vicina.
- **4 · Secondo attacco alla Sorpe**: Brown nella nebbia, con il danno dell'Upkeep di McCarthy già sulla diga.
- **5 · Attacco alla Ennepe?**: Townsend con un equipaggio recluta e la nebbia di guerra (Ennepe o Bever?).

Gli scenari di volo (6-9) e la campagna (10) non ci sono ancora.

## Cosa fa il gioco

- Sequenza del turno d'attacco: corsa, avvicinamento e sgancio, volo in cerchio, stato (A1).
- Avvicinamento in tre zone (due sulla Sorpe e sulla Bever) con vettore d'avvicinamento dalla tabella della mappa
  (colonne Eder, Sorpe/Bever, altre dighe; righe di ricognizione; sereno e nebbia), gettoni Quota e Velocità pescati
  dalle tazze con il lato d'avvicinamento e il lato rosa dello sgancio, regolazioni, luci Aldis, scorte.
- Contraerea con 2 o 3 dadi, i due più letali, colpi critici e doppi, azione evasiva (A4); mitragliatrici anteriori e
  posteriori (A5); logoramento delle difese (A7); caccia notturno con allerta, fotoelettriche e attività (A6).
- Sgancio anticipato, sgancio tardivo (A9), tiro di sgancio con tutti i modificatori (A12), concussione,
  Michelskopf (Eder), segnalini «Passaggio a vuoto» e «Avvicinamento osservato» (A8, A13).
- Detonazione degli Upkeep con il valore pari o dispari del segnalino (A14), breccia secondo la capacità e il livello
  dell'acqua, razzi Very e visibilità.
- Fine dello scenario, rientro alla base e tabella dei dispersi (E1, E2), ricognizione del mattino (E3), rapporto finale.
- Specialisti storici (Gibson, Shannon, Martin, Walker, i puntatori...) con i loro effetti.

## Interfaccia

- Mappa del bersaglio della diga di turno (Möhne, Eder o Sorpe) presa dal modulo Tabletop Simulator: le scritte inglesi
  sono state cancellate (`tools/estrazione/prepara_asset.py`) e caselle, zone e testi sono ridisegnati in italiano.
- Pedine originali dei Lancaster con i ritratti degli specialisti; gettoni, Upkeep e segnalini ridisegnati in italiano.
- Scheda della diga (acqua e capacità, difese, ricognizione, attività, Upkeep a segno), traccia dei turni d'attacco con
  i razzi, squadriglia, pannello delle decisioni con i dadi, registro della missione a macchina da scrivere.
- Le decisioni si prendono con i pulsanti, con i tasti 1-9 o cliccando le pedine evidenziate; «Decidi tu» lascia
  la scelta al computer. Aiuto completo in italiano (F1).
- Font: Josefin Sans (titoli), Source Sans 3 (testo), Crimson Pro, Special Elite (registro). `tools/controlla_glifi.py`
  controlla che ogni carattere usato esista in tutti i font.

## Salvataggi

- Automatico sul dispositivo a ogni decisione («Continua la partita salvata»).
- Online su Firebase (progetto della ludoteca, radice `enemycoastahead/partite`, coperta dalla regola comune della
  ludoteca): «Salva online» dà un codice di 6 caratteri per riprendere la partita da qualsiasi dispositivo.

## Scelte di conversione

Il libro degli scenari disponibile è una scansione poco leggibile: le combinazioni dei rapporti finali (Debriefing Chart)
sono ricostruite in modo coerente con le etichette originali tradotte; anche la contraerea della Möhne (3) e gli
specialisti proposti per ciascun Lancaster seguono la lettura più probabile. Tutti i numeri delle tabelle vengono dai
Player Aid e dalla mappa del modulo.

## Sviluppo

- Godot 4.7, rendering gl_compatibility, esportazione web.
- `scripts/dati.gd` tabelle, dighe, gettoni, Upkeep, specialisti e scenari; `scripts/partita.gd` motore delle regole
  (stato in un dizionario salvabile, decisioni in `s.attesa`); `scripts/bot.gd` giocatore automatico;
  `scripts/mappa.gd` mappa del bersaglio; `scripts/main.gd` interfaccia; `scripts/aiuto.gd` regole in italiano;
  `scripts/net.gd` Firebase.
- Prove: `godot --headless --script res://tests/partite_auto.gd` (partite automatiche di tutti gli scenari, con
  salvataggio e ricarica a metà), `xvfb-run godot --script res://tests/screenshot.gd`.
- Pubblicazione solo su richiesta: Actions → *Pubblica* → *Run workflow*, oppure un commit con `[pubblica]` nel messaggio.
