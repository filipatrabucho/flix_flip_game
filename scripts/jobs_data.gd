extends RefCounted
## Devices, faults (repair procedures), spare parts and customers.

const DEVICES := {
	"laptop": {"name": "Portátil", "article": "o"},
	"phone": {"name": "Telemóvel", "article": "o"},
	"gamepad": {"name": "Comando", "article": "o"},
	"console": {"name": "Consola", "article": "a"},
	"handheld": {"name": "Consola portátil", "article": "a"},
	"rotary": {"name": "Telefone antigo", "article": "o"},
	"radio": {"name": "Rádio antigo", "article": "o"},
}

## Workshop upgrades (bought in the shop, saved, each adds a 3D prop)
const UPGRADES := {
	"screwdriver": {"name": "Chave de fendas elétrica", "desc": "Parafusos e montagens 35% mais rápidos.", "price": 120},
	"lamp": {"name": "Candeeiro LED de bancada", "desc": "Luz branca e forte: tudo 10% mais rápido.", "price": 80},
	"coffee": {"name": "Máquina de café", "desc": "Os clientes esperam mais 1 hora e dão mais gorjeta.", "price": 90},
	"speaker": {"name": "Coluna de som", "desc": "Música no balcão: gorjetas +10%.", "price": 60},
	"display": {"name": "Montra de equipamentos", "desc": "Mostra o teu trabalho: pagamentos +10%.", "price": 220},
	"neon": {"name": "Néon «Reparações» na montra", "desc": "Atrai quem passa: mais clientes por dia.", "price": 160},
}

## New products to resell on the shop's display stand (bought online in packs).
const PACK := 4
const PRODUCTS := {
	"earbuds": {"name": "Auriculares sem fios", "buy": 22, "sell": 45, "color": Color("ecf0f1"), "band": Color("3498db"), "size": Vector3(0.09, 0.12, 0.05)},
	"charger": {"name": "Carregador rápido USB-C", "buy": 7, "sell": 18, "color": Color("2c3e50"), "band": Color("f1c40f"), "size": Vector3(0.07, 0.1, 0.04)},
	"case": {"name": "Capa de telemóvel", "buy": 4, "sell": 14, "color": Color("e84393"), "band": Color("fd79a8"), "size": Vector3(0.08, 0.15, 0.02)},
	"powerbank": {"name": "Power bank 10000 mAh", "buy": 14, "sell": 32, "color": Color("2d3436"), "band": Color("00b894"), "size": Vector3(0.08, 0.13, 0.035)},
	"pad_new": {"name": "Comando novo", "buy": 30, "sell": 59, "color": Color("1e272e"), "band": Color("e74c3c"), "size": Vector3(0.16, 0.12, 0.07)},
	"mouse": {"name": "Rato gaming", "buy": 16, "sell": 36, "color": Color("130f40"), "band": Color("6c5ce7"), "size": Vector3(0.09, 0.13, 0.06)},
	"speaker": {"name": "Coluna Bluetooth", "buy": 20, "sell": 44, "color": Color("d35400"), "band": Color("f39c12"), "size": Vector3(0.1, 0.1, 0.1)},
	"hdmi": {"name": "Cabo HDMI 2 m", "buy": 3, "sell": 11, "color": Color("dfe6e9"), "band": Color("0984e3"), "size": Vector3(0.08, 0.14, 0.03)},
}

## Bench footprint: L = large (needs a big spot), S = small
const SIZE := {"laptop": "L", "console": "L", "radio": "L", "rotary": "L", "phone": "S", "handheld": "S", "gamepad": "S"}

