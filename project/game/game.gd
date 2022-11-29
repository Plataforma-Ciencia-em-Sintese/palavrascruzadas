extends Control


#  [DOCSTRING]


#  [SIGNALS]
signal game_over

#  [ENUMS]
enum FORMAT {WIDER, TALL, SQUARE}

#  [CONSTANTS]
const RATIO = 1080/840.0
const ALLOWED_KEYS = [81, 87, 69, 82, 84, 89, 85, 73, 79, 80, 65, 83, 68, 70, 71, 72, 74, 75, 76, 90, 88, 67, 86, 66, 78, 77, 59, 16777220]
const SPECIAL_CHAR_DICIO = {'Á': 'A', 'À': 'A', 'Ã': 'A', 'Â': 'A', 'É': 'E', 'È': 'E', 'Ẽ': 'E', 'Ê': 'E', 'Í': 'I', 'Ì': 'I', 'Ĩ': 'I', 'Î': 'I', 'Ó': 'O', 'Ò': 'O', 'Õ': 'O', 'Ô': 'O', 'Ú': 'U', 'Ù': 'U', 'Ũ': 'U', 'Û': 'U', 'Ç': 'C', 'Ñ': 'N', '': ' ', ' ': ' '}

#  [EXPORTED_VARIABLES]
export (NodePath) var gameTable
export (NodePath) var clueDisplay

#  [PUBLIC_VARIABLES]perda de passo impressão 3d


#  [PRIVATE_VARIABLES]
var _sizeX := 0
var _sizeY := 0
var _game_buttons = {}
var _number_labels = {}
var _numbered_clues = {}
var _tips = 10

var _allowed_keys := []
var _special_char_dicio := {}

var _selected_item := "0"
var _last_selected_button
var _solved_itens := {}

#  [ONREADY_VARIABLES]
onready var _gameTable = get_node(gameTable) as GridContainer
onready var _clueDisplay = get_node(clueDisplay) as VBoxContainer
onready var _orientation = _clueDisplay.find_node("Orientation") as RichTextLabel
onready var _clueNumber = _clueDisplay.find_node("Number") as RichTextLabel
onready var _clue = _clueDisplay.find_node("Clue") as RichTextLabel

#  [OPTIONAL_BUILT-IN_VIRTUAL_METHOD]
#func _init() -> void:
#	pass


#  [BUILT-IN_VIRTUAL_METHOD]
func _ready() -> void:
	_override_theme()
	
#	print(_allowed_keys)
#	print(_clueDisplay)
#	print(_orientation)
#	print(_clueNumber)
#	print(_clue)

#	_mount_special_char()
#	_mount_valid_keys()
	
#	print(_allowed_keys)
	_read_data()
#	printt(_sizeX, _sizeY)
	_adjust_size()
#	printt(_sizeX, _sizeY)
	_populate_table()
	_populate_solved_dict()
	_verify_endgame()

func _input(event):
#	print(event)
#	if (event is InputEventMouseButton) and event.is_pressed():
	if (event is InputEventMouseButton) and not event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			var dic_button = _verify_owner(self.get_focus_owner()) as Dictionary
			if dic_button.has("button"):
				_click_selected(dic_button)
				_last_selected_button = dic_button
				_show_clue(_selected_item)
	elif not (event.is_pressed()):
		var dic_button = _verify_owner(self.get_focus_owner()) as Dictionary
		_last_selected_button = dic_button
		if dic_button.has("button"):
			if (event.is_action("ui_up")):
				_verify_selected(dic_button)
			elif (event.is_action("ui_down")):
				_verify_selected(dic_button)
			elif (event.is_action("ui_left")):
				_verify_selected(dic_button)
			elif (event.is_action("ui_right")):
				_verify_selected(dic_button)
			_show_clue(_selected_item)
#	elif event is InputEventKey and event.is_pressed():
#		event as InputEventKey
#		printt(event.get_scancode(), event.as_text())
#	elif event is InputEventKey and event.is_pressed():
#		var event_key = event as InputEventKey
#		var dic_button = _verify_owner(self.get_focus_owner()) as Dictionary
#		if ((event_key.get_physical_scancode() in _allowed_keys) and dic_button.has("button")):
#			if not dic_button["button"].disabled:
#				dic_button["value"] = char(event_key.get_scancode())
#				dic_button["button"].text = char(event_key.get_scancode())
#			_next_button(dic_button)
#			_show_selected_word()
#			_verify_solution()

