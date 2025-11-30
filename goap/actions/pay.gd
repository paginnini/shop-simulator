extends GoapAction

class_name PayAction

#var going_already = false

var _caixa

func get_clazz(): return "PayAction"


func is_valid(actor = null) -> bool:
	return true
	return actor._goap_state["done_shopping"]

func _init() -> void:
	_caixa = WorldState.get_elements("caixa")[0]

func get_cost(_blackboard = null) -> float:
	return _blackboard["actor"].current_bill


func get_preconditions() -> Dictionary:
	return {
		"done_shopping": true,
		"position": _caixa.position
	}


func get_effects() -> Dictionary:
	return {
		"payed": true,
		#"bill": 0.0,
	}


func perform(actor, _delta) -> bool:
	if actor.current_bill == 0.0:
		print(str(actor) + " NAO PRECISA PAGAR")
		actor._goap_state.set("payed", true)
		actor.going_already = false
		return true
	
	#print("CHEGOU NO CAIXA ---------------------------------------------------------------------------------")
	if actor.current_bill <= actor.current_money:
		print(str(actor) + " PAGOU")
		actor.current_money -= actor.current_bill
		actor.current_bill = 0.0
		actor._goap_state.set("payed", true)
		actor.going_already = false
		return true
	else:
		print(str(actor) + " ERRO: BILL FICOU MAIOR QUE O DINHEIRO DO CARA")
		return false
