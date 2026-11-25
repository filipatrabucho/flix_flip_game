# Fix & Flip Tech — v0.9

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

## Controlos

| Tecla | Ação |
| --- | --- |
| WASD + rato | Andar e olhar |
| E | Interagir (reparar / pegar ferramenta) |
| P | Pedidos dos clientes |
| L | Loja de peças |
| 1–5 / roda do rato | Escolher ferramenta |
| Q | Mão livre |
| TAB | Roda de ferramentas |
| Clique esquerdo | Usar ferramenta / mão no ponto assinalado |
| Clique direito + arrastar | Rodar a vista (na reparação) |
| Roda do rato | Zoom (na reparação) |
| Esc | Voltar / pausa |

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
