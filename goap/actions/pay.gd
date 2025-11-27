extends GoapAction

class_name PayAction

#var going_already = false

var _caixa

func get_clazz(): return "PayAction"


func is_valid(blackboard = null) -> bool:
	return true

func _init() -> void:
	_caixa = WorldState.get_elements("caixa")[0]

func get_cost(_blackboard = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return WorldState.wc_position.distance_to(_blackboard["position"]) + _blackboard["bill"]


func get_preconditions(blackboard = null) -> Dictionary:
	return {
		"done_shopping": true,
		
	}


func get_effects(blackboard = null) -> Dictionary:
	return {
		"payed": true,
		"bill": 0.0,
		"position": _caixa.position
	}


func perform(actor, _delta, agent) -> bool:
	if actor._state["bill"] == 0.0:
		actor._state.set("payed", true)
		actor.going_already = false
		return true
	
	if _caixa.position.distance_to(actor.position) <= actor.do_distance:
		#print("CHEGOU NO CAIXA ---------------------------------------------------------------------------------")
		if actor._state["bill"] <= actor._state["money"]:
			actor._state["money"] -= actor._state["bill"]
			actor._state.set("bill", 0.0)
			actor._state.set("payed", true)
			actor.going_already = false
			return true
		else:
			print("ERRO: BILL FICOU MAIOR QUE O DINHEIRO DO CARA")
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(_caixa.position)
			actor.going_already = true
	return false
