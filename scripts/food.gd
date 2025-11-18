extends Node3D

@export var nutrition := 30.0
@export var cost := 10.0

var client_holding
var highlighted

var limit_ref := "hunger_limit"

func _ready():
	if WorldState.random:
		nutrition = randf_range(15.0, 50.0)
		cost = randf_range(1.0, 20.0)

func _physics_process(_delta: float) -> void:
	$labels/label_cost_nutrition.text = "Nutrition: %.2f\nCost: %.2f" % [nutrition, cost]
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
