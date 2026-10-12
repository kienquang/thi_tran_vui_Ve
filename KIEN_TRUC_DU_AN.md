# KIẾN TRÚC TỔNG QUAN DỰ ÁN "THỊ TRẤN VUI VẺ"

Dự án "Thị Trấn Vui Vẻ" được xây dựng bằng **Godot Engine 3.x**. Cấu trúc của game được chia thành các hệ thống (Systems) hoạt động độc lập nhưng liên kết chặt chẽ với nhau thông qua **Autoloads (Singletons)** và **Signals (Tín hiệu)**.

Dưới đây là sơ đồ và giải thích chi tiết chức năng của từng file code trong toàn bộ dự án để bạn dễ dàng nắm bắt.

---

## 1. CÁC HỆ THỐNG QUẢN LÝ CỐT LÕI (AUTOLOADS / SINGLETONS)
Đây là các file luôn luôn tồn tại trong bộ nhớ từ khi bật game, quản lý dữ liệu toàn cục.
Bạn có thể gọi chúng từ bất kỳ đâu (Ví dụ: `TimeManager.game_hour`, `QuestManager.add_quest()`).

* **`game/world/time_manager.gd` (TimeManager):**
  * **Chức năng:** Trái tim điều phối nhịp độ game. Quản lý hệ thống thời gian thực tế ảo (Ngày, Giờ, Phút).
  * **Tính năng:** Tự động thay đổi thời tiết (Nắng, Mưa, Tuyết, Bão) và phát ra tín hiệu (`time_changed`, `day_changed`) để các UI và NPC cập nhật hành động tương ứng.

* **`game/world/quest_manager.gd` (QuestManager):**
  * **Chức năng:** Quản lý logic Nhiệm vụ và Cửa hàng.
  * **Tính năng:** Chứa danh sách các nhiệm vụ đang nhận (`active_quests`) và đã xong (`completed_quests`). Xử lý việc kiểm tra điều kiện hoàn thành (Giao đồ, mua đồ) và sinh ra các quầy hàng bán vật phẩm (Shops).

* **`game/world/world_log.gd` (WorldLog):**
  * **Chức năng:** Lưu lại các thông báo, sự kiện "nóng hổi" xảy ra trong thị trấn.
  * **Tính năng:** Là cơ sở dữ liệu để NPC biết được tin tức dạo này ra sao để "buôn dưa lê" với người chơi.

* **`game/world/SaveManager.gd` (SaveManager):**
  * **Chức năng:** Quản lý Lưu/Tải game.
  * **Tính năng:** Đóng gói dữ liệu từ Túi đồ, Nhiệm vụ, Tọa độ người chơi, và Thời gian thành file `savegame.json`. Khi người chơi load game, nó sẽ khôi phục lại các trạng thái này.

* **`game/world/AudioManager.gd` (AudioManager):**
  * **Chức năng:** Phát nhạc nền (BGM) tùy thuộc vào cảnh game hoặc thời tiết.

---

## 2. NHÂN VẬT & TƯƠNG TÁC THẾ GIỚI

* **`game/world/player.gd` (Player):**
  * **Chức năng:** Chứa toàn bộ logic của người chơi.
  * **Tính năng:** Xử lý di chuyển (WASD/Joystick), quản lý Túi đồ (`inventory`), quản lý Tiền (`coins`), và phát hiện NPC đứng gần để mở giao diện Tương tác/Trò chuyện.

* **`game/world/npc.gd` (NPC - Bộ não của AI):**
  * **Chức năng:** Điều khiển hành vi của tất cả cư dân trong thị trấn. Đây là file đồ sộ nhất game.
  * **Tính năng:**
    1. **Đường đi (Pathfinding):** Dựa vào đồng hồ (`TimeManager`), NPC tự động kiểm tra Lịch trình (`schedule`) và tìm đường đi (Navigation) đến đúng địa điểm (Về nhà, Ra chợ, Tòa thị chính...).
    2. **Hệ thống cảm xúc & Giao tiếp:** Quản lý điểm hảo cảm (`heart_level`). Lưu giữ "Ký ức" và "Bí mật". Tự động nói chuyện với NPC khác hoặc "phát khóc" tạo drama.
    3. **Tương tác LLM:** Gửi ngữ cảnh (Sự kiện, Tính cách, Thời tiết, Lời của người chơi, Bí mật) tới `llm_client.gd` để sinh câu trả lời tự nhiên.

