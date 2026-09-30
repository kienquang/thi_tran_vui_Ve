extends Node

enum QuestType { FETCH_ITEM, DELIVER_MSG }

signal quest_accepted(quest)
signal quest_completed(quest)

var active_quests = []
var completed_quests = []
var _next_id = 0

var shop_items = {
	"Tiểu thương Anna": [
		{"name": "Trai Tao", "price": 10, "display": "Trái Táo"},
		{"name": "Hoa Dong Tien", "price": 15, "display": "Hoa Đồng Tiền"}
	],
	"Pha chế David": [
		{"name": "Ca Phe Sua", "price": 12, "display": "Cà Phê Sữa"}
	]
}

func add_dynamic_shop_item(shop_name: String, item: Dictionary):
	if not shop_items.has(shop_name):
		shop_items[shop_name] = []
	
	# Kiểm tra trùng lặp
	for i in shop_items[shop_name]:
		if i["name"] == item["name"]:
			return
	shop_items[shop_name].append(item)

func remove_dynamic_shop_item(shop_name: String, item_name: String):
	if shop_items.has(shop_name):
		for i in range(shop_items[shop_name].size() - 1, -1, -1):
			if shop_items[shop_name][i]["name"] == item_name:
				shop_items[shop_name].remove(i)
				break

func make_fetch_quest(giver: String, item_name: String, shop_owner: String, reward: int) -> Dictionary:
	return {
		"id": -1,
		"type": QuestType.FETCH_ITEM,
		"title": "Mua " + item_name + " cho " + giver,
		"desc": giver + " nho ban mua " + item_name + " tai " + shop_owner + ".",
		"giver_npc": giver,
		"required_item": item_name,
		"shop_owner": shop_owner,
		"reward_coins": reward,
		"status": "offered"
	}

func make_deliver_quest(giver: String, target: String, reward: int) -> Dictionary:
	return {
		"id": -1,
		"type": QuestType.DELIVER_MSG,
		"title": "Gap " + target + " cho " + giver,
		"desc": giver + " nho ban den gap " + target + " de nhan tin.",
		"giver_npc": giver,
		"target_npc": target,
		"target_talked": false,
		"reward_coins": reward,
		"status": "offered"
	}

func accept_quest(quest: Dictionary):
	quest["id"] = _next_id
	_next_id += 1
	quest["status"] = "active"
	active_quests.append(quest)
	emit_signal("quest_accepted", quest)
	WorldLog.add_entry("[Nhiem vu] Nhan: " + quest["title"])

func get_active_from(giver_npc: String) -> Dictionary:
	for q in active_quests:
		if q["giver_npc"] == giver_npc:
			return q
	return {}

func has_active_from(giver_npc: String) -> bool:
	for q in active_quests:
		if q["giver_npc"] == giver_npc:
			return true
	return false

func mark_npc_talked(npc_name: String):
	for q in active_quests:
		if q.get("type") == QuestType.DELIVER_MSG:
			if q.get("target_npc", "") == npc_name:
				q["target_talked"] = true
				WorldLog.add_entry("[Nhiem vu] Da gap " + npc_name + ". Quay lai bao " + q["giver_npc"] + "!")

func can_complete_at(giver_npc: String, player_inventory: Dictionary) -> bool:
	var q = get_active_from(giver_npc)
	if q.empty():
		return false
	if q["type"] == QuestType.FETCH_ITEM:
		return player_inventory.get(q.get("required_item", ""), 0) > 0
	elif q["type"] == QuestType.DELIVER_MSG:
		return q.get("target_talked", false)
	return false

func complete_quest_at(giver_npc: String) -> int:
	var q = get_active_from(giver_npc)
	if q.empty():
		return 0
	var reward = q.get("reward_coins", 0)
	
	if q["type"] == QuestType.FETCH_ITEM:
		remove_dynamic_shop_item(q["shop_owner"], q["required_item"])
		
	q["status"] = "done"
	active_quests.erase(q)
	completed_quests.append(q)
	emit_signal("quest_completed", q)
	WorldLog.add_entry("[Nhiem vu] Hoan thanh: " + q["title"] + "! Nhan " + str(reward) + " xu.")
	return reward

func get_active_count() -> int:
	return active_quests.size()

func get_shop_items(npc_name: String) -> Array:
	return shop_items.get(npc_name, [])

func is_shop(npc_name: String) -> bool:
	return npc_name in shop_items
