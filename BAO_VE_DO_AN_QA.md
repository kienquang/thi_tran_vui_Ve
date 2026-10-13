# BỘ CÂU HỎI & CÂU TRẢ LỜI BẢO VỆ ĐỒ ÁN: "THỊ TRẤN VUI VẺ"

Tài liệu này được biên soạn dành riêng cho buổi bảo vệ đồ án/khóa luận của bạn. Các câu hỏi được phân loại theo các nhóm chủ đề mà Hội đồng giám khảo (thầy cô) hay hỏi nhất, kèm theo **chiến lược trả lời chuyên nghiệp** và **đoạn code trích dẫn cụ thể** để bạn tự tin mở màn hình chỉ thẳng vào code.

---

## CHỦ ĐỀ 1: TRÍ TUỆ NHÂN TẠO & TÍCH HỢP LLM (CHỦ ĐỀ ĐƯỢC QUAN TÂM NHẤT)

### Câu 1: Làm thế nào để NPC dùng AI nhưng không bị "ảo giác" (Hallucination) và nói chuyện đúng ngữ cảnh của game?
* **Cách trả lời tự tin:** 
  > *"Thưa thầy/cô, em sử dụng kỹ thuật **Context Injection (Bơm ngữ cảnh)** vào System Prompt trước khi gửi lên LLM. Thay vì để AI tự do suy diễn, em gói toàn bộ trạng thái thời gian thực của game (Tên nhân vật, tính cách, thời tiết, tin tức mới nhất của thị trấn và ký ức 10 sự kiện gần nhất) vào Prompt. Nhờ vậy, câu trả lời của AI luôn bám sát 100% vào thế giới ảo."*
* **Trích dẫn Code:** File [`game/world/npc.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/npc.gd) – Hàm `generate_system_prompt()`:
```gdscript
func generate_system_prompt() -> String:
	var prompt = "Bạn là nhân vật trong game tên là " + npc_memory["name"] + ". Thời gian: " + TimeManager.get_time_string() + "\n"
	# Bơm thời tiết
	var w = TimeManager.current_weather
	if w == "RAIN": prompt += "Thời tiết: Đang mưa rào.\n"
	prompt += "Tính cách: " + npc_memory["personality"] + ".\n"
	# Bơm tin tức thế giới và ký ức cá nhân
	prompt += "Tin tức thị trấn:\n" + WorldLog.get_recent_logs(3)
	if npc_memory["history_logs"].size() > 0:
		prompt += "Ký ức gần đây của bạn:\n"
		for entry in npc_memory["history_logs"]:
			prompt += "- " + entry + "\n"
	prompt += "Hãy nhập vai và trả lời tự nhiên, ngắn gọn bằng tiếng Việt dưới 20 từ."
	return prompt
```

---

### Câu 2: Khi người chơi hoặc nhiều NPC cùng nói chuyện một lúc, làm sao để không bị nghẽn mạng hoặc vượt quá giới hạn (Rate Limit) của API?
* **Cách trả lời tự tin:**
  > *"Em đã cài đặt cấu trúc dữ liệu **Hàng đợi bất đồng bộ (Asynchronous Queue)** trong `llm_client.gd`. Mọi yêu cầu gọi thoại từ NPC sẽ được xếp vào mảng `request_queue`. Một cờ `is_requesting` sẽ đảm bảo tại mỗi thời điểm chỉ có duy nhất 1 request HTTP đang bay trên mạng. Khi máy chủ trả kết quả xong (`request_completed`), hệ thống mới lấy phần tử tiếp theo ra xử lý."*
* **Trích dẫn Code:** File [`game/agent/llm_client.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/agent/llm_client.gd) – Hàm `fetch_llm()` và `_process_queue()`:
```gdscript
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
	# Đóng gói và gửi HTTPRequest...
```

---

### Câu 3: Hệ thống Hảo Cảm (Tình cảm) và Mở Khóa Bí Mật hoạt động như thế nào?
* **Cách trả lời tự tin:**
  > *"Độ hảo cảm (`heart_level`) dao động từ 0 đến 5 tim. Người chơi có thể tăng tim bằng cách tặng quà (`chat_ui.gd`) hoặc kiên trì trò chuyện mỗi ngày (`npc.gd`). Khi đạt mốc 2 tim và 4 tim, hệ thống sẽ mở khóa các 'Bí mật thị trấn' (Town Secrets) và nhét chúng vào bộ nhớ của AI. Khi trò chuyện, AI sẽ có quyền tiết lộ các bí mật này cho người chơi."*
