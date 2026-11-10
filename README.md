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

E gli scenari di volo, con le regole 6.0-7.10:

- **6 · Il volo della forza diversiva**: quattro Lancaster in onda più McCarthy da solo, per la rotta settentrionale verso la Sorpe.
- **7 · Il volo della forza principale**: le tre ondate di Gibson verso la Möhne e la Eder.
- **8 · Il volo della riserva mobile**: cinque Lancaster che partono alle 23:00 con l'allerta già a 3; ordini via radio dal turno 5.
- **9 · Il raid delle dighe**: tutte le forze insieme, diciannove Lancaster.

E la campagna:

- **10 · Operazione Chastise**: quattro turni di pianificazione (requisizioni, sicurezza, addestramento, modifiche,
  ricognizione) sulla lavagna di pianificazione, poi la preparazione del volo, la sortita con le onde scelte dal
  giocatore e il raid sulla mappa di volo, con la sorpresa alle dighe e i palloni di sbarramento.

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

## Scenari di volo

- Mappa di volo con le sei zone (Inghilterra, Costa inglese, Mare del Nord, Costa olandese, Ruhr, Weser), i riquadri
  dei dispersi e del rientro, la ricognizione delle zone ostili, le onde (in buon ordine o scompaginate) e gli isolati;
  a destra le otto dighe con lo stato e i Lancaster che le stanno attaccando, e la traccia dei turni di volo.
- Turno di volo completo: coordinamento (F1), radiotelegrafia (F2), movimento (F3), navigazione (F4), pericoli
  piazzati dalle tre tazze (16 gialli, 30 azzurri, 18 blu, con il fronte visibile) (F5), evitare con la ricognizione e
  con lo «schiva e zigzaga» (F6), risoluzione con contraerea, caccia notturni (Me 109, Me 110, Ju 88), palloni,
  schianti, fotoelettriche e guasti attaccati, salvataggio del veterano (F7), acquisizione del bersaglio con il
  tentativo ostinato (F8), mappe del bersaglio con ingresso coordinato o scoordinato e ripresa dopo il turno
  d'attacco 8 (F9), pulizia con allerta e attività.
- Un attacco di caccia sulla mappa di volo abbatte il Lancaster; i rapporti finali degli scenari 6-9 sono ricostruiti
  con le etichette del libro degli scenari (il 9 non ha una tabella leggibile: vale l'rv delle dighe aperte e le perdite).

## Interfaccia

- Le mappe sono quelle originali del modulo Tabletop Simulator, nitide, con le scritte rifatte in italiano direttamente
  sull'immagine (riconoscimento del testo, cancellazione e riscrittura con font simili: `tools/traduzione/`):
  lavagna di pianificazione, mappa di volo, mappe del bersaglio di Möhne, Eder e Sorpe, tracce delle otto dighe.
- Pedine originali dei Lancaster con i ritratti degli specialisti; segnalini (ricognizione, allerta, turni, squadre di
  terra, addestramento, modifiche, sicurezza) disegnati in italiano nelle caselle vere della mappa.
- Vista che segue la fase (lavagna, mappa di volo, mappa del bersaglio) con zoom a rotella o pizzico (anche su iPad), trascinamento con un dito o col mouse e doppio clic
  per tornare alla vista intera; a destra traccia della diga attaccata e dei turni d'attacco, decisioni con i dadi, e
  in basso le schede Diario (a macchina da scrivere) e Squadriglia. La colonna si allarga sugli schermi larghi.
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

La campagna (scenario 10) segue la terza parte del regolamento e la scheda dello scenario: addestramento che parte
da 0, acqua delle dighe «in salita», segnalini «a riposo» per tipo e specialità, doppio turno (requisizioni,
modifiche, preparazione del volo), ordine d'attacco senza radio VHF, cane di Gibson, bersaglio di riserva obbligatorio
e rapporto in cinque passi con la commissione d'inchiesta. Non sono giocabili il secondo raid (il passo 5 dice solo se
sarebbe possibile) e la regola opzionale dell'alta quota. Scelte di conversione: senza VHF un messaggio a un'onda
cambia la rotta solo se lo ricevono tutti i Lancaster; nel controllo degli equipaggi restano a terra prima le reclute.

## Sviluppo

- Godot 4.7, rendering gl_compatibility, esportazione web.
- `scripts/dati.gd` tabelle, dighe, gettoni, Upkeep, specialisti e scenari; `scripts/partita.gd` motore delle regole
  (stato in un dizionario salvabile, decisioni in `s.attesa`); `scripts/bot.gd` giocatore automatico;
  `scripts/volo.gd` scenari di volo (estende il motore); `scripts/campagna.gd` campagna e `scripts/lavagna.gd` lavagna di pianificazione; `scripts/mappa.gd` mappa del bersaglio; `scripts/mappa_volo.gd` mappa di volo; `scripts/main.gd` interfaccia; `scripts/aiuto.gd` regole in italiano;
  `scripts/net.gd` Firebase.
- Prove: `godot --headless --script res://tests/partite_auto.gd` (partite automatiche di tutti gli scenari, con
  salvataggio e ricarica a metà), `tests/voli_auto.gd` (scenari di volo), `tests/campagna_auto.gd` (campagne), `xvfb-run godot --script res://tests/screenshot.gd`.
- Pubblicazione solo su richiesta: Actions → *Pubblica* → *Run workflow*, oppure un commit con `[pubblica]` nel messaggio.
