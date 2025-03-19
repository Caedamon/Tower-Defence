extends Node3D
class_name Enemy

var attackable:bool = false
var distance_travelled:float = 0
var path_3d:Path3D
var path_follow_3d:PathFollow3D
var enemy_health: float

signal enemy_finished

@export var enemy_settings:EnemySettings

# Initializes the enemy's path
func _ready():
	add_to_group("enemies")
	if enemy_settings != null:
		enemy_health = enemy_settings.health
	else:
		#print("ERROR: enemy_settings is NULL! Using default health.")
		enemy_health = 100  # Default value (adjust as needed)
	$Path3D.curve = path_route_to_curve_3d()
	$Path3D/PathFollow3D.progress = 0

# Handles the spawning state, plays the spawn animation, and transitions to traveling
func _on_spawning_state_entered():
	attackable = false
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_travelling_state")

# Handles the transition to the traveling state, making the enemy attackable
func _on_travelling_state_entered():
	attackable = true

# Moves the enemy along the path while in the traveling state
func _on_travelling_state_processing(delta):
	distance_travelled += (delta * enemy_settings.speed)
	var distance_travelled_on_screen:float = clamp(distance_travelled, 0, PathGenInstance.get_path_route().size()-1)
	$Path3D/PathFollow3D.progress = distance_travelled_on_screen

	if distance_travelled > PathGenInstance.get_path_route().size()-1:
		$EnemyStateChart.send_event("to_damaging_state")

# Handles the despawning state, plays the despawn animation, and transitions to removal
func _on_despawning_state_entered():
	enemy_finished.emit()
	$AnimationPlayer.play("despawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

# Handles the removal of the enemy from the scene
func _on_remove_enemy_state_entered():
	queue_free()

# Handles the damaging state, preventing further attacks and transitioning to despawning
func _on_damaging_state_entered():
	attackable = false
	$EnemyStateChart.send_event("to_despawning_state")

# Handles the dying state, transitioning the enemy to removal
func _on_dying_state_entered():
	enemy_finished.emit()
	$ExplosionAudio.play()
	$Path3D/PathFollow3D/catapult/catapult.visible = false
	await $ExplosionAudio.finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

# Converts the generated path route into a Curve3D for movement
func path_route_to_curve_3d() -> Curve3D:
	var c3d:Curve3D = Curve3D.new()
	for element in PathGenInstance.get_path_route():
		c3d.add_point(Vector3(element.x, 0.25, element.y))
	return c3d

func _on_area_3d_area_entered(area):
	# Prevent damage to already defeated enemies
	if enemy_health <= 0:
		#print("Enemy already defeated! Ignoring further hits.")
		return  # Stops further processing

	#print("Enemy hit by:", area.name)
	if area is Projectile:
		#print("Applying damage:", area.damage)
		enemy_health -= area.damage
		#print("Remaining health:", enemy_health)

	if enemy_health <= 0:
		print("Enemy defeated!")
		$EnemyStateChart.send_event("to_dying_state")
