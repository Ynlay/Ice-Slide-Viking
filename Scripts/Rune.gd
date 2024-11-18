extends Node2D

enum RUNE_TYPE {SHIELD, REGEN, DAMAGE, SPEED}
@export var RuneType: RUNE_TYPE
@export var Value = 2 
@export var Duration = 5.0 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		if body.runeAcquired: return
		match(RuneType):
			RUNE_TYPE.DAMAGE: 
				body.SetDamageMultiplierRune(Value, Duration)
			RUNE_TYPE.SHIELD: 
				body.SetShieldRune(Value, Duration)
			RUNE_TYPE.REGEN:
				body.SetRegenRune(Value, Duration)
			RUNE_TYPE.SPEED:
				body.SetSpeedRune(Value, Duration)
		
		queue_free()
