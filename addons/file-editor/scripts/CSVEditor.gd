tool
extends Control
class_name CSVEditor

onready var Columns : HBoxContainer = $Container/Scroll/Columns
onready var _column_head : VBoxContainer = Columns.get_node("_COLUMN_HEAD")
onready var _row_label : Label = _column_head.get_node("1")
onready var _zero_column : VBoxContainer = Columns.get_node("0")
onready var _row_line : LineEdit = _zero_column.get_node("1")

onready var columns_count_lbl : Label = $Container/FileProperties/Dimensions/ColumnsLbl
onready var rows_count_lbl : Label = $Container/FileProperties/Dimensions/RowsLbl
onready var csv_delimiter_lbl : Label = $Container/FileProperties/Delimiter/DelimiterLbl

onready var align_menu_opitons : PopupMenu = $Container/Menu/AlignMenu.get_popup()
onready var edit_menu_options : PopupMenu = $Container/Menu/EditMenu.get_popup()
onready var settings_menu_options : PopupMenu = $Container/Menu/SettingsMenu.get_popup()

onready var readonly_btn : CheckBox = $Container/FileProperties/Readonly

onready var edit_dialog : AcceptDialog = $EditDialog
onready var edit_rows : HBoxContainer = edit_dialog.get_node("Options/Rows")
onready var edit_columns : HBoxContainer = edit_dialog.get_node("Options/Columns")
onready var edit_delimiter : HBoxContainer = edit_dialog.get_node("Options/Delimiter")
onready var new_rows_line : LineEdit = edit_rows.get_node("NewRows")
onready var new_columns_line : LineEdit = edit_columns.get_node("NewColumns")
onready var new_delimiter_line : LineEdit = edit_delimiter.get_node("DelimiterLine")

onready var editor_settings : AcceptDialog = $EditorSettingsDialog
onready var editor_columns_length : LineEdit = editor_settings.get_node("EditorSettings/ColumnsLength/ColumnsLengthLine")
onready var editor_columns_spacing : LineEdit = editor_settings.get_node("EditorSettings/ColumnsSpacing/ColumnsSpacingLine")
onready var editor_rows_spacing : LineEdit = editor_settings.get_node("EditorSettings/RowsSpacing/RowsSpacingLine")

var current_file_path : String

var file_path : String
var csv_delimiter : String = ","
var columns_count : int = 0
var rows_count : int = 0

signal update_file()

# Called when the node enters the scene tree for the first time.
func _ready():
	_connect_signals()
	_load_icons()
	_add_shortcuts()

func _add_shortcuts() -> void:
	var hotkey
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(1,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(0,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(2,hotkey.get_scancode_with_modifiers())

func _connect_signals() -> void:
	align_menu_opitons.connect("id_pressed", self, "_on_align_pressed")
	edit_menu_options.connect("id_pressed", self, "_on_edit_pressed")
	settings_menu_options.connect("id_pressed",self, "_on_settings_pressed")
	readonly_btn.connect("toggled", self, "_is_readonly")
	edit_dialog.connect("confirmed", self, "_on_edit_confirmed")
	editor_settings.connect("confirmed", self, "_on_editor_settings_confirmed")
	
	$EditDialog/Options/Columns/LessBtn.connect("pressed", self, "_on_less_pressed")
	$EditDialog/Options/Rows/LessBtn.connect("pressed", self, "_on_less_pressed")	
	$EditDialog/Options/Columns/MoreBtn.connect("pressed", self, "_on_more_pressed")
	$EditDialog/Options/Rows/MoreBtn.connect("pressed", self, "_on_more_pressed")

func _load_icons() -> void:
	$Container/Menu/AlignMenu.set_button_icon(IconLoader.load_icon_from_name("align"))
	$Container/Menu/EditMenu.set_button_icon(IconLoader.load_icon_from_name("edit_"))
	$Container/Menu/SettingsMenu.set_button_icon(IconLoader.load_icon_from_name("settings"))
	
	align_menu_opitons.set_item_icon(0,IconLoader.load_icon_from_name("text-left"))
	align_menu_opitons.set_item_icon(1,IconLoader.load_icon_from_name("text-center"))
	align_menu_opitons.set_item_icon(2,IconLoader.load_icon_from_name("text-right"))
	align_menu_opitons.set_item_icon(3,IconLoader.load_icon_from_name("text-fill"))
	
	edit_menu_options.set_item_icon(0,IconLoader.load_icon_from_name("row"))
	edit_menu_options.set_item_icon(1,IconLoader.load_icon_from_name("column"))
	edit_menu_options.set_item_icon(2,IconLoader.load_icon_from_name("save"))
	
	readonly_btn.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	readonly_btn.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))

