extends Control

@onready var login_button = $Panel/Button
@onready var matchmaking_label = $Panel/MatchmakingLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)

func _on_login_pressed():
	await NakamaManager.login_guest(matchmaking_label)
