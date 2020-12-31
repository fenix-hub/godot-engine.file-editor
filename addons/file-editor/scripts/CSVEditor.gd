tool
extends Control
class_name CSVEditor

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()

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
onready var drop_rows : VBoxContainer = edit_dialog.get_node("Options/DropRows")
onready var drop_columns : HBoxContainer = edit_dialog.get_node("Options/DropColumns")
onready var new_rows_line : LineEdit = edit_rows.get_node("NewRows")
onready var new_columns_line : LineEdit = edit_columns.get_node("NewColumns")
onready var new_delimiter_line : LineEdit = edit_delimiter.get_node("DelimiterLine")

onready var editor_settings : AcceptDialog = $EditorSettingsDialog
onready var editor_columns_length : LineEdit = editor_settings.get_node("EditorSettings/ColumnsLength/ColumnsLengthLine")
onready var editor_columns_spacing : LineEdit = editor_settings.get_node("EditorSettings/ColumnsSpacing/ColumnsSpacingLine")
onready var editor_rows_spacing : LineEdit = editor_settings.get_node("EditorSettings/RowsSpacing/RowsSpacingLine")

onready var translation_dialog : WindowDialog = $TranslationDialog
onready var token_line : LineEdit = $TranslationDialog/TranslationContainer/AuthToken/TokenLine
onready var keys_tree : Tree = $TranslationDialog/TranslationContainer/Keys/ScrollContainer/KeysTree
onready var source_lang_menu : OptionButton = $TranslationDialog/TranslationContainer/Languages/SourceLangMenu
onready var target_langs_tree : Tree = $TranslationDialog/TranslationContainer/Languages/TargetLangs/TargetLangsTree

onready var error_lbl : Label = $TranslationDialog/TranslationContainer/ErrorLbl

onready var how_to : WindowDialog = $HowTo

var current_file_path : String

var file_path : String
var csv_delimiter : String = ","
var columns_count : int = 1
var rows_count : int = 1

signal update_file()
signal editing_file()

var GoogleTranslate : = GoogleTranslateAPI.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	error_lbl.hide()
	_connect_signals()
	_load_icons()
	_add_shortcuts()
	
	add_child(GoogleTranslate)

