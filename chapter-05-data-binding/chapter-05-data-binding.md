# Lets make lasagne

# A Lesson in loose coupling: How to throw away the spaghetti code


## Chapter 5: Data binding

This chapter is going to build on concepts introduced in the previous chapters to implement a rudimentary data binding system. Data binding will allow us to synchronise the value of a variable between two objects so that when a source value is changed the target value be updated automatically to match. This will be done in a way that means the two objects don't even need to know about the existence of each other! This would allow you to decouple two objects that may normally depend on each other to update a value.

As in the previous chapter lets first look at how this might work at a high level. The use case we will focus on is updating the text displayed in the UI without the having to read the value directly or set it manually.

The data binding itself is done by calling a single function `data_bind`.

##### DataBinding.gml
```gml
function data_bind(source, sourceProperty, target, targetProperty) {
	// ...
}
```

The first and second arguments of `data_bind` are the source object and source property name. The third and fourth arguments are the target object and target property name. The data bind system works by adding a signal and a custom setter to the source object and a regular setter to the target object. The target setter will be connected to the signal on the source object. So when the custom setter on the source is called the signal will be emitted and pass the updated value to the target setter.

In the scenario we want to bind the game controller's `coins` variable to the UI renderer's `coins` variable so that the UI is updated automatically whenever the number of coins changes.

##### oHud::Create
```gml
coins = 0
```

##### oGame::Create
```gml
coins = 0;

var player = instance_create_layer(x, y, layer, oPlayer);
player.coinCollected.connect(self, addCoin);

var uiHud = instance_create_layer(x, y, layer, oHud);
data_bind(self, "coins", uiHud, "coins");

getCoins = function () {
	return coins;
}

setCoins = function (newCoins) {
	coins = newCoins;
}

addCoin = function (coin) {
	setCoins(coins + coin.getValue());
}
```

Notice that `addCoin` in `oGame` no longer calls the coin setter on `oHud` (as it no longer exists at compile time), instead when addCoin is called it will call its own setter to change the value of `coins`. This is important because the setter will be overridden by `data_bind` with the binding logic that updates the value on `oHud`.

And that is all there is to the data binding system. Whenever `setCoins` is called (either internally by `oGame` or by an external object) the value of coins on `oHud` will be updated.

Like dependency injection and connection of signals, bindings should only be setup by objects higher up in the hierarchy. Usually the target will be a direct dependency of the source object. But in theory you could have the game controller set up a binding between the player object's health and a UI component that renders this on screen. The player would then update the UI directly without even knowing that the UI existed!

If you're not interested in how it's put together and just want to use it, take the code from the project folder and skip ahead to the usage and pitfalls section. Otherwise lets look at how it's implemented.

### Implementing the `data_bind` function

The `data_bind` function is going to do 3 things:

1. A custom setter will be created for both the source and target properties on their respective objects. If a setter already exists then it will be overridden.

2. The source object will have a `Signal` attached to it. The signals will be stored in a struct called `__bindings` with the name of the source property. A double underscore is used for `__bindings` so that it's hopefully obscured enough from most people's variable naming conventions and so it won't cause any problems.

3. The setter method on the target object will be connected to the signal on the source object. Therefore when the source setter is called, it will first set the value on itself and then emit the signal with the new value.

Create a new script and call it `DataBinding`. Add a new function and call it `data_bind`. Below this function we are going to create two convenience functions that let us set and get a value regardless of if the target is an object or struct. This is just so that the code in `data_bind` is a bit more succinct.

##### DataBinding.gml
```gml
function data_bind(source, sourceProperty, target, targetProperty) {

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
```
First we'll check to see if the source object or struct has been used for data binding before. It does this by checking the existence of the map of bindings stored in `__bindings`. If it doesn't exist then it will create it.

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	var bindings = get_value(source, DATA_BIND_SIGNALS);
	if (bindings == undefined) {
		bindings = {};
		set_value(source, DATA_BIND_SIGNALS, bindings);
	}
}
```
Next we need to check to see if the source property has been bound before. It's possible that the value could be bound to multiple targets. This is done by checking the existence of a signal for the source property. A signal is created if necessary and added to the bindings map.

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	...

	// Check if sourceProperty has been bound before and signal exists
	var hasBeenPreviouslyBound = true;
	
	var sourceSignal = bindings[$ sourceProperty];
	if (sourceSignal == undefined) {
		hasBeenPreviouslyBound = false;
		sourceSignal = new Signal();
		bindings[$ sourceProperty] = sourceSignal;
	}
}
```

