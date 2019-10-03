tool
extends VBoxContainer

onready var CloseFile = $TopBar/close_btn

onready var ReadOnly = $FileInfo/Readonly
onready var FileButton = $TopBar/FileButton.get_popup()

onready var TextEditor = $TextEditor

onready var LastModified = $FileInfo/lastmodified

onready var FileList = get_parent().get_parent().get_parent().get_node("FileList")

onready var ClosingFile = get_parent().get_parent().get_parent().get_node("ConfirmationDialog")

onready var FilePath = $TopBar/filepath

onready var LastModifiedIcon = $FileInfo/lastmodified_icon

var current_path = ""
var current_filename = ""
var old_file_content = ""
var Preview = load("res://addons/file-editor/scenes/Preview.tscn")

func _ready():
	FileButton.connect("id_pressed",self,"button_pressed")
	
	ClosingFile.connect("confirmed",self,"queue_free")
	
	CloseFile.connect("pressed",self,"close_editor")
	
	ReadOnly.connect("toggled",self,"_on_Readonly_toggled")
	
	ReadOnly.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	ReadOnly.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))

func new_file_open(file_path, file_content, last_modified) :
	current_path = file_path
	var filename_ = file_path.get_file().replace(".","-")
	
	FilePath.set_text(current_path)
	
	if get_parent().has_node(filename_):
		queue_free()
	else:
		set_name(filename_)
		current_filename = filename_
		old_file_content = file_content
		TextEditor.set_text(file_content)
		
		LastModifiedIcon.texture = IconLoader.load_icon_from_name("saveas")
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
	old_file_content = current_content
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_path))
	LastModified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	LastModifiedIcon.texture = IconLoader.load_icon_from_name("save")
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
	old_file_content = current_content
	
	FileList.invalidate()

func open_filelist():
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func button_pressed(id : int):
	if id == 0:
		save_file(current_path)
	elif id == 1:
		save_file_as()
	elif id == 2:
		open_preview()
	elif id == 3:
		bbcode_preview()
	elif id == 4:
		markdown_preview()
	elif id == 5:
		html_preview()

func open_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_filename+")"
	preview.print_preview(TextEditor.get_text())

func bbcode_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_filename+")"
	preview.print_bb(TextEditor.get_text())

func markdown_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_filename+")"
	preview.print_markdown(TextEditor.get_text())

func html_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_filename+")"
	preview.print_html(TextEditor.get_text())

func close_editor():
	if old_file_content != TextEditor.get_text():
		ClosingFile.popup()
	else:
		queue_free()

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		ReadOnly.set_text("Read Only")
		TextEditor.readonly = (true)
	else:
		ReadOnly.set_text("Can Edit")
		TextEditor.readonly = (false)

func _on_TextEditor_text_changed():
	LastModifiedIcon.texture = IconLoader.load_icon_from_name("saveas")
