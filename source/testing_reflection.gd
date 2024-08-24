extends Node

var directory_scripts = {}
var file_signals = {}

var node_lookup = {}
	
func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	get_tree().node_removed.connect(_node_removed)
	var files = get_all_files("./", ["gd", "cs"])
	
	var dir = DirAccess.open("./")
	
	for key in files.keys():		
		for file in files[key]:			
			var j = load(key + "/" + file)
			if file.get_extension() == "gd":
				if (j as GDScript).get_script_signal_list().size() > 0:
					var sig_list = (j as GDScript).get_script_signal_list()
					
					print(file)
					print((j as GDScript).get_script_constant_map())
					print((j as GDScript).get_script_property_list())
					print()
					print()
					#print(key.replace(dir.get_current_dir(false) + "/", "") + "/" + file)
					#print(sig_list.map(func(x): return x.name))
					file_signals[file] = sig_list.map(func(x): return [x.name, x.args.size()])
					#print((j as GDScript).resource_path.get_file())
			elif file.get_extention() == "tscn":
				(j as PackedScene)
	
	
	for sibling in get_parent().get_children():
		_node_added(sibling)
	
func _node_added(node: Node):
	if node.get_script() == null: return
	var script = node.get_script() as GDScript
	var script_name = script.resource_path.get_file()
	
	if (!file_signals.has(script_name)): return
	print(node.name, " entered")
	node_lookup[node] = Time.get_ticks_msec()
	# print(script.get_script_signal_list())
	for sig in file_signals[script_name]:
		if !script.has_script_signal(sig[0]): continue
		var callable
		match sig[1]:
			0: callable = _test0
			1: callable = _test1
			2: callable = _test2
			3: callable = _test3
			_: return
		node.connect(sig[0], callable.bind(node, sig[0]))
func _node_removed(node: Node):
	if node.get_script() == null: return
	var script = node.get_script() as GDScript
	var script_name = script.resource_path.get_file()
	if (script.resource_path.get_file() as String).begins_with("CannonShell.gd"):
		print(script.get_script_property_list())		 
		print("Parent: ", node.get("_unit"))
		print("Parent: ", node.get("_unit").get("attack_damage"))
		print("Target: ", node.get("target_unit").get("hp"))
	if (!node_lookup.has(node)): return
	for sig in file_signals[script_name]:
		if !script.has_script_signal(sig[0]): continue
		var callable
		match sig[1]:
			0: callable = _test0
			1: callable = _test1
			2: callable = _test2
			3: callable = _test3
			_: return
		node.disconnect(sig[0], callable.bind(node, sig[0]))
	print(node.name, " exited ", Time.get_ticks_msec() - node_lookup[node])
	node_lookup.erase(node)
	print()

func _test0(node: Node, sigName: String):
	print("Node ", node.get_script().resource_path.get_file(), " emitted ", sigName)
	
	
func _test1(param1, node: Node, sigName: String):
	print("Node ", node.get_script().resource_path.get_file(), " emitted ", sigName, " ", param1)

func _test2(param1, param2, node: Node, sigName: String):
	print("Node ", node.get_script().resource_path.get_file(), " emitted ", sigName," ", param1," ", param2)
	
func _test3(param1, param2, param3, node: Node, sigName: String):
	print("Node ", node.get_script().resource_path.get_file(), " emitted ", sigName, " ", param1, " ", param2, " ", param3)

func get_all_files(path: String, file_ext:= [""], files:= {}):
	var dir = DirAccess.open(path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			var p = dir.get_current_dir(false) + "/" + file_name
			files = get_all_files(p, file_ext, files)
		else:
			var ext = file_name.get_extension()
			if !file_ext.is_empty() and ext not in file_ext:
				file_name = dir.get_next()
				continue
			var cur_dir = dir.get_current_dir(false)
			if !files.has(cur_dir):
				files[cur_dir] = []
			files.get_or_add(cur_dir).append(file_name)
		file_name = dir.get_next()
	return files
