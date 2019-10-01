tool
extends Control

onready var FileList = $FileList

onready var Editor = $Container/Editor

onready var OpenFile = $Container/Buttons/openfile_btn
onready var NewFile = $Container/Buttons/newfile_btn
onready var DeleteFile = $Container/Buttons/deletefile_btn

onready var NewFileDialogue = $NewFileDialogue
onready var NewFileDialogue_name = $NewFileDialogue/VBoxContainer/new_filename

onready var Version = $Container/Buttons/version

var FileScene = load("res://addons/file-editor/scenes/FileScene.tscn")

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
"*.json ; JavaScript Object Notation File"
]

var directories = []
var files = []

func _ready():
	OpenFile.connect("pressed",self,"open_selected_file")
	NewFile.connect("pressed",self,"open_newfiledialogue")
	DeleteFile.connect("pressed",self,"delete_selected_file")
	
	NewFileDialogue.connect("confirmed",self,"create_new_file")
	
	
	FileList.connect("confirmed",self,"update_list")
	
	FileList.set_filters(EXTENSIONS)
	
	Editor.hide()
	
	var plugin_version = ""
	var config =  ConfigFile.new()
	var err = config.load("res://addons/file-editor/plugin.cfg")
	if err == OK:
		plugin_version = config.get_value("plugin","version")
	update_version("v"+plugin_version)

func update_version(v : String):
	Version.set_text(v)

func open_file(path : String):
	var current_file : File = File.new()
	current_file.open(path,File.READ)
	var current_content = current_file.get_as_text()
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(path))
	
	var file_tab = FileScene.instance()
	Editor.add_child(file_tab)
	
	file_tab.new_file_open(path,current_content,last_modified)
	
	Editor.show()
	
	current_file.close()
	update_list()

func open_newfiledialogue():
	NewFileDialogue.popup()
	NewFileDialogue.set_position(OS.get_screen_size()/2 - NewFileDialogue.get_size()/2)

func create_new_file():
	NewFileDialogue.hide()
	var new_file_tab = FileScene.instance()
	Editor.add_child(new_file_tab)
	new_file_tab.new_file_create(NewFileDialogue_name.get_text())
	Editor.show()
	update_list()

func open_filelist():
	update_list()
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func open_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILE
	FileList.set_title("Select a file you want to edit")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if not FileList.is_connected("file_selected",self,"open_file"):
		FileList.connect("file_selected",self,"open_file")
	else:
		FileList.disconnect("file_selected",self,"open_file")
		FileList.connect("file_selected",self,"open_file")
	open_filelist()

func delete_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILE
	FileList.set_title("Select a file you want to delete")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if not FileList.is_connected("file_selected",self,"delete_file"):
		FileList.connect("file_selected",self,"delete_file")
	else:
		FileList.disconnect("file_selected",self,"delete_file")
		FileList.connect("file_selected",self,"delete_file")
	open_filelist()

func delete_file(path : String):
	var dir = Directory.new()
	dir.remove(path)
	
	update_list()

func update_list():
	FileList.invalidate()