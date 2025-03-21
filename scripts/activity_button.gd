extends Button

@export var activity_button_icon:Texture2D
@export var activity_draggable:PackedScene

var _is_dragging:bool = false
var _draggable:Node
var _is_valid_location:bool = false
var _last_valid_location:Vector3

var _cam:Camera3D
var RAYCAST_LENGTH:float = 100

@onready var _error_mat:BaseMaterial3D = preload("res://materials/red_transparent.material")

# Initializes button icon, instantiates draggable object, and gets camera reference
func _ready():
	icon = activity_button_icon
	_draggable = activity_draggable.instantiate()
	_draggable.set_patrolling(false)
	add_child(_draggable)
	_draggable.visible = false
	_cam = get_viewport().get_camera_3d()

# Handles object dragging and placement validation using raycasting
func _physics_process(_delta):
	if _is_dragging:
		var space_state = _draggable.get_world_3d().direct_space_state
		var mouse_pos:Vector2 = get_viewport().get_mouse_position()
		var origin:Vector3 = _cam.project_ray_origin(mouse_pos)
		var end:Vector3 = origin + _cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var rayResult:Dictionary = space_state.intersect_ray(query)

		if rayResult.size() > 0:
			var co:CollisionObject3D = rayResult.get("collider")

			if co.get_groups().size() > 0 and co.get_groups()[0] == "grid_empty":
				# Valid placement location
				_draggable.visible = true
				_is_valid_location = true
				_last_valid_location = Vector3(co.global_position.x, 0.2, co.global_position.z)
				_draggable.global_position = _last_valid_location
				clear_child_mesh_error(_draggable)

			else:
				# Invalid placement location
				_draggable.visible = true
				_draggable.global_position = Vector3(co.global_position.x, 0.2, co.global_position.z)
				_is_valid_location = false
				set_child_mesh_error(_draggable)

		else:
			_draggable.visible = false

# Applies an error material to all MeshInstance3D children
func set_child_mesh_error(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_error(c)
		if c is Node and c.get_child_count() > 0:
			set_child_mesh_error(c)

# Sets an error material for a single mesh
func set_mesh_error(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, _error_mat)

# Clears the error material from all MeshInstance3D children
func clear_child_mesh_error(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			clear_mesh_error(c)
		if c is Node and c.get_child_count() > 0:
			clear_child_mesh_error(c)

# Resets a mesh's material override
func clear_mesh_error(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, null)

# Starts dragging when the button is pressed
func _on_button_down():
	_is_dragging = true

# Stops dragging and places the object if the location is valid
func _on_button_up():
	_is_dragging = false
	_draggable.visible = false

	if _is_valid_location:
		var activity = activity_draggable.instantiate()
		add_child(activity)
		activity.global_position = _last_valid_location
