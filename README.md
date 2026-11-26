# Fix & Flip Tech — v1.4

Simulador de oficina de eletrónica em **Godot 4** (Forward+). Compra equipamentos avariados, repara-os passo a passo com as mãos (de luva) e ferramentas reais, e revende com lucro.

## Como abrir

1. Abre o `project.godot` no Godot 4.4 ou superior (o projeto foi feito para 4.7).
2. Deixa o editor importar os recursos na primeira abertura.
3. Carrega em **F5**.

> Se o PC não suportar Vulkan, o Godot muda automaticamente para OpenGL. Em **Definições → Qualidade gráfica** há Baixa / Média / Alta.

## O que há nesta versão

- **Menu principal** com os botões e o texto só numa barra lateral à esquerda; a imagem da oficina fica visível no resto do ecrã.
- **Oficina 3D em escala real**: bancada de madeira com tapete de corte, painel perfurado com ferramentas, néon "FIX & FLIP TECH", janela ao pôr-do-sol, prateleiras, armários vermelhos, candeeiro articulado, candeeiros suspensos e plantas.
- **Portátil realista** (312 × 221 × 18 mm): alumínio, teclado tecla a tecla, trackpad, portas USB-C/USB-A, dobradiça, ecrã a funcionar, pés de borracha, grelha de ventilação, 4 parafusos e interior (placa, RAM, SSD, ventoinha com pó, bateria).
- **Telemóvel realista** (71,6 × 7,8 × 147,6 mm): moldura metálica, botões, porta USB-C, parafusos pentalobe, ecrã rachado, ecrã que abre como um livro e interior.
- **Mão com luva** articulada (3 falanges por dedo, polegar e punho com faixa laranja), que segue o rato e segura as ferramentas.
- **HUD igual às referências**: Dia e hora, dinheiro, nível e XP, painel "Objetivo Atual", barra de ferramentas 1–5, aviso "E Interagir", painel "Reparação: …" com os passos e dicas de teclas.
- **Roda de ferramentas (TAB)**: Chave de Fendas, Ar Comprimido, Multímetro, Pano de Microfibra e Pincel.

## Clientes, pedidos e loja (v0.9)

- Ao longo do dia chegam **clientes** com o equipamento avariado e uma queixa ("Faz um barulho enorme e desliga-se sozinho"). Abre os **Pedidos (P)** para aceitar ou recusar. Cada pedido mostra o pagamento e o prazo.
- O equipamento aceite vai para a bancada (um lugar para portátil, um para telemóvel e um para comando). Os restantes ficam em fila.
- Ao entregar recebes o pagamento, uma **gorjeta** se cumprires o prazo e uma **avaliação ★**. A reputação aumenta o pagamento e a frequência dos clientes.
- **Loja de Peças (L)**: compra baterias, ecrãs, ventoinhas, SSD e módulos analógicos. A peça sai do stock quando a vais instalar.

**Equipamentos e avarias:**

| Equipamento | Avarias |
| --- | --- |
| Portátil | Bateria, Sobreaquecimento (ventoinha), Disco SSD |
| Telemóvel | Ecrã partido, Bateria inchada, Porta de carregamento suja |
| Comando | Drift do analógico, Botões presos |

## História: «A Oficina do Avô Júlio» (v1.0)

Herdaste a velha oficina do Avô Júlio numa vila pequena. Tudo começa com uma carta dele. Depois aparece o Sr. Armando, o senhorio rabugento: há renda para pagar e a oficina pode fechar.

1. **A Oficina do Avô**: as primeiras reparações. A Dona Rosa, da florista ao lado, é a primeira cliente.
2. **A Renda**: junta 300 € até ao fim do Dia 3.
3. **Boca a Boca**: o Leo traz o comando e a fama da oficina cresce. A Marta, jornalista, escreve sobre ti.
4. **O Portátil do Avô**: o Sr. Armando traz o portátil antigo do teu avô. O que estará lá dentro?

Depois do fim da história o jogo continua em modo livre.

## Balcão com clientes 3D

Os clientes entram pela porta da loja, fazem fila no balcão e esperam com um **!** por cima da cabeça. Olha para eles e carrega **E** para ouvires a queixa e aceitares ou recusares o trabalho. Quando a reparação acaba, o cliente volta ao balcão (**✓**) para levantar o equipamento e pagar.

## Novidades v1.1

