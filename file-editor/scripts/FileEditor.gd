tool
extends Control

onready var FileList = $FileList

onready var TextEditor = $Container/Editor/TextEditor
onready var Filename = $Container/Editor/TopBar/Filename
onready var CloseFile = $Container/Editor/TopBar/close_btn
onready var Editor = $Container/Editor

onready var OpenFile = $Container/Buttons/openfile_btn
onready var NewFile = $Container/Buttons/newfile_btn
onready var DeleteFile = $Container/Buttons/deletefile_btn

onready var SaveFile = $Container/Editor/EditorButtons/savefile_btn
onready var SaveFileAs = $Container/Editor/EditorButtons/savefileas_btn

onready var ReadOnly = $Container/Editor/TopBar/Readonly

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
]

var directories = []
var files = []

# -----
var current_file : File = File.new()
var current_path : String = ""
var current_content : String = ""
# -----

func _ready():
	OpenFile.connect("pressed",self,"open_selected_file")
	NewFile.connect("pressed",self,"create_new_file")
	DeleteFile.connect("pressed",self,"delete_selected_file")
	
	SaveFile.connect("pressed",self,"save_file")
	SaveFileAs.connect("pressed",self,"save_file_as")
	
	CloseFile.connect("pressed",self,"close_editor")
	
	Filename.set_editable(false)
	SaveFile.set_disabled(true)
	
	FileList.set_filters(EXTENSIONS)
	
	Editor.hide()

func close_editor():
	Editor.hide()
	Filename.set_text("")
	TextEditor.set_text("")
	current_file.close()
	current_file = File.new()
	current_path = ""
	current_content = ""

func clear_editor():
	TextEditor.set_text("")
	Filename.set_text("")
	current_file = File.new()

func create_new_file():
	close_editor()
	SaveFile.set_disabled(true)
	Editor.show()

func open_filelist():
	FileList.update()
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func save_file_as():
	current_content = TextEditor.get_text()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Save this file as...")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if not FileList.is_connected("file_selected",self,"open_file"):
		FileList.connect("file_selected",self,"open_file",[current_content])
	else:
		FileList.disconnect("file_selected",self,"open_file")
		FileList.connect("file_selected",self,"open_file",[current_content])
	open_filelist()

func open_selected_file():
	clear_editor()
	FileList.mode = FileDialog.MODE_OPEN_FILE
	FileList.set_title("Select a file you want to edit")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if not FileList.is_connected("file_selected",self,"open_file"):
		FileList.connect("file_selected",self,"open_file",[""])
	else:
		FileList.disconnect("file_selected",self,"open_file")
		FileList.connect("file_selected",self,"open_file",[""])
	open_filelist()

func delete_selected_file():
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

func open_file(path : String, content_file : String):
	var content = ""
	if content_file == "" or content_file == null:
		current_file.open(path,File.READ)
		content = current_file.get_as_text()
	else:
		content = content_file
		current_file.open(path,File.WRITE)
		current_file.store_line(content)
	
	TextEditor.set_text(content)
	Filename.set_text(path)
	
	current_file.close()
	
	current_path = path
	current_content = content
	
	Editor.show()
	SaveFile.set_disabled(false)

func save_file():
	if current_path == "" or current_path == null:
		save_file_as()
	else:
		current_file.open(current_path,File.WRITE)
		current_content = TextEditor.get_text()
		if current_content == null:
			current_content = ""
		current_file.store_line(current_content)
		current_file.close()

func delete_file(path : String):
	clear_editor()
	var dir = Directory.new()
	dir.remove(path)

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		ReadOnly.set_text("Read Only")
		TextEditor.readonly = (true)
	else:
		ReadOnly.set_text("Can Edit")
		TextEditor.readonly = (false)
