tool
extends VBoxContainer


onready var ReadOnly = $FileInfo/Readonly

onready var TextEditor = $TextEditor

onready var LastModified = $FileInfo/lastmodified

onready var FileList = get_parent().get_parent().get_parent().get_node("FileList")

onready var ClosingFile = get_parent().get_parent().get_parent().get_node("ConfirmationDialog")

onready var LastModifiedIcon = $FileInfo/lastmodified_icon

var current_path = ""
var current_filename = ""
var old_file_content = ""
var Preview = load("res://addons/file-editor/scenes/Preview.tscn")

signal text_changed()

func _ready():
	
	ClosingFile.connect("confirmed",self,"queue_free")
	
	ReadOnly.connect("toggled",self,"_on_Readonly_toggled")
	
	ReadOnly.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	ReadOnly.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))

func clean_editor():
	TextEditor.set_text("")
	LastModifiedIcon.texture = IconLoader.load_icon_from_name("save")
	LastModified.set_text("")
	FileList.invalidate()

func new_file_open(file_content, last_modified):
	TextEditor.set_text(file_content)
	update_lastmodified(last_modified,"save")
	FileList.invalidate()

func update_lastmodified(last_modified : Dictionary, icon : String):
	LastModified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	LastModifiedIcon.texture = IconLoader.load_icon_from_name(icon)

func new_file_create(file_name):
	TextEditor.set_text("")
	
	FileList.invalidate()

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
	emit_signal("text_changed")
