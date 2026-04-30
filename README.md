# Galaxy News Network (GNN) — X4 Foundations

Mod editoriale per X4: trasforma gli eventi della galassia in un palinsesto di notizie (battaglie, mercati, guerre dinamiche, territori, maree, taglie) consegnate al **logbook** e a un **footer pop-up live**.

- **Versione:** 1.10
- **Autore:** Askeladd
- **Pipeline:** 100% Mission Director (MD-puro). Nessun bridge nativo, nessun DLL, nessun Lua richiesto.

## Dipendenze

| Mod | Tipo | Note |
|---|---|---|
| **SirNukes Mod Support APIs** (`ws_2042901274`) | opzionale | Abilita il menu di configurazione (Simple Menu API). Senza, GNN gira con i default. |
| **kuertee UI Extensions and HUD** | opzionale | Migliora la resa del footer/notifiche. |

## Canali editoriali

| Canale | Cosa pubblica |
|---|---|
| **Battle Tracker** | Apertura, escalation e chiusura di battaglie sopra una soglia di score. |
| **Market** | Digest periodico di scarsita, sovrapproduzioni, eventi commerciali. |
| **Bounty** | Mandati di cattura e taglie significative, con cooldown separati per logbook e footer. |
| **Dynamic War** | Sintesi strategiche delle guerre tra fazioni. |
| **War History** | Riepiloghi narrativi di campagne concluse. |
| **Territory** | Cambi di proprieta dei settori. |
| **Tide alerts** | Allerta maree (Avarice). |

## Settings (Settings > GNN)

- **General:** Master switch, Live footer mode (off/important/normal/full), Logbook output, Debug mode.
- **Editorial Priority:** densita per ogni canale.
- **Battle Tracker:** soglie minimum/escalation score, debug trace.
- **Bounty:** modalita feed + cooldown logbook/live.
- **Market:** modalita feed + cooldown live + filtro merci comuni.
- **Diagnostics:** **Run self-test** — emette una notizia sintetica per ogni canale principale (battle/market/territory/tide) per verificare la pipeline end-to-end.

## Welcome headline

Al primo caricamento di una save dopo l'installazione (o dopo aggiornamento di versione), GNN scrive una voce nel logbook che conferma che il sistema editoriale e attivo. Si pubblica una sola volta per versione.

## Anti-doppione cross-canale

Le storie di battaglia e di guerra dinamica condividono un sistema di **claim** (`GNN_Try_Claim_FactionPair`): la prima storia che pubblica una coppia di fazioni in un settore impedisce alle altre di duplicare lo stesso evento per 5 minuti. L'**escalation** bypassa il claim per non perdere svolte importanti.

## Quiet mode in combat

Quando il giocatore e sotto attacco (`player.entity.attackers.count > 0`), il footer pop-up viene soppresso per ridurre la fatigue UI. Il logbook continua a ricevere le voci. Comportamento controllato da `$GNNTuning.$FooterQuietInCombat`.

## Troubleshooting

1. **Niente notizie?** Apri Settings > GNN > Diagnostics > Run self-test. Devono comparire 4 voci `[SELFTEST]` nel logbook.
2. **Pop-up assenti ma logbook ok:** controlla se sei in combattimento (quiet mode) o `LiveFooterMode = off`.
3. **Spam di notizie banali:** abilita `Ignore common wares unless repeated` in Market, o sposta i canali su `digest`/`important only`.
4. **Log diagnostici:** imposta `Debug mode = full` e leggi  
   `%userprofile%\Documents\Egosoft\X4\xxxxxxx\save\gnn\gnnlog.log`.
5. **Doppione cross-canale:** atteso solo se trascorrono >5 min tra le pubblicazioni della stessa coppia di fazioni nello stesso settore.

## Architettura interna (per modder)

- **Tuning centralizzato:** `namespace.static.$GNNTuning` raccoglie 16+ costanti (cooldown, soglie, dedupe). Definito in `GNN_Defaults_Tuning`.
- **Settings persistenti:** `namespace.static.$GNNSettings`. Inizializzato da `GNN_Ensure_Settings`.
- **Desk uniforme:** ogni notizia usa `GNN_ResolveDesk` per scegliere il "desk" coerente per faction/topic.
- **Menu helpers:** `GNN_Menu_Add_Header / Toggle / Dropdown / Action` — il primo "Action" introdotto con il self-test.
- **Self-test:** cue `GNN_SelfTest_Run`. Trigger via menu o `signal_cue_instantly cue="md.GalaxyNewsNetwork.GNN_SelfTest_Run"`.

## Changelog 1.10

- Rimosso bridge x4native (mod 100% MD).
- Centralizzato tuning in `$GNNTuning`.
- Anti-doppione cross-canale battle/dynamic-war.
- Quiet mode footer in combat.
- `GNN_ResolveDesk` consolidato in 11 call site.
- Aggiunta sezione Diagnostics con self-test.
- Aggiunta welcome headline versionata.
- Pulizia diagnostica: rimosse voci di logbook spam dal probe battle.
