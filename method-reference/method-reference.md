# Lets make lasagne

# How to throw away the spaghetti code


## Method Reference

Below you'll find a reference for the functions used in places throughout the text.

### for_objects
`for_objects(objectId: Asset.GMObject, callback: Function, [argument: Any]) -> undefined`
```gml
/**
 * Applies a callback function to every instance of the provided object asset.
 * This method is a wrapper around the with statement that maintains the executing
 * scope. The callback function should have at least 1 parameter which will be 
 * the current instance in the loop. Returning true from the callback function is 
 * equivalent to using the break statement in a regular loop. Returning nothing, undefined
 * or false is equivalent to a continue statement. This will happen naturally at the end of the
 * callback even if no return statement is present.
 * Additional arguments passed to the for_objects
 * method will be forwarded to the callback function. This can be used to pass local
 * variables to the callback function. 
 * @param {Asset.GMObject} objectId		The object asset name to loop over.
 * @param {Function} callback			The callback function to run for each instance.
 * @param {Any} [argument]				Optional arguments to pass to the callback function.
 */
function for_objects(objectId, callback) {
    callback = method(self, callback);
    
    // Minor optimisation for no optional arguments
    if (argument_count == 2) {
        with (objectId) {
            callback(self);
        }
    }
    else {
        var args = array_create(argument_count - 1);
        for (var i = 2; i < argument_count; i++) {
            args[i - 1] =  argument[i];
        }
    
        with (objectId) {
            args[0] = self;
            var breakOut = method_call(callback, args);
            
            if (breakOut) {
                break;
            }
        }
    }
}
```

### set_value
`set_value(target: Id.Instance OR Struct, property: String) -> undefined`
```gml
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
```

### get_value
`get_value(target: Id.Instance OR Struct, property: String) -> undefined`
```gml
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
```

### object_exists
`object_exists(instance) -> undefined`
```gml
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
```