#func _unhandled_input(event):
#	print(event)

func _unhandled_key_input(event):
#	print(event)
#	if event is InputEventKey:
#		print(event.is_pressed())
		
	if event is InputEventKey and event.is_pressed():
		var event_key = event as InputEventKey
		var dic_button = _verify_owner(self.get_focus_owner()) as Dictionary
		_last_selected_button = dic_button
#		if ((event_key.get_physical_scancode() in _allowed_keys) and dic_button.has("button")):
		if ((event_key.get_physical_scancode() in ALLOWED_KEYS) and dic_button.has("button")):
			if not dic_button["button"].disabled:
				dic_button["value"] = char(event_key.get_scancode())
				dic_button["button"].text = char(event_key.get_scancode())
			if (event_key.get_physical_scancode() == 16777220): #Backspace
				_previous_button(dic_button)
			else:
				_next_button(dic_button)
			_show_selected_word()
			_verify_solution()
			_verify_endgame()
			
#	elif (event is InputEventAction):
#		print(event)
			



#  [REMAINIG_BUILT-IN_VIRTUAL_METHODS]
#func _process(_delta: float) -> void:
#	pass


#  [PUBLIC_METHODS]




#  [PRIVATE_METHODS]

func _override_theme() -> void:
	# Game Table Theme
	var table_theme: Theme
	table_theme = $AspectRatioContainer/Separador/Panel/GameTable.get_theme()
	
	var box
	box = table_theme.get_stylebox("normal", "Button")
	box.bg_color = API.theme.get_color(API.theme.PL3)
	
	box = table_theme.get_stylebox("pressed", "Button")
	box.bg_color = API.theme.get_color(API.theme.PL1)
	
	box = table_theme.get_stylebox("hover", "Button")
	box.bg_color = API.theme.get_color(API.theme.PB)
	box.border_color = API.theme.get_color(API.theme.PD1)
	
	box = table_theme.get_stylebox("disabled", "Button")
	box.bg_color = API.theme.get_color(API.theme.PD2)
	
#	box = table_theme.get_stylebox("normal", "Table")
	
	table_theme.set_color("font_color", "Button", API.theme.get_color(API.theme.DARKGRAY))
	table_theme.set_color("font_color", "Label", API.theme.get_color(API.theme.PB))
	
	# number and clue
	var number: Theme
	var clue: Theme
	var default: Theme
	default = $AspectRatioContainer/Separador/Panel.get_theme()
#	number = $AspectRatioContainer/Separador/Panel/ClueDisplay/ClueContainer/Number.get_theme()
#	clue = $AspectRatioContainer/Separador/Panel/ClueDisplay/ClueContainer/Clue.get_theme()
#	number.set_color("font_color", "Label", API.theme.get_color(API.theme.PL1))
#	clue.set_color("font_color", "Label", API.theme.get_color(API.theme.PL1))

	default.set_color("default_color", "RichTextLabel", API.theme.get_color(API.theme.PB))
	default.set_color("font_color", "Label", API.theme.get_color(API.theme.PD2))
	
	box = default.get_stylebox("normal", "Label")
	box.border_color = API.theme.get_color(API.theme.PD2)
#	printt(default, number, clue)
	
	

func _verify_solution() -> void:
#	print(_solved_itens)
	for i in _numbered_clues:
		var correct = true
		for j in _numbered_clues[i]["buttons"]:
			correct = correct and _button_valid(j)
		if correct:
			_solved_itens[i] = true
			for j in _numbered_clues[i]["buttons"]:
				j["button"].disabled = true
#				if (j["solution"] in _special_char_dicio):
#					j["button"].text = _special_char_dicio[j["solution"]]
				if (j["solution"] in SPECIAL_CHAR_DICIO):
#					print(j["solution"])
#					j["button"].text = SPECIAL_CHAR_DICIO[j["solution"]]
					j["button"].text = j["solution"]

func _verify_endgame() -> void:
	var endgame = true
	for i in _game_buttons:
		endgame = endgame and _game_buttons[i]["button"].disabled
	if endgame:
		$gameOver.show()
#		print("Jogo terminado")
		emit_signal("game_over")

