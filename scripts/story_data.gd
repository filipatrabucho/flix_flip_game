extends RefCounted
## "A Oficina do Avô Júlio" — story characters, chapters and dialogue (PT + EN).

const CHARACTERS := {
	"julio": {"name": "Avô Júlio", "color": Color("d9a441")},
	"armando": {"name": "Sr. Armando", "color": Color("7986cb"), "look": {"skin": Color("e0b08c"), "hair": Color("8a8f96"), "shirt": Color("2f3b4c"), "pants": Color("3b3b3b"), "hair_style": 0, "extras": ["glasses", "beard"], "height": 0.98}},
	"rosa": {"name": "Dona Rosa", "color": Color("f06292"), "look": {"skin": Color("f2d0b5"), "hair": Color("8a8f96"), "shirt": Color("e8e3d9"), "pants": Color("6b5a45"), "hair_style": 2, "extras": ["apron"], "height": 0.94}},
	"leo": {"name": "Leo", "color": Color("4dd0e1"), "look": {"skin": Color("c68863"), "hair": Color("1a1a1a"), "shirt": Color("e74c3c"), "pants": Color("1f2a44"), "hair_style": 3, "extras": [], "height": 0.86}},
	"vitor": {"name": "Sr. Vítor Santos", "color": Color("e5533d"), "look": {"skin": Color("eac3a0"), "hair": Color("1c1c1c"), "shirt": Color("1f2937"), "pants": Color("1f2937"), "hair_style": 0, "extras": ["glasses"], "height": 1.04}},
	"spy": {"name": "Cliente misterioso", "color": Color("90a4ae"), "look": {"skin": Color("d7a882"), "hair": Color("5a3b22"), "shirt": Color("3d4a3a"), "pants": Color("2b2b2b"), "hair_style": 0, "extras": ["glasses", "beard"], "height": 0.97}},
	"lurdes": {"name": "Avó Lurdes (gravação)", "color": Color("f3a6c8")},
	"marta": {"name": "Marta Lopes", "color": Color("ba68c8"), "look": {"skin": Color("8d5a3b"), "hair": Color("2b1d14"), "shirt": Color("8e6fc4"), "pants": Color("2d3a4f"), "hair_style": 1, "extras": ["glasses"], "height": 1.0}},
}

const RENT := 300
const RENT_DAY := 3
const BUILDING_PRICE := 3000
const C5_DELIVERIES := 8
const FAIR_TARGET := 5

