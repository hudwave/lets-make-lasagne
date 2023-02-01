# Lets make lasagne

# How to throw away the spaghetti code


## Appendix

### A. Closures

GameMaker does not natively support closures. This is a concept from functional programming, but in brief it means that a function can make use any local variables that were previously defined in the same scope as the function itself was. Below is an example in Javascript.

```javascript
var a = "Hello";

var combine = function (b) {
    return a + b;
};

var c = combine(" World!");
// c: "Hello World!"
```

The function `combine` here is capturing the value of `a` from the local scope so that it can be used inside the function itself. This doesn't happen in GameMaker and instead of `c` being equal to "Hello World!" we will instead get a crash saying that `a` is not defined.

So how can we solve this?

#### Emulating a closure

It's possible to emulate a closure in GameMaker but it requires some tricky context switching logic and a good understanding of how method variables and scopes work.

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

We also need to build up an array of arguments to pass to the original function. This can be done by using the built in variables `argument_count` and `argument`. We can then use `method_call` which will call a method variable and pass in an array of arguments, this behaves similarly to `script_execute` for script functions.

### B. Init pattern

Sometimes the initialisation of an object or struct can be quite lengthy or complicated. Since we have been treating the create event and constructor function as if they are an class definition file, the initialisation steps can pollute the clean look of a file and make it less readable.

When defining variables, if I can't finish the declaration in one line I like to use an init method.

```gml
function ConstructorWithPrivateInit(inputData) constructor {
    // Variable definitions
    simpleVar = 5;
    complicatedVar = undefined;

    // Init method
    _init = function (inputData) {
        var processingResult = 0;
        for (var i = 0; i < array_length(inputData); i++) {
            // Do some processing
            processingResult += _processData(inputData[i]);
        }

        complicatedVar = processingResult;
    }

    // Method definitions
    _processData = function() {
        // Process data
    }

    // Call init method
    _init(inputData);
}
```

In the example above we only have three sections to the class definition.
- Variable definitions
- Init method
- Method definitions

The init method is called as the last thing before the constructor function completes. This means that everything in the constructor is already defined before you initialise the `complicatedVar`, if you have any methods or other instance variables that it depends on then you no longer need to worry about the order they are declared in.

This is an example of a private init method that is called by the constructor itself. But you can also use the pattern to define a public init method which is called by the creating object instead.

```gml
function ConstructorWithPublicInit() constructor {
    // Variable definitions
    simpleVar = 5;
    complicatedVar = undefined;

    // Init method
    init = function (inputData) {
        var processingResult = 0;
        for (var i = 0; i < array_length(inputData); i++) {
            // Do some processing
            processingResult += _processData(inputData[i]);
        }

        complicatedVar = processingResult;

        return self;
    }

    // Method definitions
    _processData = function() {
        // Process data
    }
}

var instance = new ConstructorWithPublicInit().init(inputData);
```