- **Novos equipamentos**: consola de jogos, consola portátil, telefone antigo de disco e rádio de válvulas, cada um com 2 avarias (16 avarias no total).
- **Fluxo de entrega realista**: depois de reparares, pegas no equipamento (E) e pousa-lo na prateleira **«Prontos a entregar»** (lugares #1 a #4). O cliente volta e pede «o pedido #N»: vais buscá-lo, entregas e o cliente deixa o **dinheiro no balcão**. Clica no dinheiro e ele vai para a **caixa registadora**.
- **Loja de peças** com filtros por equipamento, imagem 3D de cada peça e **entrega demorada**: a encomenda chega passados uns minutos a uma caixa de cartão na prateleira **«Receção»**, junto à porta. Abre a caixa para pôr a peça no stock.
- **Melhorias da oficina (U)**: chave de fendas elétrica, candeeiro LED, máquina de café, coluna de som, montra e néon. Cada uma aparece na oficina e tem um efeito permanente.
- **Som e música**: 6 músicas lo-fi originais em playlist aleatória e efeitos para cada ação (parafusos, ar comprimido, porta, campainha, caixa registadora...). Os volumes ajustam-se nas Definições.
- **Clientes calmos no início**: nos primeiros capítulos só há um trabalho de cada vez, e o cliente seguinte chega depois de entregares.
- **Personagens mais realistas**: corpo com proporções humanas, joelhos e cotovelos, mãos com dedos, rosto com nariz, orelhas, íris colorida, pestanas e piscar de olhos, e roupa variada (camisa, hoodie, casaco).

## Novidades v1.4

- **História muito mais longa (10 capítulos)**. Depois do portátil do avô:
  - *A Concorrência*: a MegaFix abre na vila e manda um cliente espião testar-te.
  - *Não Estás Sozinho*: contratas a tua primeira pessoa.
  - *O Rádio da Avó Lurdes*: há uma gravação escondida dentro do rádio.
  - *O Prédio*: tens de juntar 3000 € antes que a MegaFix o compre. Depois disso acabam as rendas.
  - *A Feira da Reparação*: desafio de 5 entregas num só dia.
  - *O Telefone do Vítor*: o final.
- **Passar trabalho a um técnico**: na bancada (tecla **T**, a olhar para o equipamento ou durante a reparação) ou nos Pedidos (botão «Passar a Ana ×1.7»). O técnico continua a partir do passo em que ficaste.
- **Expositor «NOVIDADES»**: compras produtos novos na loja online (separador Mercado), como auriculares, carregadores, capas, power banks, comandos, ratos, colunas e cabos. Chegam pelo carteiro e vão para o expositor junto à montra. Os clientes vêm ver, escolhem e pagam no balcão (ou ao balconista). Carrega E no expositor para o repor com o que tens em armazém.
- **Personagens em estilo boneco**: cabeça maior e redonda, olhos grandes com brilho, bochechas rosadas, mãos e pernas mais robustas e cores lisas.
- **Melhorias também se mudam de sítio** (tecla G): a coluna de som, a máquina de café, a chave elétrica, a montra (no chão) e o néon (em qualquer parede). Podes, por exemplo, pôr o café na ponta do balcão para os clientes. As posições ficam gravadas.
- **Pousar as coisas onde quiseres** (tecla G): ferramentas e decorações vão para qualquer superfície (bancada, balcão, prateleiras, armários, parapeito, frigorífico, bancadas do anexo) ou para o chão. Os equipamentos podem ir para qualquer superfície.

## Novidades v1.3 — A oficina cresce

- **Expansão da loja (separador Equipa, tecla F)**:
  1. *Anexo técnico* (900 €): abre a parede da direita e revela uma oficina com 2 bancadas para técnicos.
  2. *Ampliação da loja* (2400 €): mais 2 bancadas, uma segunda prateleira «Prontos a entregar» (#5 a #8) e mais clientes.
- **Funcionários**: há candidatos novos todas as manhãs.
  - **Técnicos**: cada um tem a sua especialidade (computadores e consolas, telemóveis e portáteis de jogos, comandos, aparelhos antigos) e é mais rápido nela. Vês-los a trabalhar na bancada, com o equipamento e a percentagem do trabalho, e põem o equipamento pronto na prateleira. Ganham experiência e ficam mais rápidos. Os de mais estrelas fazem trabalhos de 5★ mais vezes.
  - **Balconista**: atende o balcão, aceita pedidos, entrega os equipamentos prontos e guarda o dinheiro na caixa. Deixa para ti os clientes da história.
  - Cada funcionário tem o seu **horário** (manhã 08–14, tarde 14–20, dia inteiro 09–18) e um **salário diário**, pago ao fechar a loja.
  - Opção «Dar os trabalhos novos primeiro à equipa» (ou ficas tu com eles primeiro).
- **Usados (Fix & Flip)**: todos os dias há 3 equipamentos avariados à venda. Compras, reparas (tu ou a equipa), pões na prateleira e aparece um comprador.
- **Metas do dia (tecla M)**: 3 metas diárias com prémio em dinheiro, por exemplo «Entrega 3 equipamentos», «Recebe 2 avaliações de 5★» ou «Guarda 250 € na caixa».
- **17 conquistas** com prémios: Faz-tudo, Lenda da vila, Pequena empresa, Dia perfeito, entre outras.
- **Clientes VIP**: de vez em quando aparece um cliente que paga quase o dobro, mas tem pouco tempo.
- Correção: no comando, os 2 parafusos de baixo estavam escondidos dentro das pegas.

## Novidades v1.2

- **Pausa (Esc)** com Continuar, Guardar, **Definições no próprio jogo** (volumes de música e efeitos, sensibilidade, qualidade gráfica, idioma) e Sair para o menu.
- **3 ranhuras de gravação**: Novo jogo e Carregar mostram 3 ranhuras com dia, dinheiro e capítulo. Antes de escrever por cima de uma ranhura o jogo pede confirmação. O save antigo é migrado para a ranhura 1.
- **Caixa registadora de loja moderna** à direita do balcão, virada para ti: gaveta com tabuleiros de notas, ecrã tátil inclinado, visor para o cliente e impressora de talões.
- **Telefone antigo mais percetível**: auscultador curvo com bocal e auricular, garfo com pinos, contactos de latão visíveis e uma animação de levantar o auscultador.
- **Arrumar a oficina (G)**: olha para uma ferramenta, decoração ou objeto, carrega **G** para lhe pegar e move-o pela bancada, pelo balcão ou pela parede. Roda do rato ou **R** para rodar, clique ou **G** para pousar. As posições ficam gravadas.
- **Decorações (separador nas Melhorias)**: posters, gato de néon, relógio de parede com horas reais do jogo, luzes de fio, planta grande, tapete, candeeiro de lava, robô e cato.
- **Quarto das traseiras**: porta na parede esquerda. Tem saco-cama, frigorífico com snacks e chaleira. Ao fim do dia fechas a loja e dormes até ao dia seguinte.
- **Energia e fome**: as duas barras aparecem no HUD. A energia recupera com café (chaleira ou máquina de café) e a descansar. A fome recupera com snacks do frigorífico. Com pouca energia andas mais devagar e, exausto, já não consegues reparar.
- **Sentar no banco**: há bancos atrás do balcão e junto à bancada. Sentado, o tempo passa 4× mais depressa e recuperas energia enquanto esperas por clientes.
- **Campainha do balcão**: toca quando quiseres (plim plim!).
- **Carteiro de boné** que entra pela porta com as encomendas e as deixa na prateleira «Receção».
- **Ritmo de clientes**: os clientes já não esperam que acabes o trabalho anterior. Chegam um ou dois de cada vez, com intervalos irregulares, e o número de pedidos abertos sobe com os capítulos.

## Idiomas

Português e English: Definições → Idioma / Language.

## Controlos

| Tecla | Ação |
| --- | --- |
| WASD + rato | Andar e olhar |
| E | Interagir (falar com clientes / reparar / pegar ferramenta) |
| P | Pedidos dos clientes |
| L | Loja de peças |
| U | Melhorias da oficina |
| F | Equipa e expansão da loja |
| M | Metas do dia e conquistas |
| 1–5 / roda do rato | Escolher ferramenta |
| Q | Mão livre |
| TAB | Roda de ferramentas |
| Clique esquerdo | Usar ferramenta / mão no ponto assinalado |
| Clique direito + arrastar | Rodar a vista (na reparação) |
| Roda do rato | Zoom (na reparação) |
| G | Pegar e mover um objeto para qualquer superfície ou para o chão |
| T | Passar o equipamento da bancada a um técnico |
| R / roda do rato | Rodar o objeto que estás a mover |
| E (no banco, saco-cama, frigorífico, café, campainha) | Sentar, dormir, comer, beber, tocar |
| Esc | Voltar / pausa (com definições) |

## Reparações

- **Portátil — Bateria**: abrir a tampa → tentar ligar → medir a USB-C com o multímetro → virar → 4 parafusos → retirar a tampa inferior → limpar a ventoinha → trocar a bateria → fechar → aparafusar → ligar.
- **Telemóvel — Ecrã partido**: ligar → limpar o ecrã com o pano → 2 parafusos pentalobe → abrir o ecrã → trocar o ecrã → fechar → aparafusar → ligar.

## Estrutura

- `scripts/main.gd`: estado do jogo, menus, HUD, modo de andar e modo de reparação.
- `scripts/room.gd`: oficina.
- `scripts/laptop.gd`, `scripts/phone.gd`, `scripts/device_base.gd`: equipamentos e animações.
- `scripts/glove_hand.gd`: mão com luva e poses.
- `scripts/tools3d.gd`: modelos das ferramentas.
- `scripts/kit.gd`: geração de malhas (arestas arredondadas, tubos, folhas) e materiais.
- `scripts/radial_menu.gd`, `scripts/ui_icon.gd`: roda de ferramentas e ícones da UI.

Os modelos são todos gerados por código; não há ficheiros 3D externos. Tipo de letra: Nunito (licença SIL OFL, em `assets/fonts/OFL.txt`).
