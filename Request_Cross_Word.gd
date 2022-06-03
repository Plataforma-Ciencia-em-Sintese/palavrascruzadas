extends HTTPRequest


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dicio = {}
var semaforo = Semaphore.new()
var test_input = "http://localhost:8000/jsons/23686.json"
#var test_input = "https://repositorio.canalciencia.ibict.br/api/items/23686"
var loaded = false


# Called when the node enters the scene tree for the first time.
func _ready():
#	print("api ready")
#	print("javascript: ", OS.has_feature("HTML5"))
#	print("android: ", OS.has_feature("Android"))
#	var link = test_input
	var link = OS.get_cmdline_args()[-1]
	self._requisitar_json(link)
	

func _requisitar_json(link: String):
	var result = -1
	var requi
	var retorno
	var saida
	while result != 0:
		requi = self.request(link)
		retorno = yield(self, "request_completed")
		var saida3 = retorno[3].get_string_from_utf8()
		saida = JSON.parse(saida3).result
		result = retorno[0]
		print(result)
	dicio = saida
	self.loaded = true
#	self.semaforo.post()
	
#	self.semaforo.post()
#	return saida



