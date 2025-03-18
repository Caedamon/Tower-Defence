extends Node3D

var enemies_in_range: Array[Node3D]
var current_enemy: Node3D = null
var current_enemy_targetted: bool = false
var acquire_slerp_progress: float = 0
var last_fire_time:int
var projectile_spawn: Node3D

@export var turret: Node3D
@export var fire_rate_ms:int = 1000
@export var projectile_type:PackedScene

# Called when the node enters the scene.
# Finds and assigns the turret node for rotation.
func _ready():
	var turret_path = "building_tower_cannon_red/building_tower_cannon_red/cannon_turret_red"
	if has_node(turret_path):
		turret = get_node(turret_path)
		print("Found turret node: ", turret.name)
	else:
		print("ERROR: Could not find turret node! Check if the scene is instanced correctly.")

	var spawn_path = "building_tower_cannon_red/projectile_spawn"
	if has_node(spawn_path):
		projectile_spawn = get_node(spawn_path)
		print("Found projectile spawn point:", projectile_spawn.name)
	else:
		print("ERROR: projectile_spawn not found!")

# Triggered when an enemy enters the patrol zone.
# Adds the enemy to the list of detected targets.
func _on_patrol_zone_area_entered(area):
	print(area, " entered")
	if current_enemy == null:
		current_enemy = area
	enemies_in_range.append(area)
	print(enemies_in_range.size())

# Triggered when an enemy exits the patrol zone.
# Removes the enemy from the list and updates the current target if needed.
func _on_patrol_zone_area_exited(area):
	print(area, " exited")
	enemies_in_range.erase(area)

# Enables or disables patrolling behavior.
func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

# Rotates the turret smoothly toward the target enemy.
func rotate_towards_target(rtarget, delta):
	if turret == null:
		print("ERROR: Turret node is NULL! Check the path in _ready().")
		return

	var target_vector = turret.global_position.direction_to(Vector3(rtarget.global_position.x, global_position.y, rtarget.global_position.z))
	var target_basis: Basis = Basis.looking_at(target_vector)
	turret.basis = turret.basis.slerp(target_basis, acquire_slerp_progress)
	acquire_slerp_progress = min(acquire_slerp_progress + delta, 1.0) # Speed at which the turret locks onto the target

	if acquire_slerp_progress >= 1.0:
		$StateChart.send_event("to_attacking_state")

# Runs during the "Patrolling" state.
# Switches to "Acquiring" if enemies are detected.
func _on_patrolling_state_processing(_delta):
	if enemies_in_range.size() > 0:
		enemies_in_range.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
		current_enemy = enemies_in_range[0]
		$StateChart.send_event("to_acquiring_state")
	else:
		current_enemy = null

# Called when entering the "Acquiring" state.
# Resets the turret's targeting progress.
func _on_acquiring_state_entered():
	current_enemy_targetted = false
	acquire_slerp_progress = 0

# Runs during the "Acquiring" state.
# Rotates towards the enemy or returns to patrolling if the enemy disappears.
func _on_acquiring_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		print("Enemy disappeared while acquiring!")
		$StateChart.send_event("to_patrolling_state")

# Runs during the "Attacking" state.
# Keeps the turret aimed at the enemy or returns to patrolling if the enemy disappears.
func _on_attacking_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
		_maybe_fire() #provisional name for now
	else:
		print("Enemy disappeared!")
		$StateChart.send_event("to_patrolling_state")

#func _maybe_fire(): <--- original code, keeping "incase new is wrong" xD
	#if Time.get_ticks_msec() > (last_fire_time+fire_rate_ms):
		#print("FIRE!!")
		#var projectile:Projectile = projectile_type.instantiate()
		#projectile.starting_position = $building_tower_cannon_red/building_tower_cannon_red/cannon_turret_red/cannon_red/projectile_spawn.global_position
		#projectile.target = current_enemy
		#add_child(projectile)
		#last_fire_time = Time.get_ticks_msec()

# Fires a projectile if enough time has passed.
func _maybe_fire(): # eeeh fugg it, im keeping the name.
	if Time.get_ticks_msec() > (last_fire_time + fire_rate_ms):
		if projectile_spawn == null:
			print("ERROR: projectile_spawn is NULL! Check _ready().")
			return
		if current_enemy == null or not is_instance_valid(current_enemy):
			print("ERROR: current_enemy is NULL or deleted! Cannot fire.")
			return

		print("Fire!!")
		var projectile:Projectile = projectile_type.instantiate()
		projectile.starting_position = projectile_spawn.global_position
		projectile.target = current_enemy
		add_child(projectile)
		last_fire_time = Time.get_ticks_msec()

# Called when entering the "Attacking" state.
# Fire projectiles.
func _on_attacking_state_entered():
	if current_enemy != null:
		print("Target acquired:", current_enemy.name)
	else:
		print("ERROR: No enemy targeted!")
	last_fire_time = Time.get_ticks_msec()
