tool
extends Node

const lastopenedfile_path : String = "res://addons/file-editor/lastopenedfiles.lastcfg"


func _ready():
	pass

func store_opened_files(filecontainer : Control):
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	for child in range(0,filecontainer.get_item_count()):
		var filepath = filecontainer.get_item_metadata(child)[0].current_path
		file.set_value("Opened",filepath.get_file(),filepath)
	
	file.save(lastopenedfile_path)

func remove_opened_file(index : int , filecontainer : Control):
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	var filepath = filecontainer.get_item_metadata(index)[0].current_path
	file.set_value("Opened",filepath.get_file(),null)
	file.save(lastopenedfile_path)

func load_opened_files() -> Array:
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	var keys = []
	# Load opened files
	if file.has_section("Opened"):
		var openedfiles = file.get_section_keys("Opened")
		for openedfile in openedfiles:
			# Load each single file which was opened
			# creating and returning an Array with this format [1:file name, 2:file path, 3:file font]
			keys.append([openedfile, file.get_value("Opened",openedfile), file.get_value("Fonts",openedfile) if file.has_section_key("Fonts",openedfile) else "null"])
	return keys

func store_editor_fonts(file_name : String, font_path : String):
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	file.set_value("Fonts",file_name,font_path)
	file.save(lastopenedfile_path)

func get_editor_font():
	var editor_plugin : EditorPlugin = EditorPlugin.new()
	return editor_plugin.get_editor_interface().get_editor_settings().get_setting("interface/editor/code_font")
