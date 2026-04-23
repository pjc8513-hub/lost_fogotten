# LootDistributor.gd - New autoload
extends Node

func distribute_chest_loot(chest: TreasureChest, gold: int, loot_ids: Array):
	# Add gold to party
	PartyState.party_gold += gold
	
	# Handle items
	for item_id in loot_ids:
		var item_data = LootManager.get_item_data(item_id)
		if item_data:
			# Add to a random party member's inventory
			var selected_member = PartyState.get_selected()
			var item_instance = ItemInstance.new()
			item_instance.item_data = item_data
			selected_member.inventory.append(item_instance)
			GameEvents.inventory_changed.emit(selected_member)
		else:
			print("No item data found for: ", item_id)

func distribute_enemy_loot(enemy: Enemy):
	var enemy_data = enemy.enemy_data
	
	# Add enemy gold
	PartyState.party_gold += enemy_data.gold
	GameEvents.message_logged.emit("[color=gold]Found %d gold![/color]" % enemy.enemy_data.gold)

	#print("enemy loot table: ", enemy.enemy_data.loot_table)
	# Roll loot tables
	if not (enemy.enemy_data.loot_table):
		return
	
	var loot_ids = LootManager.roll_loot(enemy_data.loot_table, 0)  # Add luck bonus later
	for item_id in loot_ids:
		var item_data = LootManager.get_item_data(item_id)
		if item_data:
			var random_member = PartyState.active_party.pick_random()
			var item_instance = ItemInstance.new()
			item_instance.item_data = item_data
			random_member.inventory.append(item_instance)
			GameEvents.inventory_changed.emit(random_member)
			var loot_names = loot_ids.map(func(id): return id.replace("_", " ").capitalize())
			GameEvents.message_logged.emit("[color=yellow]%s[/color] [color=cyan]Found: %s[/color]" % [random_member.member_name, ", ".join(loot_names)])

func distribute_quest_reward(gold: int, food: int, item_ids: Array = []):
	PartyState.party_gold += gold
	PartyState.party_food += food
	
	for item_id in item_ids:
		var item_data = LootManager.get_item_data(item_id)
		if item_data:
			var random_member = PartyState.active_party.pick_random()
			var item_instance = ItemInstance.new()
			item_instance.item_data = item_data
			random_member.inventory.append(item_instance)
			GameEvents.inventory_changed.emit(random_member)

# LootDistributor
func distribute_xp(xp: int = 0):
	if xp <= 0:
		return
		
	var members: Array[ClassData] = PartyState.get_active_party()
	if members.is_empty():
		return
	
	var xp_per_member: int = xp / members.size()
	var remainder: int = xp % members.size() # handle leftover xp
	
	GameEvents.message_logged.emit("[color=green]Party gained %s xp[/color]" % [xp])
	
	for i in members.size():
		var member: ClassData = members[i]
		var gained: int = xp_per_member
		if i < remainder: # distribute remainder 1 by 1
			gained += 1
			
		member.xp += gained
		
		# Handle multiple level ups
		while member.xp >= member.xp_to_next_level:
			var xp_for_level: int = member.xp_to_next_level
			member.xp -= xp_for_level # subtract cost, keep overflow
			
			var points = member.roll_level_up_points()
			member.gain_level(points) # this should update xp_to_next_level internally
			
			GameEvents.message_logged.emit("[color=yellow]%s reached level %s![/color]" % [member.member_name, member.level])
		
		# Only emit once after all level ups are done
		GameEvents.party_member_stats_changed.emit(member)		
