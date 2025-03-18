extends Area3D
class_name Projectile

var starting_position: Vector3
var target: Node3D

@export var speed: float = 2  # Meters per second
@export var damage: int = 20
var lerp_pos: float = 0

# Called when the projectile enters the scene
func _ready():
	starting_position = global_position

# Moves the projectile using lerp()
func _process(delta):
	if target != null and is_instance_valid(target) and lerp_pos < 1:
		global_position = starting_position.lerp(target.global_position, lerp_pos)
		#print("Projectile moving... Lerp Pos:", lerp_pos, "Global Pos:", global_position)
		lerp_pos += delta * speed
	else:
		#print("Projectile reached target or expired.")
		await get_tree().create_timer(0.1).timeout
		queue_free()
