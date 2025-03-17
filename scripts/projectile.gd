extends Area3D
class_name Projectile

var target: Node3D
var direction: Vector3 = Vector3.ZERO

@export var speed: float = 10  # Adjust speed for testing
@export var damage: int = 20

# Called when the projectile enters the scene
func _ready():
	if target:
		direction = (target.global_position - global_position).normalized()
	else:
		print("WARNING: Projectile has no target!")

# Move the projectile each frame
func _process(delta):
	if direction != Vector3.ZERO:
		var new_position = global_position + direction * speed * delta
		if not new_position.is_finite():
			print("ERROR: Invalid position calculated! Skipping update.")
			return
		global_position = new_position

		if target != null and is_instance_valid(target):
			if global_position.distance_to(target.global_position) < 0.5:  
				print("Projectile hit the target!")
				queue_free()
		else:
			print("WARNING: Target is null or deleted! Moving in a straight line.")
			target = null

# Set the projectile's direction
func set_direction(new_direction: Vector3):
	direction = new_direction.normalized()

# Detect collisions and delete the projectile on impact
func _on_area_entered(area):
	print("Projectile hit:", area.name)
	if area.is_in_group("enemies"):
		print("Projectile hit an enemy, dealing damage.")
		queue_free()

func set_target(new_target: Node3D):
	if new_target == null or not is_instance_valid(new_target):
		print("WARNING: Tried to assign a null or invalid target to the projectile!")
		return

	target = new_target
	direction = (target.global_position - global_position).normalized()
	print("Projectile target set successfully:", target.name)

#extends Node3D <--- this and below is origin *working* code
#class_name Projectile
#
#var target: Node3D
#var direction: Vector3 = Vector3.ZERO
#var lerp_pos: float = 0
#
#@export var speed: float = 10
#@export var damage: int = 20
#
## Called when the node enters the scene
#func _ready():
	#if target:
		#direction = (target.global_position - global_position).normalized()
	#else:
		#print("WARNING: Projectile has no target!")
#
## Move the projectile each frame
#func _process(delta):
	#if target != null:
		#global_position += direction * speed * delta
		#print("Projectile moving to:", global_position)
#
		#if global_position.distance_to(target.global_position) < 0.5:  
			#print("Projectile hit the target!")
			#queue_free()
	#else:
		#global_position += direction * speed * delta
#
## Set the projectile's direction
#func set_direction(new_direction: Vector3):
	#direction = new_direction.normalized()
