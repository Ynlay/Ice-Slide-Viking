extends Node2D

var player_scene: PackedScene = preload("res://Scenes/VikingPlayer.tscn")
var players = {} 
@onready var players_parent = $Players

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NakamaManager.socket.received_match_state.connect(_on_match_state_received)
	# ✅ Ensure signal is connected
	if NakamaManager.socket.received_match_state.is_connected(_on_match_state_received):
		print("✅ received_match_state is already connected.")
	
	for user_id in NakamaManager.players_in_match.keys():
		spawn_player(user_id)
	
#func _on_match_state_received(match_id: String, op_code: int, sender, data: String): 
func _on_match_state_received(match_data: NakamaRTAPI.MatchData):
	var data = match_data.data
	var parsed_data = JSON.parse_string(data)
	if parsed_data and parsed_data.has("action"):
		match parsed_data.action: 
			"move":
				update_player_position(parsed_data.user_id, parsed_data.position_x, parsed_data.position_y, parsed_data.velocity_x)
			"animate":
				update_player_animation(parsed_data.user_id, parsed_data.animation)
			"health": 
				update_player_health(parsed_data.remote_player_id, parsed_data.health_value)

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

func update_player_position(user_id, position_x, position_y, velocity_x): 
	if players.has(user_id):
		players[user_id].global_position = Vector2(float(position_x), float(position_y))
		players[user_id].velocity.x = float(velocity_x)

func update_player_animation(user_id, animation_name): 
	if players.has(user_id):
		players[user_id].play_remote_animation(animation_name)
		
func update_player_health(remote_player_id, health_value): 
	if players.has(remote_player_id): 
		if players[remote_player_id].combatController.HealthBar.value == float(health_value): return
		var damage_value = players[remote_player_id].combatController.HealthBar.value - float(health_value)
		if damage_value <= 0: return
		players[remote_player_id].combatController.DamageHealth(damage_value, 1)
