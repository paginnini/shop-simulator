extends UDGoapAction

class_name UDPayAction

var _caixa

func get_clazz(): return "UDPayAction"

func is_valid(state: Dictionary, actor) -> bool:
	return actor._udgoap_state["done_shopping"] or state.get("done_shopping")

func _init() -> void:
	_caixa = WorldState.get_elements("caixa")[0]

func get_cost(_blackboard = null) -> float:
	return _blackboard["actor"]._udgoap_state["current_bill"]

func get_preconditions() -> Dictionary:
	return {
		"done_shopping": true,
		"position": _caixa.position
	}

func get_effects(state: Dictionary) -> Dictionary:
	return {
		"payed": true,
		"current_bill": - state["current_bill"]
	}

func perform(actor, _delta, state = null) -> bool:
	if actor._udgoap_state["current_bill"] == 0.0:
		#print(str(actor) + " NAO PRECISA PAGAR")
		actor._udgoap_state["payed"] = true
		actor.going_already = false
		return true
	
	if actor._udgoap_state["current_bill"] <= actor._udgoap_state["current_money"]:
		#print(str(actor) + " PAGOU")
		actor._udgoap_state["current_money"] -= actor._udgoap_state["current_bill"]
		actor._udgoap_state["current_bill"] = 0.0
		actor._udgoap_state["payed"] = true
		actor.going_already = false
		return true
	else:
		#print(str(actor) + " ERRO: BILL FICOU MAIOR QUE O DINHEIRO DO CARA")
		return false
