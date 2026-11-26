extends RefCounted
## Staff, shop expansion, daily goals and achievements data.

## Device skill categories (each technician is faster in some of them).
const CATEGORIES := {
	"pc": {"name": "Computadores e consolas", "devices": ["laptop", "console"]},
	"mobile": {"name": "Telemóveis e portáteis de jogos", "devices": ["phone", "handheld"]},
	"pad": {"name": "Comandos", "devices": ["gamepad"]},
	"retro": {"name": "Aparelhos antigos", "devices": ["rotary", "radio"]},
}

const SHIFTS := {
	"morning": {"name": "Manhã", "start": 8, "end": 14, "mult": 0.75},
	"afternoon": {"name": "Tarde", "start": 14, "end": 20, "mult": 0.75},
	"full": {"name": "Dia inteiro", "start": 9, "end": 18, "mult": 1.3},
}

const ROLES := {
	"tech": {"name": "Técnico/a", "desc": "Repara equipamentos numa bancada do anexo e põe-nos na prateleira."},
	"desk": {"name": "Balconista", "desc": "Atende o balcão: aceita pedidos, entrega equipamentos prontos e guarda o dinheiro na caixa."},
}

const NAMES := [
	["Ana Lopes", {"hair_style": 1}], ["Bruno Faria", {"extras": ["beard"]}], ["Carolina Reis", {"hair_style": 2}], ["Duarte Melo", {"extras": ["glasses"]}],
	["Eva Martins", {"hair_style": 3}], ["Filipe Sousa", {}], ["Gabriela Nunes", {"hair_style": 1, "extras": ["glasses"]}], ["Hugo Pires", {"extras": ["beard"]}],
	["Joana Matos", {"hair_style": 2}], ["Luís Teixeira", {}], ["Mafalda Costa", {"hair_style": 3}], ["Nuno Barros", {"extras": ["glasses"]}],
	["Olívia Santos", {"hair_style": 1}], ["Paulo Gomes", {"extras": ["beard", "glasses"]}], ["Rita Fonseca", {"hair_style": 2}], ["Samuel Rocha", {}],
	["Telma Vieira", {"hair_style": 3}], ["Vasco Cardoso", {"extras": ["beard"]}],
]

## Shop expansion levels (index 0 = first purchase).
const EXPANSIONS := [
	{"name": "Anexo técnico", "price": 900, "desc": "Abre a parede da direita: um anexo com 2 bancadas para técnicos. Mais 1 pedido aberto ao mesmo tempo."},
	{"name": "Ampliação da loja", "price": 2400, "desc": "Mais 2 bancadas no anexo, uma segunda prateleira «Prontos a entregar» (#5 a #8) e mais 1 pedido aberto. Chegam mais clientes."},
]

## Daily goals: kind, text (with %d / %s), amount range, reward per unit.
const GOALS := [
	{"kind": "repair", "text": "Entrega %d equipamentos reparados", "one": "Entrega 1 equipamento reparado", "min": 2, "max": 4, "reward": 25},
	{"kind": "ontime", "text": "Entrega %d pedidos dentro do prazo", "one": "Entrega 1 pedido dentro do prazo", "min": 2, "max": 3, "reward": 25},
	{"kind": "five", "text": "Recebe %d avaliações de 5 estrelas", "one": "Recebe 1 avaliação de 5 estrelas", "min": 1, "max": 3, "reward": 30},
	{"kind": "earn", "text": "Guarda %s na caixa hoje", "min": 150, "max": 400, "reward": 0},
	{"kind": "device", "text": "Repara um equipamento do tipo: %s", "min": 1, "max": 1, "reward": 45},
	{"kind": "flip", "text": "Revende %d equipamento usado", "min": 1, "max": 1, "reward": 50},
	{"kind": "sell", "text": "Vende %d produtos do expositor", "one": "Vende 1 produto do expositor", "min": 2, "max": 4, "reward": 12},
	{"kind": "parts", "text": "Abre %d encomendas de peças", "one": "Abre 1 encomenda de peças", "min": 1, "max": 2, "reward": 15},
]

## Achievements: id -> name, description, stat key and target.
const ACHIEVEMENTS := {
	"first_fix": {"name": "Mãos à obra", "desc": "Entrega a primeira reparação.", "stat": "repairs", "target": 1, "reward": 20},
	"fix_10": {"name": "Aprendiz", "desc": "Entrega 10 reparações.", "stat": "repairs", "target": 10, "reward": 50},
	"fix_50": {"name": "Técnico de confiança", "desc": "Entrega 50 reparações.", "stat": "repairs", "target": 50, "reward": 150},
	"fix_150": {"name": "Lenda da vila", "desc": "Entrega 150 reparações.", "stat": "repairs", "target": 150, "reward": 400},
	"all_devices": {"name": "Faz-tudo", "desc": "Repara todos os 7 tipos de equipamento.", "stat": "device_types", "target": 7, "reward": 120},
	"five_20": {"name": "Cinco estrelas", "desc": "Recebe 20 avaliações de 5★.", "stat": "five_stars", "target": 20, "reward": 100},
	"rich_1k": {"name": "Primeiro milhar", "desc": "Junta 1000 € na conta.", "stat": "money", "target": 1000, "reward": 0},
	"rich_5k": {"name": "Negócio sério", "desc": "Junta 5000 € na conta.", "stat": "money", "target": 5000, "reward": 0},
	"hire": {"name": "Chefe de equipa", "desc": "Contrata o primeiro funcionário.", "stat": "hired", "target": 1, "reward": 40},
	"team_4": {"name": "Pequena empresa", "desc": "Tem 4 funcionários ao mesmo tempo.", "stat": "team_size", "target": 4, "reward": 200},
	"expand_1": {"name": "Mais espaço", "desc": "Compra o anexo técnico.", "stat": "expansion", "target": 1, "reward": 0},
	"expand_2": {"name": "Loja a sério", "desc": "Faz a ampliação completa da loja.", "stat": "expansion", "target": 2, "reward": 0},
	"flip_1": {"name": "Fix & Flip", "desc": "Revende o primeiro equipamento usado.", "stat": "flips", "target": 1, "reward": 30},
	"flip_10": {"name": "Olho para o negócio", "desc": "Revende 10 equipamentos usados.", "stat": "flips", "target": 10, "reward": 150},
	"perfect_day": {"name": "Dia perfeito", "desc": "Cumpre as 3 metas de um dia.", "stat": "perfect_days", "target": 1, "reward": 60},
	"vip_5": {"name": "Clientes VIP", "desc": "Entrega 5 pedidos VIP.", "stat": "vips", "target": 5, "reward": 120},
	"shop_10": {"name": "Lojista", "desc": "Vende 10 produtos novos no expositor.", "stat": "sold", "target": 10, "reward": 60},
	"shop_50": {"name": "Comerciante da vila", "desc": "Vende 50 produtos novos no expositor.", "stat": "sold", "target": 50, "reward": 200},
	"story_end": {"name": "A oficina nunca fecha", "desc": "Termina a história do Avô Júlio.", "stat": "story_end", "target": 1, "reward": 300},
	"week": {"name": "Uma semana de portas abertas", "desc": "Chega ao Dia 7.", "stat": "day", "target": 7, "reward": 70},
}
