extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum state_machine {LOADING, READY}
var _self_state = state_machine.LOADING

export (NodePath) var path_lista_dicas
export (NodePath) var path_table_palavras
export (NodePath) var path_numeracao

export (String, FILE) var glossario_acentuacao

export (int, 1, 300) var linhas
export (int, 1, 300) var colunas
export (int, 1, 128) var tamanho_celula = 32

export (Color) var cor_numeracao = Color(1, 1, 1, 0.6)

var injetor_letras	:= LineEdit.new()
var lista_dicas 	:= VBoxContainer.new()
var table_palavras 	:= Control.new()
var numeracao 		:= Control.new()

var palavras = {}
var dicio_solucao = {}
var special_char = {}

const V_SCORE = 1.0
const H_SCORE = 0.8
const DELAY = 1000 # 0.1 segundos

# Called when the node enters the scene tree for the first time.
func _ready():
	seed(OS.get_unix_time())
	
#	Api.semaforo.wait()
	
	# Caracters especiais
	_gerar_special_char_dicio()
	
	# Encontrar os nodes
	lista_dicas = get_node(path_lista_dicas)
	table_palavras = get_node(path_table_palavras)
	numeracao = get_node(path_numeracao)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _self_state == state_machine.READY:
		var fim_de_jogo = true
		for i in palavras:
			if (!palavras[i]["resolvida"]):
				fim_de_jogo = false
				_verificar_palavra(i)
		if (fim_de_jogo):
			#mostra a pontuacao
			print("YOU WIN")
			get_tree().quit()
	elif Api.loaded:
		var cleaned_data = _parse_game_contains(Api.dicio)
		_gen_cross_word(cleaned_data)
		_self_state = state_machine.READY

func _unhandled_input(event):
	if (event is InputEventKey):
		var letra = char(event.scancode)
		var focus = get_focus_owner()
		if (focus is Button):
			focus as Button
			if (!focus.disabled and focus.get_parent() == table_palavras):
				focus.text = letra
	if (event is InputEventWithModifiers):
		pass


func _verificar_palavra(p: String):
	var inicio = palavras[p]["posicao"]
	var direcao = palavras[p]["direcao"]
	var lista = []
	var certo = true
	for i in range(len(p)):
		lista.append(str(inicio + direcao*i))
		dicio_solucao[lista[i]]["exibir"] = dicio_solucao[lista[i]]["botao"].text
		if (p[i] in special_char):
			certo = certo and (special_char[p[i]] == dicio_solucao[lista[i]]["exibir"])
		elif (p[i] == " "):
			certo = certo
			dicio_solucao[lista[i]]["botao"].text = " "
		else:
			certo = certo and (p[i] == dicio_solucao[lista[i]]["exibir"])
	if (certo):
		palavras[p]["resolvida"] = true
		for i in lista:
			dicio_solucao[i]["botao"].disabled = true
			dicio_solucao[i]["botao"].text = dicio_solucao[i]["resposta"]
	
	
func _gerar_special_char_dicio() -> void:
	var glossario = File.new()
	glossario.open(glossario_acentuacao, File.READ)
	var saida = JSON.parse(glossario.get_as_text()).result
	for i in saida:
		for j in saida[i]:
			special_char[j] = i
	
func _gerar_grafo_completo(entrada: Dictionary) -> Dictionary:
	var saida = {}
	for i in entrada:
		saida[i] = {"possiveis": [], "adjacencias": [], "acesso": false, "dicas": entrada[i]["dicas"]}
	
	for i in saida:
		for k in i:
			saida[i]["adjacencias"].append(k)
		for j in saida:
			for k in i:
				if (i != j and k in j and not j in saida[i]["possiveis"]):
					saida[i]["possiveis"].append(j)
	return saida

func _gerar_grafo_jogo(grafo_completo: Dictionary):
	var tempo_inicial = OS.get_ticks_msec()
	var tempo_atual = 0
	var melhor_grafo = _gerar_grafo_concorrente(grafo_completo.duplicate(true))
	var melhor_validade = _validar_jogo(melhor_grafo)
	var melhor_pontuacao = _calcular_pontuacao(melhor_grafo)
#	print(melhor_pontuacao)
	while tempo_atual < tempo_inicial + DELAY or not melhor_validade:
		var grafo_atual = _gerar_grafo_concorrente(grafo_completo.duplicate(true))
		var validade_atual = _validar_jogo(grafo_atual)
		var pontuacao_atual = _calcular_pontuacao(grafo_atual)
		tempo_atual = OS.get_ticks_msec()
		if (validade_atual):
			
			if not melhor_validade:
				melhor_grafo = grafo_atual
				melhor_validade = validade_atual
				melhor_pontuacao = pontuacao_atual
			elif (pontuacao_atual < melhor_pontuacao):
				melhor_grafo = grafo_atual
				melhor_validade = validade_atual
				melhor_pontuacao = pontuacao_atual
#			printt("melhor", melhor_pontuacao)
#		print(melhor_pontuacao)
#	print(melhor_grafo)
	return melhor_grafo
	

