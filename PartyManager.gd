extends VBoxContainer

const MEMBER_UI_SCENE = preload("res://party_member_ui.tscn")

func _ready():
	#print("[FRAME ", Engine.get_process_frames(), "] PartyManager _ready, party size=", PartyState.active_party.size())
	refresh_party_ui()

func refresh_party_ui():
	#print("[FRAME ", Engine.get_process_frames(), "] PartyManager refresh_party_ui start, existing children=", get_child_count())
	for child in get_children():
		#print("[FRAME ", Engine.get_process_frames(), "] PartyManager queue_free child ", child.name)
		child.queue_free()
	
	# enumerate() gives you index + data together
	for i in PartyState.active_party.size():
		var member_data = PartyState.active_party[i]
		var new_ui = MEMBER_UI_SCENE.instantiate()
		#print("[FRAME ", Engine.get_process_frames(), "] PartyManager instantiated UI index=", i, " name=", member_data.member_name, " node_ready=", new_ui.is_node_ready())
		add_child(new_ui)
		#print("[FRAME ", Engine.get_process_frames(), "] PartyManager added child ", new_ui.name, " node_ready=", new_ui.is_node_ready())
		new_ui.setup(member_data, i) # pass the index here
		print(member_data.member_name, " panel set up complete")
	#print("[FRAME ", Engine.get_process_frames(), "] PartyManager refresh_party_ui end, children now=", get_child_count())
