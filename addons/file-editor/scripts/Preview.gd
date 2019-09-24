tool
extends WindowDialog

onready var TextPreview = $Container/TextPreview

func _ready():
	pass

func print_preview(content : String):
	TextPreview.append_bbcode(content)

func print_bb(content : String):
	TextPreview.append_bbcode(content)

func print_markdown(content : String):
	content = content.replace(" **"," [b]")
	content = content.replace("**","[/b]")
	
	content = content.replace(" *"," [i]")
	content = content.replace("*","[/i] ")
	
	content = content.replace(" ~~","[s] ")
	content = content.replace("~~","[/s]")
	
	content = content.replace(" `"," [code]")
	content = content.replace("`","[/code]")
	
	TextPreview.append_bbcode(content)

func _on_Preview_popup_hide():
	queue_free()
