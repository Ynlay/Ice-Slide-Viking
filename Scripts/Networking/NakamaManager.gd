extends Node

const SERVER_KEY = "defaultkey"
const HOST = "164.90.218.172"  # Use your Nakama server IP if remote
const PORT = 7350
const SCHEME = "http"

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var match_id: String = ""

var players_in_match = {}

func _ready():
	# Initialize Nakama client
	client = Nakama.create_client(SERVER_KEY, HOST, PORT, SCHEME)

func login_guest(matchmaking_label: Label):
	var randomID = str(randi() % 10000)
	var device_id = OS.get_unique_id() + "_" + randomID # Append Random ID 
	var random_username = "Guest_" + str(randomID)
	print("Logging in as guest with device_id: ", device_id, " and username: ", random_username)
	
	session = await client.authenticate_device_async(device_id, random_username)
	if session.is_valid():
		print("Logged in successfully! User ID: ", session.user_id)
		matchmaking_label.text = "Logged in successfully! User ID: %s" % session.user_id
		connect_socket()
	else:
		print("Login failed!")

func connect_socket(): 
	socket = Nakama.create_socket_from(client)
	socket.received_matchmaker_matched.connect(_on_matchmaker_matched)
	socket.received_match_presence.connect(_on_match_presence)
	await socket.connect_async(session)
	print("Connected to Nakama Socket")
	find_match()
	
func find_match():
	var min_players = 2
	var max_players = 4 # Ensure quick matching
	var query = "*"
	var string_properties = {"match_group": "test_match"}
	var numeric_properties = {}
	print("🔍 searching for a match...")
	
	var matchmaker_ticket: NakamaRTAPI.MatchmakerTicket = await socket.add_matchmaker_async(query, min_players, max_players, string_properties, numeric_properties)
	
	if matchmaker_ticket:
		print("✅ Matchmaker ticket received: ", matchmaker_ticket.ticket)
	else:
		print("❌ ERROR: Matchmaker request failed!")

func _on_matchmaker_matched(matched_data: NakamaRTAPI.MatchmakerMatched):
	if matched_data.users.size() < 2: 
		print("Not Enough players in match! Waiting for more players...")
		return 
	for player in matched_data.users:
		print("👤 Player Username: ", player.presence.username, " User ID: ", player.presence.user_id)
		
	# ✅ Wait before joining the match to allow both players to be registered
	await get_tree().create_timer(2.0).timeout
	
	var joined_match: NakamaRTAPI.Match = await socket.join_matched_async(matched_data)
	print("🆔 Joined match response: ", joined_match)
	match_id = joined_match.match_id
	
	# 🚀 Check how many players are in the match
	print("👥 Players in match: ", joined_match.presences.size())
	for player in joined_match.presences:
		print("👤 Player: ", player.username, " (", player.user_id, ")")
	
	print("👥 Waiting for players to join match...")

func _on_match_presence(match_presence: NakamaRTAPI.MatchPresenceEvent):
	print("🔹 Match Presence Update: ", match_presence)

	for presence in match_presence.joins:
		players_in_match[presence.user_id] = presence.username
		print("✅ Player joined: ", presence.username, " (", presence.user_id, ")")

	for presence in match_presence.leaves:
		players_in_match.erase(presence.user_id)
		print("❌ Player left: ", presence.username, " (", presence.user_id, ")")

	print("👥 Total Players in Match: ", players_in_match.size())
	# ✅ If 2+ players are in the match, start the game!
	if players_in_match.size() >= 2:
		print("🚀 Enough players joined! Starting match...")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenes/Level1.tscn")
	
func send_spawn_request():
	var data = {"action": "spawn", "user_id": session.user_id}
	var op_code = 0
	var result = socket.send_match_state_async(match_id, op_code, JSON.stringify(data))
	if result is NakamaException:
		print("Failed to send spawn request: ", result.message)
	else: 
		print("Spawn request sent successfully.")
