extends Node
class_name JsonHelper

const classDictionary : Dictionary = Dictionary()

static func json_string_to_class(json_string: String, _class: Object) -> Object:
	var parse_result: JSONParseResult = JSON.parse(json_string)
	if !parse_result.error:
		return json_to_class(parse_result.result, _class)
	return _class

static func _populateClassDictionary(className:String, obj:Object):
	var properties: Array = obj.get_property_list()
	for property in properties:
		var propertyName = property.name
		if not propertyName.empty() and not propertyName[0] == "_":
			# skip built in properties
			if not propertyName in ["editor_description"]:
				classDictionary[className + "." + property.name] = property
				classDictionary[className + "." + property.name.to_lower()] = property
				if property.hint_string != null and property.hint_string != "" and property.hint_string != property.name:
					classDictionary[className + "." + property.hint_string] = property	
					classDictionary[className + "." + property.hint_string.to_lower()] = property	
	classDictionary[className] = ""	

static func json_to_class(json: Dictionary, obj: Object) -> Object:
	var className = obj.get_class()
	if not classDictionary.has(className):
		_populateClassDictionary(className,obj)
	var propertyKey : String = ""		
	for jsonKey in json.keys():
		propertyKey = className + "." + jsonKey.to_lower()
		if classDictionary.has(propertyKey):
			var property = classDictionary[propertyKey]
			var propertyType : int = property["type"]
			var propertyValue = obj.get(property.name)
			var jsonValue = json[jsonKey]
			# 17 is class
			if property.usage >= (1 << 13) and propertyType == 17 and propertyValue != null:
				var propertyClass = propertyValue.get_class()
				if propertyClass == "TypedList":
					var arr = []
					var typedList = obj.get(property.name) as TypedList
					if json[jsonKey] != null:
						for d in json[jsonKey]:
							var newElement = typedList.getNewElement()
							var el = json_to_class(d,newElement)
							typedList.addElement(el)
				else:					
					if jsonValue != null:
						obj.set(property.name, json_to_class(jsonValue, propertyValue))
			# 19 is array
			elif propertyType == 19:
				if propertyValue == null:
					propertyValue = Array()
				var arr = (propertyValue as Array)
				for d in json[jsonKey]:
					arr.append(d)
				
			else:
				obj.set(property.name, jsonValue)
	return obj
	

#static func json_to_class_old(json: Dictionary, _class: Object) -> Object:
#	var properties: Array = _class.get_property_list()
#	for key in json.keys():
#		var lowerCaseKey = key.to_lower();
#		for property in properties:
#			var property_name = property.name.to_lower()
#			if  property_name == lowerCaseKey and property.usage >= (1 << 13):
#				if (property["class_name"] in ["Reference", "Object"] and property["type"] == 17):
#					_class.set(key, json_to_class(json[key], _class.get(key)))
#				else:
#					_class.set(key, json[key])
#				break
#			if lowerCaseKey  == property.hint_string.to_lower()  and property.usage >= (1 << 13):
#				if (property["class_name"] in ["Reference", "Object"] and property["type"] == 17):
#					_class.set(property.name, json_to_class(json[key], _class.get(key)))
#				else:
#					_class.set(property.name, json[key])
#				break
#	return _class

static func class_to_json_string(obj: Object) -> String:
	return JSON.print(class_to_json(obj))

static func class_to_json(obj: Object) -> Dictionary:
	var dictionary: Dictionary = {}
	var properties: Array = obj.get_property_list()
	for property in properties:
		var propertyType : int = property["type"]
		var propertyValue = obj.get(property.name)
		var propertyName = property["name"]
		# skip the private properties
		# empty propertes and some built in
		# properties like editor_description
		if propertyName.empty() or propertyName[0] == "_":
			continue
		if propertyName in ["editor_description"]:			
			continue
		if property.usage >= (1 << 13):
			if propertyType == 17:
				var propertyClass = propertyValue.get_class()
				if propertyClass == "TypedList":
					var arr = (propertyValue as TypedList).asArray()
					var newArr = Array()
					for el in arr:
						var jsonEl := class_to_json(el)
						newArr.append(jsonEl)
					dictionary[property.name] = newArr
				else:
					dictionary[property.name] = class_to_json(propertyValue)
			else:
				dictionary[property.name] = propertyValue
		if not property["hint_string"].empty() and property.usage >= (1 << 13):
			if (property["class_name"] in ["Reference", "Object"] and property["type"] == 17):
				dictionary[property.hint_string] = class_to_json(propertyValue)
			else:
				dictionary[property.hint_string] = propertyValue
	return dictionary