* **Trích dẫn Code:** File [`game/world/npc.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/npc.gd) – Đoạn mở khóa bí mật:
```gdscript
var hearts = npc_memory.get("heart_level", 0)
if hearts >= 2:
	prompt += "BÍ MẬT THỊ TRẤN ĐƯỢC MỞ KHÓA (Tùy chọn chia sẻ nếu có ngữ cảnh phù hợp):\n"
	if npc_name == "Thị trưởng Thomas":
		if hearts >= 2: prompt += "- Ngân quỹ thị trấn tháng trước thâm hụt là do tôi lỡ mua mô hình siêu nhân bản giới hạn.\n"
		if hearts >= 4: prompt += "- Tôi bị hói và đang đội tóc giả 20 năm nay rồi! Cấm nói ai biết!\n"
```

---

## CHỦ ĐỀ 2: KIẾN TRÚC PHẦN MỀM & MẪU THIẾT KẾ (DESIGN PATTERNS)

### Câu 4: Em đã áp dụng những Design Pattern nào trong dự án?
* **Cách trả lời tự tin:**
  > *"Dự án của em áp dụng 3 Design Pattern kinh điển trong ngành phát triển Game:*
  > 1. ***Singleton Pattern (Autoloads):*** Dùng cho `TimeManager`, `QuestManager`, `SaveManager`, `WorldLog`, `AudioManager` để duy trì dữ liệu toàn cục xuyên suốt các Scene.
  > 2. ***Observer Pattern (Signals):*** Các Manager phát ra sự kiện (`time_changed`, `day_changed`, `weather_changed`), các đối tượng UI và NPC đăng ký lắng nghe và tự động phản ứng mà không bị phụ thuộc chéo (Decoupling).
  > 3. ***Finite State Machine (FSM):*** Điều khiển hành vi NPC qua các trạng thái hữu hạn (`IDLE`, `WALKING`, `TALKING`, `CRYING`)."*

---

### Câu 5: Cơ chế Lưu/Tải (Save/Load) dữ liệu được triển khai như thế nào?
* **Cách trả lời tự tin:**
  > *"Em sử dụng cơ chế **Serialization (Tuần tự hóa)** dữ liệu thành định dạng JSON nhẹ tại `user://savegame.json`. Khi lưu, `SaveManager` gom trạng thái từ TimeManager (ngày, giờ, phút, thời tiết), QuestManager (nhiệm vụ active/done), và Player (tọa độ x/y, số xu, túi đồ dictionary). Khi nạp lại, hệ thống đọc file, phục hồi dữ liệu và phát các tín hiệu ép UI vẽ lại đúng trạng thái cũ."*
* **Trích dẫn Code:** File [`game/world/SaveManager.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/SaveManager.gd) – Hàm `save_game()` và `apply_save_data()`.

---

## CHỦ ĐỀ 3: ĐỒ HỌA, ÁNH SÁNG & TỐI ƯU HÓA HIỆU NĂNG

### Câu 6: Làm sao nhân vật đi vào trong nhà (Interiors) mà không bị màn hình chờ (Loading Screen)?
* **Cách trả lời tự tin:**
  > *"Em áp dụng kỹ thuật **Seamless World Coordinates (Tọa độ thế giới liền mạch)**. Tất cả nội thất căn phòng đều nằm chung trong `World.tscn`, nhưng được đặt ở các tọa độ rất xa ngoài rìa bản đồ (X > 5000px). Khi nhân vật bước vào cửa (`Door.tscn`), code chỉ đơn giản dịch chuyển tức thời tọa độ Player đến căn phòng đó. Không cần giải phóng bộ nhớ hay load Scene mới nên tốc độ chuyển cảnh đạt 0ms."*
* **Trích dẫn Code:** File [`game/world/door.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/door.gd) – Hàm `_on_body_entered()`.

---

### Câu 7: Hệ thống Chiếu sáng Ngày - Đêm và Đèn đường hoạt động ra sao? Có làm tụt FPS không?
* **Cách trả lời tự tin:**
  > *"Hệ thống hoàn toàn tối ưu và không hề tụt FPS:*
  > * *Hiệu ứng ngày đêm sử dụng `CanvasModulate` để phủ màu toàn màn hình (Hoàng hôn cam, Đêm xanh trăng). Khi vào nhà, ánh sáng tự chuyển về màu trắng ấm cúng.*
  > * *Hệ thống đèn đường (`StreetLamp.tscn`) sử dụng node `Light2D`. Em viết một hàm tạo Texture dải sáng tròn (Cosine Radial Falloff) có kích thước 64x64 siêu nhẹ. Đèn có logic tự bật sáng lúc 17h-19h và tự tắt lúc 5h-6h sáng."*
* **Trích dẫn Code:** File [`game/world/street_lamp.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/street_lamp.gd) và [`game/world/time_manager.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/world/time_manager.gd) – Hàm `update_lighting()`.

---

### Câu 8: Game có hỗ trợ thiết bị di động (Mobile) không? Em giải quyết phần điều khiển như thế nào?
* **Cách trả lời tự tin:**
  > *"Game được thiết kế đa nền tảng (Cross-platform). Em đã tạo file `mobile_controls.gd`: một bên nửa trái màn hình là Cần gạt ảo (Virtual Joystick) nhận diện vuốt/kéo cảm ứng, bên phải là nút tương tác [E] tròn. Các thao tác này được chèn trực tiếp vào hệ thống Input gốc của Godot (`Input.parse_input_event`), do đó người chơi trên máy tính hay điện thoại đều có trải nghiệm mượt mà như nhau."*
* **Trích dẫn Code:** File [`game/ui/mobile_controls.gd`](file:///d:/GAME%20Project/thi_tran_vui_Ve/game/ui/mobile_controls.gd).

---

## 3 BÍ QUYẾT KHI ĐỨNG TRƯỚC HỘI ĐỒNG:
1. **Nếu thầy cô hỏi: "Tại sao không dùng Godot 4 mà dùng Godot 3?":**
   * *Trả lời:* "Godot 3 có tính ổn định cực cao trên các nền tảng web và thiết bị cấu hình thấp, đồng thời tương thích xuất sắc với phong cách đồ họa Pixel-Art 2D mà em đang hướng tới."
2. **Khi Demo thực tế:** 
   * Hãy mở khung Chat với NPC, tặng 1 quả táo để thấy tim tăng lên, và gõ một câu hỏi bất kỳ như *"Dạo này thị trấn có tin gì hot không?"* để khoe khả năng trả lời tự nhiên của AI.
3. **Thái độ:** Bình tĩnh, tự tin, luôn mở sẵn Godot Editor với các file code tương ứng để chỉ tay vào màn hình khi trả lời.
