extends UDGoapGoal

class_name UDPickItensGoal

func get_clazz(): return "UDPickItensGoal"


func is_valid(actor) -> bool:
	var all_elements = WorldState.get_elements("item")
	#print("all elements: ", all_elements)
	if actor._state["satisfaction"] >= actor._state["satisfaction_limit"]:
		#print("goal pickitens not valid 1")
		actor._state.set("done_shopping", true)
		return false
	for i in all_elements:
		#print(i.client_holding)
		if not i.client_holding:
			if actor._state["money"] - actor._state["bill"] >= i.cost:
				#print("goal pickitens VALID")
				return true
	#print("actor._state['money']: ", actor._state["money"])
	#print("actor._state['bill']: ", actor._state["bill"])
	#print("i.cost: ", i.cost)
	#print("goal pickitens not valid 2")
	actor._state.set("done_shopping", true)
	return false

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 6

func get_desired_state(actor) -> Dictionary:
	return {
		"satisfaction": actor._state["satisfaction_limit"]
	}
