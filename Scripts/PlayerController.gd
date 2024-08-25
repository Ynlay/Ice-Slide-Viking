extends CharacterBody2D

@export_category("Movement")
@export var Speed = 400
@export var Acceleration = 300
@export var Deceleration = 300
@export var AltKeys = false 

@export_category("Attack")
@export var AxeStrikeDuration = 1.0
@export var AxeStrikeCD = 2.0 
@onready var axeCooling = false 
@export var WhirlwindDuration = 2.0
@export var WhirlwindCD = 2.0
@onready var whirlCooling = false 
@onready var AttackFacing = $AttackFacing
@onready var lastAttack = "none"

@export_category("Health")
@onready var HealthBar = $Control/Healthbar
@export var DamageInvincibilityTimerAxeStrike = 1.0
@export var DamageInvincibilityTimerWhirlwind = 0.5
@onready var recentlyDamaged = false 

@onready var attacking = false
@onready var body_in_area = false
@onready var attackingBody
@onready var attackDue = 0 
@onready var anim = $Animations

var last_direction = Vector2.ZERO

func _physics_process(delta):
	HandleMovement(delta)
	HandleAxeStrike()
	HandleWhirlwind()
	HandleAttack()
	
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	move_and_slide()

func HandleAttack(): 
	if not attacking: return 
	if attackingBody == null: return
	if attackingBody.is_in_group("Player"): 
		attackingBody.HandleDamage(attackDue, lastAttack)
	

func HandleDamage(damageReceived, strikeType): 
	if damageReceived < 0: return 
	if recentlyDamaged: return
	if strikeType == "none": return
	DamageNumbers.DisplayNumber(damageReceived, global_position, false)
	HealthBar.value = HealthBar.value - damageReceived
	recentlyDamaged = true
	if strikeType == "Whirlwind": 
		await get_tree().create_timer(DamageInvincibilityTimerWhirlwind).timeout
	else: 
		await get_tree().create_timer(DamageInvincibilityTimerAxeStrike).timeout
	recentlyDamaged = false
	
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
		velocity = velocity.move_toward(input_direction * Speed, Acceleration*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Deceleration * delta)
		
	# Flip Sprite
	if last_direction == Vector2.LEFT or (velocity.x < -50): 
		anim.flip_h = true
		AttackFacing.position = Vector2(-30, 0)
	elif last_direction == Vector2.RIGHT or (velocity.x > 50): 
		anim.flip_h = false
		AttackFacing.position = Vector2(30, 0)
		
	# Animation handling 
	if attacking: return
	if velocity != Vector2.ZERO: 
		anim.play("Slide")
	else: 
		anim.play("Idle")
		attackDue = 0

func HandleWhirlwind(): 
	if whirlCooling: return
	if attacking: return
	var inputActionPressed
	if AltKeys: 
		inputActionPressed = Input.is_action_just_pressed("alt_key_two")
	else: 
		inputActionPressed = Input.is_action_just_pressed("key_two")
	if inputActionPressed: 
		lastAttack = "Whirlwind"
		anim.play("Whirlwind")
		attackDue = 5.0
		attacking = true
		await get_tree().create_timer(WhirlwindDuration).timeout
		attacking = false
		whirlCooling = true
		await get_tree().create_timer(WhirlwindCD).timeout
		whirlCooling = false
		
func HandleAxeStrike(): 
	if axeCooling: return
	if attacking: return
	var inputActionPressed
	if AltKeys: 
		inputActionPressed = Input.is_action_just_pressed("alt_key_one")
	else: 
		inputActionPressed = Input.is_action_just_pressed("key_one")
	if inputActionPressed: 
		lastAttack = "AxeStrike"
		anim.play("AxeStrike")
		attackDue = 20
		attacking = true
		await get_tree().create_timer(AxeStrikeDuration).timeout
		attacking=false
		axeCooling = true
		await get_tree().create_timer(AxeStrikeCD).timeout
		axeCooling = false




func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		body_in_area = true
		attackingBody = body



func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		body_in_area = false
		attackingBody = null
