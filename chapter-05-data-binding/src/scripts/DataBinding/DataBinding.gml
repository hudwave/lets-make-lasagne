#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	var bindings = get_value(source, DATA_BIND_SIGNALS);
	if (bindings == undefined) {
		bindings = {};
		set_value(source, DATA_BIND_SIGNALS, bindings);
	}
	
	// Check if sourceProperty has been bound before and signal exists
	var hasBeenPreviouslyBound = true;
	
	var sourceSignal = bindings[$ sourceProperty];
	if (sourceSignal == undefined) {
		hasBeenPreviouslyBound = false;
		sourceSignal = new Signal();
		bindings[$ sourceProperty] = sourceSignal;
	}

	// Generate source setter if required
	if (!hasBeenPreviouslyBound) {
		var sourceSetterName = generate_setter_name(sourceProperty);
		
		// Capture variables from scope
		var scopeVars = {
			property: sourceProperty,
			signal: sourceSignal
		};
		
		// Create a setter function for the source
		var sourceSetter = undefined;
		if (is_struct(source)) {
			sourceSetter = function (newValue) {
				self[$ other.property] = newValue
				other.signal.emit(newValue);
			};
		}
		else {
			sourceSetter = function (newValue) {
				variable_instance_set(self, other.property, newValue);
				other.signal.emit(newValue);
			};
		}
		
		// Create closure and set on the source object
		set_value(source, sourceSetterName, closure(scopeVars, sourceSetter, source));
	}
	
		// Generate target setter if required
	var targetSetterName = generate_setter_name(targetProperty);
	
	var targetSetter = get_value(target, targetSetterName);
	if (targetSetter == undefined) {
		// Capture variables from scope
		var scopeVars = {
			property: targetProperty,
		};
		
		// Create a setter for the target
		if (is_struct(target)) {
			targetSetter = function (newValue) {
				self[$ other.property] = newValue;
			};
		}
		else {
			targetSetter = function (newValue) {
				variable_instance_set(self, other.property, newValue);
			};
		}
		
		// Create closure and set on the target object
		set_value(target, targetSetterName, closure(scopeVars, targetSetter, target));
	}
	
	// Connect source signal to target setter
	sourceSignal.connect(target, targetSetter);
	
	// Update target to reflect the source's initial value
	set_value(target, targetProperty, get_value(source, sourceProperty));
}

// Function to generate closures
function closure(scopeVars, func, context = undefined) {
	// Ensure there is a context
	context ??= self;
	
	// Remove context from the original function
	func = method(undefined, func);
	
	// Add context and original function to the captured scope variables
	scopeVars[$ "__this"] = context;
	scopeVars[$ "__func"] = func;
	
	// Create the closure function
	var closureFunc = function () {
		// Generate array of args
		var __args = [];
		for (var i = 0; i < argument_count; i++) {
			array_push(__args, argument[i]);
		}
		
		// Switch to original context to execute the function
		// Captured variables will appear on other when the function is executed
		with (__this) {
			method_call(other.__func, __args);
		}
	};
	
	// Bind the closure to the captured scope variables struct
	closureFunc = method(scopeVars, closureFunc);
	
	return closureFunc;
}

// Helper function to generate setter names
function generate_setter_name(property) {
	var startLetter = string_upper(string_char_at(property, 1));
	var remaining = string_copy(property, 2, string_length(property));
	var setterName = string("set{0}{1}", startLetter, remaining);
	return setterName;
}

function set_value(target, property, value) {
	if (is_struct(target)) {
		target[$ property] = value;
	}
	else if (instance_exists(target)) {
		variable_instance_set(target, property, value);
	}
}

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
