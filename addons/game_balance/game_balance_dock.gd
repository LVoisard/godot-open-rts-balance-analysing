@tool
extends Control

@export var puglin_settings_path: String
@export var game_files_path: String
@export var dir_text: LineEdit
@export var file_tree: Tree

const NAME_COLUMN_INDEX = 0
const VIEW_FILE_COLUMN_INDEX = 1
const TYPE_COLUMN_INDEX = 2
const IGNORE_COLUMN_INDEX = 3

signal files_loaded

var scanned_game_files

func _ready() -> void:
	files_loaded.connect(on_files_loaded)

func on_scan_files_button_pressed() -> void:
	if dir_text.text.is_empty():
		push_warning("Source Code Directory Not Specified")
		return
	
	var path = dir_text.text
	scanned_game_files = get_all_files(path, ["gd", "cs", "tscn"])	
	files_loaded.emit()

func on_files_loaded() -> void:
	
	# setup tree
	file_tree.clear()
	
	file_tree.set_column_expand(VIEW_FILE_COLUMN_INDEX, false)
	file_tree.set_column_expand(TYPE_COLUMN_INDEX, false)
	file_tree.set_column_expand(IGNORE_COLUMN_INDEX, false)
	file_tree.set_column_custom_minimum_width(TYPE_COLUMN_INDEX, 120)
	file_tree.set_column_custom_minimum_width(IGNORE_COLUMN_INDEX, 50)
	file_tree.set_column_title(NAME_COLUMN_INDEX, "Name")
	file_tree.set_column_title(TYPE_COLUMN_INDEX, "Type")
	file_tree.set_column_title(IGNORE_COLUMN_INDEX, "Ignore")
	
	
	var root = file_tree.create_item()
	root.set_cell_mode(NAME_COLUMN_INDEX, TreeItem.CELL_MODE_CHECK)
	root.set_icon(0, get_theme_icon("Folder", 'EditorIcons'))
	root.set_text(NAME_COLUMN_INDEX, scanned_game_files.name)
	root.set_editable(NAME_COLUMN_INDEX, true)
	root.set_metadata(NAME_COLUMN_INDEX, scanned_game_files)
	

	for child in scanned_game_files.children:
		if child.files.size() == 0 && child.children.size() == 0: continue
		create_sub_tree(root, child)
		
	for file in scanned_game_files.files:
		var f = file_tree.create_item(root)
		f.set_cell_mode(NAME_COLUMN_INDEX, TreeItem.CELL_MODE_CHECK)
		f.set_editable(NAME_COLUMN_INDEX, true)
		
		var info = ""		
		if file.script != null and file.scene != null:
			info = "( script / scene )"
		elif file.script != null and file.scene == null:
			info = "( script )"
		elif file.script == null and file.scene != null:
			info = "( scene )"
		
		f.set_text(NAME_COLUMN_INDEX, file.name + " " + info)
		f.set_icon(NAME_COLUMN_INDEX, get_theme_icon("File", 'EditorIcons'))
		f.set_cell_mode(TYPE_COLUMN_INDEX, TreeItem.CELL_MODE_RANGE)
		f.set_text(TYPE_COLUMN_INDEX, "Entity,Component")
		f.set_range(TYPE_COLUMN_INDEX, file.probable_type)
		f.set_editable(TYPE_COLUMN_INDEX, true)
		if file.user_script != null:
			f.add_button(VIEW_FILE_COLUMN_INDEX, get_theme_icon("FileAccess", 'EditorIcons'))
			f.set_metadata(VIEW_FILE_COLUMN_INDEX, file.user_script)
		if file.has_signals:
			f.set_checked(NAME_COLUMN_INDEX, true)
			f.propagate_check(NAME_COLUMN_INDEX)

	if on_item_checked not in file_tree.item_edited.get_connections().map(func(x): return x["callable"]):
		file_tree.item_edited.connect(on_item_checked)
	if on_item_button_pressed not in file_tree.button_clicked.get_connections().map(func(x): return x["callable"]):
		file_tree.button_clicked.connect(on_item_button_pressed)
	
	#file_tree.check_propagated_to_item.connect(prop)

