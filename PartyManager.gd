extends VBoxContainer

const MEMBER_UI_SCENE = preload("res://party_member_ui.tscn")

func _ready():
	# It can even call itself when it enters the scene!
	refresh_party_ui()

func refresh_party_ui():
	for child in get_children():
		child.queue_free()
	
	# Access the global PartyState instead of hardcoding a list here
	for member_data in PartyState.active_party:
		var new_ui = MEMBER_UI_SCENE.instantiate()
		add_child(new_ui)
		new_ui.setup(member_data)
		print(member_data.name, " panel set up complete")
