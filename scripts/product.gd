extends Node3D

@export var hygiene := 0.0
@export var cost := 10.0

var client_holding
var highlighted

var limit_ref := "hygiene_limit"

func _ready():
	if WorldState.random:
		hygiene = randf_range(15.0, 50.0)
		cost = randf_range(1.0, 20.0)

func _physics_process(_delta: float) -> void:
	$labels/label_info.text = "Hygiene: %.2f\nCost: %.2f" % [hygiene, cost]
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