## Each chapter: id, title, goal text. Progress is checked by the game.
const CHAPTERS := [
	{"id": "c1", "title": {"pt": "Capítulo 1 — A Oficina do Avô", "en": "Chapter 1 — Grandpa's Workshop"},
	 "goal": {"pt": "Repara e entrega 2 equipamentos", "en": "Repair and deliver 2 devices"}},
	{"id": "c2", "title": {"pt": "Capítulo 2 — A Renda", "en": "Chapter 2 — The Rent"},
	 "goal": {"pt": "Junta 300 € para a renda até ao fim do Dia 3", "en": "Save €300 for the rent by the end of Day 3"}},
	{"id": "c3", "title": {"pt": "Capítulo 3 — Boca a Boca", "en": "Chapter 3 — Word of Mouth"},
	 "goal": {"pt": "Faz 6 entregas com reputação ★4.5 ou mais", "en": "Make 6 deliveries with a ★4.5+ reputation"}},
	{"id": "c4", "title": {"pt": "Capítulo 4 — O Portátil do Avô", "en": "Chapter 4 — Grandpa's Laptop"},
	 "goal": {"pt": "Repara o portátil antigo do Avô Júlio", "en": "Repair Grandpa Júlio's old laptop"}},
	{"id": "c5", "title": {"pt": "Capítulo 5 — A Concorrência", "en": "Chapter 5 — The Competition"},
	 "goal": {"pt": "A MegaFix abriu na vila. Faz 8 entregas com ★4.3 ou mais", "en": "MegaFix opened in town. Make 8 deliveries with a ★4.3+ reputation"}},
	{"id": "c6", "title": {"pt": "Capítulo 6 — Não Estás Sozinho", "en": "Chapter 6 — You're Not Alone"},
	 "goal": {"pt": "Contrata o teu primeiro funcionário (tecla F)", "en": "Hire your first employee (F key)"}},
	{"id": "c7", "title": {"pt": "Capítulo 7 — O Rádio da Avó Lurdes", "en": "Chapter 7 — Grandma Lurdes' Radio"},
	 "goal": {"pt": "Repara o rádio que o avô construiu para a avó", "en": "Repair the radio grandpa built for grandma"}},
	{"id": "c8", "title": {"pt": "Capítulo 8 — O Prédio", "en": "Chapter 8 — The Building"},
	 "goal": {"pt": "Junta 3000 € para comprares o prédio antes da MegaFix", "en": "Save €3000 to buy the building before MegaFix does"}},
	{"id": "c9", "title": {"pt": "Capítulo 9 — A Feira da Reparação", "en": "Chapter 9 — The Repair Fair"},
	 "goal": {"pt": "Desafio da feira: faz 5 entregas num só dia", "en": "Fair challenge: make 5 deliveries in a single day"}},
	{"id": "c10", "title": {"pt": "Capítulo 10 — O Telefone do Vítor", "en": "Chapter 10 — Vítor's Phone"},
	 "goal": {"pt": "Repara o telefone antigo do Sr. Vítor", "en": "Repair Mr. Vítor's old phone"}},
	{"id": "free", "title": {"pt": "Modo Livre", "en": "Free Play"},
	 "goal": {"pt": "Faz da oficina a melhor da vila!", "en": "Make this the best workshop in town!"}},
]