This could be useful if you need to defer the initialisation until later but it can also provide an alternative to passing a struct into the  `instance_create_*` methods. This is a way of passing variables dynamically into an object but it is not possible to predefine what these variables are (unless you also put them all in the variable definitions part of the inspector, which is not useful if you don't intend them to be modified in the room editor). By using the public init method you can pre define all the variables as `undefined` in the create event and then pass in the final values after the object has been created.

The public init method returns `self` so that it can be chained onto the end of the constructor function. See the fluent API section in [Appendix D](/appendix-gamemaker-patterns/appendix-gamemaker-patterns.md#f-fluent-style-api) below for more details.

Note that this is not especially useful for constructors as you can just pass these in directly into the constructor function itself.

### C. Static classes

The behaviour of static variables has changed in version `2023.1`. For constructor functions you can now access static variables using the dot notation after the constructor name.

##### StaticTest.gml
```gml
function StaticTest() constructor {
    static test = function () {
        // ...
    }
}
// Initialise the statics by calling the constructor function without the new keyword
StaticTest();

// Or create an instance to initialise the statics
var instance = new StaticTest();

// Old style access
instance.test();

// New style access
StaticTest.test();
```

The only catch is that the statics need to be initialised before they are used. This can be done in two ways:

1. Call the constructor function without the `new` keyword. Be aware that if there are any non-static variables declared in the constructor these will be added to the global scope!

2. If you do have non-static variables then it is better to create an instance using the `new` keyword. Then the instance that is created can be thrown away and the statics are still accessible.

Previously you would have needed an instance to access the static variables, but now they are essentially globally accessible through the constructor function itself.

This opens up some interesting possibilities.

1. A namespace for groups of related functions
2. Static 'singleton' classes
3. Custom enum classes

If you are using an older version of GameMaker you can still make of use these patterns, it's just the syntax won't look as nice. Do this by storing the initialising instance as a global variable and accessing the methods via `global` like so.

```gml
global.StaticTest = new StaticTest();
global.StaticTest.test();
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
Array();
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
StaticCounter();
```

In this regard it will behave similarly to a singleton class in that there will only ever be one instance in the game. This means instead of using `global` to store data or references to global objects, we can use the static class instead. Just remember to preface anything that needs to be accessible by the static class with `static`.

As with any global object, think carefully about whether it needs to be global or not. Anywhere the global object is used you are adding in an explicit dependency.

#### Custom enum classes

Enums are a great way to make code more readable and help to enforce pre-defined values. However I find that there are two main limitations of enums in GameMaker.

1. The value assigned to each constant has to be an integer.

Having an assignable value to the enum is a useful feature. You might use an enum value to lookup something in a specific index of an array. Or perhaps you use the enum value for something when saving your game's data. But integers can only go so far, sometimes you might want to use a string value instead. This would make your save data more human readable when you're debugging. You could use it as label text or maybe it could be the name of a function you want to execute.

We can do this now by using a static class

```gml
function Dir() constructor {
    static CENTER = "center";
    static UP = "up";
    static DOWN = "down";
    static LEFT = "left";
    static RIGHT = "right";
}
var dir = new Dir();

var testDirection = "up";
if (testDirection == Dir.UP) {
    show_debug_message("Going {0}!", Dir.UP);	// Prints: 'Going up!'
}
```

While the creation of the static enum is different, the syntax for accessing the enum looks identical to if you had defined a regular enum like so

```gml
enum Dir {
    CENTER,
    UP,
    DOWN,
    LEFT,
    RIGHT,
}

var testDirection = 1;
if (testDirection == Dir.UP) {
    show_debug_message("Going {0}!", Dir.UP);	// Prints: 'Going 1!'
}
```

2. It is not possible to natively loop over the value of each enum constant.

Sometimes you might want to loop over each constant in turn and do something with the value. There are workarounds for this if you have not specified specific values for the enums such as setting the last enum value to `length` or `size`. This will then naturally represent the number of actual constants so you can loop over numbers up to this value. However you cannot do this if you have set custom values.

With the static enum class we can add methods and variables to help us with this. As an example lets create a `StringEnum` class to handle the base functionality, any enums we create will inherit from this.

```gml
function StringEnum() constructor {
    static values = undefined;

    static getValues = function () {
        if (values == undefined) {
            values = [];
            
            var keys = variable_struct_get_names(self);
            for (var i = 0; i < array_length(keys); i++) {
                var key = keys[i];
                var value = self[$ key];
                if (is_string(value)) {
                    array_push(values, value);
                }
            }
        }
        
        return values;
    }
}
var stringEnum = new StringEnum();
```

`StringEnum` has a method `getValues`, this will return an array of the enum's constant values. Notice however that this is populated for the first time when the method is called using lazy instantiation. This is because the `StringEnum` constructor function will be run before the constructor of any inheriting class. This means there is no way of getting the struct values of the child at this point.

When `getValues` is called on the child constructor function, the `self` scope will point to the child constructor's own static struct instead of `StringEnum`. This is used to get a list of the variable names, find any that are strings and add them to the `values` array. In this simple implementation above, be aware that any string values will be added to the array.

Now we can take the exact same `Dir` enum that we created above, inherit from `StringEnum` and then we get the functionality get a list of the enum constants!

```gml
function Dir() : StringEnum() constructor {
    static CENTER = "center";
    static UP = "up";
    static DOWN = "down";
    static LEFT = "left";
    static RIGHT = "right";
}
var dir = new Dir();

array_foreach(Dir.getValues(), function (dir) {
    if (dir == Dir.DOWN) {
        show_debug_message(dir);	// Prints 'down'
    }
});
```

You don't need to stop there though, you can add methods that apply specifically to your newly created enum. Here's an example of a function that gets the opposite value of the enum constant.

```gml
// Example of how to define a StringEnum
function Dir() : StringEnum() constructor {
    static CENTER = "center";
    static UP = "up";
    static DOWN = "down";
    static LEFT = "left";
    static RIGHT = "right";
    
    static flipDirection = function (dir) {
        switch (dir) {
            case Dir.UP:
                return Dir.DOWN;
            case Dir.DOWN:
                return Dir.UP;
            case Dir.LEFT:
                return Dir.RIGHT;
            case Dir.RIGHT:
                return Dir.LEFT;
            default:
                return Dir.CENTER;
        }
    }
}
var dir = new Dir();

array_foreach(Dir.getValues(), function (dir) {
    if (dir == Dir.DOWN) {
        show_debug_message(Dir.flipDirection(dir));		// Prints 'up'
    }
});
```

As a small convenience you can define a macro to make defining new enums simpler.

```gml
#macro ENUM () : StringEnum() constructor
```

```gml
function Dir ENUM {
    static CENTER = "center";
    static UP = "up";
    static DOWN = "down";
    static LEFT = "left";
    static RIGHT = "right";
}
```

### D. Method metadata (Annotations)

In GameMaker methods are also structs! You can do this:

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

### E. Fluent style API

If you have an object that has a lot of configurable properties then you might create it and then configure it by writing multiple statements one after the other like so.

```gml
var titleAnimation = new Tween(titleElement);
titleAnimation.repeat = false;
titleAnimation.persistent = false;
titleAnimation.duration = 90;
titleAnimation.addProperty("xScale", TWEEN_CURVE_POP);
titleAnimation.addProperty("yScale", TWEEN_CURVE_POP);
titleAnimation.after(function () {
    titleElement.destroy();
});

titleAnimation.play();
```

It's possible to streamline this by using a Fluent style API. This will allow you to configure an object by chaining methods together in a single statement. It might look something like this.

```gml
var titleAnimation = new Tween(titleElement)
    .setRepeat(false)
    .setPersistent(false)
    .setDuration(90)
    .addProperty("xScale", TWEEN_CURVE_POP)
    .addProperty("yScale", TWEEN_CURVE_POP)
    .after(function () {
        titleElement.destroy();
    });

titleAnimation.play();
```

Usually these variables will have a default value already set so that you don't need to explicitly set up each variable. Only if you want to change the default behaviour.

The way to achieve the chaining functionality is to return `self` from the setter methods and any other method that is required to configure the object.

```gml
function Tween() constructor {
    repeat = false;

    setRepeat = function (newRepeat) {
        repeat = newRepeat;
        return self;
    }

    // ...
}
```

The chain is processed from left to right, or top to bottom depending on how you're looking at it. The constructor function returns an instance and then we use the dot notation to access a method on it. That method returns itself, so we have the same instance we originally made and we can go again and select another method.

This is mostly a stylistic choice but it does communicate to the reader which variables are allowed to change for setting up an object.