func _button_valid(button: Dictionary) -> bool:
	if button["solution"] == "" or button["solution"] == " ":
		button["button"].text = ""
		return true
#	if button["solution"] in _special_char_dicio:
	if button["solution"] in SPECIAL_CHAR_DICIO:
#		print(button["solution"])
		var character = button["solution"]
		if character == "" or character == " ":
			button["button"].text = ""
#			return (_special_char_dicio[character] == button["value"])
#			return (SPECIAL_CHAR_DICIO[character] == button["value"])
			return true
		else:
			return (SPECIAL_CHAR_DICIO[character] == button["value"])
#			return false
	else:
		return (button["solution"] == button["value"])
#	return false

func _show_selected_word() -> void:
	for i in _game_buttons:
		if _selected_item in _game_buttons[i]["affiliation"]:
			_game_buttons[i]["button"].pressed = true
		else:
			_game_buttons[i]["button"].pressed = false

func _next_button(button: Dictionary) -> void:
	var direction := Vector2.ZERO
	if (_numbered_clues[_selected_item]["horizontal"]):
		direction = Vector2.RIGHT
	else:
		direction = Vector2.DOWN
	var position = str(button["position"]+direction)
	if (_game_buttons.has(position)):
		var next = _game_buttons[position]
		next["button"].grab_focus()
#		print(next["button"].text)
		if (next["button"].text == ' '):
			_next_button(next)
	
func _previous_button(button: Dictionary) -> void:
	var direction := Vector2.ZERO
	if (_numbered_clues[_selected_item]["horizontal"]):
		direction = Vector2.LEFT
	else:
		direction = Vector2.UP
	var position = str(button["position"]+direction)
	if (_game_buttons.has(position)):
		var prev = _game_buttons[position]
		prev["button"].grab_focus()
#		print(prev["button"].text)
		if (prev["button"].text == ' '):
			_previous_button(prev)

func _show_clue(number: String) -> void:
	_clueNumber.text = number
	_clueNumber.show()
	if (number in _numbered_clues):
#		printt(number, _numbered_clues[number])
		_clue.text = _numbered_clues[number]["clue"]
		_clue.show()
		if _numbered_clues[number]["horizontal"]:
			_orientation.text = "Horizontal"
		else:
			_orientation.text = "Vertical"
		_orientation.show()
		_show_selected_word()
	

func _click_selected(_selected_button: Dictionary) -> void:
#	print(_selected_button["affiliation"])
	var len_affiliation = len(_selected_button["affiliation"])
	if (len_affiliation > 1):
		if (_solved_itens[_selected_button["affiliation"][0]]):
			_selected_item = _selected_button["affiliation"][1]
		elif (_solved_itens[_selected_button["affiliation"][1]]):
			_selected_item = _selected_button["affiliation"][0]
	elif (_selected_item in _selected_button["affiliation"]):
#		var len_affiliation = len(_selected_button["affiliation"])
		if (len_affiliation > 1) and _selected_button["button"].is_hovered():
			# Se eh um segundo click em um botao selecionado
#			printt(_solved_itens, _selected_button["affiliation"])
			if (_selected_button == _last_selected_button):
#				printt(_selected_button, _last_selected_button)
				var position = _selected_button["affiliation"].bsearch(_selected_item)
				_selected_item = _selected_button["affiliation"][posmod(position + 1, len_affiliation)]
	else:
		_selected_item = _selected_button["affiliation"][0]

func _verify_selected(_selected_button: Dictionary) -> void: #verifica qual eh a dica a ser apresentada
	if not _selected_item in _selected_button["affiliation"]:
		_selected_item = _selected_button["affiliation"][0]

func _verify_owner(button: Button) -> Dictionary:
	for i in _game_buttons:
		if _game_buttons[i]["button"] == button:
#			$Keyboard.update_keyset(_game_buttons[i]["keyboard"])
#			_last_selected_button = _game_buttons[i]
			return _game_buttons[i]
	return {}


func _read_data() -> void:
	var game_data = API.get_game()
#	print(game_data)
	var size := Vector2.ZERO
	var iteration = 1
	for i in game_data:
		var position = game_data[i]["position"] + game_data[i]["direction"]*(len(i))
		if position.x > size.x:
			size.x = position.x
		if position.y > size.y:
			size.y = position.y
			
		var label_position = str(game_data[i]["position"] - game_data[i]["direction"])