## Dialogue scenes: list of [speaker, {pt, en}]
const SCENES := {
	"intro": [
		["julio", {"pt": "Se estás a ler esta carta, é porque a oficina agora é tua.", "en": "If you're reading this letter, the workshop is yours now."}],
		["julio", {"pt": "Passei quarenta anos nesta bancada a dar vida nova a rádios, telefones e computadores. Cada aparelho tem uma história — e uma pessoa à espera dele.", "en": "I spent forty years at this bench giving new life to radios, phones and computers. Every device has a story — and someone waiting for it."}],
		["julio", {"pt": "A vila mudou, e a oficina ficou fechada tempo demais. Mas eu sei que tens jeito de mãos e paciência de sobra.", "en": "The town has changed, and the workshop stayed closed for too long. But I know you have skilled hands and patience to spare."}],
		["julio", {"pt": "Abre a porta. Ouve as pessoas. Repara com carinho. O resto vem por acréscimo.\n— Avô Júlio", "en": "Open the door. Listen to people. Repair with care. The rest will follow.\n— Grandpa Júlio"}],
	],
	"armando_arrives": [
		["armando", {"pt": "Então és tu o neto do Júlio... Sou o Armando, o dono deste espaço.", "en": "So you're Júlio's grandkid... I'm Armando, I own this place."}],
		["armando", {"pt": "Vou ser direto: a renda são 300 €, e vence ao fim do Dia 3. Sem renda, a oficina fecha de vez.", "en": "I'll be straight with you: the rent is €300, due at the end of Day 3. No rent, and the workshop closes for good."}],
		["armando", {"pt": "O teu avô nunca falhou um pagamento. Vamos ver se sais a ele.", "en": "Your grandfather never missed a payment. Let's see if you take after him."}],
	],
	"rosa_accept": [
		["rosa", {"pt": "Ai, que alegria ver esta porta aberta outra vez! Sou a Rosa, da florista aqui ao lado.", "en": "Oh, what a joy to see this door open again! I'm Rosa, from the flower shop next door."}],
		["rosa", {"pt": "Deixei cair o telemóvel dentro de um vaso... O teu avô arranjava-me tudo. Confio em ti!", "en": "I dropped my phone into a flower pot... Your grandpa used to fix everything for me. I trust you!"}],
	],
	"rosa_deliver": [
		["rosa", {"pt": "Está perfeito! Vou contar a toda a gente do mercado.", "en": "It's perfect! I'm telling everyone at the market."}],
		["rosa", {"pt": "Sabes, o Júlio dizia sempre: «Não há nada que não se arranje com tempo e um bom chá.»", "en": "You know, Júlio always said: \"There's nothing that can't be fixed with time and a good cup of tea.\""}],
	],
	"c1_done": [
		["julio", {"pt": "(Encontras um envelope na gaveta do balcão, com a letra do avô.)", "en": "(You find an envelope in the counter drawer, in grandpa's handwriting.)"}],
		["julio", {"pt": "As primeiras reparações são as mais difíceis. Depois, as mãos lembram-se sozinhas. Estou orgulhoso de ti.", "en": "The first repairs are the hardest. After that, your hands remember on their own. I'm proud of you."}],
	],
	"rent_paid": [
		["armando", {"pt": "300 €, certinhos. Hm.", "en": "€300, exactly. Hm."}],
		["armando", {"pt": "Já não via a vila a falar desta oficina há anos. Talvez fiques mais tempo do que pensei.", "en": "I haven't heard the town talk about this workshop in years. Maybe you'll stay longer than I thought."}],
	],
	"rent_short": [
		["armando", {"pt": "Não chega... Mas vejo que trabalhaste a sério. Pagas o que tens e dou-te mais uns dias para o resto.", "en": "That's not enough... But I can see you worked hard. Pay what you have and I'll give you a few more days for the rest."}],
		["armando", {"pt": "Não digas a ninguém que fiquei mole.", "en": "Don't tell anyone I went soft."}],
	],
	"leo_accept": [
		["leo", {"pt": "Olá! O meu comando está possuído! A personagem anda sozinha e perdi o torneio da escola!", "en": "Hi! My controller is possessed! My character walks on its own and I lost the school tournament!"}],
		["leo", {"pt": "A Dona Rosa disse que aqui arranjam tudo. É verdade?", "en": "Mrs. Rosa said you can fix anything here. Is that true?"}],
	],
	"leo_deliver": [
		["leo", {"pt": "FUNCIONA! Vou dizer a todos os meus amigos para trazerem os comandos!", "en": "IT WORKS! I'm telling all my friends to bring their controllers!"}],
	],
	"marta_arrives": [
		["marta", {"pt": "Olá! Sou a Marta, do Jornal da Vila. Toda a gente fala da oficina reaberta.", "en": "Hi! I'm Marta, from the Town Gazette. Everyone's talking about the reopened workshop."}],
		["marta", {"pt": "Posso escrever um artigo sobre ti? «O neto do Júlio devolve a vida aos aparelhos da vila.» Que tal?", "en": "Can I write an article about you? \"Júlio's grandkid brings the town's devices back to life.\" How does that sound?"}],
		["marta", {"pt": "Prepara-te — amanhã vais ter muito mais clientes!", "en": "Get ready — you'll have many more customers tomorrow!"}],
	],
	"armando_laptop": [
		["armando", {"pt": "Lê-se o jornal e vê-se a tua cara na primeira página... O Júlio ia rir-se.", "en": "I open the paper and there's your face on the front page... Júlio would have laughed."}],
		["armando", {"pt": "Isto era dele. O portátil antigo. Nunca tive coragem de o ligar. Já não arranca.", "en": "This was his. His old laptop. I never had the courage to turn it on. It doesn't boot anymore."}],
		["armando", {"pt": "Fomos amigos cinquenta anos. Se houver alguma coisa lá dentro... gostava de ver.", "en": "We were friends for fifty years. If there's anything left in there... I'd like to see it."}],
	],
	"armando_deliver": [
		["armando", {"pt": "(No ecrã aparece uma pasta: «Para quem ficar com a oficina».)", "en": "(A folder appears on the screen: \"For whoever takes over the workshop\".)"}],
		["julio", {"pt": "Se conseguiste abrir isto, é porque já és um verdadeiro técnico. O Armando deve estar aí ao teu lado, a fingir que não está emocionado.", "en": "If you managed to open this, you're a real technician now. Armando must be standing right next to you, pretending he's not emotional."}],
		["julio", {"pt": "Armando, velho amigo: cuida do meu neto. E baixa-lhe a renda, sovina!", "en": "Armando, old friend: look after my grandkid. And lower the rent, you old miser!"}],
		["armando", {"pt": "...Aquele teimoso. Está bem, está bem. A partir de hoje a renda fica a metade.", "en": "...That stubborn man. Fine, fine. From today the rent is half."}],
		["armando", {"pt": "Bem-vindo a casa, técnico.", "en": "Welcome home, technician."}],
		["armando", {"pt": "...Há mais uma coisa. Ontem veio cá um senhor de fato, da MegaFix. Querem abrir uma loja enorme no fundo da rua.", "en": "...There's one more thing. A man in a suit came by yesterday, from MegaFix. They want to open a huge store at the end of the street."}],
		["armando", {"pt": "Reparações em série, peças baratas, tudo a correr. Não gosto nada disto. Prepara-te.", "en": "Assembly-line repairs, cheap parts, everything rushed. I don't like it one bit. Get ready."}],
	],
	"vitor_arrives": [
		["vitor", {"pt": "Bom dia! Vítor Santos, diretor regional da MegaFix. Que espaço... pitoresco.", "en": "Good morning! Vítor Santos, regional director at MegaFix. What a... quaint little place."}],
		["vitor", {"pt": "Abrimos ontem, ao fundo da rua. Reparamos em 30 minutos, com garantia. Os clientes adoram rapidez.", "en": "We opened yesterday at the end of the street. 30-minute repairs, with a warranty. Customers love speed."}],
		["vitor", {"pt": "Daqui a um mês ninguém se lembra desta oficina. Mas se quiseres vender, ligo-te. Tenho um cartão aqui algures.", "en": "In a month nobody will remember this workshop. But if you want to sell, I'll call you. I have a card here somewhere."}],
	],
	"spy_accept": [
		["spy", {"pt": "Olá. Hm. O meu telemóvel desliga-se sozinho. Quanto tempo demora? E que peças usam?", "en": "Hello. Hm. My phone keeps shutting itself off. How long will it take? And what parts do you use?"}],
		["spy", {"pt": "(Ele tira notas num caderninho enquanto olha para a bancada.)", "en": "(He takes notes in a little notebook while staring at your bench.)"}],
	],
	"spy_deliver": [
		["spy", {"pt": "Bateria nova, colada direitinha, e até limpaste a porta de carregamento...", "en": "New battery, glued in neatly, and you even cleaned the charging port..."}],
		["spy", {"pt": "Tenho de confessar: trabalho na MegaFix. O Sr. Vítor mandou-me ver como trabalhas.", "en": "I have to confess: I work at MegaFix. Mr. Vítor sent me to see how you work."}],
		["spy", {"pt": "Lá trocamos o telemóvel inteiro e cobramos o triplo. Tu arranjaste-o. Vou dizer-lhe a verdade... e talvez procurar outro emprego.", "en": "Over there we swap the whole phone and charge triple. You fixed it. I'll tell him the truth... and maybe look for another job."}],
	],
	"c5_done": [
		["marta", {"pt": "Fiz um inquérito na vila: 8 em cada 10 pessoas preferem a tua oficina à MegaFix!", "en": "I ran a survey in town: 8 out of 10 people prefer your workshop to MegaFix!"}],
		["marta", {"pt": "Mas tens filas à porta. Sozinho não vais aguentar muito tempo. Já pensaste em contratar alguém?", "en": "But you have queues at the door. You won't last long on your own. Have you thought about hiring someone?"}],
	],
	"c6_done": [
		["rosa", {"pt": "Que bom ver gente nova a trabalhar aqui! O Júlio sonhava com isto.", "en": "How lovely to see new people working here! Júlio used to dream about this."}],
		["rosa", {"pt": "Olha... nunca te contei. Quando a tua avó Lurdes morreu, o Júlio deixou-me guardar uma coisa: o rádio que ele construiu para ela.", "en": "Listen... I never told you. When your grandma Lurdes passed away, Júlio asked me to keep something: the radio he built for her."}],
		["rosa", {"pt": "Está mudo há anos. Ele dizia que tinha lá dentro «a voz mais bonita do mundo». Traz-to amanhã?", "en": "It's been silent for years. He used to say it held \"the most beautiful voice in the world\". Shall I bring it tomorrow?"}],
	],
	"rosa_radio_accept": [
		["rosa", {"pt": "Aqui está. Tem cuidado, por favor... é a coisa mais preciosa que tenho.", "en": "Here it is. Please be careful... it's the most precious thing I own."}],
	],
	"rosa_radio_deliver": [
		["rosa", {"pt": "(O rádio aquece devagar. Ouve-se um estalido... e depois uma voz de mulher, gravada numa fita escondida lá dentro.)", "en": "(The radio warms up slowly. A crackle... and then a woman's voice, recorded on a tape hidden inside.)"}],
		["lurdes", {"pt": "Júlio, meu amor, se estás a ouvir isto é porque o arranjaste outra vez. Tu arranjas sempre tudo.", "en": "Júlio, my love, if you're hearing this, you've fixed it again. You always fix everything."}],
		["lurdes", {"pt": "Promete-me que a oficina nunca fecha. Que vai sempre haver alguém a dar segundas vidas às coisas... e às pessoas.", "en": "Promise me the workshop never closes. That there will always be someone giving second lives to things... and to people."}],
		["rosa", {"pt": "(A Dona Rosa limpa as lágrimas.) Ela ia gostar tanto de ti.", "en": "(Mrs. Rosa wipes away her tears.) She would have loved you so much."}],
		["armando", {"pt": "(O Sr. Armando entra, sério.) Desculpem interromper. Tenho más notícias: a MegaFix quer comprar o prédio. Ofereceram-me muito dinheiro.", "en": "(Mr. Armando walks in, serious.) Sorry to interrupt. Bad news: MegaFix wants to buy the building. They offered me a lot of money."}],
		["armando", {"pt": "Estou velho e quero reformar-me. Mas prefiro vender-te a ti. Junta 3000 € e o prédio é teu. Não posso esperar para sempre.", "en": "I'm old and I want to retire. But I'd rather sell to you. Raise €3000 and the building is yours. I can't wait forever."}],
	],
	"armando_sell": [
		["armando", {"pt": "3000 €. Aqui tens a escritura. O prédio é teu — acabaram-se as rendas.", "en": "€3000. Here's the deed. The building is yours — no more rent."}],
		["armando", {"pt": "Liguei ao Vítor e disse-lhe que não. Ficou vermelho como um tomate. Valeu a pena só por isso.", "en": "I called Vítor and told him no. He turned as red as a tomato. It was worth it just for that."}],
		["marta", {"pt": "(A Marta aparece à porta, ofegante.) Novidades! Este sábado há a Feira da Reparação na praça. A MegaFix também vai.", "en": "(Marta appears at the door, out of breath.) News! This weekend there's a Repair Fair in the square. MegaFix is going too."}],
		["marta", {"pt": "Quem fizer mais reparações num dia ganha o troféu da vila. Mostra-lhes do que és capaz!", "en": "Whoever makes the most repairs in one day wins the town trophy. Show them what you can do!"}],
	],
	"fair_win": [
		["marta", {"pt": "CINCO entregas num dia, todas impecáveis! A MegaFix só fez três... e duas voltaram estragadas.", "en": "FIVE deliveries in one day, all spotless! MegaFix only made three... and two came back broken."}],
		["marta", {"pt": "O troféu da Feira da Reparação é teu! Vai para a primeira página, outra vez.", "en": "The Repair Fair trophy is yours! You're on the front page again."}],
		["vitor", {"pt": "(O Sr. Vítor aproxima-se, sem o sorriso de vendedor.) ...Parabéns. A sério.", "en": "(Mr. Vítor comes over, without his salesman smile.) ...Congratulations. Really."}],
	],
	"vitor_accept": [
		["vitor", {"pt": "Isto é embaraçoso. Era o telefone do meu pai. Na MegaFix disseram-me que «não compensa arranjar» e ofereceram-me um novo.", "en": "This is embarrassing. It was my father's phone. At MegaFix they told me it's \"not worth repairing\" and offered me a new one."}],
		["vitor", {"pt": "Não quero um novo. Quero este. Consegues?", "en": "I don't want a new one. I want this one. Can you do it?"}],
	],
	"vitor_deliver": [
		["vitor", {"pt": "(Ele roda o disco e o telefone toca como antigamente. Fica calado uns segundos.)", "en": "(He turns the dial and the phone rings like it used to. He stays silent for a few seconds.)"}],
		["vitor", {"pt": "O meu pai ligava-me deste telefone todos os domingos. Obrigado.", "en": "My father called me from this phone every Sunday. Thank you."}],
		["vitor", {"pt": "Vou propor à MegaFix que mande para cá as reparações difíceis. Em vez de concorrentes... parceiros?", "en": "I'm going to suggest MegaFix sends the tricky repairs here. Instead of competitors... partners?"}],
		["julio", {"pt": "(Na parede, a fotografia do avô Júlio parece sorrir um pouco mais.)", "en": "(On the wall, grandpa Júlio's photo seems to smile a little wider.)"}],
	],
}

