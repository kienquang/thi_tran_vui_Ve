extends HTTPRequest

signal response_received(text_output)

export var groq_model = "openai/gpt-oss-20b" 
var groq_api_key = ""

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://config.cfg")
	if err == OK:
		groq_api_key = config.get_value("API", "groq_api_key", "")
	else:
		print("Không tìm thấy file config.cfg, vui lòng tạo file và cấu hình API Key.")

	# Kết nối tín hiệu theo chuẩn Godot 3.x
	connect("request_completed", self, "_on_request_completed")

func fetch_llm_dialogue(system_prompt: String, user_input: String):
	if groq_api_key == "" or groq_api_key == "YOUR_GROQ_API_KEY_HERE":
		print("Lỗi: Bạn chưa cấu hình Groq API Key!")
		emit_signal("response_received", "[Chưa có API Key]")
		return
		
	var url = "https://api.groq.com/openai/v1/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + groq_api_key
	]
	
	# Dictionary tạo payload theo chuẩn OpenAI tương thích với Groq API
	var payload_dict = {
		"model": groq_model,
		"messages": [
			{
				"role": "system",
				"content": system_prompt
			},
			{
				"role": "user",
				"content": user_input
			}
		],
		"stream": false
	}
	
	# Dùng JSON.print() của Godot 3
	var json_payload = JSON.print(payload_dict)
	
	# Gửi POST request (tham số thứ 3 là true để validate SSL/HTTPS)
	var err = request(url, headers, true, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		print("Không thể gửi request đến Groq API, mã lỗi: ", err)

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if response_code == 200:
		var response_str = body.get_string_from_utf8()
		# Dùng JSON.parse().result của Godot 3
		var json_result = JSON.parse(response_str).result
		
		# Parse JSON theo format của Groq (OpenAI format)
		if json_result != null and json_result.has("choices") and json_result["choices"].size() > 0:
			var message_data = json_result["choices"][0].get("message", {})
			var response_text = message_data.get("content", "")
			
			# Phát tín hiệu theo chuẩn Godot 3.x
			emit_signal("response_received", response_text)
		else:
			print("Groq API trả về định dạng JSON không hợp lệ.")
			emit_signal("response_received", "...")
	else:
		print("Lỗi từ server Groq. HTTP Code: ", response_code)
		var error_msg = body.get_string_from_utf8()
		print("Chi tiết: ", error_msg)
		emit_signal("response_received", "[Lỗi kết nối Groq]")
