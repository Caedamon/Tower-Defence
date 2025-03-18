extends Node3D

@export var tile_start:PackedScene
@export var tile_end:PackedScene
@export var tile_straight:PackedScene
@export var tile_corner:PackedScene
@export var tile_crossroads:PackedScene
@export var tile_enemy:PackedScene
@export var tile_empty:Array[PackedScene]
@export var enemy:PackedScene

# Raycast settings
@onready var cam = $Camera3D
var RAYCAST_LENGTH:float = 100

# Assumes the path generator has finished, and adds the remaining tiles to fill in the grid.
# Completes the grid and spawns enemy waves when the scene is ready
func _ready():
	_complete_grid()
	_spawn_wave()

# Spawns a wave of enemies with a delay between each spawn
func _spawn_wave():    
	for i in range(2): #Number here decides how many enemies spawn.
		await get_tree().create_timer(2.275).timeout
		var enemy2:Node3D = enemy.instantiate()
		add_child(enemy2)
		enemy2.add_to_group("enemies")

# Fills in the grid with appropriate tiles based on the path and empty spaces
func _complete_grid():
	# Fill empty spaces with random empty tiles
	for x in range(PathGenInstance.path_config.map_length):
		for y in range(PathGenInstance.path_config.map_height):
			if not PathGenInstance.get_path_route().has(Vector2i(x, y)):
				var tile:Node3D = tile_empty.pick_random().instantiate()
				add_child(tile)
				tile.global_position = Vector3(x, 0, y)
				tile.global_rotation_degrees = Vector3(0, randi_range(0, 3) * 90, 0)

	# Place the correct tile types along the path
	for i in range(PathGenInstance.get_path_route().size()):
		var tile_score:int = PathGenInstance.get_tile_score(i)
		var tile:Node3D = tile_empty[0].instantiate()
		var tile_rotation:Vector3 = Vector3.ZERO

		# Determine tile type and rotation based on tile score
		if tile_score == 2:
			tile = tile_end.instantiate()
			tile_rotation = Vector3(0, -90, 0)
		elif tile_score == 8:
			tile = tile_start.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score == 10:
			tile = tile_straight.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score in [1, 4, 5]:
			tile = tile_straight.instantiate()
			tile_rotation = Vector3(0, 0, 0)
		elif tile_score == 6:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 180, 0)
		elif tile_score == 12:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score == 9:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 0, 0)
		elif tile_score == 3:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 270, 0)
		elif tile_score == 15:
			tile = tile_crossroads.instantiate()
			tile_rotation = Vector3(0, 0, 0)

		# Add the tile to the scene and position it correctly
		add_child(tile)
		tile.global_position = Vector3(PathGenInstance.get_path_tile(i).x, 0, PathGenInstance.get_path_tile(i).y)
		tile.global_rotation_degrees = tile_rotation