func _gerar_grafo_concorrente(grafo_completo: Dictionary) -> Dictionary:
	var vizinhanca = []
	var saida = {}
	var chaves = grafo_completo.keys()
	var horizontal = randi()
	chaves.shuffle()
	while len(chaves) > 0:
		var at = chaves.pop_front()
		if saida.size() == 0:
			saida[at] = grafo_completo[at]
			saida[at]["horizontal"] = (horizontal%2 == 1)
			vizinhanca.append_array(grafo_completo[at]["possiveis"])
		elif at in vizinhanca:
			var chaves_locais = saida.keys()
			var vizinho = chaves_locais[randi()%len(chaves_locais)]
#			for i in chaves_locais:
#				if at in grafo_completo[i]["possiveis"]:
#					vizinho = i
			saida[at] = grafo_completo[at]
			var pat = randi()%len(at)
			var pvi = randi()%len(vizinho)
			
#			while at[pat] != vizinho[pvi]: # or len(saida[at]["adjacencias"][pat]) > 1 or len(saida[vizinho]["adjacencias"][pvi]) > 1:
			while at[pat] != saida[vizinho]["adjacencias"][pvi]:
				pat = randi()%len(at)
				vizinho = chaves_locais[randi()%len(chaves_locais)]
				pvi = randi()%len(vizinho)
			saida[at]["adjacencias"][pat] = vizinho
			saida[vizinho]["adjacencias"][pvi] = at
			saida[at]["horizontal"] = not saida[vizinho]["horizontal"]
			vizinhanca.append_array(grafo_completo[at]["possiveis"])
			# vizinhanca precisa ser atualizada aqui
			vizinhanca = []
			for i in saida.keys():
				for j in saida[i]["possiveis"]:
					if j in saida.keys():
						continue
					else:
						for k in saida[i]["adjacencias"]:
							if (len(k) == 1 and k in j):
								vizinhanca.append(j)
		elif chaves.empty():
			#do nothing
			pass
		else:
			chaves.push_back(at)
	return saida

func _validar_jogo(entrada: Dictionary) -> bool:
	# primeiro se valida se todas as arestas existem
	for i in entrada.keys():
		var grafo_conexo = false
		for j in entrada[i]["adjacencias"]:
			if (j in entrada.keys()):
				grafo_conexo = true
#				if not i in entrada[j]["adjacencias"]:
#					print(entrada[i], "\n", entrada[j], "\n")
#					return false
		if not grafo_conexo:
			return false
	
	# Calcula a posicao de inicio de cada palavra atraves de uma busca em largura
	
	var inicio = entrada.keys()[randi()%len(entrada.keys())]
	entrada[inicio]["posicao"] = Vector2.ZERO
	if entrada[inicio]["horizontal"]:
		entrada[inicio]["direcao"] = Vector2.RIGHT
	else:
		entrada[inicio]["direcao"] = Vector2.DOWN
	
	_busca_profundidade(entrada, inicio)
	var offset = Vector2.ZERO
	for i in entrada:
		if entrada[i]["posicao"].x < offset.x:
			offset.x = entrada[i]["posicao"].x
		if entrada[i]["posicao"].y < offset.y:
			offset.y = entrada[i]["posicao"].y
#	print("\n", entrada)
	# Final se valida se nao ha conflito entre as pecas
	var mapa = {}
	for i in entrada.keys():
		entrada[i]["posicao"] -= offset
		entrada[i]["resolvida"] = false
#		if (entrada[i]["posicao"].x > colunas or entrada[i]["posicao"].y > linhas):
#			print(entrada[i]["posicao"])
#			return false
		for j in range(len(i)):
			var pos = String(entrada[i]["posicao"] + entrada[i]["direcao"]*j)
			if not pos in mapa:
				mapa[pos] = i[j]
			elif mapa[pos] != i[j]:
				return false
		## verify caps
		var pi = String(entrada[i]["posicao"] - entrada[i]["direcao"])
		var pf = String(entrada[i]["posicao"] + entrada[i]["direcao"]*len(i))
		if mapa.has(pi) or mapa.has(pf):
			return false
	return true

func _gerar_posicoes(entrada: Dictionary) -> Dictionary:
	var saida = {}
	var offset = Vector2.ZERO
	for i in entrada:
		if entrada[i]["posicao"].x < offset.x:
			offset.x = entrada[i]["posicao"].x
		if entrada[i]["posicao"].y < offset.y:
			offset.y = entrada[i]["posicao"].y
	for i in entrada.keys():
		for j in range(len(i)):
			var pos = String(entrada[i]["posicao"] + entrada[i]["direcao"]*j - offset)
#			var pos = String(entrada[i]["posicao"] + entrada[i]["direcao"]*j)
			if not pos in saida:
				saida[pos] = i[j]
	return saida

