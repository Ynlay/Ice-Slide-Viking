extends CharacterBody2D

@export_category("Movement")
@export var Speed = 400
@export var Acceleration = 300
@export var Deceleration = 300

@export_category("Attack")
@export var AxeStrikeDuration = 1.0
@export var AxeStrikeCD = 2.0 
@onready var axeCooling = false 
@export var WhirlwindDuration = 2.0
@export var WhirlwindCD = 2.0
@onready var whirlCooling = false 

@onready var attacking = false

@onready var anim = $Animations

var last_direction = Vector2.ZERO

func _physics_process(delta):
	HandleMovement(delta)
	HandleAxeStrike()
	HandleWhirlwind()
	
	
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	move_and_slide()

func HandleMovement(delta): 
	# Get Direction
	var input_direction = Input.get_vector("left", "right", "up", "down")
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
	elif last_direction == Vector2.RIGHT or (velocity.x > 50): 
		anim.flip_h = false
		
	# Animation handling 
	if attacking: return
	if velocity != Vector2.ZERO: 
		anim.play("Slide")
	else: 
		anim.play("Idle")

func HandleWhirlwind(): 
	if whirlCooling: return
	if attacking: return
	if Input.is_action_just_pressed("key_two"): 
		anim.play("Whirlwind")
		attacking = true
		await get_tree().create_timer(WhirlwindDuration).timeout
		attacking = false
		whirlCooling = true
		await get_tree().create_timer(WhirlwindCD).timeout
		whirlCooling = false
		
func HandleAxeStrike(): 
	if axeCooling: return
	if attacking: return
	if Input.is_action_just_pressed("key_one"): 
		anim.play("AxeStrike")
		attacking = true
		await get_tree().create_timer(AxeStrikeDuration).timeout
		attacking=false
		axeCooling = true
		await get_tree().create_timer(AxeStrikeCD).timeout
		axeCooling = false


