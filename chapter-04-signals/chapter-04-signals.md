# Lets make lasagne

# A Lesson In loose coupling: How to throw away the spaghetti code


## Chapter 4: Signals (Observer Pattern)

This one is a game changer. This might be the most important piece of code you write and add to your projects. It's an implementation of the observer pattern. Again there are entire books dedicated to design patterns and I don't want to scare people away so we're going to talk about how it works in practice rather than with UML diagrams.

We are going to create a system where an object can emit a signal, imagine a medieval city that lights a smoke signal to warn others. Other objects will observe or listen for the signal and react to it.

Before diving into the implementation details lets look at how the system will work. At the centre of the system is one constructor class which we'll call `Signal`. The `Signal` class will have a method called `emit` which will notify anyone listening to the signal that the event has occurred.

In terms of our scenario the player object will emit a signal when a coin is collected. The signal will be called `coinCollected`. We will replace the direct call to `oGame.addCoin()` with the signal being emitted `coinCollected.emit()`. We can also remove the instance variable that stores the game controller and associated setter.

##### oPlayer::Create
```gml
coinCollected = new Signal();
```

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);
if (coin != noone) {
	// Emit signal that coin has been collected
	coinCollected.emit();

	// Start process of destroying coin
	coin.collectCoin();
}
```

The `Signal` class also needs a method to register objects who want to listen for the signal. Here is an example of how to connect to a signal[^1].

```gml
player.coinCollected.connect(oGame, addCoin);
```

The first argument is the listener that will observe the signal and the second argument is a callback function to run when the signal is emitted. Similarly to how we handle dependencies we will connect objects to the signal from an object higher up in the hierarchy[^2]. Lets look at how this changes the game controller.

##### oGame::Create
```gml
coins = 0;

var player = instance_create_layer(x, y, layer, oPlayer);
var uiHud = instance_create_layer(x, y, layer, oHud);

getCoins = function () {
	return coins;
}

addCoin = function () {
	coins++;
	uiHud.setCoins(coins);
}

player.coinCollected.connect(self, addCoin);
```

We no longer use dependency injection to set the game controller on the player. Instead we connect to the signal that the player object exposes. Now when the player collects a coin the signal is emitted, every object that is connected to the signal will be notified i.e. the callback method we provided when connecting will be called.

The player object is now entirely independent from the game controller. The general rule when using signals is that you signal up to objects higher in the hierarchy and call down to objects lower down in the hierarchy (by accessing methods). This will reduce the coupling between the objects and allow them to be used in multiple contexts without any changes required.

Now we need to actually implement the `Signal` class.

### Implementing the `Signal` class

Create a new script and call it Signals. Add a new constructor function called `Signal`. We only need one instance variable which will be an array of the listeners connected to the signal. Lets also add empty methods for connect and emit that we discussed in the section above.

##### Signals.gml
```gml
function Signal() constructor {
	listeners = [];

	connect = function (target, callback) {

	}

	emit = function () {

	}
}
```

We also need a small data class called `Listener` to store the details of each listener. This can be added to the bottom of `Signals.gml`.

##### Signals.gml
```gml
function Listener(_target, _callback) constructor {
	target = _target;
	callback = _callback;

	getTarget = function () {
		return target;
	}

	getCallback = function () {
		return callback;
	}
}
```

Implementing the connect method is simple, all we need to do is add a new listener to the signal's array of listeners.

##### Signals.gml::Signal::connect
```gml
connect = function (target, callback) {
	array_push(listeners, new Listener(target, callback));
}
```

In it's current state it would be possible to add the same listener twice. This would mean that the listener would be notified twice when the signal is emitted. Feel free to add in a check to prevent this if you want but for the sake of keeping the tutorial simple we will skip over this.

We're going to implement the simplest version of the emit method first and then refine it later.

##### Signals.gml::Signal::emit
```gml
emit = function (payload = undefined) {
	for (var i = 0; i < array_length(listeners); i++) {
		var listener = listeners[i];
			
		if (instance_exists(listener)) {
			var callback = listener.getCallback();
			callback(payload);
		}
	}
}
```

Notice that we have added an optional argument called payload. This will allow you to pass information over with the signal if required. For example if each of the coins had a different value we could pass the coin over when the signal is emitted and the game controller can read the value from the coin.

##### oCoin::Create
```gml
getValue = function () {
	// value is defined in the Variable Definitions part of the object inspector so that it can be set in the room editor
	return value;
}
```

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);
if (coin != noone) {
	// Emit signal that coin has been collected and pass coin to listeners
	coinCollected.emit(coin);

	// Start process of destroying coin
	coin.collectCoin();
}
```

##### oGame::Create::addCoin
```gml
addCoin = function (coin) {
	coins += coin.getValue();
	uiHud.setCoins(coins);
}
```

This is the simplest possible version of the pattern. You could use it in this state and for the most part you wouldn't encounter any issues. We're going to make some changes so that it can handle both objects and structs and will clean up any listeners that no longer exist.

#### Handling structs

In the implementation above, when the signal is emitted we check to see if the object instance exists before calling the callback function. If we want to support structs then we need to handle them differently. Not only do they have a different method to check for their existence but they are also handled differently in memory than object instances.

If an object instance is not marked as persistent then it be removed from memory when the room changes or if it is manually destroyed.

Structs however are removed by the garbage collector when no other object or struct holds a reference to it. A reference to the struct is the same thing as storing the struct as an instance variable.

The `Signal` class is designed to decouple from other objects. However if we hold a reference to the struct in the signal then we may prevent it from being removed from memory. Luckily there is a way to prevent this from happening by wrapping the struct in a weak reference.

