extends VBoxContainer

const MEMBER_UI_SCENE = preload("res://party_member_ui.tscn")

func _ready():
	refresh_party_ui()

func refresh_party_ui():
	for child in get_children():
		child.queue_free()
	
	# enumerate() gives you index + data together
	for i in PartyState.active_party.size():
		var member_data = PartyState.active_party[i]
		var new_ui = MEMBER_UI_SCENE.instantiate()
		add_child(new_ui)
		new_ui.setup(member_data, i) # pass the index here
		print(member_data.name, " panel set up complete")
