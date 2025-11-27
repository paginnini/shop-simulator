extends Node3D

@export var satisfaction := 10.0
@export var cost := 10.0

var client_holding
var highlighted

var type

var hydration = 0.0

#var limit_ref := "hygiene_limit"

func _ready():
	if WorldState.random:
		satisfaction = randf_range(10.0, 30.0)
		cost = randf_range(5.0, 20.0)
		type = WorldState.item_types[randi_range(0, WorldState.item_types.size()-1)]
	else:
		satisfaction = WorldState.item_satisfaction_rng.randf_range(10.0, 30.0)
		cost = WorldState.item_cost_rng.randf_range(5.0, 20.0)
		type = WorldState.item_types[WorldState.item_type_rng.randi_range(0, WorldState.item_types.size()-1)]
	apply_type(type)
	WorldState._state.set(str(self)+"is_picked_up", false)

func _physics_process(_delta: float) -> void:
	$labels/label_info.text = "Type: %s\nSati: %.2f\nCost: %.2f" % [type, satisfaction, cost]
	if client_holding:
		position = client_holding.position


func picked_up(client):
	client_holding = client

func highlight():
	if not highlighted:
		var outline := $MeshInstance3D.duplicate()
		outline.material_override = preload("res://OutlineMaterial.tres")
		outline.scale *= 1.3
		add_child(outline)
		highlighted = true

func unhighlight():
	pass

func apply_type(type: String):
	var mat: StandardMaterial3D
	var mes
	
	match type:
		"refrigerante":
			if WorldState.random:
				hydration = randf_range(10.0, 30.0)
			else:
				hydration = WorldState.item_hydration_rng.randf_range(10.0, 30.0)
			mat = load("res://assets/refrigerante.tres")
			mes = load("res://assets/refrigerante_mesh.tres")
		"suco":
			if WorldState.random:
				hydration = randf_range(10.0, 30.0)
			else:
				hydration = WorldState.item_hydration_rng.randf_range(10.0, 30.0)
			mat = load("res://assets/suco.tres")
			mes = load("res://assets/suco_mesh.tres")
		"agua":
			if WorldState.random:
				hydration = randf_range(10.0, 30.0)
			else:
				hydration = WorldState.item_hydration_rng.randf_range(10.0, 30.0)
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