func _add_shortcuts() -> void:
	var hotkey
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(0,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(1,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.alt = true
	edit_menu_options.set_item_accelerator(2,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.alt = true
	hotkey.shift = true
	edit_menu_options.set_item_accelerator(3,hotkey.get_scancode_with_modifiers())
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.alt = true
	hotkey.shift = true
	edit_menu_options.set_item_accelerator(4,hotkey.get_scancode_with_modifiers())

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
	
	$TranslationDialog/TranslationContainer/AuthToken/SecretCheck.connect("toggled", self, "_on_secret_check")
	$TranslationDialog/TranslationContainer/Buttons/AcceptBtn.connect("pressed", self, "_on_translation_accept")
	$TranslationDialog/TranslationContainer/Buttons/GetTokenBtn.connect("pressed", how_to, "popup")
	source_lang_menu.connect("item_selected", self , "_on_source_lang_selected")
	
	keys_tree.connect("cell_selected", self , "_on_keys_select_all_pressed")
	target_langs_tree.connect("cell_selected", self , "_on_langs_select_all_pressed")

func _on_keys_select_all_pressed():
	if keys_tree.get_selected() != keys_tree.get_root():
		return
	var check : bool = not keys_tree.get_root().is_checked(0)
	var first_key : TreeItem = keys_tree.get_root().get_children()
	set_checked(first_key, check)
	for key in range(0, keys.size()-1):
		first_key = set_checked(first_key.get_next(), check)

func _on_langs_select_all_pressed():
	if target_langs_tree.get_selected() != target_langs_tree.get_root():
		return
	var check : bool = not target_langs_tree.get_root().is_checked(0)
	var first_key : TreeItem = target_langs_tree.get_root().get_children()
	set_checked(first_key, check)
	for key in range(0, keys.size()-1):
		first_key = set_checked(first_key.get_next(), check)

func set_checked(key : TreeItem, to_check : bool) -> TreeItem:
	if key!=null and key.is_editable(0): key.set_checked(0, to_check)
	return key

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
	edit_menu_options.set_item_icon(2,IconLoader.load_icon_from_name("delimiter"))
	edit_menu_options.set_item_icon(3,IconLoader.load_icon_from_name("drop_row"))
	edit_menu_options.set_item_icon(4,IconLoader.load_icon_from_name("drop_column"))
	
	readonly_btn.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	readonly_btn.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))
	
	settings_menu_options.set_item_icon(0, IconLoader.load_icon_from_name("tools"))
	settings_menu_options.set_item_icon(1, IconLoader.load_icon_from_name("translate"))

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
	
	if columns != 0:
		columns_count = columns
	if rows.size() != 0:
		rows_count = rows.size()
	
	load_file_properties()
	load_file_in_table(rows,columns)

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
	
	for column in range(1, columns_count+1): 
		for row in range(1, rows_count+1):
			if Columns.get_child(column).get_child(row).is_connected("text_changed", self, "_on_editing_cell"):
				Columns.get_child(column).get_child(row).connect("text_changed", self, "_on_editing_cell", [Vector2(column, row)])

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
	
	emit_signal("update_file")

func _on_editing_cell(new_text : String, cell_position : Vector2) -> void:
	emit_signal("editing_file")

func _on_secret_check(toggled : bool) -> void:
	token_line.set_secret(toggled)

func _on_translation_accept() -> void:
	error_lbl.hide()
	var token : String = token_line.get_text()
	var tw : Tween = Tween.new()
	if token in ["", " "]:
		error_lbl.show()
		error_lbl.set_text("An Auth Token is required in order to make translation requests to Google Translate API.")
		add_child(tw)
		tw.interpolate_property($TranslationDialog/TranslationContainer/AuthToken,"modulate",Color("#ffffff"),Color("#ff0000"),0.5,Tween.TRANS_BACK,Tween.EASE_OUT_IN)
		tw.start()
		return
	tw.queue_free()
	$TranslationDialog/TranslationContainer/AuthToken.set_modulate(Color("#ffffff"))
	GoogleTranslate.set_token(token)
	
	var source_lang_idx : int = langs.find(source_lang_menu.get_text()) if source_lang_menu.get_selected() == -1 else source_lang_menu.get_selected()
	source_lang_idx += 2 # + zero_column + "keys" column
	
	var target_langs_idx : Array = []
	var first_lang : TreeItem = target_langs_tree.get_root().get_children()
	get_checked(first_lang, target_langs_idx, langs)
	for lang in range(0, langs.size()-1):
		first_lang = get_checked(first_lang.get_next(), target_langs_idx, langs)
	
	if target_langs_idx.empty() : 
		error_lbl.show()
		error_lbl.set_text("You must select at least one target language to translate.")
		return
	
	var selected_keys_idx : Array = []
	var first_key : TreeItem = keys_tree.get_root().get_children()
	get_checked(first_key, selected_keys_idx, keys)
	for key in range(0, keys.size()-1):
		first_key = get_checked(first_key.get_next(), selected_keys_idx, keys)
	
	if selected_keys_idx.empty() : 
		error_lbl.show()
		error_lbl.set_text("You must select at least one key to translate.")
		return
	
	var target_keys : Array = []
	for key_idx in selected_keys_idx:
		target_keys.append(Columns.get_child(source_lang_idx).get_child(key_idx).get_text().replace("\"",""))
	
	for lang_idx in target_langs_idx:
		GoogleTranslate.request_translation(
			Columns.get_child(source_lang_idx).get_child(1).get_text(),
			Columns.get_child(lang_idx).get_child(1).get_text(),
			target_keys
		)
		var response : Array = yield(GoogleTranslate, "translation_received")
		if response[0] != 200: 
			error_lbl.show()
			error_lbl.set_text(response[1].error.errors[0].message)
			return
		var translation_table : Array = response[1].data.translations
		var i : int = 0
		for key in selected_keys_idx:
			Columns.get_child(lang_idx).get_child(key).set_text("\"%s\""%translation_table[i].translatedText)
			i+=1
	
	translation_dialog.hide()

func get_checked(tree_item : TreeItem, idx_array : Array, source_array : Array) -> TreeItem:
	if tree_item.is_checked(0):
		idx_array.append(source_array.find(tree_item.get_text(0)) + 2)
	return tree_item

func _on_align_pressed(id : int) -> void:
	for column in range(1, columns_count+1):
		for row in range(1, rows_count+1):
			Columns.get_child(column).get_child(row).set_align(id)

# If an Edit button is pressed
func _on_edit_pressed(id : int) -> void:
	for child in range(0, edit_dialog.get_node("Options").get_child_count()):
		edit_dialog.get_node("Options").get_child(child).set_visible((child == id))
	
	edit_dialog.rect_min_size = Vector2.ZERO
	edit_dialog.rect_size = Vector2(250,100)
	new_rows_line.set_text(str(0))
	new_columns_line.set_text(str(0))
	new_delimiter_line.set_text(csv_delimiter)
	
	for column in drop_columns.get_children():
		column.queue_free()
	
	for row in drop_rows.get_children():
		row.queue_free()
	
	
	match id:
		0:
			edit_dialog.window_title = ("Add Rows")
		1:
			edit_dialog.window_title = ("Add Columns")
		2:
			edit_dialog.window_title = ("Change Delimiter")
		3:
			edit_dialog.window_title = ("Drop Rows")
			for row in range(0, rows_count):
				var check : CheckBox = CheckBox.new()
				drop_rows.add_child(check)
				check.set_text(str(row+1))
		4:
			edit_dialog.window_title = ("Drop Columns")
			for column in range(0, columns_count):
				var check : CheckBox = CheckBox.new()
				drop_columns.add_child(check)
				check.set_text(str(column+1))
	
	edit_dialog.popup()

# If Edit Option is confirmed
func _on_edit_confirmed() -> void:
	# Add new Columns
	if edit_columns.is_visible():
		var ref_column : VBoxContainer = _zero_column.duplicate(8)
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
	
	# Drop rows
	if drop_rows.is_visible():
		var rows_to_drop : PoolIntArray = []
		for row in drop_rows.get_children():
			if row.is_pressed(): rows_to_drop.append(int(row.get_text()))
		drop_rows(rows_to_drop)
	
	# Drop Columns
	if drop_columns.is_visible():
		var columns_to_drop : PoolIntArray = []
		for column in drop_columns.get_children():
			if column.is_pressed(): columns_to_drop.append(int(column.get_text()))
		drop_columns(columns_to_drop)

func drop_columns(columns_to_drop : PoolIntArray) -> void:
	for column in columns_to_drop:
		Columns.get_child(column).queue_free()
		columns_count-=1
	for column in range(1, columns_count+1):
		Columns.get_child(column).get_child(0).set_text(str(column))
	
	save_table()

func drop_rows(rows_to_drop : PoolIntArray) -> void:
	for column in range(0, columns_count+1):
		for row in rows_to_drop:
			Columns.get_child(column).get_child(row).queue_free()
	rows_count-=rows_to_drop.size()
	for row in range(1, rows_count+1):
		_column_head.get_child(row).set_text(str(row))
	
	save_table()

var keys : Array = []
var langs : Array = []
#var source_lang : String = ""

func load_translation_table() -> void:
	keys.clear()
	langs.clear()
	for column in range(2, columns_count+1):
		langs.append(Columns.get_child(column).get_child(1).get_text())
	for row in range(2, rows_count+1):
		keys.append(Columns.get_child(1).get_child(row).get_text())
	
	create_key_tree(keys)
	load_source_lang(langs)
	create_lang_tree(langs)

func load_source_lang(langs : Array) -> void:
	source_lang_menu.clear()
	var lang_popup : PopupMenu = source_lang_menu.get_popup()
	for lang in langs:
		lang_popup.add_item(lang)
	source_lang_menu.set_text(langs[0])

func create_key_tree(keys : Array) -> void:
	keys_tree.clear()
	keys_tree.set_column_titles_visible(true)
	keys_tree.set_column_title(0, "Keys to translate")
	var root : TreeItem = keys_tree.create_item()
	root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	root.set_text(0, "Select/Deselect All")
	root.set_editable(0, true)
	for key in keys:
		var child : TreeItem = keys_tree.create_item(root)
		child.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		child.set_editable(0, true)
		child.set_text(0, key)

func create_lang_tree(target_langs : Array) -> void:
	target_langs_tree.clear()
	var root : TreeItem = target_langs_tree.create_item()
	root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	root.set_text(0, "Select/Deselect All")
	root.set_editable(0, true)
	for lang in target_langs:
		var child : TreeItem = target_langs_tree.create_item(root)
		child.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		child.set_editable(0, true)
		child.set_text(0, lang)
	
	disable_source_lang(target_langs)

func disable_source_lang(langs : Array) -> void:
	var first_lang : TreeItem = target_langs_tree.get_root().get_children()
	check_source_target_lang(first_lang)
	for lang in range(0, langs.size()-1):
		first_lang = check_source_target_lang(first_lang.get_next())

func check_source_target_lang(target : TreeItem) -> TreeItem :
	if target.get_text(0) == source_lang_menu.get_text() :
		target.set_checked(0, false)
		target.set_editable(0, false)
		target.set_selectable(0, false)
		target.set_custom_bg_color(0, Color("64373737"))
	else:
		target.set_editable(0, true)
		target.set_selectable(0, true)
		target.set_custom_bg_color(0, Color.transparent)
	return target

func _on_source_lang_selected(idx : int) -> void:
	disable_source_lang(langs)

func _on_settings_pressed(id : int) -> void:
	match id:
		0: # Change CSV Editor Settings
			editor_columns_length.set_text(str(Columns.get_child(1).get_child(1).get_size().x))
			editor_columns_spacing.set_text(str(Columns.get("custom_constants/separation")))
			editor_rows_spacing.set_text(str(Columns.get_child(1).get("custom_constants/separation")))
			editor_settings.popup()
		1:
			load_translation_table()
			translation_dialog.popup()

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

# Set a LineEdit readonly property to TRUE or FALSE
func _is_readonly(readonly : bool) -> void:
	for column in range(1, columns_count+1):
		for row in range(1, rows_count+1):
			Columns.get_child(column).get_child(row).set_editable(not readonly)
	edit_menu_options.set_item_disabled(0, readonly)
	edit_menu_options.set_item_disabled(1, readonly)

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