func create_sub_tree(root: TreeItem, item) -> void:
	
	var tree_item = file_tree.create_item(root)
	tree_item.set_collapsed_recursive(true)
	tree_item.set_cell_mode(NAME_COLUMN_INDEX, TreeItem.CELL_MODE_CHECK)
	tree_item.set_editable(NAME_COLUMN_INDEX, true)
	tree_item.set_icon(NAME_COLUMN_INDEX, get_theme_icon("Folder", 'EditorIcons'))
	tree_item.set_metadata(NAME_COLUMN_INDEX, item)
	tree_item.set_text(NAME_COLUMN_INDEX, item.name)	
	tree_item.add_button(IGNORE_COLUMN_INDEX, get_theme_icon("Eraser", 'EditorIcons'), -1, false, "Erase this item and it's children from the tree.")
	#tree_item._on_selected
	for child in item.children:
		if child.files.size() == 0 && child.children.size() == 0: continue
		create_sub_tree(tree_item, child)
	
	for file in item.files:
		var f = file_tree.create_item(tree_item)
		f.set_cell_mode(NAME_COLUMN_INDEX, TreeItem.CELL_MODE_CHECK)
		f.set_editable(NAME_COLUMN_INDEX, true)
		var info = ""		
		if file.script != null and file.scene != null:
			info = "( script / scene )"
		elif file.script != null and file.scene == null:
			info = "( script )"
		elif file.script == null and file.scene != null:
			info = "( scene )"
			
		
		f.set_text(NAME_COLUMN_INDEX, file.name + " " + info)
		f.set_icon(NAME_COLUMN_INDEX, get_theme_icon("File", 'EditorIcons'))
		f.set_cell_mode(TYPE_COLUMN_INDEX, TreeItem.CELL_MODE_RANGE)
		f.set_text(TYPE_COLUMN_INDEX, "Entity,Component")
		f.set_range(TYPE_COLUMN_INDEX, file.probable_type)
		f.set_editable(TYPE_COLUMN_INDEX, true)
		if file.user_script != null:
			f.add_button(VIEW_FILE_COLUMN_INDEX, get_theme_icon("FileAccess", 'EditorIcons'))
			f.set_metadata(VIEW_FILE_COLUMN_INDEX, file.user_script)
		if file.has_signals:
			f.set_checked(NAME_COLUMN_INDEX, true)
			f.propagate_check(NAME_COLUMN_INDEX)
	
	if tree_item.get_children().is_empty():
		root.remove_child(tree_item)
	

func get_all_files(path: String, file_ext:= [""]):
	var dir = DirAccess.open(path)
	
	var files = JsonItemDirectory.new()
	
	files.name = dir.get_current_dir().split("/")[-1]
	files.files = []
	files.children = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var p = dir.get_current_dir(false) + "/" + file_name
			files.children.append(get_all_files(p, file_ext))
		else:
			var ext = file_name.get_extension()
			if !file_ext.is_empty() and ext not in file_ext:
				file_name = dir.get_next()
				continue
				
			var existing_file = files.files.filter(func(x: JsonItemFile): return x.name == file_name.get_basename())
			if existing_file.size() == 1:
				file_name = dir.get_next()
				continue
				
			files.files.append(JsonItemFile.new(file_name, dir, file_ext))
			
		file_name = dir.get_next()
	return files
	
func on_save_config_pressed() -> void:
	var root = file_tree.get_root()
	
	while (root != null):
		root = root.get_next()
	
	var data = root.get_metadata(NAME_COLUMN_INDEX) as JsonItemDirectory
	# cant do this, need to iterate and find the selected ones
	var str = JSON.stringify(data.to_data_dict(), "\t")
	print(str)
	#$var config_json = JSON.stringify(file_tree.get_root().get_child(-1).get_metadata(VIEW_FILE_COLUMN_INDEX))
	#print(config_json)
	print("saved")
	pass

func iterate_files():
	pass

func iterate_children():
	pass


func on_item_checked() -> void:
	if file_tree.get_selected_column() == NAME_COLUMN_INDEX:
		file_tree.get_selected().propagate_check(NAME_COLUMN_INDEX)
		
func on_item_button_pressed(item: TreeItem, col,id, ind) -> void:
	print("joe")
	if col == IGNORE_COLUMN_INDEX:
		item.free()
	elif col == VIEW_FILE_COLUMN_INDEX:
		EditorInterface.edit_resource(load(item.get_metadata(VIEW_FILE_COLUMN_INDEX)))

class JsonItemDirectory:
	var name: String
	var children: Array
	var files : Array
	
	func to_data_dict() -> Dictionary:
		var dict = {
			"name" : self.name,
			"children" : self.children.map(func(x): return x.to_data_dict()),
			"files": self.files.map(func(x): return x.to_data_dict())
		}
		return dict
	
class JsonItemFile:
	var name: String
	var user_script: Script
	var scene: PackedScene
	var parent_class: Script
	var probable_type: Types
	var has_signals: bool
	
	func _init(file_name: String, dir: DirAccess, file_ext: Array) -> void:
		var gditem = dir.file_exists(file_name.get_basename() + "." + file_ext[0])
		var csItem = dir.file_exists(file_name.get_basename() + "." + file_ext[1])
		var sceneItem = dir.file_exists(file_name.get_basename() + "." + file_ext[2])
		
		var base_file_path = dir.get_current_dir(false).path_join(file_name.get_basename())
		self.name = file_name.get_basename()
		self.user_script = load(base_file_path + "." + file_ext[0]) if gditem else load(base_file_path + "." + file_ext[1]) if csItem else null
		self.scene = load(base_file_path + "." + file_ext[2]) if sceneItem else null
		self.probable_type = Types.Entity if user_script != null and self.scene != null else Types.Component
		
		if user_script != null:
			self.parent_class = user_script.get_base_script()
			self.has_signals = user_script.get_script_signal_list().size() > 0
	
	func to_data_dict() -> Dictionary:
		var dict = {
			"name" : self.name,
			"user_script" : self.user_script.resource_path if self.user_script != null else "",
			"scene": self.scene.resource_path if self.scene != null else "",
			"parent_class": self.parent_class.resource_path if self.parent_class != null else "",
			"probable_type": self.probable_type,
			"has_signals": self.has_signals
		}
		return dict
			
	
enum Types {
	Entity,
	Component,
}