const PARTS := {
	"battery": {"name": "Bateria de portátil", "price": 35, "device": "laptop"},
	"laptop_fan": {"name": "Ventoinha de portátil", "price": 22, "device": "laptop"},
	"ssd": {"name": "SSD NVMe 512 GB", "price": 45, "device": "laptop"},
	"phone_screen": {"name": "Ecrã de telemóvel", "price": 45, "device": "phone"},
	"phone_battery": {"name": "Bateria de telemóvel", "price": 18, "device": "phone"},
	"joystick": {"name": "Módulo analógico", "price": 9, "device": "gamepad"},
	"console_fan": {"name": "Ventoinha de consola", "price": 18, "device": "console"},
	"disc_drive": {"name": "Leitor de discos", "price": 40, "device": "console"},
	"handheld_battery": {"name": "Bateria de consola portátil", "price": 15, "device": "handheld"},
	"ringer": {"name": "Bobina de campainha", "price": 12, "device": "rotary"},
	"radio_tube": {"name": "Válvula de rádio", "price": 14, "device": "radio"},
}

static func open_steps(cover_word: String) -> Array:
	return [
		{"g": 2, "text": "Remove os parafusos da %s" % cover_word, "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Desaparafusar", "act": "unscrew", "enter": "flip_bottom"},
		{"g": 3, "text": "Retira a %s" % cover_word, "tool": "none", "targets": ["cover"], "view": "bottom", "verb": "Retirar", "act": "remove_cover"},
	]


static func close_steps(test_text: String, test_target: String, test_act: String) -> Array:
	return [
		{"g": 4, "text": "Volta a colocar a tampa", "tool": "none", "targets": ["cover"], "view": "interior", "verb": "Colocar", "act": "replace_cover"},
		{"g": 4, "text": "Aperta os parafusos", "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Aparafusar", "act": "screw_in"},
		{"g": 4, "text": test_text, "tool": "none", "targets": [test_target], "view": "front", "verb": "Testar", "act": test_act, "enter": "flip_top"},
	]


static func swap_steps(part: String, remove_text: String, install_text: String) -> Array:
	return [
		{"g": 3, "text": remove_text, "tool": "none", "targets": [part], "view": "interior", "verb": "Retirar", "act": "remove_part", "part": part},
		{"g": 3, "text": install_text, "tool": "none", "targets": ["new_" + part], "view": "interior", "verb": "Instalar", "act": "install_part", "part": part},
	]

const CUSTOMERS := [
	["Ana", Color("e57373")], ["Rui", Color("64b5f6")], ["Sofia", Color("ba68c8")], ["Tiago", Color("4db6ac")],
	["Marta", Color("ffb74d")], ["João", Color("81c784")], ["Beatriz", Color("f06292")], ["Pedro", Color("7986cb")],
	["Inês", Color("4dd0e1")], ["Miguel", Color("a1887f")], ["Carla", Color("dce775")], ["Diogo", Color("90a4ae")],
]

const LAPTOP_OPEN := [
	{"g": 2, "text": "Remove os parafusos da tampa inferior", "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Desaparafusar", "act": "unscrew", "enter": "flip_bottom"},
	{"g": 3, "text": "Retira a tampa inferior", "tool": "none", "targets": ["cover"], "view": "bottom", "verb": "Retirar", "act": "remove_cover"},
]
const LAPTOP_CLOSE := [
	{"g": 4, "text": "Volta a colocar a tampa", "tool": "none", "targets": ["cover"], "view": "interior", "verb": "Colocar", "act": "replace_cover"},
	{"g": 4, "text": "Aperta os parafusos", "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Aparafusar", "act": "screw_in"},
	{"g": 4, "text": "Liga o portátil para testar", "tool": "none", "targets": ["power"], "view": "front_open", "verb": "Ligar", "act": "power_on", "enter": "flip_top_open"},
]
const PAD_OPEN := [
	{"g": 2, "text": "Remove os parafusos da tampa traseira", "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Desaparafusar", "act": "unscrew", "enter": "flip_bottom"},
	{"g": 3, "text": "Retira a tampa traseira", "tool": "none", "targets": ["cover"], "view": "bottom", "verb": "Retirar", "act": "remove_cover"},
]
const PAD_CLOSE := [
	{"g": 4, "text": "Volta a colocar a tampa", "tool": "none", "targets": ["cover"], "view": "interior", "verb": "Colocar", "act": "replace_cover"},
	{"g": 4, "text": "Aperta os parafusos", "tool": "screwdriver", "targets": ["screw0", "screw1", "screw2", "screw3"], "need": 4, "view": "bottom", "verb": "Aparafusar", "act": "screw_in"},
]

