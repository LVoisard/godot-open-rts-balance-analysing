@tool
extends EditorPlugin

var game_balance

func _enter_tree() -> void:
	game_balance = preload("res://addons/game_balance/game_balance_dock.tscn").instantiate()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, game_balance)
	
	#var client = HTTPClient.new()
	#client.request(client.METHOD_GET, "/index.php", [""], "")

	
func _exit_tree() -> void:
	pass
