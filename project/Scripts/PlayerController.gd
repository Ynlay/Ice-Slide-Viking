extends CharacterBody2D

@export_category("Movement")
@export var Speed = 400
@export var Acceleration = 300
@export var Deceleration = 300
@export var VelocityBeforeFlip = 10.0

@export_category("Controls")
@export var AltKeys = false 

@export_category("Effects")
@onready var EffectOnCharacter = $EffectOnCharacter
@onready var EffectSideOfCharacter = $EffectSideOfCharacter

@onready var anim = $Animations
@onready var isAttacking = false 
@onready var combatController = $CombatController
var current_animation 

var last_direction = Vector2.ZERO
var flipped_horizontal = false 
var runeAcquired = false 
var is_local = false 

func _ready(): 
	EffectOnCharacter.visible = false 
	EffectSideOfCharacter.visible = false
	
	platform_floor_layers = false
	#await get_tree().create_timer(1.0).timeout
	#if AltKeys: 
		#combatController.AltKeys = true
func _physics_process(delta):
	if is_local: 
		HandleMovement(delta)
		send_movement_update()
		if Input.is_action_just_pressed("escape"):
			get_tree().quit()
	
	move_and_slide()
	
func HandleMovement(delta): 
	# Get Direction
	var input_direction = Input.get_vector("left", "right", "up", "down")
	#if AltKeys: 
		#input_direction = Input.get_vector("altLeft", "altRight", "altUp", "altDown")
	if input_direction != Vector2.ZERO: 
		last_direction = input_direction
		
	# Acceleration / Deceleration
	if input_direction != Vector2.ZERO: 
		velocity = velocity.move_toward(input_direction * Speed, Acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, (Deceleration*0.5) * delta)
		
	# Flip Sprite
	if velocity.x < -VelocityBeforeFlip: 
		anim.flip_h = true 
		flipped_horizontal = true 
		EffectSideOfCharacter.position = Vector2(20,10)
	elif velocity.x > VelocityBeforeFlip: 
		anim.flip_h = false
		flipped_horizontal = false 
		EffectSideOfCharacter.position = Vector2(-20,10)
		
	# Animation handling 
	if isAttacking: return
	if velocity != Vector2.ZERO: 
		play_animation("Slide")
	else: 
		play_animation("Idle")

func play_animation(animation_name): 
	if current_animation == animation_name: return
	current_animation = animation_name
	anim.play(animation_name)
	if is_local and NakamaManager.match_id != "":
		var data = {
			"action": "animate", 
			"user_id": NakamaManager.session.user_id,
			"animation": animation_name
		}
		NakamaManager.socket.send_match_state_async(NakamaManager.match_id, 2, JSON.stringify(data))

func send_movement_update(): 
	if NakamaManager.match_id != "":
		var data = {
			"action": "move",
			"user_id": NakamaManager.session.user_id,
			"position_x": global_position.x,
			"position_y": global_position.y,
			"velocity_x": velocity.x
		}
		NakamaManager.socket.send_match_state_async(NakamaManager.match_id, 1, JSON.stringify(data))

func send_health_update(remote_player_id, value): 
	if NakamaManager.match_id != "":
		var data = {
			"action": "health", 
			"user_id": NakamaManager.session.user_id,
			"remote_player_id": remote_player_id,
			"health_value": value
		}
		NakamaManager.socket.send_match_state_async(NakamaManager.match_id, 3, JSON.stringify(data))

func set_as_local(): 
	is_local = true
	var camera = $Camera2D
	camera.make_current()

func update_position(new_position): 
	global_position = new_position

func play_remote_animation(animation_name): 
	play_animation(animation_name)

func SetIsAttacking(_attacking): 
	isAttacking = _attacking

# RUNES
func SetDamageMultiplierRune(_multiplier, _duration): 
	if runeAcquired: return
	var pastDamage = combatController.DamageMultiplier
	combatController.DamageMultiplier = _multiplier
	runeAcquired = true 
	print("DamageRuneAcquired")
	EffectOnCharacter.visible = true
	EffectOnCharacter.animation = "DamageAura"
	EffectOnCharacter.play()
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	print("DamageRune effects fade")
	combatController.DamageMultiplier = pastDamage
	EffectOnCharacter.visible = false
	
func SetSpeedRune(_multiplier, _duration): 
	if runeAcquired: return
	var pastSpeed = Speed
	Speed = Speed * _multiplier
	runeAcquired = true
	EffectSideOfCharacter.visible = true
	EffectSideOfCharacter.play()
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	Speed = pastSpeed
	EffectSideOfCharacter.visible = false
	
func SetRegenRune(_healAmount, _duration): 
	if runeAcquired: return 
	var healTick = _healAmount/_duration
	var elapsed_time = 0.0  # Track how much time has passed
	runeAcquired = true
	EffectOnCharacter.visible = true
	EffectOnCharacter.animation = "HealthAura"
	EffectOnCharacter.play()
	while elapsed_time < _duration:
		# Heal the player
		combatController.HealthBar.value = combatController.HealthBar.value + healTick
		elapsed_time += 1.0   
		# Wait for 1 second before the next tick 
		await get_tree().create_timer(1.0).timeout
	
	runeAcquired = false 
	EffectOnCharacter.visible = false
	

func SetShieldRune(_value, _duration): 
	if runeAcquired: return 
	runeAcquired = true 
	combatController.invincible = true 
	EffectOnCharacter.visible = true
	EffectOnCharacter.animation = "ShieldAura"
	EffectOnCharacter.play()
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	combatController.invincible = false 
	EffectOnCharacter.visible = false

func Pushback(block_position, force): 
	var direction = (global_transform.origin - block_position).normalized()
	var push_vector = direction * force
	velocity = push_vector 
	move_and_slide()
