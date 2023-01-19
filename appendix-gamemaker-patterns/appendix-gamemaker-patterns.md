# Lets make lasagne

# How to throw away the spaghetti code


## Appendix - Gamemaker patterns and useful functions

### A. Closures

Gamemaker does not natively support closures. This is a concept from functional programming, but in brief it means that a function can make use any local variables that were previously defined in the same scope as the function itself was. Below is an example in Javascript.

```javascript
var a = "Hello";

var combine = function (b) {
	return a + b;
};

var c = combine(" World!");
// c: "Hello World!"
```

The function `combine` here is capturing the value of `a` from the local scope so that it can be used inside the function itself. This doesn't happen in Gamemaker and instead of `c` being equal to "Hello World!" we will instead get a crash saying that `a` is not defined.

So how can we solve this?

#### Emulating a closure

It's possible to emulate a closure in Gamemaker but it requires some tricky context switching logic and a good understanding of how method variables and scopes work.

The example below shows how we will create a closure function. The closure is able to access both instance scoped variables (directly or using `self`), and any captured variables via `other`.

```gml

instanceCount = 5;              // Instance variable
var localCount = 10;            // Local variable

// Capture variables from scope
var scopeVars = {
    captured: localCount
};

// Define closure function
var closureFn = function () {
    show_debug_message("Instance count {0}", instanceCount);
    show_debug_message("Local count {0}", other.captured);
}

// Generate closure function
closureFn = closure(scopeVars, closureFn);

closureFn();
// Prints 'Instance count 5'
// Prints 'Local count 10'
```

First we need to create a struct that will contain all the variables we want to capture from the current scope. This can be an anonymous struct passed directly into the function or one that already exists.

Next we define the closure function remembering that any captured variable will be accessed using `other`. If you were to call the function now it would not work.

Finally we call the function `closure` (which we will define below) to do the magic and capture the local variables. This will return a new function so be careful to actually use the returned value.

##### DataBinding.gml::closure
```gml
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
```

This is quite a complicated process so lets look at it step by step. Firstly, the `self` context is removed from the original function by binding it to `undefined`. This means when it is run, it will use the `self` of whatever the caller uses.

Two variables are added to the `scopeVars` struct. One is a reference to the `self` context that we want the final closure function to use. The second is a reference to the original function that we pass in.

What we do next is create a function `closureFunc` that will wrap around our original function. At this point if you called the function it wouldn't work, what needs to happen is that `closureFunc` is bound to the struct of scope variables. This means that everything in `scopeVars` is accessible by directly referencing the name or using `self`. 

The part that makes this work though is calling the `with` statement on the original `self` context (stored as `__this` in `scopeVars`). The `with` statement allows us to access the struct of `scopeVars` on `other` and everything on `self` directly.

We also need to build up an array of arguments to pass to the original function. This can be done by using the built in variables `argument_count` and `argument`. There is a new method in the latest beta version `method_call` which can call a method variable and pass in an array of arguments. This should be released in `2023.1`.

### B. Static classes

The behaviour of static variables has changed in version `2023.1`. For constructor functions you can now access static variables using the dot notation after the constructor name.

##### StaticTest.gml
```gml
function StaticTest() constructor {
	static test = function () {
		// ...
	}
}

// Create an instance to initialise the statics
var instance = new StaticTest();

// Old style access
instance.test();

// New style access
StaticTest.test();
```

The only catch is that the constructor needs to be called at least once to initialise the statics. Then the instance that is created can be thrown away and the statics are still accessible.

Previously you would have needed to access the static variables through an instance but now they are essentially globally accessible through the constructor function itself.

This opens up some interesting possibilities.

1. A namespace for groups of related functions
2. Static 'singleton' classes

If you are using an older version of Gamemaker you can still make of use these patterns, it's just the syntax won't look as nice. Do this by storing the initialising instance as a global variable and accessing the methods via `global` like so.

```gml
global.staticTest = new StaticTest();
global.staticTest.test();
```

#### Namespace

If you had a group of functions that operated on a arrays you would likely put them all in the same script file. To keep things organised they would have the same prefix e.g. `array_`. This is how most of the built in functions in GML are structured.

```Arrays.gml
function array_shuffle(array) {
	// ...
}

function array_sort(array) {
	// ...
}
```

This can now be replaced by a utility class where each method is defined as static

```Arrays.gml
function Array() constructor {
	static shuffle = function (array) {
		// ...
	}

	static sort = function (array) {
		// ...
	}
}
var instance = new Array();
```

This can be accessed as `Array.shuffle()` or `Array.sort()`. There is no particular advantage of doing things this way but some people may prefer the syntax. Feather doesn't currently auto complete all of the static variables but hopefully this will change in future versions.

#### Static 'singleton' classes

In addition to just methods we can also add state to these classes.

##### StaticTest.gml
```gml
function StaticCounter() constructor {
	static count = 0;

	static add = function () {
		count++;
	}
}
var instance = new StaticCounter();
```

In this regard it will behave similarly to a singleton class in that there will only ever be one instance in the game. This means instead of using `global` to store data or references to global objects, we can use the static class instead. Just remember to preface anything that needs to be accessible by the static class with `static`.

As with any global object, think carefully about whether it needs to be global or not. Anywhere the global object is used you are adding in an explicit dependency. 

### C. Method metadata (Annotations)

In Gamemaker methods are also structs! You can do this:

```gml
// Define a method
var func = function () {

}

// Add a variable
func.a = "What?!";

// Access variable
show_debug_message(func.a);		// Prints 'What?!'
```

This means we can add variables or even other methods to a method. Why on earth would you want to do this? Well, it can be useful to add metadata to methods that can be read at runtime to affect how the method is used. There are equivalent features in other languages such as Java that let you annotate a method with data.

That's quite an abstract thought but the most common use cases would be if you are writing a framework (e.g. unit test, serialisation) and need to configure how the framework will handle a method. 

For example if you are creating a unit test framework you can mark which methods should be run as a test.

```ArrayTest.gml
function ArrayTest() constructor {
	arrayShuffleTest = function () {

	}
	arrayShuffleTest.test = true;
}
```

Now we could build a `TestRunner` class that has a method `runTests` that takes an instance of a test suite e.g. `ArrayTest` above.

```TestRunner.gml
function TestRunner() constructor {
	runTests = function (testSuite) {
		var keys = variable_struct_get_names(testSuite);
		for (var i = 0; i < array_length(keys); i++) {
			var key = keys[i];
			var value = testSuite[$ key];
			
			if (typeof(value) == "method" &&
				variable_struct_exists(testSuite, "test") &&
				value.test) {
				
				// Run Test
				try {
					value();
				}
				catch (e) {
					// Mark test as failed
				}
			}
		}
	}
}
```

`runTests` will loop through all the variables on the test suite and check to see if there are any methods with the meta data `test = true`. If so it will execute the method to run the test.

This metadata can only be applied to method variables or global script functions. It cannot be applied to regular variables. However if you are following the advice in [Chapter 2](/chapter-02-self-imposed-restrictions/chapter-02-self-imposed-restrictions.md) you will have getter and setter methods for them. Say you are writing a serialisation framework, you can apply any serialisation metadata to the setter, and any deserialisation metadata to the getter. 

### D. Convenience methods

#### `set_value(target, property, value) -> undefined`
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

#### `get_value(target, property) -> undefined`

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

