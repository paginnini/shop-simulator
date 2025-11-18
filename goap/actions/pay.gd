extends GoapAction

class_name PayAction

#var going_already = false

var _caixa

func get_clazz(): return "PayAction"


func is_valid() -> bool:
	return true

func _init() -> void:
	_caixa = WorldState.get_elements("caixa")[0]

func get_cost(_blackboard = null) -> float:
	return _blackboard.actor.bill


func get_preconditions(actor) -> Dictionary:
	return {
		str(actor)+"hunger_limit": true,
		str(actor)+"thirst_limit": true,
		str(actor)+"hygiene_limit": true
		
	}


func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"payed": true
	}


func perform(actor, _delta, agent) -> bool:
	if actor.bill == 0.0:
		WorldState.set_state(str(actor)+"payed", true)
		actor.going_already = false
		return true
	
	if _caixa.position.distance_to(actor.position) < actor.do_distance:
		#print("CHEGOU NO CAIXA ---------------------------------------------------------------------------------")
		if actor.bill <= actor.money:
			actor.money -= actor.bill
			actor.bill = 0.0
			WorldState.set_state(str(actor)+"payed", true)
			actor.going_already = false
			return true
		else:
			print("ERRO: BILL FICOU MAIOR QUE O DINHEIRO DO CARA")
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(_caixa.position)
			actor.going_already = true
	return false
