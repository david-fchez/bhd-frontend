class_name TypedList
func get_class():
	return "TypedList"

func is_class(value):
	return value == "TypedList"
	
var _className : String
var _arr : Array
var _blueprint : Object

func asArray() -> Array :
	return self._arr

func _init(obj : Object):
	self._className = obj.get_class()
	self._blueprint = obj

# will return the new 
# copy of the original element
# supplied
func getNewElement() -> Object:
	return self._blueprint.duplicate()
	
# adds new element on the end of 
# list (which is internal array)
func addElement(obj : Object):
	if obj != null:
		var objClassName = obj.get_class()
		if objClassName != self._className:
			print("The class types do not match wants:" + self._className + ", got:" + objClassName)
			return
	self._arr.append(obj)	

# finds element in the array
# via fieldName and returns that element
func findElement(fieldName:String, value:String)->Object:
	for el in self._arr:
		var val = String(el[fieldName])
		if val == value:
			return el
	return null

# replaces element in the list with 
# another element
func replaceElement(oldElement : Object, newElement : Object)-> void:
	for el in self._arr:
		if el == oldElement:
			el = newElement


# finds element in the array
# via fieldName and returns that element
func removeElementViaField(fieldName:String, value:String)->void:
	var i = 0
	var el_found : bool = false
	for el in self._arr:
		var val = String(el[fieldName])
		if val == value:
			el_found = true
			break
		i = i + 1
	if el_found:
		self._arr.remove(i)
	else:
		Global.Log("Unable to remove element from list field:",fieldName,"value:",value)

# removes element from the list			
func removeElement(element : Object)->void:
	var cntBefore = self._arr.size()
	self._arr.erase(element)
	var cntAfter = self._arr.size()
	if cntBefore != cntAfter:
		var box =  element as BoxInfo
		Global.Log.error("Failed to remove element from the list",box.BoxId)
 

var _sortingField = ""
func _sortAscending(a,b) -> bool:
	var a_val = a[self._sortingField]
	var b_val = b[self._sortingField]
	return a_val < b_val
	
func _sortDescending(a,b) -> bool:
	var a_val = a[self._sortingField]
	var b_val = b[self._sortingField]
	return a_val > b_val

# sorts elements in the array in ascending manner
# you must provide the fieldName which is used
# to sort the array
func sortAscending(fieldName:String)->void:
	self._sortingField = fieldName
	self._arr.sort_custom(self,"_sortAscending")

# sorts elements in the array in descending manner
# you must provide the fieldName which is used
# to sort the array
func sortDescending(fieldName:String)->void:
	self._sortingField = fieldName
	self._arr.sort_custom(self,"_sortDescending")

# returns the number of elements 
# in the list
func size()->int:
	return self._arr.size()

# clears the list of all elements
func clear()->void:
	self._arr.clear()	

