extends Node3D

# Stores a list of enemies currently within the patrol zone
var enemies_in_range:Array[Node3D]

# Called when an enemy enters the patrol zone
func _on_patrol_zone_area_entered(area):
	print(area, " entered")
	enemies_in_range.append(area.get_node("../../.."))  # Add the enemy to the list
	print(enemies_in_range.size())

# Called when an enemy exits the patrol zone
func _on_patrol_zone_area_exited(area):
	print(area, " exited")
	enemies_in_range.erase(area.get_node("../../.."))  # Remove the enemy from the list
	print(enemies_in_range.size())

# Enables or disables patrolling by toggling the patrol zone's monitoring state
func set_patrolling(patrolling:bool):
	$PatrolZone.monitoring = patrolling