### Generating the source setter function

We need to generate the source setter if it does not already exist. In order to add the setter we need to know its name, this tutorial assumes that you are using `lowerCamelCase` for instance variable and method names. For example an instance variable called `myVariable` would have a setter called `setMyVariable`. If you are using a different naming convention e.g. `my_variable` and `set_my_variable` then you will need to implement your own version of the helper function `generate_setter_name`.

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	...

	// Check if sourceProperty has been bound before and signal
	...

	// Generate source setter if required
	if (!hasBeenPreviouslyBound) {
		var sourceSetterName = generate_setter_name(sourceProperty);
		...
	}
}

// Helper function to generate setter names
function generate_setter_name(property) {
	var startLetter = string_upper(string_char_at(property, 1));
	var remaining = string_copy(property, 2, string_length(property));
	var setterName = string("set{0}{1}", startLetter, remaining);
	return setterName;
}
```

Lets look at what the custom setter could look like for a concrete example in the game controller if we were writing it manually. Remember that this will override the existing `setCoins` function that we have defined already.

```gml
setCoins = function (newValue) {
	coins = newValue
	var signal = __bindings[$ "coins"];
	signal.emit(newValue);
};
```

The first line is the same as any other setter we have made, but after that we obtain the signal for the coins variable and emit the new value. However, rather than a concrete example we need to generate it dynamically. We have all the variables we need ready to go in the `data_bind` function (`sourceProperty`, `sourceSetterName`, `sourceSignal`). Ideally we would do something like this in `data_bind`

##### DataBinding.gml::data_bind
```gml
var sourceSetterName = generate_setter_name(sourceProperty);

// Create a setter function
var sourceSetter = function (newValue) {
	self[$ sourceProperty] = newValue;
	sourceSignal.emit(newValue);
};

// Put setter on source struct
source[$ sourceSetterName] = sourceSetter;
```

At first glance this seems reasonable and straightforward, especially if you are used to a language such as Javascript, but there are a number of problems with the code due to the way GML works.

The first problem is that the method variable `sourceSetter` will be bound to the scope of whichever object called `data_bind`. This means that the reference to `self` (where we set the new value) will not be the source object. We would then attempt to set the value on the caller to `data_bind` which will most likely result in a crash. Luckily this is easy to fix as we can re-bind the method to the scope of the source object using `method`.

```gml
// Put setter on source struct
source[$ sourceSetterName] = method(source, sourceSetter);
```

The second problem is a little bit trickier to solve. The code above is written assuming that method variables in Gamemaker form a closure around the local variables in the current scope. This is a concept from functional programming but in brief it means that a function can make use any local variables that were previously defined in the same scope as the function itself was. Below is an example in Javascript.

```javascript
var a = "Hello";

var combine = function (b) {
	return a + b;
};

var c = combine(" World!");
// c: "Hello World!"
```

The function `combine` here is capturing the value of `a` from the local scope so that it can be used inside the function itself. This doesn't happen in Gamemaker and instead of `c` being equal to "Hello World!" we will instead get a crash saying that `a` is not defined.

So how can we solve this and get the values of the source property name and the signal into the setter function?

### Emulating a closure

It's possible to emulate a closure in Gamemaker but we need to make use of our old friend, self imposed coding restrictions.

First we need to create a struct that will contain all the variables we want to capture from the current scope.

```gml
// Capture variables from scope
var scopeVars = {
	signal: sourceSignal,
	property: sourceProperty,
};

// Create a setter function
var sourceSetter = function (newValue) {
	self[$ property] = newValue;
	signal.emit(newValue);
};

