## Testi dell'aiuto in linea: le regole degli scenari d'attacco riassunte in italiano, con le tabelle.
class_name Aiuto
extends RefCounted

const CAPITOLI := {
"Come si gioca": """[b]Enemy Coast Ahead: The Dambuster Raid[/b] è un solitario: comandi il 617° Squadron della RAF nella notte del 16-17 maggio 1943 (Operazione Chastise), quando i Lancaster attaccarono le dighe della Ruhr con la bomba rimbalzante [i]Upkeep[/i].

Negli scenari d'attacco (1-5) la squadriglia è già sopra la diga. Ogni [b]turno d'attacco[/b] dura 7-8 minuti e ha quattro fasi:

[b]1. Corsa[/b] - un solo Lancaster con l'Upkeep lascia il Cerchio vicino ed entra nella zona lontana dell'avvicinamento. Fino a due Lancaster [i]senza[/i] Upkeep possono fargli da scorta.
[b]2. Avvicinamento e sgancio[/b] - il Lancaster attraversa le zone lontana, vicina e ravvicinata (la Sorpe non ha la zona vicina), affronta la contraerea, regola velocità e quota e sgancia l'Upkeep. Oppure richiama e torna al Cerchio vicino per riprovare.
[b]3. Volo in cerchio[/b] - si spostano i Lancaster fra il Cerchio vicino e il Cerchio lontano; chi non ha più l'Upkeep può lasciare il bersaglio; dal Cerchio vicino si sparano i razzi Very.
[b]4. Stato[/b] - visibilità (turni 3, 5 e 7), logoramento delle difese, controllo del caccia notturno, detonazione degli Upkeep (solo se c'è un Lancaster nel Cerchio vicino che osserva), razzi che si spengono.

Dopo il turno 8 si ricomincia dal turno 1. Lo scenario finisce quando la diga cede, quando un caccia notturno attacca, quando nessun Lancaster sulla diga ha più un Upkeep o quando il carburante finisce. Poi si fanno i controlli del [b]rientro alla base[/b], la [b]ricognizione del mattino[/b] e il [b]rapporto[/b] (Debriefing).

[b]Comandi[/b]
- Le decisioni compaiono nel pannello a destra: clicca il pulsante o premi il numero (1-9).
- Le mappe sono quelle originali del gioco, con le scritte in italiano. In alto si passa fra lavagna di pianificazione, mappa di volo e mappa del bersaglio; la vista segue da sola la fase in corso.
- Sulle mappe: rotella del mouse (o pizzico sul trackpad) per ingrandire, tasto destro o trascinamento per spostarsi, doppio clic per tornare alla vista intera. Passando sopra una pedina compare la sua scheda.
- Sulla mappa di volo, a destra, ci sono le tracce delle otto dighe con danni, ricognizione, attività, contraerea e livello dell'acqua; sulla mappa del bersaglio la traccia della diga attaccata è in alto a destra.
- In basso a destra, le schede Diario e Squadriglia.
- Puoi anche cliccare sulla mappa i Lancaster evidenziati in giallo (per scegliere chi attacca e per spostarli fra i cerchi).
- Passa col mouse su una pedina per vedere equipaggio, specialista e stato.
- «Decidi tu» lascia la scelta al computer. F1 apre questo aiuto.
- La partita si salva da sola su questo dispositivo; «Salva online» dà un codice di 6 caratteri per riprenderla altrove.""",

"Avvicinamento": """[b]Zona lontana[/b]
[b]Passo 1 · Vettore d'avvicinamento.[/b] Un dado sulla tabella stampata sulla mappa: la colonna dipende dalla diga (Eder, Sorpe o Bever, altre dighe), la riga dal livello di ricognizione. Con tempo sereno valgono solo i risultati in alto della casella, con la nebbia anche quelli in basso.
  S = un gettone Velocità in meno · A = un gettone Quota in meno · M = un segno Michelskopf (solo Eder).
  Ogni razzo Very sulla traccia dei turni annulla una A. Shannon tira due dadi e sceglie.
[b]Passo 2 · Velocità.[/b] Peschi tanti gettoni Velocità quanti ne concede l'addestramento (vedi Tabelle), +1 col motorista, -1 per ogni S. Ne tieni uno; gli altri tornano nella tazza. Se non puoi pescarne, resti senza gettone fino allo sgancio.
[b]Passo 3 · Quota.[/b] Come sopra con i gettoni Quota (+1 col navigatore Walker o Urquhart, -1 per ogni A). Servono le [b]luci Aldis accese[/b], tranne sulla Sorpe e sulla Bever.
[b]Passo 4 · Contraerea[/b] (se la diga ne ha).
[b]Passo 5 · Decisione:[/b] sganciare subito (sgancio anticipato, -2), proseguire o richiamare.

[b]Zona vicina[/b] (non c'è sulla Sorpe e sulla Bever)
[b]Passo 6 · Regolazione:[/b] peschi un nuovo gettone Velocità [i]oppure[/i] Quota, che sostituisce quello che hai. Sulla Eder entrare nella zona vicina dà un segno M.
[b]Passo 7 · Contraerea. Passo 8 · Mitragliatrici anteriori[/b] (anche delle scorte). [b]Passo 9 · Decisione.[/b]

[b]Zona ravvicinata[/b]
[b]Passo 10 · Regolazione e contraerea. Passo 11 · Mitragliatrici. Passo 12 · Sgancio o richiamo.[/b] Sganciando da qui si fa il [b]controllo dello sgancio tardivo[/b]: 1 = -2 «un rimbalzo di troppo?» · 2-3 = -1 · 4-5 = nessun effetto · 6 = +1 «Centrato!». Sulla Eder dà anche segni M (2, 2, 1, 0).

[b]Richiamo[/b]: il Lancaster torna al Cerchio vicino con il segnalino «Passaggio a vuoto», che più avanti si può scambiare con un gettone in più (passi 2, 3, 6, 10 o controllo finale). Chi nel Cerchio vicino vede fallire uno sgancio riceve il segnalino «Avvicinamento osservato», che vale allo stesso modo.

[b]Scorte[/b]: sparano con le mitragliatrici anteriori e la contraerea può colpire loro invece del Lancaster all'attacco. Con lo sgancio o il richiamo tornano al Cerchio vicino.""",

"Sgancio": """[b]Sequenza di sgancio[/b]
[b]1 · Quota finale.[/b] Peschi tanti gettoni Quota quanti ne indica il gettone d'avvicinamento («n gettoni») e ne tieni uno: conta il lato rosa, con il suo modificatore (+0/+4) ed eventualmente il segno M.
[b]2 · Velocità finale.[/b] Lo stesso con i gettoni Velocità.
[b]3 · SGANCIO![/b] Due dadi più i modificatori:
  gettoni Quota e Velocità finali · addestramento al puntamento · +1 puntatore specialista · -2 sgancio anticipato · sgancio tardivo · -4 fotoelettriche · -1 Lancaster danneggiato.
  [b]15 o più[/b]: l'Upkeep colpisce la diga. [b]11-14[/b]: la manca. [b]10 o meno[/b]: la manca e l'esplosione danneggia il Lancaster (concussione).
  Ogni sgancio alza di 1 l'attività della diga. Il valore dell'Upkeep resta coperto fino alla detonazione.
[b]4 · Risalita.[/b] I gettoni tornano nelle tazze. Sulla Eder: [b]controllo del Michelskopf[/b], 2 dadi -1 per ogni segno M raccolto: con 3 o meno il Lancaster si schianta.
[b]5 · Contraerea[/b] in risalita (niente azione evasiva). [b]6 · Mitragliatrice posteriore[/b] contro una difesa.

[b]Detonazione[/b] (fase di stato): se un Lancaster è nel Cerchio vicino si girano gli Upkeep andati a segno e si tira un dado: pari vale il numero pari del segnalino, dispari quello dispari. Quando i danni raggiungono la capacità della diga (secondo il livello dell'acqua) la diga cede: [b]breccia[/b].
[b]Ricognizione del mattino[/b]: per ogni Upkeep a segno un dado: 1 = un danno in meno, 6 = un danno in più.""",

"Pericoli": """[b]Contraerea (A4)[/b] - Si tirano 2 dadi, 3 se le luci Aldis sono accese o ci sono fotoelettriche (si tengono i due più letali). Colpisce se la somma è nell'intervallo del livello:
  livello 1: 2-4 · livello 2: 3-5 · livello 3: 4-6 · livello 4: 5-7 · livello 5: 6-9.
  Con i livelli 4 e 5 un colpo con somma 7 è [b]critico[/b]: due colpi. Con un doppio si applica il risultato e si ritira, finché escono doppi o il Lancaster è abbattuto o tenta l'azione evasiva.
  Un colpo danneggia il Lancaster; il secondo lo abbatte.
[b]Azione evasiva[/b] - Il Lancaster all'attacco rinuncia a un gettone (Velocità o Quota), la scorta si sgancia nel Cerchio vicino; poi un dado: pari il colpo è annullato, dispari va a segno.

[b]Mitragliatrici (A5)[/b] - Ogni aereo tira un dado contro una difesa: con un risultato uguale o minore del livello la difesa scende di 1 (una sola riduzione per difesa a ogni passo). -1 col mitragliere specialista. Ogni riduzione alza l'attività di 1.
[b]Logoramento (A7)[/b] - Se in quel turno è stato sganciato un Upkeep, un dado per ogni difesa: uguale o minore del livello, scende di 1.

[b]Caccia notturno (A6)[/b] - Passo 1, avvistamento: 2 dadi, l'intervallo dipende dall'allerta (allerta 0: 2-3, 1: 2-4, 2: 3-5, 3: 4-6, 4: 5-7; con le fotoelettriche 2-4, 3-5, 4-6, 5-7, 6-9).
  Passo 2: 2 dadi secondo l'attività della diga (Upkeep sganciati, razzi Very, Lancaster abbattuti, difese ridotte dalle mitragliatrici):
  [b]nessun caccia nei paraggi[/b] - attività 0: attacco 2, nei paraggi 3-4, svanisce 5+ · 1-3: attacco 2, paraggi 3-7, svanisce 8+ · 4-6: attacco 2-3, paraggi 4-8, svanisce 9+ · 7+: attacco 2-4, paraggi 5-10, svanisce 11+.
  [b]caccia già nei paraggi[/b] - attività 0: attacco 2-3, paraggi 4, svanisce 5+ · 1-3: 2-4, 5, 6+ · 4-6: 2-5, 6-7, 8+ · 7+: 2-6, 7-8, 9+.
  Se attacca, abbatte un Lancaster del Cerchio vicino e gli altri si disperdono: l'attacco alla diga finisce.

[b]Visibilità (A1)[/b] - Turni 3, 5 e 7 (e quando si ricomincia dal turno 1): 2 dadi, 5 o meno nebbia, 6 o più sereno. Negli scenari 4 e 5 -2 al tiro.
[b]Razzi Very[/b] - Un Lancaster che inizia e finisce la fase in cerchio nel Cerchio vicino può spararne uno: annulla una A del vettore d'avvicinamento ma alza l'attività. A ogni fase di stato un dado meno i turni trascorsi: 0 o meno, il razzo si spegne.""",

"Tabelle": """[b]Addestramento degli equipaggi[/b] (scenari 1-9)
  Recluta: livello 2 · Esperto: livello 3 · Veterano: livello 5.
[b]Gettoni concessi da Quota e Velocità[/b]: livello 1-2 = 1 gettone · 3-4 = 2 · 5-6 = 3 · 7 = 4.
[b]Modificatore di puntamento e sgancio[/b]: livello 2-4 = +1 · 5-6 = +2 · 7 = +3 · 8 = +4.

[b]Gettoni Quota[/b] (avvicinamento · sgancio sgancio)
  53 ft, 1 gettone · sgancio 64 ft +3 · 54 ft, 1 · sgancio 56 ft +2 M · 56 ft, 2 · sgancio 52 ft +1 M · 60 ft, 3 · sgancio 70 ft +1
  65 ft, 2 · sgancio 67 ft +2 · 70 ft, 1 · sgancio 60 ft +4 · irregolare, 0 · sgancio irregolare +0 M
[b]Gettoni Velocità[/b]
  210 mph, 1 · sgancio 218 mph +3 M · 212 mph, 1 · sgancio 223 mph +2 · 216 mph, 2 · sgancio 228 mph +1 · 220 mph, 3 · sgancio 213 mph +1 M
  227 mph, 2 · sgancio 216 mph +2 M · 231 mph, 1 · sgancio 220 mph +4 · irregolare, 0 · sgancio irregolare +0 M

[b]Capacità di danno delle dighe[/b] (acqua in salita / alta / piena)
  Möhne, Eder, Ennepe, Lister, Diemel, Henne: 12 / 8 / 6 · Sorpe: 15 / 12 / 10 · Bever: 14 / 11 / 9.

[b]Rientro alla base (E1)[/b] - 2 dadi: 7 o più torna a Scampton; 6 o meno tabella dei dispersi (E2): 4 o meno disperso (M.I.A.), 5 lunga deviazione e rientro, 6-9 rientro danneggiato (se era già danneggiato un dado: 1-4 precipita), 10+ rientro.
  Modificatori: -1 recluta, +1 veterano, +1 specialista a bordo, -1 danneggiato, -1 zona della Ruhr, -2 zona del Weser, -1 allarme (allerta 4).
[b]Ricognizione del mattino (E3)[/b] - per ogni Upkeep a segno: 1 = -1 danno, 2-5 = nessun cambiamento, 6 = +1 danno.

[b]Specialisti[/b] (uno per Lancaster)
  Puntatore +1 allo sgancio · Motorista +1 gettone Velocità · Navigatore (Walker, Urquhart) +1 gettone Quota · Mitragliere di prua -1 alla mitragliatrice anteriore · Mitragliere di coda -1 alla posteriore · Gibson, comandante: un tiro ripetuto a partita · Shannon: 2 dadi per il vettore d'avvicinamento · Martin: ignora un danno · Ogni specialista dà +1 al rientro alla base.""",

"Scenari": """[b]1 · Attacco alla diga della Möhne[/b] (turno 4, sereno, allerta 1, ricognizione 2, attività 1, acqua piena, contraerea 3). Otto Lancaster, tutti con l'Upkeep: AJ-G di Gibson nel Cerchio vicino, gli altri nel Cerchio lontano; AJ-M di Hopgood è già danneggiato. Equipaggi veterani tranne AJ-J e AJ-N (esperti). Gli Upkeep rimasti proseguono verso la Eder. Il carburante finisce al terzo turno 8.
[b]2 · Attacco alla diga della Eder[/b] (turno 5, nebbia, allerta 2, ricognizione 2, nessuna contraerea). AJ-G senza Upkeep (fa da scorta e osserva), AJ-L, AJ-N e AJ-Z con l'Upkeep. Attenzione al Michelskopf.
[b]3 · Primo attacco alla Sorpe[/b] (turno 3, nebbia, allerta 1). AJ-T di McCarthy, esperto e danneggiato, con il puntatore Johnson. Sulla Sorpe non c'è la zona vicina e le luci Aldis non contano.
[b]4 · Secondo attacco alla Sorpe[/b] (turno 3, nebbia con -2 alla visibilità, allerta 3, attività 2, un razzo Very sul turno 2). AJ-F di Brown con il puntatore Oancia. Sulla diga c'è già l'Upkeep di McCarthy (danno coperto). Dopo il primo turno 8: -1 al rientro.
[b]5 · Attacco alla Ennepe?[/b] (turno 5, nebbia -2, allerta 3, ricognizione 1). AJ-O di Townsend, equipaggio recluta, con il puntatore Franklin. Nebbia di guerra: a ogni avvicinamento un dado, pari Ennepe (mappa della Möhne), dispari Bever (mappa della Sorpe).
  [b]Prima partita[/b]: equipaggio veterano, sereno, allerta 1, solo la Ennepe.

Il rapporto finale usa le etichette dei Debriefing Chart del libro degli scenari.""",

"Volo": """[b]Scenari di volo (6-9)[/b] - I Lancaster partono da Scampton e attraversano sei zone: Inghilterra, Costa inglese, Mare del Nord, Costa olandese, Ruhr e Weser. Ogni [b]turno di volo[/b] dura un'ora (dalle 21:00 alle 05:00; i turni 6-8 hanno -2 alla visibilità, il turno 9 è sempre nebbia).

[b]Sequenza del turno di volo[/b]
[b]1. Coordinamento (F1)[/b] - riordinare un'onda scompaginata, unire un Lancaster isolato a un'onda con lo stesso bersaglio, formare una nuova onda con due isolati: 2 dadi contro la peggiore abilità di navigazione (+1 se il capo è veterano). Con la radio rotta non si può.
[b]2. Radiotelegrafia (F2)[/b] - nuovo bersaglio principale a un'onda o a un Lancaster: 4 o meno non ricevuto · 5-6 frainteso (1 rientro, 2-3 diga con meno ricognizione, 4-5 con più ricognizione, 6 bersaglio di riserva) · 7 disturbato, si ritrasmette con +1 · 8+ ricevuto. Negli scenari 6 e 7 la radio tace finché il bersaglio principale non è aperto; negli scenari 8 e 9 dal turno 5.
[b]3. Movimento (F3)[/b] - un'onda o un Lancaster avanza di una zona verso il proprio bersaglio. Chi non ha più l'Upkeep rientra (tranne il capo di un'onda). Chi è danneggiato, con motore guasto, luci Aldis guaste o radio rotta può rientrare. Dal turno 7 si può puntare sul bersaglio di riserva. Partenza ritardata: fermo per un turno.
[b]4. Navigazione (F4)[/b] - 2 dadi contro l'abilità di navigazione del capo (recluta 8, esperto 7, veterano 6): +1 navigatore specialista, -1 per ogni errore di rotta, fotoelettrica, bussola deviata. Un'onda che fallisce perde la formazione; se era già scompaginata, un aereo si perde. Un isolato che fallisce finisce tra i dispersi; dai dispersi esce con un controllo riuscito, altrimenti tabella dei dispersi.
[b]5. Pericoli (F5)[/b] - Costa inglese 1, Mare del Nord 2 (gialli, non evitabili); Costa olandese 3, Ruhr 2, Weser 2 (azzurri e blu) più 1 per ogni onda o isolato nella zona e più il livello d'allerta. Si dividono il più possibile alla pari fra le onde e gli isolati.
[b]6. Evitare (F6)[/b] - nelle zone ostili si tolgono tanti pericoli quanto la ricognizione della zona; si vede solo il fronte (sagoma d'aereo, cannone, fascio di luce, palloni, tralicci, punto di domanda). Knight e McCarthy possono schivare un pericolo una volta. Un caccia sullo stesso gruppo di una contraerea si ritira.
[b]7. Risolvere (F7)[/b] - i pericoli si dividono fra i Lancaster dell'onda (al massimo 3 a testa) e si girano: contraerea (con azione evasiva tra i dispersi), caccia notturni, palloni, schianti, fotoelettriche (controllo di navigazione), uccelli; oppure guasti che restano attaccati (radio, bussola, Merlin, comandi, sgancio, luci Aldis, errore di rotta, equipaggio inabile, partenza ritardata). Il veterano o un pilota specialista salvano con un 6 i pericoli V.
[b]8. Acquisizione del bersaglio (F8)[/b] - nella zona del bersaglio: 2 dadi contro la ricognizione di zona più diga (0-1: 11 · 2: 10 · 3: 9 · 4: 7 · 5: 6 · 6+: 4). Se fallisce si può insistere con un controllo di navigazione.
[b]9. Mappa del bersaglio (F9)[/b] - per ogni diga raggiunta si giocano fino a 8 turni d'attacco, come negli scenari 1-5. Un'onda in buon ordine entra coordinata (pari Cerchio vicino, dispari lontano, il capo vicino); gli altri arrivano a un turno d'attacco tirato a caso. Dopo il turno 8 l'azione riprende nel turno di volo successivo. Chi vede la breccia passa al bersaglio secondario o di riserva.
[b]10. Fine del turno[/b] - una breccia o un attacco di caccia alzano l'allerta di 1; l'attività di ogni diga scende di 1.

Alle 05:00 tutti rientrano. Poi rientro alla base (con il modificatore della zona), ricognizione del mattino e rapporto.""",

"Campagna": """[b]Scenario 10 · Operazione Chastise (campagna)[/b] - Prima del raid ci sono fino a quattro [b]turni di pianificazione[/b] di due settimane (luna, senza luna, luna, senza luna). Si parte con 60 RP; all'inizio del turno 2 ne arrivano altri 60. Al turno 4 il raid parte per forza. Con il raid in un turno senza luna: -1 alla navigazione e allo sgancio e acquisizione del bersaglio più difficile.

[b]Personale di terra[/b] - sei squadre, ognuna con maneggio, erk e sortita (più bassi quando è affaticata). In ogni fase una squadra libera si [b]dedica[/b] a un compito; per spostarla a un altro compito nello stesso turno la si [b]trasferisce[/b] e si affatica per sempre. L'armiere esperto evita una volta la fatica.

[b]1. Requisizioni (P1)[/b] - chiedere RP al Comando (dado pari 30, dispari 20; +1 al rischio), requisire squadre di terra, e solo nel primo turno gli equipaggi (recluta 1 RP, esperto 2, veterano 3; ogni sei equipaggi arriva uno specialista). Lancaster e Upkeep costano 1 RP l'uno, fino al maneggio delle squadre dedicate alle requisizioni.
[b]2. Sicurezza (P3)[/b] - prima si può girare un segnalino giocato in un turno precedente, poi giocarne uno nuovo: Voce sulla Tirpitz (gratis, rischio -1; girato Inganno Tirpitz, 5 RP, -1/-3), Polizia in più (5 RP, -2; girato Trasferire la barista, 5 RP, -1 e allontana la spia), Trasferire il 57° Squadron (15 RP e una squadra di terra, -2/-4; girato Quarantena: niente più RP né squadre, allontana la spia, niente bonus Wallis, +1/-3/-5).
[b]3. Addestramento[/b] - due specialità (navigazione, quota e velocità, puntamento e sgancio); con l'addestramento extra (5 RP) una terza o la stessa due volte e uno specialista. Un dado per ogni tipo di equipaggio e specialità sulla tabella dell'addestramento: livelli guadagnati, schianti, danni, riposo e specialisti. -1 senza squadra dedicata, -1 se gli equipaggi sono almeno il doppio dei Lancaster integri; +1 navigazione con la ricognizione in tutte le zone ostili, +1 quota con le luci Aldis, +1 puntamento con il mirino Dann.
[b]4. Modifiche (P5)[/b] - ogni squadra dedicata tira tanti dadi quanti i suoi erk, più un dado per RP: radio VHF con un 6, luci Aldis e mirino Dann con due 6 (si accumulano). Riparazioni: tanti aerei quanti gli erk, 1 RP l'uno. Senza radio VHF non c'è il coordinamento in volo.
[b]5. Ricognizione (P7-P8)[/b] - zone ostili 5 RP (livello massimo 3), dighe 1 RP (massimo 4), una volta per turno. La prima foto rivela difese e acqua; le successive possono solo abbassare le difese note e alzare l'acqua.

[b]Preparazione del volo[/b] - controllo degli aerei e degli Upkeep (2 dadi, +2 per squadra fresca dedicata, +1 per affaticata, -1 con la spia), controllo degli equipaggi (-1 per addestramento extra, +1 per tipo riposato), briefing con le ultime foto delle dighe e il [b]rischio per la sicurezza[/b]: turni, richieste, squadre, ricognizioni alte, bonus Wallis, veterani e spia contro le misure di sicurezza. Il rischio dà l'allerta iniziale e il modificatore della [b]sorpresa[/b]. Poi la [b]sortita[/b]: si formano le onde (bersaglio principale e secondario) o si mandano Lancaster isolati; la capacità di sortita delle squadre dice quanti aerei decollano in ogni turno di volo.

[b]Sorpresa alle dighe (P10)[/b] - alla prima onda che arriva su una diga si gira il segnalino di ricognizione: l'acqua piena può essere scesa, e con 2 dadi + modificatore sotto il numero indicato dall'icona della traccia le difese sono state rinforzate (e può esserci un caccia nei paraggi). Le dighe con palloni di sbarramento li fanno pesare nella zona ravvicinata e nella risalita.

[b]Bonus Wallis[/b] - se i livelli di quota e velocità dei tre tipi di equipaggio arrivano a 12, ogni Upkeep vale il più alto dei due valori.
""",
"Note": """Versione digitale per uso personale di [b]Enemy Coast Ahead: The Dambuster Raid[/b] (GMT Games, 2014), progetto e grafica di Jeremy White. Mappa e pedine vengono dal modulo Tabletop Simulator; caselle, segnalini e testi sono ridisegnati in italiano.

[b]Cosa c'è[/b]: gli scenari d'attacco 1-5 (regole 1.0-5.0) e gli scenari di volo 6-9 (regole 6.0-7.10), con le tabelle A1-A14, F1-F9 ed E1-E3, le tre tazze dei pericoli (64 segnalini), gli specialisti storici, il Michelskopf, la nebbia di guerra della Ennepe, il rientro alla base, la ricognizione del mattino e il rapporto.
[b]Cosa manca per ora[/b]: la campagna (scenario 10, con i turni di pianificazione) e le regole opzionali (alta quota).
[b]Nei voli[/b]: l'attacco di un caccia notturno sulla mappa di volo abbatte il Lancaster; la ricognizione delle zone è quella iniziale (2); i Lancaster della forza diversiva e della riserva seguono la lettura più probabile del libro degli scenari.

[b]Scelte di conversione[/b]
- Il libro degli scenari disponibile è una scansione poco leggibile: le combinazioni dei rapporti finali (Debriefing Chart) sono ricostruite in modo coerente con le etichette originali, e anche alcuni valori di partenza (contraerea della Möhne, specialisti di ciascun Lancaster) seguono la lettura più probabile.
- Gibson (comandante) può far ripetere il tiro di sgancio, della contraerea, del Michelskopf o del caccia notturno.
- Le luci Aldis si decidono all'inizio di ogni avvicinamento e restano così fino alla risalita.

Font: Josefin Sans (titoli), Source Sans 3 (testo), Crimson Pro e Special Elite, licenze OFL e Apache.""",
}
