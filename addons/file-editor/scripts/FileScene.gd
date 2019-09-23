tool
extends VBoxContainer

onready var CloseFile = $TopBar/close_btn

onready var ReadOnly = $FileInfo/Readonly
onready var FileButton = $TopBar/FileButton.get_popup()

onready var TextEditor = $TextEditor

onready var LastModified = $FileInfo/lastmodified

onready var FileList = get_parent().get_parent().get_parent().get_node("FileList")

onready var FilePath = $TopBar/filepath

var current_path = ""
var current_filename = ""

func _ready():
	FileButton.connect("id_pressed",self,"button_pressed")
	
	CloseFile.connect("pressed",self,"close_editor")
	
	ReadOnly.connect("toggled",self,"_on_Readonly_toggled")

func new_file_open(file_path, file_content, last_modified) :
	current_path = file_path
	var filename_ = file_path.get_file().replace(".","-")
	
	FilePath.set_text(current_path)
	
	if get_parent().has_node(filename_):
		queue_free()
	else:
		set_name(filename_)
		current_filename = filename_
		TextEditor.set_text(file_content)
		LastModified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	
	FileList.invalidate()

func new_file_create(file_name):
	set_name(file_name)
	current_filename = file_name
	FileButton.set_item_disabled(0,true)
	
	FileList.invalidate()

func save_file(current_path : String):
	var current_file = File.new()
	current_file.open(current_path,File.WRITE)
	var current_content = TextEditor.get_text()
	if current_content == null:
		current_content = ""
	current_file.store_line(current_content)
	current_file.close()
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_path))
	LastModified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	
	FilePath.set_text(current_path)
	
	FileList.invalidate()

func save_file_as():
	var current_content = TextEditor.get_text()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Save this file as...")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if not FileList.is_connected("file_selected",self,"save_file"):
		FileList.connect("file_selected",self,"save_file")
	FileList.current_file = current_filename.replace("-",".")
	open_filelist()
	
	FileList.invalidate()

func open_filelist():
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func button_pressed(id : int):
	if id == 0:
		save_file(current_path)
	elif id == 1:
		save_file_as()

func close_editor():
	queue_free()

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		ReadOnly.set_text("Read Only")
		TextEditor.readonly = (true)
	else:
		ReadOnly.set_text("Can Edit")
		TextEditor.readonly = (false)