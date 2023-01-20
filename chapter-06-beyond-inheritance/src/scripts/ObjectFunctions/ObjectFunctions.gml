/**
 * Sets a value on the target struct or object.
 * The is a convenience method that is useful when
 * the caller does not know the type of the target.
 * @param {Id.Instance, Struct} target		The object or struct to set the value on.
 * @param {String} property					The name of the property to set the value on.
 * @param {Any} value						The value to set.
 */
function set_value(target, property, value) {
	if (is_struct(target)) {
		target[$ property] = value;
	}
	else if (instance_exists(target)) {
		variable_instance_set(target, property, value);
	}
}

/**
 * Gets a value from a target struct or object.
 * The is a convenience method that is useful when
 * the caller does not know the type of the target.
 * @param {Id.Instance, Struct} target		The object or struct to get the value from.
 * @param {String} property					The name of the property to retrieve.
 */
function get_value(target, property) {
	var value = undefined;
	
	if (is_struct(target)) {
		value = variable_struct_get(target, property);
	}
	else if (instance_exists(target)) {
		value = variable_instance_get(target, property);
	}
	
	return value;
}

/**
 * Checks to see if the instance or struct exists
 * @param {Id.Instance, Struct} instance	The object to check existence of.
 */
function object_exists(instance) {
	if (is_struct(instance)) {
		if (instanceof(instance) == "weakref") {
			return weak_ref_alive(instance);
		}
		else {
			return instance != undefined;
		}
	}
	else if (typeof(instance) == "ref") {
		return instance_exists(instance);
	}

	return false;
}
