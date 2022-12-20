function Signal() constructor {
	listeners = [];

	connect = function (target, callback) {
		array_push(listeners, new Listener(target, callback));
	}

	emit = function (payload = undefined) {
		for (var i = array_length(listeners) -1; i > -1; i--) {
			var listener = listeners[i];
				
			if (listener.exists()) {
				var callback = listener.getCallback();
				callback(payload);
			}
			else {
				array_delete(listeners, i, 1);
			}
		}
	}
	
	disconnect = function (target) {
		for (var i = 0; i < array_length(listeners); i++) {
			var listener = listeners[i];
			
			if (listener.exists() && listener.getTarget() == target) {
				array_delete(listeners, i, 1);
				break;
			}
		}
	}

}

function Listener(_target, _callback) constructor {
	target = undefined;
	callback = _callback;
	getTarget = undefined
	exists = undefined;

	init = function (_target) {
		// Initialise to struct specific implementations
		if (is_struct(_target)) {
			// Wrap struct in weak reference
			target = weak_ref_create(_target);

			getTarget = function () {
				return target.ref; 
			};

			exists = function () {
				return weak_ref_alive(target);
			};
		}
		// Initialise to object specific implementations
		else if (instance_exists(_target)) {
			// Is an object so nothing else is required
			target = _target;
			
			getTarget = function () {
				return target;
			};

			exists = function () {
				return instance_exists(target);
			};
		}
	}

	getCallback = function () {
		return callback;
	}

	init(_target);
}