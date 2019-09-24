tool
extends EditorPlugin

var doc
var plugin_version

func _enter_tree():
	doc = preload("../scenes/FileEditor.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR,doc)


func _exit_tree():
	remove_control_from_docks(doc)
	doc.queue_free()