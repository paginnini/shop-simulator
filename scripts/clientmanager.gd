extends Node

@export var client_scene = preload("res://scenes/client.tscn")
@onready var spawn_area := $Area3D
# Called when the node enters the scene tree for the first time.


func _ready() -> void:
	pass # Replace with function body.


# Called every fram	e. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"):
		#print('cria cliente')
		var new_client = client_scene.instantiate()
		if WorldState.random:
			new_client.position = get_random_point_in_area(spawn_area)
		else:
			new_client.position = Vector3(0.0, 2.0, 10.0)
		
		add_child(new_client)

func _on_timer_timeout() -> void:
	#print('cria cliente')
	var new_client = client_scene.instantiate()
	if WorldState.random:
		new_client.position = Vector3(0.0, 0.0, 10.9)
		new_client.position = get_random_point_in_area(spawn_area)
	else:
		new_client.position = Vector3(0.0, 2.0, 10.0)

	add_child(new_client)
	
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
