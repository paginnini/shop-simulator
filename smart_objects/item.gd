extends Node3D

@export var satisfaction := 10.0
@export var cost := 10.0

var client_holding: CharacterBody3D = null
var outline

var follow_offset := 1.5  # meters behind the NPC (custom per item)
var follow_speed := 6.0   # how fast the item catches up

var type

var hydration = 0.0

var do_distance = 6.0

#var limit_ref := "hygiene_limit"

func _ready():
	if WorldState.random:
		satisfaction = snappedf(randf_range(10.0, 30.0), 0.01)
		cost = snappedf(randf_range(5.0, 20.0), 0.01)
		type = WorldState.item_types[randi_range(0, WorldState.item_types.size()-1)]
	else:
		satisfaction = snappedf(WorldState.item_satisfaction_rng.randf_range(10.0, 30.0), 0.01)
		cost = snappedf(WorldState.item_cost_rng.randf_range(5.0, 20.0), 0.01)
		type = WorldState.item_types[WorldState.item_type_rng.randi_range(0, WorldState.item_types.size()-1)]
	apply_type(type)
	WorldState._state.set(str(self)+"is_picked_up", false)
	#print("satisfaction %f | cost: %f"%[satisfaction, cost], " 		| position: ", position, " ", type)

func _physics_process(delta: float) -> void:
	$labels/label_info.text = "Type: %s\nSati: %f\nCost: %f" % [type, satisfaction, cost]
	if client_holding:
		position = client_holding.position
		var npc := client_holding
		# direction the NPC is facing
		var back_dir = -npc.transform.basis.z.normalized()
		# desired position behind the NPC
		var target_pos = npc.position + back_dir * follow_offset
		# smooth movement (lerp)
		position = position.lerp(target_pos, follow_speed * delta)


func picked_up(client):
	#if client_holding:
		#print(str(client) + " ERRO, CHAMOU PICKUP EM ALGO QUE JA ESTA PEGO")
	client_holding = client

func highlight():
	outline.visible = true

func unhighlight():
	outline.visible = false

func apply_type(type: String):
	var mat: StandardMaterial3D
	var mes
	
	match type:
		"refrigerante":
			if WorldState.random:
				hydration = snappedf(randf_range(10.0, 30.0), 0.01)
			else:
				hydration = snappedf(WorldState.item_hydration_rng.randf_range(10.0, 30.0), 0.01)
			mat = load("res://assets/refrigerante.tres")
			mes = load("res://assets/refrigerante_mesh.tres")
		"suco":
			if WorldState.random:
				hydration = snappedf(randf_range(10.0, 30.0), 0.01)
			else:
				hydration = snappedf(WorldState.item_hydration_rng.randf_range(10.0, 30.0), 0.01)
			mat = load("res://assets/suco.tres")
			mes = load("res://assets/suco_mesh.tres")
		"agua":
			if WorldState.random:
				hydration = snappedf(randf_range(10.0, 30.0), 0.01)
			else:
				hydration = snappedf(WorldState.item_hydration_rng.randf_range(10.0, 30.0), 0.01)
			mat = load("res://assets/agua.tres")
			mes = load("res://assets/agua_mesh.tres")
		"doce":
			mat = load("res://assets/doce.tres")
			mes = load("res://assets/doce_mesh.tres")
		"carne":
			mat = load("res://assets/carne.tres")
			mes = load("res://assets/carne_mesh.tres")
		"massa":
			mat = load("res://assets/massa.tres")
			mes = load("res://assets/massa_mesh.tres")
		_:
			return  # unknown type
	
	$MeshInstance3D.mesh = mes
	$MeshInstance3D.material_override = mat
	outline = $MeshInstance3D.duplicate()
	outline.material_override = preload("res://OutlineMaterial.tres")
	outline.scale *= 1.3
	outline.visible = false
	add_child(outline)