const GROUPS_STD := ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir peça", "Fechar e testar"]


static func faults() -> Dictionary:
	return {
		"laptop_battery": {
			"device": "laptop", "fault": "Bateria", "part": "battery", "pay": 95, "xp": 40,
			"complaints": ["Não liga, nem ligado ao carregador.", "A bateria morreu de vez, preciso dele para as aulas!", "Desliga-se assim que tiro o carregador."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir bateria", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Abre a tampa do portátil", "tool": "none", "targets": ["lid"], "view": "overview", "verb": "Abrir", "act": "open_lid"},
				{"g": 0, "text": "Carrega no botão de ligar", "tool": "none", "targets": ["power"], "view": "front_open", "verb": "Ligar", "act": "power_dead"},
				{"g": 1, "text": "Mede a tensão na porta USB-C", "tool": "multimeter", "targets": ["port"], "view": "left_side", "verb": "Medir", "act": "measure", "reading": "0.00", "result": "0,00 V — a bateria não segura carga. Avaria: BATERIA"},
			] + LAPTOP_OPEN + [
				{"g": 3, "text": "Limpa o pó da ventoinha", "tool": ["brush", "air"], "targets": ["fan"], "need": 3, "view": "interior", "verb": "Limpar", "act": "clean_fan"},
				{"g": 3, "text": "Retira a bateria avariada", "tool": "none", "targets": ["battery"], "view": "interior", "verb": "Retirar", "act": "remove_part", "part": "battery"},
				{"g": 3, "text": "Instala a bateria nova", "tool": "none", "targets": ["new_battery"], "view": "interior", "verb": "Instalar", "act": "install_part", "part": "battery"},
			] + LAPTOP_CLOSE,
		},
		"laptop_fan": {
			"device": "laptop", "fault": "Sobreaquecimento", "part": "laptop_fan", "pay": 75, "xp": 35,
			"complaints": ["Faz um barulho enorme e desliga-se sozinho.", "Aquece tanto que queima as pernas e depois desliga.", "A ventoinha parece um avião a descolar."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir ventoinha", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Abre a tampa do portátil", "tool": "none", "targets": ["lid"], "view": "overview", "verb": "Abrir", "act": "open_lid"},
				{"g": 1, "text": "Liga o portátil e observa", "tool": "none", "targets": ["power"], "view": "front_open", "verb": "Ligar", "act": "power_hot"},
			] + LAPTOP_OPEN + [
				{"g": 3, "text": "Limpa o pó acumulado na ventoinha", "tool": ["brush", "air"], "targets": ["fan"], "need": 3, "view": "interior", "verb": "Limpar", "act": "clean_fan"},
				{"g": 3, "text": "Retira a ventoinha gasta", "tool": "none", "targets": ["laptop_fan"], "view": "interior", "verb": "Retirar", "act": "remove_part", "part": "laptop_fan"},
				{"g": 3, "text": "Instala a ventoinha nova", "tool": "none", "targets": ["new_laptop_fan"], "view": "interior", "verb": "Instalar", "act": "install_part", "part": "laptop_fan"},
			] + LAPTOP_CLOSE,
		},
		"laptop_ssd": {
			"device": "laptop", "fault": "Disco SSD", "part": "ssd", "pay": 120, "xp": 45,
			"complaints": ["Aparece uma mensagem de 'sem disco' e não arranca.", "Ficou preso no logótipo e agora diz que não há sistema.", "Caiu-me da mesa e já não entra no Windows."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir SSD", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Abre a tampa do portátil", "tool": "none", "targets": ["lid"], "view": "overview", "verb": "Abrir", "act": "open_lid"},
				{"g": 1, "text": "Liga o portátil e lê o erro", "tool": "none", "targets": ["power"], "view": "front_open", "verb": "Ligar", "act": "power_nodisk"},
			] + LAPTOP_OPEN + [
				{"g": 3, "text": "Retira o SSD avariado", "tool": "none", "targets": ["ssd"], "view": "interior", "verb": "Retirar", "act": "remove_part", "part": "ssd"},
				{"g": 3, "text": "Instala o SSD novo", "tool": "none", "targets": ["new_ssd"], "view": "interior", "verb": "Instalar", "act": "install_part", "part": "ssd"},
			] + LAPTOP_CLOSE,
		},
		"phone_screen": {
			"device": "phone", "fault": "Ecrã partido", "part": "phone_screen", "pay": 130, "xp": 45,
			"complaints": ["Caiu-me ao chão e o ecrã ficou todo riscado.", "O ecrã está rachado e já não responde bem ao toque.", "Tem riscos coloridos e o vidro partido."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir ecrã", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Carrega no botão lateral para ligar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_glitch"},
				{"g": 1, "text": "Limpa o ecrã com o pano para ver o dano", "tool": "cloth", "targets": ["screen"], "need": 3, "view": "front", "verb": "Limpar", "act": "wipe"},
				{"g": 2, "text": "Remove os parafusos pentalobe", "tool": "screwdriver", "targets": ["pscrew0", "pscrew1"], "need": 2, "view": "bottom_edge", "verb": "Desaparafusar", "act": "unscrew"},
				{"g": 3, "text": "Levanta o ecrã com a ventosa", "tool": "none", "targets": ["screen"], "view": "front", "verb": "Abrir", "act": "open_screen"},
				{"g": 3, "text": "Retira o ecrã partido", "tool": "none", "targets": ["screen"], "view": "open", "verb": "Retirar", "act": "remove_screen"},
				{"g": 3, "text": "Instala o ecrã novo", "tool": "none", "targets": ["new_screen"], "view": "open", "verb": "Instalar", "act": "install_screen", "part": "phone_screen"},
				{"g": 4, "text": "Fecha o ecrã", "tool": "none", "targets": ["screen"], "view": "open", "verb": "Fechar", "act": "close_screen"},
				{"g": 4, "text": "Aperta os parafusos", "tool": "screwdriver", "targets": ["pscrew0", "pscrew1"], "need": 2, "view": "bottom_edge", "verb": "Aparafusar", "act": "screw_in"},
				{"g": 4, "text": "Liga o telemóvel para testar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_on"},
			],
		},
		"phone_battery": {
			"device": "phone", "fault": "Bateria inchada", "part": "phone_battery", "pay": 65, "xp": 35,
			"complaints": ["A bateria dura duas horas e o ecrã está a levantar.", "Desliga-se aos 30% e está estranhamente quente.", "Parece que o ecrã está a descolar sozinho."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir bateria", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Carrega no botão lateral para ligar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_lowbat"},
				{"g": 1, "text": "Mede a tensão na porta USB-C", "tool": "multimeter", "targets": ["port"], "view": "bottom_edge", "verb": "Medir", "act": "measure", "reading": "3.1", "result": "3,1 V com carga — bateria degradada e inchada. Avaria: BATERIA"},
				{"g": 2, "text": "Remove os parafusos pentalobe", "tool": "screwdriver", "targets": ["pscrew0", "pscrew1"], "need": 2, "view": "bottom_edge", "verb": "Desaparafusar", "act": "unscrew"},
				{"g": 3, "text": "Levanta o ecrã com a ventosa", "tool": "none", "targets": ["screen"], "view": "front", "verb": "Abrir", "act": "open_screen"},
				{"g": 3, "text": "Retira a bateria inchada", "tool": "none", "targets": ["phone_battery"], "view": "open", "verb": "Retirar", "act": "remove_part", "part": "phone_battery"},
				{"g": 3, "text": "Instala a bateria nova", "tool": "none", "targets": ["new_phone_battery"], "view": "open", "verb": "Instalar", "act": "install_part", "part": "phone_battery"},
				{"g": 4, "text": "Fecha o ecrã", "tool": "none", "targets": ["screen"], "view": "open", "verb": "Fechar", "act": "close_screen"},
				{"g": 4, "text": "Aperta os parafusos", "tool": "screwdriver", "targets": ["pscrew0", "pscrew1"], "need": 2, "view": "bottom_edge", "verb": "Aparafusar", "act": "screw_in"},
				{"g": 4, "text": "Liga o telemóvel para testar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_on"},
			],
		},
		"phone_port": {
			"device": "phone", "fault": "Porta de carregamento", "part": "", "pay": 35, "xp": 25,
			"complaints": ["Só carrega se segurar o cabo num certo ângulo.", "Não carrega com nenhum cabo.", "O carregador entra mal e não faz contacto."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Limpar a porta", "Testar a carga", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Carrega no botão lateral para ligar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_nocharge"},
				{"g": 1, "text": "Mede a tensão na porta USB-C", "tool": "multimeter", "targets": ["port"], "view": "bottom_edge", "verb": "Medir", "act": "measure", "reading": "0.00", "result": "Sem contacto — a porta está cheia de cotão. Avaria: PORTA SUJA"},
				{"g": 2, "text": "Sopra o cotão da porta com ar comprimido", "tool": "air", "targets": ["port"], "need": 3, "view": "bottom_edge", "verb": "Soprar", "act": "blow_port"},
				{"g": 3, "text": "Volta a medir a tensão", "tool": "multimeter", "targets": ["port"], "view": "bottom_edge", "verb": "Medir", "act": "measure", "reading": "5.02", "result": "5,02 V — já carrega!"},
				{"g": 4, "text": "Liga o telemóvel para testar", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_on"},
			],
		},
		"gamepad_drift": {
			"device": "gamepad", "fault": "Drift do analógico", "part": "joystick", "pay": 40, "xp": 30,
			"complaints": ["A personagem anda sozinha para a esquerda!", "O analógico esquerdo mexe-se sem lhe tocar.", "Nos jogos a câmara não pára de rodar."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir analógico", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Carrega no botão central para ligar", "tool": "none", "targets": ["home"], "view": "front", "verb": "Ligar", "act": "pad_on"},
				{"g": 1, "text": "Testa o analógico esquerdo", "tool": "none", "targets": ["stick_l"], "view": "front", "verb": "Testar", "act": "pad_drift"},
			] + PAD_OPEN + [
				{"g": 3, "text": "Retira o módulo analógico gasto", "tool": "none", "targets": ["joystick"], "view": "interior", "verb": "Retirar", "act": "remove_part", "part": "joystick"},
				{"g": 3, "text": "Instala o módulo novo", "tool": "none", "targets": ["new_joystick"], "view": "interior", "verb": "Instalar", "act": "install_part", "part": "joystick"},
			] + PAD_CLOSE + [
				{"g": 4, "text": "Testa o analógico", "tool": "none", "targets": ["stick_l"], "view": "front", "verb": "Testar", "act": "pad_test", "enter": "flip_top"},
			],
		},
		"gamepad_buttons": {
			"device": "gamepad", "fault": "Botões presos", "part": "", "pay": 25, "xp": 20,
			"complaints": ["Entornei sumo e os botões ficaram pegajosos.", "O botão A fica preso lá em baixo.", "Os botões custam a voltar ao sítio."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Limpar botões", "Polir", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Carrega no botão central para ligar", "tool": "none", "targets": ["home"], "view": "front", "verb": "Ligar", "act": "pad_on"},
				{"g": 1, "text": "Carrega no botão A", "tool": "none", "targets": ["btn_a"], "view": "front", "verb": "Carregar", "act": "pad_stuck"},
				{"g": 2, "text": "Escova os botões para tirar a sujidade", "tool": "brush", "targets": ["buttons"], "need": 2, "view": "front", "verb": "Escovar", "act": "clean_buttons"},
				{"g": 3, "text": "Limpa os botões com o pano", "tool": "cloth", "targets": ["buttons"], "need": 2, "view": "front", "verb": "Limpar", "act": "clean_buttons"},
				{"g": 4, "text": "Testa o botão A", "tool": "none", "targets": ["btn_a"], "view": "front", "verb": "Testar", "act": "pad_ok"},
			],
		},
		"console_overheat": {
			"device": "console", "fault": "Sobreaquecimento", "part": "console_fan", "pay": 75, "xp": 35,
			"complaints": ["Desliga-se sozinha a meio dos jogos.", "Faz um barulho de turbina e aquece imenso.", "A luz pisca a vermelho e a consola apaga."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir ventoinha", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga a consola no botão da frente", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_flash_off"},
			] + open_steps("tampa inferior") + [
				{"g": 3, "text": "Limpa o pó da ventoinha", "tool": ["brush", "air"], "targets": ["fan"], "need": 3, "view": "interior", "verb": "Limpar", "act": "clean"},
			] + swap_steps("console_fan", "Retira a ventoinha gasta", "Instala a ventoinha nova") + close_steps("Liga a consola para testar", "power", "power_ok"),
		},
		"console_drive": {
			"device": "console", "fault": "Leitor de discos", "part": "disc_drive", "pay": 90, "xp": 40,
			"complaints": ["Não lê nenhum jogo, só faz cliques.", "O disco entra mas diz 'disco não reconhecido'.", "O leitor deixou de puxar os discos."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir leitor", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga a consola no botão da frente", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_drive"},
			] + open_steps("tampa inferior") + swap_steps("disc_drive", "Retira o leitor avariado", "Instala o leitor novo") + close_steps("Liga a consola para testar", "power", "power_ok"),
		},
		"handheld_battery": {
			"device": "handheld", "fault": "Bateria", "part": "handheld_battery", "pay": 50, "xp": 30,
			"complaints": ["Não liga, mesmo depois de carregar a noite toda.", "A bateria não dura dez minutos.", "Liga e apaga logo a seguir."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir bateria", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga a consola no interruptor lateral", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_none"},
				{"g": 1, "text": "Mede a tensão na porta de carregamento", "tool": "multimeter", "targets": ["port"], "view": "port", "verb": "Medir", "act": "measure", "reading": "0.42", "result": "0,4 V — bateria completamente gasta. Avaria: BATERIA"},
			] + open_steps("tampa traseira") + swap_steps("handheld_battery", "Retira a bateria gasta", "Instala a bateria nova") + close_steps("Liga a consola para testar", "power", "power_ok"),
		},
		"handheld_buttons": {
			"device": "handheld", "fault": "Botões presos", "part": "", "pay": 25, "xp": 20,
			"complaints": ["Os botões ficaram duros depois de uma viagem à praia.", "O botão de saltar não responde.", "Tem areia nos botões!"],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Limpar botões", "Polir", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga a consola no interruptor lateral", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "power_ok_quiet"},
				{"g": 1, "text": "Carrega nos botões", "tool": "none", "targets": ["buttons"], "view": "front", "verb": "Carregar", "act": "buttons_stuck"},
				{"g": 2, "text": "Escova os botões para tirar a areia", "tool": "brush", "targets": ["buttons"], "need": 2, "view": "front", "verb": "Escovar", "act": "clean_buttons"},
				{"g": 3, "text": "Limpa os botões com o pano", "tool": "cloth", "targets": ["buttons"], "need": 2, "view": "front", "verb": "Limpar", "act": "clean_buttons"},
				{"g": 4, "text": "Testa os botões", "tool": "none", "targets": ["buttons"], "view": "front", "verb": "Testar", "act": "buttons_ok"},
			],
		},
		"rotary_bell": {
			"device": "rotary", "fault": "Campainha", "part": "ringer", "pay": 45, "xp": 35,
			"complaints": ["Era da minha avó. Já não toca quando me ligam.", "Dá sinal, mas a campainha está muda.", "Só toca às vezes, muito baixinho."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir bobina", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Levanta o auscultador", "tool": "none", "targets": ["hook"], "view": "front", "verb": "Levantar", "act": "ring_fail"},
				{"g": 1, "text": "Roda o disco para testar a marcação", "tool": "none", "targets": ["dial"], "view": "front", "verb": "Rodar", "act": "dial_ok_diag"},
			] + open_steps("base") + [
				{"g": 3, "text": "Limpa os contactos com o pincel", "tool": "brush", "targets": ["contacts"], "need": 2, "view": "interior", "verb": "Limpar", "act": "clean"},
			] + swap_steps("ringer", "Retira a bobina queimada", "Instala a bobina nova") + close_steps("Testa a campainha", "hook", "ring_ok"),
		},
		"rotary_dial": {
			"device": "rotary", "fault": "Disco preso", "part": "", "pay": 35, "xp": 25,
			"complaints": ["O disco fica preso a meio e não volta.", "Não consigo marcar números com o 9.", "O disco está duro como pedra."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Desentupir o disco", "Polir", "Testar"],
			"steps": [
				{"g": 0, "text": "Levanta o auscultador", "tool": "none", "targets": ["hook"], "view": "front", "verb": "Levantar", "act": "hook_tone"},
				{"g": 1, "text": "Roda o disco", "tool": "none", "targets": ["dial"], "view": "front", "verb": "Rodar", "act": "dial_stuck"},
				{"g": 2, "text": "Sopra o pó do mecanismo do disco", "tool": "air", "targets": ["dial"], "need": 3, "view": "front", "verb": "Soprar", "act": "blow_port"},
				{"g": 3, "text": "Limpa o disco com o pano", "tool": "cloth", "targets": ["dial"], "need": 2, "view": "front", "verb": "Limpar", "act": "wipe"},
				{"g": 4, "text": "Testa o disco", "tool": "none", "targets": ["dial"], "view": "front", "verb": "Testar", "act": "dial_ok"},
			],
		},
		"radio_tube": {
			"device": "radio", "fault": "Válvula fundida", "part": "radio_tube", "pay": 60, "xp": 40,
			"complaints": ["Acende a luz mas não sai som nenhum.", "Era do meu pai. Ficou mudo de repente.", "Liga, aquece, e depois... nada."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Substituir válvula", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga o rádio no botão da esquerda", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "radio_dead"},
				{"g": 1, "text": "Roda a sintonia e escuta", "tool": "none", "targets": ["tuning"], "view": "front", "verb": "Sintonizar", "act": "tune_silent"},
			] + open_steps("tampa traseira") + swap_steps("radio_tube", "Retira a válvula fundida", "Instala a válvula nova") + close_steps("Liga o rádio para testar", "power", "radio_on"),
		},
		"radio_static": {
			"device": "radio", "fault": "Sintonia suja", "part": "", "pay": 40, "xp": 30,
			"complaints": ["Só se ouve chiado, as estações fogem.", "Faz um barulho de fritura ao mudar de estação.", "O som vai e vem."],
			"groups": ["Examinar o equipamento", "Identificar avaria", "Remover parafusos", "Limpar a sintonia", "Fechar e testar"],
			"steps": [
				{"g": 0, "text": "Liga o rádio no botão da esquerda", "tool": "none", "targets": ["power"], "view": "front", "verb": "Ligar", "act": "radio_static"},
				{"g": 1, "text": "Roda a sintonia e escuta", "tool": "none", "targets": ["tuning"], "view": "front", "verb": "Sintonizar", "act": "tune_crackle"},
			] + open_steps("tampa traseira") + [
				{"g": 3, "text": "Sopra o pó do condensador de sintonia", "tool": ["air", "brush"], "targets": ["chassis"], "need": 3, "view": "interior", "verb": "Limpar", "act": "clean"},
			] + close_steps("Liga o rádio para testar", "power", "radio_on"),
		},
	}
