extends Node2D

var player_scene: PackedScene = preload("res://Scenes/VikingPlayer.tscn")
var players = {} 
@onready var players_parent = $Players

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1).timeout
	NakamaManager.socket.received_match_state.connect(_on_match_state_received)
	NakamaManager.send_spawn_request()
	
#func _on_match_state_received(match_id: String, op_code: int, sender, data: String): 
func _on_match_state_received(match_data: NakamaRTAPI.MatchData):
	var match_id = match_data.match_id
	var op_code = match_data.op_code
	var sender = match_data.presence.user_id
	var data = match_data.data
	print("🔍 Received match state:")
	print("Match ID:", match_id)
	print("Op Code:", op_code)
	print("Sender:", sender)
	print("Data:", data)
	
	var parsed_data = JSON.parse_string(data)
	if parsed_data and parsed_data.has("action"):
		match parsed_data.action: 
			"spawn": 
				print("🚀 Spawning player:", parsed_data.user_id)
				spawn_player(parsed_data.user_id)
			"move":
				update_player_position(parsed_data.user_id, parsed_data.position)
			"animate":
				update_player_animation(parsed_data.user_id, parsed_data.animation)

func spawn_player(user_id): 
	if players.has(user_id): 
		print("⚠️ Player already spawned: ", user_id)
		return  # Avoid spawning the same player twice
	var player = player_scene.instantiate()
	player.name = user_id # Assign player's ID as their node name 
	players_parent.add_child(player)
	players[user_id] = player # Store reference to player 
	print("✅ Spawned player: ", user_id)
	# Set local player controls
	if user_id == NakamaManager.session.user_id:
		player.set_as_local()  # This function should enable movement for the local player

func update_player_position(user_id, player_position): 
	if players.has(user_id):
		players[user_id].global_position = player_position

func update_player_animation(user_id, animation_name): 
	if players.has(user_id):
		players[user_id].play_remote_animation(animation_name)
