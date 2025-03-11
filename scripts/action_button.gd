extends Button

@export var button_icon:Texture2D
@export var button_object:PackedScene

var cam:Camera3D
var action_object:Node

var RAYCAST_LENGTH:int = 100

var _is_dragging:bool = false
var _is_valid_location:bool = false
var _last_valid_location:Vector3

var _drag_alpha:float = 0.5

@onready var error_mat:BaseMaterial3D = preload("res://materials/red_transparent.material")

# Initialize button icon, instantiate the action object, and get the camera reference
func _ready():
	icon = button_icon
	action_object = button_object.instantiate()
	add_child(action_object)
	action_object.visible = false
	cam = get_viewport().get_camera_3d()

# Handles object dragging using raycasting
func _physics_process(_delta):
	if _is_dragging:
		var space_state = action_object.get_world_3d().direct_space_state
		var mouse_pos:Vector2 = get_viewport().get_mouse_position()
		var origin:Vector3 = cam.project_ray_origin(mouse_pos)
		var end:Vector3 = origin + cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var rayResult:Dictionary = space_state.intersect_ray(query)

		if rayResult.size() > 0:
			_on_main_mouse_hit(rayResult.get("collider"))
		else:
			action_object.visible = false
			_is_valid_location = false

# Sets alpha transparency for all MeshInstance3D children
func set_child_mesh_alphas(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_alpha(c)
		if c is Node and c.get_child_count() > 0:
			set_child_mesh_alphas(c)

# Applies transparency to a mesh
func set_mesh_alpha(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, mesh_3d.mesh.surface_get_material(si).duplicate(true))
		mesh_3d.get_surface_override_material(si).transparency = 1
		mesh_3d.get_surface_override_material(si).albedo_color.a = _drag_alpha

# Sets an error material for all MeshInstance3D children
func set_child_mesh_error(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_error(c)
		if c is Node and c.get_child_count() > 0:
			set_child_mesh_error(c)

# Applies an error material to a mesh
func set_mesh_error(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, error_mat)

# Clears material overrides from all MeshInstance3D children
func clear_material_overrides(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			clear_material_override(c)
		if c is Node and c.get_child_count() > 0:
			clear_material_overrides(c)

# Resets a mesh's material override
func clear_material_override(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, null)

# Handles placement logic when the raycast hits a tile
func _on_main_mouse_hit(tile:CollisionObject3D):
	action_object.visible = true

	if tile.get_groups()[0].begins_with("grid_empty"):
		set_child_mesh_alphas(action_object)
		action_object.global_position = Vector3(tile.global_position.x, 0.2, tile.global_position.z)
		_last_valid_location = action_object.global_position
		_is_valid_location = true
	else:
		set_child_mesh_error(action_object)
		action_object.global_position = Vector3(tile.global_position.x, 0.2, tile.global_position.z)
		_is_valid_location = false

# Starts dragging when the button is pressed
func _on_button_down():
	_is_dragging = true
	_is_valid_location = false

# Stops dragging and places the object if the location is valid
func _on_button_up():
	_is_dragging = false
	action_object.visible = false

	if _is_valid_location:
		var new_object:Node3D = button_object.instantiate()
		get_viewport().add_child(new_object)
		new_object.global_position = _last_valid_location
