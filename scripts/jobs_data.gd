extends RefCounted
## Devices, faults (repair procedures), spare parts and customers.

const DEVICES := {
	"laptop": {"name": "Portátil", "article": "o"},
	"phone": {"name": "Telemóvel", "article": "o"},
	"gamepad": {"name": "Comando", "article": "o"},
}

const PARTS := {
	"battery": {"name": "Bateria de portátil", "price": 35},
	"laptop_fan": {"name": "Ventoinha de portátil", "price": 22},
	"ssd": {"name": "SSD NVMe 512 GB", "price": 45},
	"phone_screen": {"name": "Ecrã de telemóvel", "price": 45},
	"phone_battery": {"name": "Bateria de telemóvel", "price": 18},
	"joystick": {"name": "Módulo analógico", "price": 9},
}

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
	}
