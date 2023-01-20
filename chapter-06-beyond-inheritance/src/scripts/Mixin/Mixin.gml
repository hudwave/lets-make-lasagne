#macro APPLIED_MIXINS "__mixins"

function Mixin() constructor {
	static registeredInstances = {};

	static apply = function(target, mixinId) {
		// Register target as a mixin user
		var appliedMixins = get_value(target, APPLIED_MIXINS);
		if (appliedMixins == undefined) {
			appliedMixins = [];
			set_value(target, APPLIED_MIXINS, appliedMixins);
		}
		
		var mixinName = script_get_name(mixinId);
		if (!array_contains(appliedMixins, mixinName)) {
			// Create mixin
			var mixin = new mixinId();
			
			// Shallow copy properties across to target
			var keys = variable_struct_get_names(mixin);
		
			for (var i = 0; i < array_length(keys); i++) {
				var key = keys[i];
				var value = mixin[$ key];
				
				if (is_method(value)) {
					value = method(target, value);
				}
				
				set_value(target, key, value);
			}
			
			// Mark mixin on target
			array_push(appliedMixins, mixinName);
			
			// Register instance globally
			var instances = registeredInstances[$ mixinName];
			if (instances == undefined) {
				instances = [];
				registeredInstances[$ mixinName] = instances;
			}

			if (is_struct(target)) {
				target = weak_ref_create(target);
			}
			
			array_push(instances, target);
		}
	}
	
	static is = function (target, mixinId) {
		var targetTypes = get_value(target, APPLIED_MIXINS);
		if (targetTypes == undefined) {
			return false;
	   }
		
		var mixinName = script_get_name(mixinId);
		return array_contains(targetTypes, mixinName);
	}

	static getAll = function (mixinId) {
		var mixinName = script_get_name(mixinId);
		var instances = registeredInstances[$ mixinName];
		instances ??= [];
		
		// Remove any dead weak refs
		var cleaned = [];
		for (var i = 0; i < array_length(instances); i++) {
			var instance = instances[i];
			if (object_exists(instance)) {
				array_push(cleaned);
			}
		}
		
		// Update stored list of instances
		registeredInstances[$ mixinName] = cleaned;
		
		return cleaned;
	}
}
// Instantiate statics
var mixin = new Mixin();