func _busca_profundidade(dicionario: Dictionary, item: String):
	for i in range(len(dicionario[item]["adjacencias"])):
		var item_i = dicionario[item]["adjacencias"][i]
		if item_i in dicionario:
			if not "posicao" in dicionario[item_i].keys():
				if dicionario[item_i]["horizontal"]:
					dicionario[item_i]["direcao"] = Vector2.RIGHT
				else:
					dicionario[item_i]["direcao"] = Vector2.DOWN
				var pos_j = dicionario[item_i]["adjacencias"].find(item)
				dicionario[item_i]["posicao"] = dicionario[item]["posicao"] + dicionario[item]["direcao"]*i - dicionario[item_i]["direcao"]*pos_j
				_busca_profundidade(dicionario, item_i)

func _calcular_pontuacao(entrada: Dictionary) -> float:
	var inicio = Vector2.ZERO
	var fim = Vector2.ZERO
	for i in entrada:
#		printt(i, entrada)
		var p1 = entrada[i]["posicao"]
		var p2 = entrada[i]["posicao"] + entrada[i]["direcao"] * len(i)
		if (p1.x < inicio.x):
			inicio.x = p1.x
		if (p1.y < inicio.y):
			inicio.y = p1.y
		if (p2.x > fim.x):
			fim.x = p2.x
		if (p2.y > fim.y):
			fim.y = p2.y
	var tamanho = fim - inicio
#	print(tamanho.x * H_SCORE + tamanho.y * V_SCORE)
	return tamanho.x * tamanho.x * tamanho.x *H_SCORE + tamanho.y * tamanho.y * tamanho.y * V_SCORE


func _gen_cross_word(word_list: Dictionary):
	var adj = _gerar_grafo_completo(word_list)
	palavras = _gerar_grafo_jogo(adj)
#	print(palavras)
	
	# Adicionar a lista de dicas
	var iterador = 1
	for i in palavras:
		var novoLabel = Label.new()
		novoLabel.rect_position = palavras[i]["posicao"] * tamanho_celula
		novoLabel.modulate = cor_numeracao
		if (palavras[i]["direcao"] == Vector2.DOWN):
			novoLabel.text = "%d |"%[iterador]
			novoLabel.rect_position.x += tamanho_celula/2.0
		else:
			novoLabel.text = "%d --"%[iterador]
		numeracao.add_child(novoLabel)

		var dica = RichTextLabel.new()
		var linh = LineEdit.new()
		var ld = len(palavras[i]["dicas"])
		dica.text = str(iterador) + " " + palavras[i]["dicas"][randi()%ld]
		dica.fit_content_height = true
		linh.max_length = len(i)
		linh.placeholder_text = "%d letras"%len(i)
		lista_dicas.add_child(dica)
		lista_dicas.add_child(linh)
		iterador += 1

	# Criar cada uma das palavras
#	var lista_posicoes := []
	for i in palavras:
		var pos = palavras[i]["posicao"]
		var dir = palavras[i]["direcao"]
		for j in range(len(i)):
#			var posstr = "%d,%d"%[pos.x+dir.x*j, pos.y+dir.y*j]
			var posstr = str(pos+dir*j)
			dicio_solucao[posstr] = {"resposta":i[j],
									"exibir": " ",
#									"certo": false,
									"posicao":pos + dir*j}

	# Criar botoes
	for i in dicio_solucao:
		var novoBotao = Button.new()
		novoBotao.rect_min_size = Vector2(tamanho_celula, tamanho_celula)
		novoBotao.rect_position = dicio_solucao[i]["posicao"]*tamanho_celula
		dicio_solucao[i]["botao"] = novoBotao
		table_palavras.add_child(novoBotao)
#	print(dicio_solucao)

func _parse_game_contains(raw_dicio: Dictionary):
	var saida = {}
	
	for i in raw_dicio["game:contains"]:
		var value = i["@value"] as String
		var chave_valor
		if "|" in value:
			chave_valor = value.split("|")
		if ":" in value:
			chave_valor = value.split(":")
		print(chave_valor)
		saida[chave_valor[0]] = {"dicas": [chave_valor[1]]}
	
#	var palavras_test = {}
#
#	palavras_test["CACHORRO"] = {"dicas": ["Quem botou para nos beber?", "Animal domestico que morde.", "Satanas do Chaves"]}
#	palavras_test["GATO"] = {"dicas": ["Felino Doméstico", "É você Satanas?", "Divindade egípicia"]}
#	palavras_test["LEÃO"] = {"dicas": ["Aslam", "Simbá", "Sport, Avaí, Vitória, Bragantino, Macaé, Fortaleza, Portuguesa, Clube do Remo, Nacional, CRAC, Guarani de Juazeiro, Villa Nova..."]}
#	palavras_test["PANDA"] = {"dicas": ["Animal preto e branco", "Never say no to...", "Urso que pesa apenas 100 quilos", "A raposa de fogo é um?", "Kung Fu..."]}
#	palavras_test["CAVALO"] = {"dicas": ["Animal muito usado como tração", "Sinônimo de potência"]}
#	palavras_test["CORSA"] = {"dicas": ["Animal que inspirou o nome de um carro da Chevrolet"]}
	
	return saida
	
	
