#tool
class_name RequestCommon #, res://class_name_icon.svg
extends Request


#  [DOCSTRING]


#  [SIGNALS]
signal all_request_common_completed


#  [ENUMS]


#  [CONSTANTS]


#  [EXPORTED_VARIABLES]


#  [PUBLIC_VARIABLES]


#  [PRIVATE_VARIABLES]
var _short_title: String = String() \
		setget set_short_title, get_short_title

var _article_summary: String = String() \
		setget set_article_summary, get_article_summary

var _game_logo: ImageTexture = null \
		setget set_game_logo, get_game_logo


#  [ONREADY_VARIABLES]


#  [OPTIONAL_BUILT-IN_VIRTUAL_METHOD]
#func _init() -> void:
#	pass


#  [BUILT-IN_VURTUAL_METHOD]
#func _ready() -> void:
#	pass


#  [REMAINIG_BUILT-IN_VIRTUAL_METHODS]
#func _process(_delta: float) -> void:
#	pass


#  [PUBLIC_METHODS]
func set_short_title(new_value: String) -> void:
	_short_title = new_value


func get_short_title() -> String:
	return _short_title


func set_article_summary(new_value: String) -> void:
	_article_summary = new_value


func get_article_summary() -> String:
	return _article_summary


func set_game_logo(new_value: ImageTexture) -> void:
	_game_logo = new_value


func get_game_logo() -> ImageTexture:
	return _game_logo


#  [PRIVATE_METHODS]
 

#  [SIGNAL_METHODS]