func _on_align_pressed(id : int) -> void:
	for column in range(1, columns_count+1):
		for row in range(1, rows_count+1):
			Columns.get_child(column).get_child(row).set_align(id)

func _on_edit_pressed(id : int) -> void:
	new_rows_line.set_text(str(0))
	new_columns_line.set_text(str(0))
	new_delimiter_line.set_text(csv_delimiter)
	
	for child in range(0, edit_dialog.get_node("Options").get_child_count()):
		edit_dialog.get_node("Options").get_child(child).set_visible((child == id))
	
	match id:
		0:
			edit_dialog.window_title = ("Add Rows")
		1:
			edit_dialog.window_title = ("Add Columns")
		2:
			edit_dialog.window_title = ("Change Delimiter")
	
	edit_dialog.popup()

func _on_settings_pressed(id : int) -> void:
	match id:
		0: # Change Columns Size
			editor_columns_length.set_text(str(Columns.get_child(1).get_child(1).get_size().x))
			editor_columns_spacing.set_text(str(Columns.get("custom_constants/separation")))
			editor_rows_spacing.set_text(str(Columns.get_child(1).get("custom_constants/separation")))
			editor_settings.popup()

func _on_editor_settings_confirmed() -> void:
	for column in range(0, columns_count+1):
		Columns.get_child(column).set("custom_constants/separation", float(editor_rows_spacing.get_text()))
		if column == 0: continue
		Columns.get_child(column).get_child(1).set_custom_minimum_size(Vector2(float(editor_columns_length.get_text()), 0.0))
	Columns.set("custom_constants/separation", float(editor_columns_spacing.get_text()))

func _on_less_pressed() -> void:
	if edit_columns.is_visible():
		if int(new_columns_line.get_text()) > 0 : new_columns_line.set_text(str(int(new_columns_line.get_text())-1))
	if edit_rows.is_visible():
		if int(new_rows_line.get_text()) > 0 : new_rows_line.set_text(str(int(new_rows_line.get_text())-1))

func _on_more_pressed() -> void:
	if edit_columns.is_visible():
		new_columns_line.set_text(str(int(new_columns_line.get_text())+1))
	if edit_rows.is_visible():
		new_rows_line.set_text(str(int(new_rows_line.get_text())+1))

func _on_edit_confirmed() -> void:
	# Add new Columns
	if edit_columns.is_visible(): 
		var ref_column : VBoxContainer = Columns.get_child(columns_count).duplicate(8)
		for row in ref_column.get_children():
			row.set_text("")
		var new_columns : int = new_columns_line.get_text() as int
		for new_column in range(0,new_columns):
			var column : VBoxContainer = ref_column.duplicate(8)
			column.get_child(0).set_text((columns_count+new_column+1) as String)
			Columns.add_child(column)
		columns_count+=new_columns
	# Add new Rows
	if edit_rows.is_visible():
		var new_rows : int = new_rows_line.get_text() as int
		for column in range(1, columns_count+1):
			for row in range(0, new_rows):
				Columns.get_child(column).add_child(LineEdit.new())
		for row in range(0, new_rows):
			var lbl : Label = Label.new()
			lbl.set_text(str(rows_count+row+1))
			_column_head.add_child(lbl)
		rows_count+=new_rows
	# Change delimiter
	if edit_delimiter.is_visible():
		assert(not new_delimiter_line.get_text() in ["", " "], "Delimiter not valid.")
		open_csv_file(file_path, new_delimiter_line.get_text())
	load_file_properties()

