Modifiche fatte:
-Tutti i menu sono ora navigabili con E & Invio per accettare, WASD per navigare e ESC per tornare indietro o chiudere le finestre
-cambiato sprite ragno
-aggiunto tutorial dedicato
-cambiate collisioni ed attacchi di alcuni nemici
-aggiunto feedback visivo quando un nemico riceve danno
-aggiunto feedback sonoro quando un nemico riceve danno
-risolti molti bug che impedivano o alteravano il proseguimento del gioco
-aggiunto breve tutorial scritto per la modalità game & wait
-aggiunta nella modalità GAME & WAIT il tasto debug "O" per resettare il timer di attesa e dare 1 copia di tutti gli oggetti




Readme precedente
README
Qui di seguito tutte le modifiche e le aggiunte fatte per la parte riguardante la tesi di Savino Daniele:
-Si può notare un'aura attorno al personaggio quando si può interagire con qualcosa
-Trasferita la modalità di gioco a "ondate" direttamente nella parte di attesa
-Trasformata la modalità di gioco a ondate in una modalità endless "GAME & WAIT", una specie di modalità pomodoro in cui c'è prima lo svago e poi lo studio. 
-Approcciando la modalità Game & Wait (attivabile dai tavoli nella parte sinistra dell'hub) si sceglie quanto tempo si vuole giocare (massimo 15 min) e eventualmente si può aggiungere cosa si farà dopo durante l'attesa. Come detto si dovrà aspettare in seguito dopo aver giocato un tempo che va dal doppio al triplo del tempo inserito
Questo tempo viene decretato da quanto sarà bravo il giocatore durante la parte di game, più tempo resisterà meno tempo dovrà aspettare. in caso di sconfitta il tempo rimanente da giocare sarà sommato al countdown (il doppio del tempo che si era inserito) e si dovrà scontare questa attesa.
Ad esempio se si sceglie 2 minuti e si muore dopo 1 minuto avremo 4 minuti (2 min x 2) + 1 minuto rimanente = 5 minuti di countdown di attesa
-Durante l'attesa non è possibile giocare al game e ci sarà presentato un countdown da scontare in game.
-Il gioco ci suggerirà di fare attività creative o produttive durante l'attesa
-giocando il gioco si otterranno degli oggetti attivabili che avranno come durata tutta la prossima partita:
--Mela: aumenta leggermente gli hp di 10
--Carne: aumenta leggermente il danno di 5
--Pozione di rigenerazione: abilita una rigenerazione di vita di 2 hp/s
--Molla: fa saltare un po' più in alto
--Piuma: abilita il doppio salto
-I precedenti oggetti sono tutti attivabili dal menu inventario (apribile con TAB)
-Il gioco in se quindi consiste nel gioco consapevole dell'utente di un "X" minuti con una seguente attesa di X*2 + residui in cui il gioco stesso spingerà l'utente fare attività creative o utili. Ovviamente lo svolgimento o meno di queste ultime dipende dall'utente e il gioco svolge il semplice ruolo di aiutante che da una piccola spinta nella direzione giusta
-presente un log in cui si possono verificare tutte le precedenti partite (attivabile a destra dei tavoli, da alcuni libri su una cassa)
--Future aggiunte comprendono tutorial esaustivo in gioco, trama che possa offrire un contesto alle nostre azioni, nuove mappe, nuovi oggetti, una classifica con i record di "sopravvivenza" e altre possibili funzionalità che possano spingere il giocatore ad un uso consapevole.



Qui di seguito sono elencate tutte le modifiche e aggiunte che son state effettuate per quanto riguarda la parte d tesi d Trotta Alessio Lorenzo:
-Cambiato genere del gioco, da gioco esclusivamente a ondate a gioco platform con nemici a schermo
-Cambiata logica dei nemici se presenti nel livello platform per non attaccare il personaggio giocante sempre ma a partire dalla loro area
-Aggiunti 3 livelli platform + mini livello dov'è presente il boss finale della zona, se si sconfigge questo boss (hp = 250) si sbloccherà un cancello che poterà ad incontrare una ragazza che attiverà il trigger della vittoria
-Ad ogni fine livello, il giocatore sarà trasportato in un'area dove potrà fare tre delle seguenti cose: continuare, riposare ed aprire l'inventario:
	1) Se decidesse di continuare, il gioco avvierà immediatamente il livello successivo assegnando al giocatore (esclusivo al platform) uno di questi debuff:
		I) SLOW: la velocità del giocatore si dimezza
		II) LOW DAMAGE: l'attacco del giocatore verrà dimezzato
		III) ATTACK DELAY: viene imposto un delay tra tasto premuto e attacco del personaggio di 0.5 secondi
		IV) NO ROLL: viene tolta la possibilità di effettuare la rotolata
		V) NO JUMP: viene ridotta l'altezza del salto
		VI) HP DRAIN: ogni 5 secondi viene tolto 1 hp dal giocatore
		VII) INVERT COMMANDS: ogni secondo c'è il 50% che i comandi di sinistra e destra vengano invertiti
		VIII) ENEMY DAMAGE UP: Viene aumentato il danno dei nemici di 1.5x
		XI) SLIDING: Il personaggio scivola come se stesse camminando sul ghiaccio
		X) VIGNETTE: Si oscura circolarmente la vista del giocatore 
	2) Se si decidesse di riposare, scatta un timer di 5 minuti e si blocca il tasto continua, così facendo il nostro personaggio giocante si riposa e noi prendiamo una pausa.
		A riposo finito, il tasto continua viene sbloccato e si può premere continua, però, essendo che c'è stato il riposo, non da debuff
	3) A prescindere dalle due decisioni, si può aprire un'inventario di oggetti ottenuti dalla modalità ad ondate e possono essere usati sia per rigenerare hp, sia per dare altri buff
		Questo inventario NON potrà essere aperto durante le fasi di platform, relegandolo esclusivamente alla scena del riposo.

-Nell'exe presentato, oltre al tasto "Platform" che permette di azionare la modalità principale, nel menù c'è un livello aggiuntivo chiamato DebugDebuff, questo permette di testare e vedere la maggior parte dei debuff applicabili al personaggio
-Il gioco in sè dovrebbe scoraggiare l'utente a giocare compulsivamente al gioco, andando avanti senza fermarsi adeguatamente, fornendo un mezzo di pausa, sia ludica che reale, facendo legare il personaggio giocante all'utente che prova la demo.
-Future aggiunte comprendono una trama base per far comprendere all'utente lo scopo del viaggio, mappe nuove per far accumulare di più i debuff e nuovi nemici