##### Signals.gml::Listener
```gml
function Listener(_target, _callback) constructor {
	target = undefined;
	callback = _callback;

	if (is_struct(_target)) {
		// Wrap struct in weak reference
		target = weak_ref_create(_target);
	}
	else if (instance_exists(_target)) {
		// Is an object so nothing else is required
		target = _target;
	}

	getTarget = function () {
		return target;
	}

	getCallback = function () {
		return callback;
	}
}
```

Now that the struct is wrapped in a weak reference the `getTarget` method will return the weak reference instead of the struct itself. We need to have a different implementation of the getter based on whether or not the target is an object or an instance. Another win for using getters and setters! Well also add a convenience method to check whether the object or struct still exists. This will also have a different implementation for objects and structs.

##### Signals.gml::Listener
```gml
function Listener(_target, _callback) constructor {
	target = undefined;
	callback = _callback;
	getTarget = undefined
	exists = undefined;

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

	getCallback = function () {
		return callback;
	}
}
```

The initialisation of the `Listener` class is becoming quite complicated now. This is optional but I like to move all initialisation into a method. Anything beyond a simple setting of an instance variable would go in the `init` method.

##### Signals.gml::Listener
```gml
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
```

The `init` method can be called at the end of the constructor function or it offers the possibility to delay the initialisation of the object until later. Lets now update the `Signals` class to use the new exists method.

##### Signals.gml::Signal
```gml
function Signal() constructor {
	listeners = [];

	connect = function (target, callback) {
		array_push(listeners, new Listener(target, callback));
	}

	emit = function (payload = undefined) {
		for (var i = 0; i < array_length(listeners); i++) {
			var listener = listeners[i];
				
			if (listener.exists()) {
				var callback = listener.getCallback();
				callback(payload);
			}
		}
	}
}
```

#### Clean up

If the target of the listener no longer exists then we don't want it to remain a listener. If the `exists` check fails then we will delete the listener from the array. To do this safely instead of increasing the index as we loop over the array we will decrease it starting from the highest index. Doing it this way will ensure that we will always be accessing a valid array index even if the size of the array decreases.

##### Signals.gml::Signal
```gml
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
}
```

One last thing you might need is a way to disconnect from the signal. This simply searches through all listeners and looks to see if the provided target is already listening and removes it if found.

##### Signals.gml::Signal::disconnect
```gml
disconnect = function (target) {
	for (var i = 0; i < array_length(listeners); i++) {
		var listener = listeners[i];
			
		if (listener.exists() && listener.getTarget() == target) {
			array_delete(listeners, i, 1);
			break;
		}
	}
}
```

 And that's all there is to the `Signal` class. This is an incredibly simple method to decouple two objects but it's also a very expressive and intuitive way to kick off events that happen.

 Here are some other ideas for how you might use signals:

 #### UI Components

 If you have a button and want to perform an action when it is clicked simply add a signal called clicked. In the logic for determining if the button has been clicked emit the signal. This will help keep your UI Elements generic and leave the actions that occur when pressed to other objects.

 ```gml
 clicked = new Signal();

 handleEvent = function (event) {
	if (event.getType() == UI_EVENT_MOUSE_CLICKED && containsPoint(event.getX(), event.getY())) {
		clicked.emit();
	}
 }
 ```

 #### Animation ended

You might need to know when an animation has ended. Instead of checking the object directly or having the object call a dependency, why not add a signal.

 ```gml
 animationEnded = new Signal();

 stepAnimation = function () {
	position++;

	if (position > length) {
		animationEnded.emit();
	}
 }
 ```

 #### Collisions

If you have a collision area that needs to track when an object enters and exits add signals! This can be used to create a generic trigger area (this is coming on the roadmap as a new asset type but you can do it now!)

 ```gml
objectEntered = new Signal();
objectExited = new Signal();

checkCollisions = function () {
	var collisionList = ds_list_create();
	var collisions = collision_circle_list(x, y, 15, pEntity, false, true, collisionList, true);

	var newObjects = findNewObjects(collisionList);
	for (var i = 0; i < array_length(newObjects); i++) {
		entityEntered.emit(newObjects[i]);
	}

	var leavingObjects = findLeavingObjects(collisionList);
	for (var i = 0; i < array_length(leavingObjects); i++) {
		entityExited.emit(leavingObjects[i]);
	}

	ds_list_destroy(list);
}
 ```

 #### State transitions

If you have a state machine you can emit signals upon entering or leaving a state.

 ```gml
 stateEntered = new Signal();
 stateExited = new Signal();

exitState = function () {
	onExit();
	stateExited.emit(currentStateName);
 }

 enterState = function () {
	onEnter();
	stateEntered.emit(currentStateName);
 }
 ```

 ### Test example

 Recall the test example from the previous chapter. After adding signals the player object is decoupled from the game controller. We no longer need to inject a mock game controller object. We can delete the room creation code and the test will not crash when the player picks up a coin. The signal will be emitted but there are no listeners so nothing happens. No other changes are required.
 
 This is the power of decoupling your objects. It allows you to reuse them in different contexts or make changes to the object without affecting other parts of the code base.

### Footnotes

[^1]: Observant readers will notice that we have accessed the signal directly, going against our own self imposed rules! 😱 In this instance we are going to take the other piece of important advice and choose to ignore it this time. A new self imposed rule that signals should be accessed directly, this will make it feel like they are a first class language feature.

[^2]: It is also valid to connect an object's own signals to itself or make use of signals of an object passed in by dependency injection.

## [← Previous](/chapter-03-dependency-injection/chapter-03-dependency-injection.md) | [Next →](/chapter-05-data-binding/chapter-05-data-binding.md)