* **`game/world/llm_client.gd` (AI Client):**
  * **Chức năng:** Kết nối với API (ví dụ: Google Gemini) để lấy câu trả lời động cho NPC dựa trên prompt (gợi ý) từ `npc.gd`.

---

## 3. GIAO DIỆN NGƯỜI DÙNG (USER INTERFACE - UI)

* **`game/ui/QuestUI.tscn` & `quest_ui.gd` (QuestUI):**
  * **Chức năng:** Bảng thông tin luôn hiện trên màn hình chính.
  * **Tính năng:** Hiển thị số Tiền, danh sách Túi đồ (`inventory`), Nhiệm vụ hiện tại. Nơi đặt Nút Lịch (Calendar) để xem sự kiện và Lưu game, hiển thị Đồng hồ.

* **`game/ui/ChatUI.tscn` & `chat_ui.gd` (ChatUI):**
  * **Chức năng:** Khung chat bật lên khi người chơi bấm nút Tương tác với NPC.
  * **Tính năng:**
    * Hiển thị nội dung trò chuyện (Lịch sử chat) với NPC.
    * Hiển thị mức độ thân thiết (Thanh Trái Tim).
    * Hiển thị Nút "🎁 Tặng Quà", Nút Nhận nhiệm vụ, Mua đồ shop, Trả nhiệm vụ.

* **`game/ui/mobile_controls.gd` (Mobile Controls):**
  * **Chức năng:** Giao diện điều khiển cho điện thoại.
  * **Tính năng:** Được nạp động (spawn) bởi `player.gd`. Tạo ra một Joystick ẩn bên trái màn hình để nhận diện vuốt/kéo, và một Nút "E" tròn bên phải để tương tác với NPC.

* **`game/ui/ui_utils.gd` (UIUtils):**
  * **Chức năng:** Chứa các hàm tiện ích vẽ UI chung.
  * **Tính năng:** Giúp tạo nhanh các hiệu ứng nút bấm (đổi màu khi trỏ chuột vào, đổi màu khi bấm).

* **`game/ui/MainMenu.tscn`:**
  * **Chức năng:** Màn hình chào mừng khi mới vào game, chứa Nút "Bắt Đầu" và "Tiếp Tục" (Load Save).

---

## TÓM TẮT LUỒNG DỮ LIỆU ĐIỂN HÌNH (WORKFLOW)

**Ví dụ: Khi bạn nói chuyện với NPC và Tặng Quà:**
1. Người chơi tới gần NPC -> **`player.gd`** nhận diện có thể tương tác.
2. Bạn bấm Nút E (hoặc phím ảo từ **`mobile_controls.gd`**).
3. Khung chat hiện ra nhờ gọi **`ChatUI.open_chat(npc_node)`**.
4. Khung chat truy cập vào biến `npc_memory` của **`npc.gd`** để hiển thị số trái tim hiện tại.
5. Bạn bấm "Tặng Quà" -> **`chat_ui.gd`** đọc `player.inventory` từ **`player.gd`**, trừ vật phẩm đi và cộng 1 tim vào **`npc.gd`**.
6. Đồng thời, **`chat_ui.gd`** báo cho **`QuestUI.gd`** cập nhật vẽ lại bảng Túi đồ để bạn thấy số lượng Táo đã giảm đi.
7. Khi bạn bấm nút Save trong Lịch -> **`SaveManager.gd`** đi qua toàn bộ **`QuestManager`**, **`TimeManager`**, và **`player.gd`** để ghi lại chỉ số vào JSON.