## Story orders (fixed customer + fault)
const STORY_ORDERS := {
	"rosa": {"fault": "phone_screen", "pay": 140, "complaint": {"pt": "Deixei cair o telemóvel dentro de um vaso de flores!", "en": "I dropped my phone into a flower pot!"}, "accept": "rosa_accept", "deliver": "rosa_deliver"},
	"leo": {"fault": "gamepad_drift", "pay": 45, "complaint": {"pt": "O meu comando anda sozinho! Perdi o torneio!", "en": "My controller moves on its own! I lost the tournament!"}, "accept": "leo_accept", "deliver": "leo_deliver"},
	"spy": {"char": "spy", "fault": "phone_battery", "pay": 90, "complaint": {"pt": "O telemóvel desliga-se sozinho. Quanto tempo demora?", "en": "My phone shuts itself off. How long will it take?"}, "accept": "spy_accept", "deliver": "spy_deliver"},
	"rosa_radio": {"char": "rosa", "fault": "radio_tube", "pay": 0, "complaint": {"pt": "O rádio da Lurdes. Está mudo há anos.", "en": "Lurdes' radio. It's been silent for years."}, "accept": "rosa_radio_accept", "deliver": "rosa_radio_deliver"},
	"vitor": {"fault": "rotary_dial", "pay": 120, "complaint": {"pt": "Era do meu pai. O disco não marca.", "en": "It was my father's. The dial won't dial."}, "accept": "vitor_accept", "deliver": "vitor_deliver"},
	"armando": {"fault": "laptop_ssd", "pay": 0, "complaint": {"pt": "Era do Júlio. Já não arranca.", "en": "It was Júlio's. It won't boot anymore."}, "accept": "armando_laptop", "deliver": "armando_deliver"},
}
