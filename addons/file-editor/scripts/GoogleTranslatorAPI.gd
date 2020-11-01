tool
extends HTTPRequest
class_name GoogleTranslateAPI

var endpoint : String = "https://translation.googleapis.com/language/translate/v2"
var headers : PoolStringArray = ["Authorization: Bearer [token]", "Content-Type: application/json; charset=utf-8"]
var token : String = ""

signal translation_received(translations)

func _ready() -> void:
	connect("request_completed", self, "_on_translation_received")
#	endpoint.replace("[project-number-or-id]", project_number)
#	headers = ["Authentication: Bearer %s" % auth_token, "Content-Type: application/json; charset=utf-8"]

func set_token(t : String) -> void:
	token = t

func get_token() -> String:
	return token

func request_translation(source_language : String, target_language : String, contents : PoolStringArray) -> void:
	var temp_headers : PoolStringArray = headers
	temp_headers[0] = temp_headers[0].replace("[token]", token)
	request(endpoint, temp_headers, true, HTTPClient.METHOD_POST, JSON.print({"source":source_language, "target":target_language, "q":contents}))

func request_dummy() -> void:
	var dummy : Dictionary = { "source":"en", "target": "ru", "q": ["Dr. Watson, come here!", "Bring me some coffee!"] }
	request_translation(dummy.source, dummy.target, dummy.q)

func _on_translation_received(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
#	print("Request Result ", result, " with response code ", response_code)
	if response_code != 200 : print(JSON.parse(body.get_string_from_utf8()).result)
	emit_signal("translation_received", [response_code,JSON.parse(body.get_string_from_utf8()).result])
