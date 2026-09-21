extends HTTPRequest

signal response_received(action_type, text_output)

export var groq_model = "openai/gpt-oss-20b" 
var groq_api_key = ""

var request_queue = []
var is_requesting = false

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://config.cfg")
	if err == OK:
		groq_api_key = config.get_value("API", "groq_api_key", "")
	else:
		print("Không tìm thấy file config.cfg, vui lòng tạo file và cấu hình API Key.")

	connect("request_completed", self, "_on_request_completed")

# Hàm cũ giữ lại để tương thích, ngầm định action = "chat"
func fetch_llm_dialogue(system_prompt: String, user_input: String):
	fetch_llm("chat", system_prompt, user_input)

# Hàm mới hỗ trợ action_type
func fetch_llm(action_type: String, system_prompt: String, user_input: String):
	request_queue.append({
		"action": action_type,
		"prompt": system_prompt,
		"input": user_input
	})
	_process_queue()

func _process_queue():
	if is_requesting or request_queue.empty():
		return
		
	is_requesting = true
	var req = request_queue[0]
	
	if groq_api_key == "" or groq_api_key == "YOUR_GROQ_API_KEY_HERE":
		print("Lỗi: Bạn chưa cấu hình Groq API Key!")
		_finish_request(req["action"], "[Chưa có API Key]")
		return
		
	var url = "https://api.groq.com/openai/v1/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + groq_api_key
	]
	
	var payload_dict = {
		"model": groq_model,
		"messages": [
			{ "role": "system", "content": req["prompt"] }
		],
		"stream": false
	}
	
	if req["input"] != "":
		payload_dict["messages"].append({ "role": "user", "content": req["input"] })
	
	var json_payload = JSON.print(payload_dict)
	var err = request(url, headers, true, HTTPClient.METHOD_POST, json_payload)
	
	if err != OK:
		print("Không thể gửi request đến Groq API, mã lỗi: ", err)
		_finish_request(req["action"], "[Lỗi gửi request]")

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if request_queue.empty():
		is_requesting = false
		return
		
	var current_req = request_queue[0]
	var response_text = "..."
	
	if response_code == 200:
		var response_str = body.get_string_from_utf8()
		var json_result = JSON.parse(response_str).result
		
		if json_result != null and json_result.has("choices") and json_result["choices"].size() > 0:
			var message_data = json_result["choices"][0].get("message", {})
			response_text = message_data.get("content", "")
		else:
			print("Groq API trả về định dạng JSON không hợp lệ.")
	else:
		print("Lỗi từ server Groq. HTTP Code: ", response_code)
		print("Chi tiết: ", body.get_string_from_utf8())
		response_text = "[Lỗi kết nối Groq]"
		
	_finish_request(current_req["action"], response_text)

func _finish_request(action: String, text: String):
	if request_queue.size() > 0:
		request_queue.pop_front()
	is_requesting = false
	emit_signal("response_received", action, text)
	
	# Gọi đệ quy thông qua deferred để tránh lỗi kẹt stack
	call_deferred("_process_queue")