func _is_readonly(readonly : bool) -> void:
	for column in range(1, columns_count+1):
		for row in range(1, rows_count+1):
			Columns.get_child(column).get_child(row).set_editable(not readonly)
	edit_menu_options.set_item_disabled(0, readonly)
	edit_menu_options.set_item_disabled(1, readonly)

func clear_editor() -> void:
	for column in Columns.get_children():
		if not column in [_zero_column, _column_head]:
			column.free()
	for row in _zero_column.get_children():
		if not row.get_name() in ["0","1"]:
			row.free()
	for label in _column_head.get_children():
		if not label.get_text() in ["@", "1"]:
			label.free()

func open_csv_file(filepath : String, csv_delimiter : String = ";") -> void:
	if rows_count != 0 and columns_count != 0: clear_editor()
	self.file_path = filepath
	self.csv_delimiter = csv_delimiter
	var csv = File.new()
	csv.open(filepath,File.READ)
	var rows : Array = []
	var columns : int = 0
	if not csv.get_as_text().empty():
		while not csv.eof_reached():
			var csv_line = csv.get_csv_line(csv_delimiter)
			if Array(csv_line) != [""]:
				columns = csv_line.size() if columns < csv_line.size() else columns
				if csv_line.size() < columns:
					csv_line.resize(columns)
				rows.append(csv_line)
	csv.close()
	
	columns_count = columns
	rows_count = rows.size()
	
	load_file_properties()
	load_file_in_table(rows,columns)
#	ReadOnly.pressed = (true)
#	$Editor/FileInfo/delimiter.set_text(csv_delimiter)
#	ChangeDelimiterDialog.get_node("VBoxContainer/delim_read").set_text(csv_delimiter)

func load_file_properties() -> void:
	rows_count_lbl.set_text(str(rows_count))
	columns_count_lbl.set_text(str(columns_count))
	csv_delimiter_lbl.set_text(csv_delimiter)

func load_csv_grid(rows : Array, columns : int) -> void:
	for row in range(1,rows.size()):
		var csv_field : LineEdit = _row_line.duplicate(8)
		_zero_column.add_child(csv_field)
		var csv_field_label : Label = _row_label.duplicate(8)
		_column_head.add_child(csv_field_label)
		csv_field_label.set_text(str(row+1))
	
	for column in range(1,columns):
		var csv_column : VBoxContainer = _zero_column.duplicate(8)
		Columns.add_child(csv_column)
		csv_column.get_node("0").set_text(str(column+1))

func load_file_in_table(rows : Array, columns : int) -> void:
	load_csv_grid(rows, columns)
	
	for row in range(0,rows.size()):
		for column in range(0,columns):
			Columns.get_child(column+1).get_child(row+1).set_text(rows[row][column])

func save_table() -> void:
	var file = File.new()
	file.open(file_path, File.WRITE)
	for row in range(0, rows_count):
		var current_row : PoolStringArray = []
		for column in range(0, columns_count):
			current_row.append(Columns.get_child(column+1).get_child(row+1).get_text())
		file.store_csv_line(current_row, csv_delimiter)
	file.close()
	pass
	emit_signal("update_file")

# This is the loading function used to initially build this node. No need to use this anymore
func _load():
	# Load Rows
	for i in range(2,101):
		# Load Row Headers
		var lbl : Label = _row_label.duplicate()
		_column_head.add_child(lbl)
		lbl.set_text(str(i))
		lbl.set_owner(_column_head)
		# Load First Column
		var line : LineEdit = _row_line.duplicate()
		_zero_column.add_child(line)
		line.set_owner(_zero_column)
	
	# Load Columns
	for i in range(1,26):
		var column : VBoxContainer = _zero_column.duplicate()
		var label : Label = column.get_node("A")
		var _char : String = char(i+65)
		label.set_text(_char)
		label.set_name(_char)
		Columns.add_child(column)
		label.set_owner(Columns)