// Create closure and put setter on source struct
source[$ sourceSetterName] = method(scopeVars, sourceSetter);
```

We are going to bind the setter function to the `scopeVars` struct instead of the source object. This means that we can access the `signal` and `property` directly. But now `self` no longer refers to the source object so we would be setting the `newValue` on the `scopeVars` struct. Obviously we don't want to do this so here's where the self imposed restriction comes in.

In a closure, any place we want to refer to a variable on the 'original' `self` context will be accessed via `this` instead. To make things simpler lets define a function which will create a closure and add `this` to the scope variables.

##### DataBinding.gml::closure
```gml
function closure(scopeVars, func, context = undefined) {
	context ??= self;
	scopeVars[$ "this"] = context;
	return method(scopeVars, func);
}
```

If the context is undefined then it will default to the calling object. Lets look at how all this changes the `data_bind` code.

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	...

	// Check if sourceProperty has been bound before and signal exists
	...

	// Generate source setter if required
	if (!hasBeenPreviouslyBound) {
		var sourceSetterName = generate_setter_name(sourceProperty);
		
		// Capture variables from current scope
		var scopeVars = {
			property: sourceProperty,
			signal: sourceSignal
		};
		
		// Create a setter function for the source
		var sourceSetter = undefined;
		if (is_struct(source)) {
			sourceSetter = function (newValue) {
				this[$ property] = newValue
				signal.emit(newValue);
			};
		}
		else {
			sourceSetter = function (newValue) {
				variable_instance_set(this, property, newValue);
				signal.emit(newValue);
			};
		}
		
		// Create closure and set on the source object
		set_value(source, sourceSetterName, closure(scopeVars, sourceSetter, source));
	}
}

// Function to generate closures
function closure(scopeVars, func, context = undefined) {
	context ??= self;
	scopeVars[$ "this"] = context;
	return method(scopeVars, func);
}
```

Take a deep breath, that was a lot. We're only half way through and we need to add a setter to the target object. Luckily for you it's almost identical to the above. So actually, we're basically done!

### Generating the target setter function

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	...

	// Check if sourceProperty has been bound before and signal exists
	...

	// Generate source setter if required
	...

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
				this[$ property] = newValue;
			};
		}
		else {
			targetSetter = function (newValue) {
				variable_instance_set(this, property, newValue);
			};
		}
		
		// Create closure and set on the target object
		set_value(target, targetSetterName, closure(scopeVars, targetSetter, target));
	}
}
```

The only difference in the target setter is that it does not have a signal. Because of this we are making the assumption that if a variable already exists on the target with the setter's name that we don't need to create one. This also assumes the existing setter is doing it's job correctly so be careful!

### Final touches

All we need to do now is connect up the target setter function to the signal and then make sure the initial target value is synchronised to the initial value of the source.

##### DataBinding.gml::data_bind
```gml
#macro DATA_BIND_SIGNALS "__bindings"

function data_bind(source, sourceProperty, target, targetProperty) {
	// Register the source as a data bind source
	...

	// Check if sourceProperty has been bound before and signal exists
	...

	// Generate source setter if required
	...

	// Generate target setter if required
	...
	
	// Connect source signal to target setter
	sourceSignal.connect(target, targetSetter);
	
	// Update target to reflect the source's initial value
	set_value(target, targetProperty, get_value(source, sourceProperty));
}
```

And we're done! Take a well earned rest and admire what you've just built, it's pretty cool even if I do say so myself.

### Usage, pitfalls and ideas for improvements

#### Usage

Data binding should probably be used sparingly. The fact that two completely separate objects can unknowingly update each other could lead to confusing debug sessions trying to work out why an object is being updated. And this tutorial has been campaigning against spaghetti code! However UI does make a great use case for this.

#### Pitfalls

1. You may encounter a problem using this system if you already have a setter defined on your source or target object that does more than just set the value e.g. validation of new value. This will be overridden by `data_bind`! It wouldn't be too difficult to modify the `data_bind` method to add an already existing setter to the set of scope variables. Then have the new setter call the old setter first before emitting the signal.

2. You may find that library code doesn't play nicely with this system because they won't be using setters and getters to modify properties on your objects. This is just something to be aware of and you can probably work around it for most use cases.

3. Updating the value on the target does not change the source value and will be overwritten again when the source next changes. If the target absolutely needs to make changes to the binding value then it needs to communicate that change back to the source object rather than modify the value directly. The source can set the value and trigger the update on the target.

#### Improvements

This chapter is already long enough so I won't be implementing them here but here are some improvements you could make to this system without much trouble.

Add an `unbind(target, targetProperty, source)` function to remove the source object from the signal stored in `__bindings[$ targetProperty]`. This can be done with the signal's `disconnect` method.

Look into implementing the update pattern. If you know that this is a use case you need then you can add a signal called `update` to the target object. This can be connected to the setter on the source object. When the value needs to change, emit the update signal with the new value. This will then call the setter on the target with the new value.

#### The End

Thanks for reading if you made it this far. I might write more chapters if people have found this useful. If you have any comments or suggestions you can leave them in the GMC forums in this thread [here](https://forum.gamemaker.io/index.php?threads/lets-make-lasagne-a-clean-code-tutorial-series.100427/).

## [← Previous](/chapter-05-data-binding/chapter-05-data-binding.md)
