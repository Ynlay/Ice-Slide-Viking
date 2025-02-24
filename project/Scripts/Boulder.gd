extends Node2D

@export var push_force = 200.0 
@export var Damage = 10
@export var InvincibilityTimer = 1
@onready var recentlyTossed = false 
var velocity: Vector2 = Vector2.ZERO
var last_pusher: Node2D = null 
var break_timer : Timer
 
func _ready() -> void:
	var anim = $Sprite2D  # Reference to the AnimatedSprite2D node
	var available_animations = anim.sprite_frames.get_animation_names()
	var random_index = randi() % available_animations.size()
	anim.animation = available_animations[random_index]  # Set the random animation

func _physics_process(delta: float) -> void:
	# Update position based on velocity 
	if velocity != Vector2.ZERO: 
		global_position += velocity * delta 
		# Gradually reduce velocity (friction sim) 
		velocity = velocity.move_toward(Vector2.ZERO, delta * 100)

func _on_area_entered(area: Area2D) -> void:
	print("boulder area with: ", area.name)
	# Check if a boulder was hit (Push back both boulders)
	if area.is_in_group("Boulder"): 
		var push_direction = (global_position - area.global_position).normalized()
		velocity = push_direction * push_force/2
		area.velocity = ((area.global_transform.origin - global_position).normalized()) * push_force/2
	
	# Pushback the boulder if it hits a wall
	if area.is_in_group("Wall"):
		# Reflect velocity to stop it from going through walls 
		#velocity = -velocity
		# Ricochetting method
		var collision_normal = (global_position - area.global_position).normalized()
		velocity = velocity.bounce(collision_normal) * 0.8
		# Reset tossing when ricochetting off wall
		recentlyTossed = true
		last_pusher = area
		# Reset Tossing after delay
		await get_tree().create_timer(1.45).timeout
		recentlyTossed = false
		last_pusher = null

func _on_body_entered(body: Node2D) -> void:
	print("boulder collided with: ", body.name)
	
	# Check if player was hit (damage player or enable push by player) 
	if body.is_in_group("Player"): 
		# Check if boulder is currently being tossed targeting an opposing player
		if recentlyTossed and body != last_pusher: 
			body.combatController.DamageHealth(Damage, InvincibilityTimer)
			body.Pushback(global_position, 100)
		# Check if Player is moving. If he is it means the player wants to toss the boulder.
		elif body.velocity != Vector2.ZERO: 
			# Set the player as the last_pusher
			last_pusher = body
			recentlyTossed = true
			# Push the boulder 
			var push_direction = (global_position - body.global_position).normalized()
			velocity = push_direction * push_force
			# Reset Tossing after delay
			await get_tree().create_timer(2.0).timeout
			recentlyTossed = false
			last_pusher = null
