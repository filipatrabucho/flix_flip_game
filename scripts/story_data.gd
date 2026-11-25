extends RefCounted
## "A Oficina do Avô Júlio" — story characters, chapters and dialogue (PT + EN).

const CHARACTERS := {
	"julio": {"name": "Avô Júlio", "color": Color("d9a441")},
	"armando": {"name": "Sr. Armando", "color": Color("7986cb"), "look": {"skin": Color("e0b08c"), "hair": Color("8a8f96"), "shirt": Color("2f3b4c"), "pants": Color("3b3b3b"), "hair_style": 0, "extras": ["glasses", "beard"], "height": 0.98}},
	"rosa": {"name": "Dona Rosa", "color": Color("f06292"), "look": {"skin": Color("f2d0b5"), "hair": Color("8a8f96"), "shirt": Color("e8e3d9"), "pants": Color("6b5a45"), "hair_style": 2, "extras": ["apron"], "height": 0.94}},
	"leo": {"name": "Leo", "color": Color("4dd0e1"), "look": {"skin": Color("c68863"), "hair": Color("1a1a1a"), "shirt": Color("e74c3c"), "pants": Color("1f2a44"), "hair_style": 3, "extras": [], "height": 0.86}},
	"marta": {"name": "Marta Lopes", "color": Color("ba68c8"), "look": {"skin": Color("8d5a3b"), "hair": Color("2b1d14"), "shirt": Color("8e6fc4"), "pants": Color("2d3a4f"), "hair_style": 1, "extras": ["glasses"], "height": 1.0}},
}

const RENT := 300
const RENT_DAY := 3

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
	],
}

## Story orders (fixed customer + fault)
const STORY_ORDERS := {
	"rosa": {"fault": "phone_screen", "pay": 140, "complaint": {"pt": "Deixei cair o telemóvel dentro de um vaso de flores!", "en": "I dropped my phone into a flower pot!"}, "accept": "rosa_accept", "deliver": "rosa_deliver"},
	"leo": {"fault": "gamepad_drift", "pay": 45, "complaint": {"pt": "O meu comando anda sozinho! Perdi o torneio!", "en": "My controller moves on its own! I lost the tournament!"}, "accept": "leo_accept", "deliver": "leo_deliver"},
	"armando": {"fault": "laptop_ssd", "pay": 0, "complaint": {"pt": "Era do Júlio. Já não arranca.", "en": "It was Júlio's. It won't boot anymore."}, "accept": "armando_laptop", "deliver": "armando_deliver"},
}
