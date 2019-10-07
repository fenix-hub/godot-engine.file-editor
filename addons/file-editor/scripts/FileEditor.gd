tool
extends Control

onready var FileList = $FileList

onready var NewFileDialogue = $NewFileDialogue
onready var NewFileDialogue_name = $NewFileDialogue/VBoxContainer/new_filename

onready var FileBTN = $FileEditorContainer/TobBar/file_btn.get_popup()
onready var PreviewBTN = $FileEditorContainer/TobBar/preview_btn.get_popup()
onready var EditorBTN = $FileEditorContainer/TobBar/editor_btn.get_popup()

onready var Version = $FileEditorContainer/TobBar/version

onready var VanillaEditor = $FileEditorContainer/SplitContainer/VanillaEditor
onready var IniEditor = $FileEditorContainer/SplitContainer/IniEditor

onready var OpenFileList = $FileEditorContainer/SplitContainer/BoxContainer/OpenFileList
onready var OpenFileName = $FileEditorContainer/SplitContainer/BoxContainer/OpenFileName

var Preview = preload("res://addons/file-editor/scenes/Preview.tscn")

var DIRECTORY : String = "res://"
var EXCEPTIONS : String = "addons"
var EXTENSIONS : PoolStringArray = [
"*.txt ; Plain Text File", 
"*.rtf ; Rich Text Format File", 
"*.log ; Log File", 
"*.md ; MD File",
"*.doc ; WordPad Document",
"*.doc ; Microsoft Word Document",
"*.docm ; Word Open XML Macro-Enabled Document",
"*.docx ; Microsoft Word Open XML Document",
"*.bbs ; Bulletin Board System Text",
"*.dat ; Data File",
"*.xml ; XML File",
"*.sql ; SQL database file",
"*.json ; JavaScript Object Notation File",
"*.html ; HyperText Markup Language",
"*.csv ; Comma-separated values",
"*.cfg ; Configuration File",
"*.ini ; Initialization File (same as .cfg Configuration File)",
]

var directories = []
var files = []
var current_file_index = -1
var current_file_path = ""
var save_as = false

func _ready():
	clean_editor()
	update_version()
	connect_signals()
	create_shortcuts()
	load_icons()
	
	
	var opened_files : Array = LastOpenedFiles.load_opened_files()
	for open_file in opened_files:
		open_file(open_file[1])
	
	FileList.set_filters(EXTENSIONS)
	IniEditor.hide()

func create_shortcuts():
	var hotkey 
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	FileBTN.set_item_accelerator(4,hotkey.get_scancode_with_modifiers()) # save file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_N
	hotkey.control = true
	FileBTN.set_item_accelerator(0,hotkey.get_scancode_with_modifiers()) # new file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_O
	hotkey.control = true
	FileBTN.set_item_accelerator(1,hotkey.get_scancode_with_modifiers()) # open file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.control = true
	FileBTN.set_item_accelerator(6,hotkey.get_scancode_with_modifiers()) # delete file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(5,hotkey.get_scancode_with_modifiers()) #save file as
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(2,hotkey.get_scancode_with_modifiers()) # close file
	
	# vanilla editor -----------------------
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_1
	hotkey.control = true
	EditorBTN.set_item_accelerator(0,hotkey.get_scancode_with_modifiers()) # vanilla editor
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_3
	hotkey.control = true
	EditorBTN.set_item_accelerator(2,hotkey.get_scancode_with_modifiers()) # vanilla editor

func load_icons():
	$FileEditorContainer/TobBar/file_btn.icon = IconLoader.load_icon_from_name("file")
	$FileEditorContainer/TobBar/preview_btn.icon = IconLoader.load_icon_from_name("read")
	$FileEditorContainer/TobBar/editor_btn.icon = IconLoader.load_icon_from_name("edit_")

func connect_signals():
	FileList.connect("confirmed",self,"update_list")
	FileBTN.connect("id_pressed",self,"_on_filebtn_pressed")
	PreviewBTN.connect("id_pressed",self,"_on_previewbtn_pressed")
	EditorBTN.connect("id_pressed",self,"_on_editorbtn_pressed")
	
	OpenFileList.connect("item_selected",self,"_on_fileitem_pressed")
	
	VanillaEditor.connect("text_changed",self,"_on_vanillaeditor_text_changed")
	
	#---------------- to update from IniEditor to VanillaEditor
	IniEditor.connect("update_file",self,"_on_update_file")
	
	# ---- preview buttons
	

func update_version():
	var plugin_version = ""
	var config =  ConfigFile.new()
	var err = config.load("res://addons/file-editor/plugin.cfg")
	if err == OK:
		plugin_version = config.get_value("plugin","version")
	Version.set_text("v"+plugin_version)

func create_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Create a new File")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if not FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.connect("file_selected",self,"create_new_file")
	open_filelist()

func open_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILE
	FileList.set_title("Select a File you want to edit")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.disconnect("file_selected",self,"create_new_file")
	if not FileList.is_connected("file_selected",self,"open_file"):
		FileList.connect("file_selected",self,"open_file")
	open_filelist()

func delete_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILES
	FileList.set_title("Select one or more Files you want to delete")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.disconnect("file_selected",self,"create_new_file")
	if not FileList.is_connected("files_selected",self,"delete_file"):
		FileList.connect("files_selected",self,"delete_file")
	open_filelist()

func save_current_file_as():
	update_list()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Save this File as...")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if not FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.connect("file_selected",self,"create_new_file")
	open_filelist()

