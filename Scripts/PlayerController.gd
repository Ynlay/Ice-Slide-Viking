extends CharacterBody2D

@export_category("Movement")
@export var Speed = 400
@export var Acceleration = 300
@export var Deceleration = 300
@export var VelocityBeforeFlip = 10.0

@export_category("Controls")
@export var AltKeys = false 

@onready var anim = $Animations
@onready var isAttacking = false 
@onready var combatController = $CombatController

var last_direction = Vector2.ZERO
var flipped_horizontal = false 
var runeAcquired = false 

func _ready(): 
	platform_floor_layers = false
	await get_tree().create_timer(1.0).timeout
	if AltKeys: 
		combatController.AltKeys = true
func _physics_process(delta):
	HandleMovement(delta)
	
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	move_and_slide()
	
func HandleMovement(delta): 
	# Get Direction
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if AltKeys: 
		input_direction = Input.get_vector("altLeft", "altRight", "altUp", "altDown")
	if input_direction != Vector2.ZERO: 
		last_direction = input_direction
		
	# Constant static speed
	#velocity = last_direction * Speed  
	
	# Acceleration / Deceleration
	if input_direction != Vector2.ZERO: 
		velocity = velocity.move_toward(input_direction * Speed, (Acceleration)*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, (Deceleration*0.5) * delta)
		
	# Flip Sprite
	#if last_direction == Vector2.LEFT or (velocity.x < -50): 
		#anim.flip_h = true
	#elif last_direction == Vector2.RIGHT or (velocity.x > 50): 
		#anim.flip_h = false
	if velocity.x < -VelocityBeforeFlip: 
		anim.flip_h = true 
		flipped_horizontal = true 
	elif velocity.x > VelocityBeforeFlip: 
		anim.flip_h = false
		flipped_horizontal = false 
		
	# Animation handling 
	if isAttacking: return
	if velocity != Vector2.ZERO: 
		anim.play("Slide")
	else: 
		anim.play("Idle")

func SetIsAttacking(_attacking): 
	isAttacking = _attacking

# RUNES
func SetDamageMultiplierRune(_multiplier, _duration): 
	if runeAcquired: return
	var pastDamage = combatController.DamageMultiplier
	combatController.DamageMultiplier = _multiplier
	runeAcquired = true 
	print("DamageRuneAcquired")
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	print("DamageRune effects fade")
	combatController.DamageMultiplier = pastDamage
	
func SetSpeedRune(_multiplier, _duration): 
	if runeAcquired: return
	var pastSpeed = Speed
	Speed = Speed * _multiplier
	runeAcquired = true
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	Speed = pastSpeed
	
func SetRegenRune(_healAmount, _duration): 
	if runeAcquired: return 
	var healTick = _healAmount/_duration
	var elapsed_time = 0.0  # Track how much time has passed
	runeAcquired = true
	while elapsed_time < _duration:
		# Heal the player
		combatController.HealthBar.value = combatController.HealthBar.value + healTick
		elapsed_time += 1.0   
		# Wait for 1 second before the next tick 
		await get_tree().create_timer(1.0).timeout
	
	runeAcquired = false 

func SetShieldRune(_value, _duration): 
	if runeAcquired: return 
	runeAcquired = true 
	combatController.invincible = true 
	await get_tree().create_timer(_duration).timeout
	runeAcquired = false 
	combatController.invincible = false 

func Pushback(block_position, force): 
	var direction = (global_transform.origin - block_position).normalized()
	var push_vector = direction * force
	velocity = push_vector 
	move_and_slide()
