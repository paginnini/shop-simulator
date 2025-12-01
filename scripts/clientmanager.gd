extends Node

var client_scene = preload("res://scenes/client.tscn")
var ud_client_scene = preload("res://scenes/ud_client.tscn")
@onready var spawn_area := $Area3D

@onready var ud := WorldState.ud

var spawn_pos := Vector3(0.0, 2.0, 10.0)

var num_npcs = 1

func _ready() -> void:
	pass # Replace with function body.


# Called every fram	e. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"):
		#print('cria cliente')
		if ud == 0:
			var new_client = client_scene.instantiate()
			new_client.position = spawn_pos
			add_child(new_client)
		elif ud == 1:
			var new_ud_client = ud_client_scene.instantiate()
			new_ud_client.position = spawn_pos
			add_child(new_ud_client)
		else:
			var new_client = client_scene.instantiate()
			new_client.position = spawn_pos
			add_child(new_client)
			var new_ud_client = ud_client_scene.instantiate()
			new_ud_client.position = spawn_pos
			add_child(new_ud_client)

var num = 0
func _on_timer_timeout() -> void:
	if num >= num_npcs:
		return
	num += 1
	#print('cria cliente')
	if ud == 0:
		var new_client = client_scene.instantiate()
		new_client.position = spawn_pos
		add_child(new_client)
	elif ud == 1:
		var new_ud_client = ud_client_scene.instantiate()
		new_ud_client.position = spawn_pos
		add_child(new_ud_client)
	else:
		var new_client = client_scene.instantiate()
		new_client.position = spawn_pos
		add_child(new_client)
		var new_ud_client = ud_client_scene.instantiate()
		new_ud_client.position = spawn_pos
		add_child(new_ud_client)


func get_random_point_in_area(area_node: Area3D) -> Vector3:
	var collision_shape = area_node.get_node("CollisionShape3D") # Assuming one child CollisionShape3D
	if collision_shape and collision_shape.shape is BoxShape3D:
		var box_shape: BoxShape3D = collision_shape.shape
		var extents = box_shape.extents
		var origin = area_node.global_transform.origin - extents
		var x = randf_range(origin.x, origin.x + 2 * extents.x)
		var y = 2.0
		var z = randf_range(origin.z, origin.z + 2 * extents.z)
		return Vector3(x, y, z)
	# Add logic for other shape types if needed
	return area_node.global_transform.origin # Fallback