func _on_filebtn_pressed(index : int):
	match index:
		0:
			create_selected_file()
		1:
			open_selected_file()
		2:
			if current_file_index!=-1 and current_file_path != "":
				close_file(current_file_index)
		
		3:
			if current_file_index!=-1 and current_file_path != "":
				save_as = false
				save_file(current_file_path)
		4:
			if current_file_index!=-1 and current_file_path != "":
				save_as = true
				save_file(current_file_path)
				save_current_file_as()
		5:
			delete_selected_file()

func _on_previewbtn_pressed(id : int):
	if id == 0:
		bbcode_preview()
	elif id == 1:
		markdown_preview()
	elif id == 2:
		html_preview()
	elif id == 3:
		csv_preview()
	elif id == 4:
		xml_preview()
	elif id == 5:
		json_preview()

func _on_editorbtn_pressed(index : int):
	match index:
		0:
			if not VanillaEditor.visible:
				VanillaEditor.show()
				IniEditor.hide()
		2:
			if not IniEditor.visible:
				VanillaEditor.hide()
				IniEditor.show()

func _on_fileitem_pressed(index : int):
	current_file_index = index
	var selected_item_metadata = OpenFileList.get_item_metadata(index)
	current_file_path = selected_item_metadata[2]
	
	OpenFileName.set_text(current_file_path)
	
	VanillaEditor.new_file_open(selected_item_metadata[0],selected_item_metadata[1])
	open_in_inieditor(current_file_path)

func close_file(index):
	LastOpenedFiles.remove_opened_file(index,OpenFileList)
	OpenFileList.remove_item(index)
	OpenFileName.clear()
	VanillaEditor.clean_editor()

func open_file(path : String):
	if current_file_path != path:
		current_file_path = path
		
		open_in_vanillaeditor(path)
		open_in_inieditor(path)
		
		LastOpenedFiles.store_opened_files(OpenFileList)

func open_in_vanillaeditor(path : String):
	var current_file : File = File.new()
	current_file.open(path,File.READ)
	
	var current_content = current_file.get_as_text()
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(path))
	
	current_file.close()
	
	OpenFileName.set_text(path)
	OpenFileList.add_item(path.get_file(),IconLoader.load_icon_from_name("file"),true)
	current_file_index = OpenFileList.get_item_count()-1
	OpenFileList.set_item_metadata(current_file_index,[current_content,last_modified,path])
	
	VanillaEditor.new_file_open(current_content,last_modified)
	
	update_list()
	
	OpenFileList.select(OpenFileList.get_item_count()-1)

func open_in_inieditor(path : String):
	var extension = path.get_file().get_extension()
	if extension == "ini" or extension == "cfg":
		IniEditor.current_file_path = path
		var current_file : ConfigFile = ConfigFile.new()
		var err = current_file.load(path)
		if err == OK:
			var sections = current_file.get_sections()
			var filemap = []
			for section in sections:
				var keys = []
				var section_keys = current_file.get_section_keys(section)
				for key in section_keys:
					keys.append([key,current_file.get_value(section,key)])
				
				filemap.append([section,keys])
			
			IniEditor.open_file(filemap)
	else:
		IniEditor.clean_editor()


func _on_update_file():
	VanillaEditor.clean_editor()
	var current_file : File = File.new()
	current_file.open(current_file_path,File.READ)
	
	var current_content = current_file.get_as_text()
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_file_path))
	
	current_file.close()
	
	VanillaEditor.new_file_open(current_content,last_modified)

func delete_file(files_selected : PoolStringArray):
	var dir = Directory.new()
	for file in files_selected:
		dir.remove(file)
	
	update_list()

func open_newfiledialogue():
	NewFileDialogue.popup()
	NewFileDialogue.set_position(OS.get_screen_size()/2 - NewFileDialogue.get_size()/2)

func open_filelist():
	update_list()
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func _on_vanillaeditor_text_changed():
	if not OpenFileList.get_item_text(current_file_index).ends_with("(*)"):
		OpenFileList.set_item_text(current_file_index,OpenFileList.get_item_text(current_file_index)+"(*)")

func create_new_file(given_path : String):
	var current_file = File.new()
	current_file.open(given_path,File.WRITE)
	if save_as : 
		current_file.store_line(VanillaEditor.get_node("TextEditor").get_text())
	current_file.close()
	
	open_file(given_path)

func save_file(current_path : String):
	var current_file = File.new()
	current_file.open(current_path,File.WRITE)
	var current_content = VanillaEditor.get_node("TextEditor").get_text()
	if current_content == null:
		current_content = ""
	current_file.store_line(current_content)
	current_file.close()
	
	current_file_path = current_file_path
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_path))
	
	VanillaEditor.update_lastmodified(last_modified,"save")
	OpenFileList.set_item_metadata(current_file_index,[current_content,last_modified,current_path])
	
	if OpenFileList.get_item_text(current_file_index).ends_with("(*)"):
		OpenFileList.set_item_text(current_file_index,OpenFileList.get_item_text(current_file_index).rstrip("(*)"))
	
	open_in_inieditor(current_file_path)
	update_list()

func clean_editor():
	OpenFileName.clear()
	OpenFileList.clear()
	VanillaEditor.clean_editor()
	IniEditor.clean_editor()

func csv_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	var lines = VanillaEditor.get_node("TextEditor").get_line_count()
	var rows = []
	for i in range(0,lines-1):
		rows.append(VanillaEditor.get_node("TextEditor").get_line(i).rsplit(",",false))
	preview.print_csv(rows)

func bbcode_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_bb(VanillaEditor.get_node("TextEditor").get_text())

func markdown_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_markdown(VanillaEditor.get_node("TextEditor").get_text())

func html_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_html(VanillaEditor.get_node("TextEditor").get_text())

func xml_preview():
	pass

func json_preview():
	pass

func update_list():
	FileList.invalidate()