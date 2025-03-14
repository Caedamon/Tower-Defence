extends Node3D

var enemies_in_range: Array[Node3D]
var current_enemy: Node3D = null
var current_enemy_targetted: bool = false
var acquire_slerp_progress: float = 0

@export var turret: Node3D

func _ready():
	var turret_path = "building_tower_cannon_red/building_tower_cannon_red/cannon_turret_red"
	
	if has_node(turret_path):
		turret = get_node(turret_path)
		print("✅ Found turret node: ", turret.name)
	else:
		print("❌ ERROR: Could not find turret node! Check if the scene is instanced correctly.")


func _on_patrol_zone_area_entered(area: Area3D):
	if area and area.get_parent():
		var enemy = area.get_parent()
		print(enemy, " entered")
		if current_enemy == null:
			current_enemy = enemy
		enemies_in_range.append(enemy)

func _on_patrol_zone_area_exited(area: Area3D):
	if area and area.get_parent():
		var enemy = area.get_parent()
		print(enemy, " exited")
		enemies_in_range.erase(enemy)

		if current_enemy == enemy:
			current_enemy = enemies_in_range.back() if enemies_in_range.size() > 0 else null

func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

func rotate_towards_target(rtarget, delta):
	if turret == null:
		print("❌ ERROR: Turret node is NULL! Check the path in _ready().")
		return

	var target_vector = turret.global_position.direction_to(
		Vector3(rtarget.global_position.x, global_position.y, rtarget.global_position.z)
	)
	var target_basis: Basis = Basis.looking_at(target_vector)
	turret.basis = turret.basis.slerp(target_basis, acquire_slerp_progress)

	acquire_slerp_progress = min(acquire_slerp_progress + delta, 1.0)

	if acquire_slerp_progress >= 1.0:
		$StateChart.send_event("to_attacking_state")


func _on_patrolling_state_processing(_delta):
	if enemies_in_range.size() > 0:
		current_enemy = enemies_in_range.back()
		$StateChart.send_event("to_acquiring_state")
	else:
		current_enemy = null

func _on_acquiring_state_entered():
	current_enemy_targetted = false
	acquire_slerp_progress = 0

func _on_acquiring_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		print("Enemy disappeared while acquiring!")
		$StateChart.send_event("to_patrolling_state")

func _on_attacking_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		print("Enemy disappeared!")
		$StateChart.send_event("to_patrolling_state")

func _on_attacking_state_entered():
	print("Target acquired")