#		var label_position = str(game_data[i]["position"])
		var label = Label.new()
		label.text = str(iteration)
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		label.set_v_size_flags(3)
#		print(label_position)
		_number_labels[label_position] = {"label": label}
		_numbered_clues[str(iteration)] = {}
		_numbered_clues[str(iteration)]["clue"] = game_data[i]["clue"]
		_numbered_clues[str(iteration)]["horizontal"] = game_data[i]["horizontal"]
		_numbered_clues[str(iteration)]["buttons"] = []
		for j in range(len(i)):
			var button_position = str(game_data[i]["position"] + game_data[i]["direction"]*j)
			if not button_position in _game_buttons:
				var button = Button.new()
				button.toggle_mode = true
				_game_buttons[button_position] = {"solution": i[j],
												"affiliation": [str(iteration)],
												"button": button,
												"solved": false,
												"position": game_data[i]["position"] + game_data[i]["direction"]*j,
												"value": "",
												"keyboard": game_data[i]["keyboard"][j]}
			else:
				_game_buttons[button_position]["affiliation"].append(str(iteration))
			
			#tratar espacos
			if (i[j] == " "):
#				print("botão vazio")
				_game_buttons[button_position]["solved"] = true
				_game_buttons[button_position]["button"].text = " "
				_game_buttons[button_position]["button"].disabled = true
			
			_numbered_clues[str(iteration)]["buttons"].append(_game_buttons[button_position])
		iteration += 1
	
#	print(_numbered_clues)
	
	_sizeX = size.x
	_sizeY = size.y
	
func _adjust_size() -> void:
	if _sizeY*RATIO > _sizeX+1:
		_sizeX += 1
		_adjust_size()
	elif _sizeY*RATIO < _sizeX-1:
		_sizeY += 1
		_adjust_size()

func _mount_valid_keys() -> void:
	var file = File.new()
	file.open("res://game/allowed_keys", File.READ) #isso aqui nao vai ser lido
	var f_output = file.get_as_text()
	f_output = f_output.split("\n")
	for i in range(len(f_output)):
		if (i%2 == 1):
			_allowed_keys.append(int(f_output[i]))

func _populate_solved_dict() -> void:
	for i in _numbered_clues:
		_solved_itens[i] = false

func _populate_table() -> void:
	print()
	_gameTable.columns = _sizeX
	for i in range(_sizeY):
		for j in range(_sizeX):
			var newAspect = AspectRatioContainer.new()
			newAspect.set_h_size_flags(3)
			newAspect.set_v_size_flags(3)
			_gameTable.add_child(newAspect)
			var position = "(%d, %d)"%[j, i]
			if (position in _number_labels):
#				print(position)
				newAspect.add_child(_number_labels[position]["label"])
			elif (position in _game_buttons):
				newAspect.add_child(_game_buttons[position]["button"])
			else:
				var newPanel = Panel.new()
				newAspect.add_child(newPanel)

func _mount_special_char() -> void: #O navegador nao vai encontrar esse arquivo
	var glossary = File.new()
	glossary.open("res://game/glossario_acentuacao.json", File.READ)
	var output = JSON.parse(glossary.get_as_text()).result
#	print(output)
	for i in output:
		for j in output[i]:
			_special_char_dicio[j] = i
#	print (_special_char_dicio)

#  [SIGNAL_METHODS]


func _on_Tip_pressed():
	if (_tips > 0):
		if _last_selected_button != null:
#			if not _last_selected_button["solved"]:
			if not _last_selected_button["button"].is_disabled():
				_tips -= 1
				$AspectRatioContainer/Separador/HBoxContainer/AspectRatioContainer2/tipbutton/tips.text = str(_tips)
				_last_selected_button["value"] = _last_selected_button["solution"]
				_last_selected_button["button"].text = _last_selected_button["solution"]
#				_last_selected_button["solved"] = true
				_last_selected_button["button"].set_disabled(true)
				_next_button(_last_selected_button)
				_verify_solution()
				_verify_endgame()
#			print(_selected_button)


func _on_home_pressed():
	API.reset_words()
	get_tree().change_scene("res://intro/intro.tscn")
	
	
func _on_help_pressed():
	$HowToPlay.visible = not $HowToPlay.visible
	$AspectRatioContainer/Separador/Panel.visible = not $AspectRatioContainer/Separador/Panel.visible
