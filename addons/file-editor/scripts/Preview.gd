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
	var result = ""
	var bolded = []
	var italics = []
	var striked = []
	var coded = []
	var linknames = []
	var images = []
	var links = []
	var lists = []
	
	var regex = RegEx.new()
	regex.compile('\\*\\*(?<boldtext>.*)\\*\\*')
	result = regex.search_all(content)
	if result:
		for res in result:
			bolded.append(res.get_string("boldtext"))
	
	
	regex.compile("\\*(?<italictext>.*)\\*")
	result = regex.search_all(content)
	if result:
		for res in result:
			italics.append(res.get_string("italictext"))
	
	regex.compile("~~(?<strikedtext>.*)~~")
	result = regex.search_all(content)
	if result:
		for res in result:
			striked.append(res.get_string("strikedtext"))
	
	regex.compile("`(?<coded>.*)`")
	result = regex.search_all(content)
	if result:
		for res in result:
			coded.append(res.get_string("coded"))
	
	regex.compile("[+-](?<element>\\s.*)")
	result = regex.search_all(content)
	if result:
		for res in result:
			lists.append(res.get_string("element"))
	
	regex.compile("(?<img>!\\[.*?\\))")
	result = regex.search_all(content)
	if result:
		for res in result:
			images.append(res.get_string("img"))
	
	regex.compile("\\[(?<linkname>.*?)\\]|\\((?<link>[h\\.]\\S*?)\\)")
	result = regex.search_all(content)
	if result:
		for res in result:
			if res.get_string("link")!="":
				links.append(res.get_string("link"))
			if res.get_string("linkname")!="":
				linknames.append(res.get_string("linkname"))
	
	for bold in bolded:
		content = content.replace("**"+bold+"**","[b]"+bold+"[/b]")
	for italic in italics:
		content = content.replace("*"+italic+"*","[i]"+italic+"[/i]")
	for strik in striked:
		content = content.replace("~~"+strik+"~~","[s]"+strik+"[/s]")
	for code in coded:
		content = content.replace("`"+code+"`","[code]"+code+"[/code]")
	for image in images:
		var substr = image.split("(")
		var imglink = substr[1].rstrip(")")
		content = content.replace(image,"[img]"+imglink+"[/img]")
	for i in links.size():
		content = content.replace("["+linknames[i]+"]("+links[i]+")","[url="+links[i]+"]"+linknames[i]+"[/url]")
	for element in lists:
		if content.find("- "+element):
			content = content.replace("-"+element,"[indent]-"+element+"[/indent]")
		if content.find("+ "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
	
	TextPreview.append_bbcode(content)

func print_html(content : String):
	content = content.replace("<i>","[i]")
	content = content.replace("</i>","[/i]")
	content = content.replace("<b>","[b]")
	content = content.replace("</b>","[/b]")
	content = content.replace("<u>","[u]")
	content = content.replace("</u>","[/u]")
	content = content.replace('<a href="',"[url=")
	content = content.replace('">',"]")
	content = content.replace("</a>","[/url]")
	content = content.replace('<img src="',"[img]")
	content = content.replace('" />',"[/img]")
	content = content.replace('"/>',"[/img]")
	content = content.replace("<pre>","[code]")
	content = content.replace("</pre>","[/code]")
	content = content.replace("<center>","[center]")
	content = content.replace("</center>","[/center]")
	
	TextPreview.append_bbcode(content)

func _on_Preview_popup_hide():
	queue_free()
