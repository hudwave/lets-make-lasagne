# Lets make lasagne

# How to throw away the spaghetti code


## Chapter 6: Beyond inheritance

This chapter moves on from the theme of loose coupling in the previous chapters. Instead it will focus on alternatives to using inheritance and when and where to use them.

Both objects and constructor functions can make use of inheritance in GameMaker[^1] and there are several excellent uses:

#### Code re-use
Sharing common code and behaviours from a parent object across multiple child objects. This prevents duplication of code e.g. adding a basic attack method to the parent enemy object `pEnemy` which will then be present in all child enemies.

##### pEnemy::Create
```gml
attack = function () {
    // Do damage
}
```

#### Overriding
Overriding parent behaviour in the child object to produce different effects e.g. making the base attack stronger in a powerful child enemy.

##### oStrongEnemy::Create
```gml
event_inherited();

// By redefining attack it will override the
// method defined in the parent object.
attack = function () {
    // Do double damage
}
```

Notice that we have still inherited the original create event using `event_inherited` which will run the parent's create event first. You might think that this would only allow us to extend the parent's behaviour. In GameMaker you have the option to override the event which does not run the parent's create event.

However since we are encapsulating our functionality in methods rather than whole events we choose to inherit them. The overriding here occurs when we re-define the `attack` method. This gives us much more control over what is overridden while still being able to inherit other methods and variables.

#### Extending
Extending the capabilities of a parent object by adding new code and behaviours e.g. adding a secondary attack to a child enemy that is not present in any other enemies.

##### oSpecialEnemy::Create
```gml
event_inherited();

specialAttack = function () {
    // Do special damage
}
```

#### Polymorphic behaviour
Ability to use different child object types in places where a parent object type is specified (this is called polymorphism) e.g. using the parent object `pEnemy` in collision functions will also check for all child enemy objects because a child enemy is a  `pEnemy`.

Note that for the most part you won't need to make use of polymorphism. This is because GameMaker is dynamically typed i.e. it does not enforce a specific type for method calls. You can pass in any object you like to a method and as long as it has the the correct properties the method will not crash. This is called duck typing.

These are all pretty useful features of inheritance and for the most part you will not encounter any problems using them in GameMaker.

Inheritance does have its limitations though so it's important to know what these are and what to do when you brush up against them.

### The problem

Inheritance has a bad reputation in the object orientated world. However since GameMaker is not fully object orientated and is not strongly typed, a lot of the reasons for avoiding inheritance are not strictly applicable. We can also manoeuvre around inheritance in other ways that do not depend on coding to an interface as you would in an object orientated language.

One problem that you may encounter however is when inheritance cannot adequately describe your hierarchy of objects. This usually happens when there is some logic or feature that is only applicable to some of the child objects even though they share other common behaviour.

You either end up with some of your child objects inheriting code that they do not ever intend to use; or you have to duplicate the specific code across the other child objects that need it.

To demonstrate this lets use the classic vehicle analogy. We want to model a bunch of different cars using inheritance. Cars will have a different sprite, top speed, engine size and fuel capacity. Specific models of car can inherit from a parent `pCar` object.

```
         pCar
           |
    ----------------
    |               |
   oHatchback     oSuv
```

This works fine as long as you only require cars. What if you wanted to add a bicycle? It's a mode of transport like a car but it doesn't have an engine.

One way to get around this is to split the functionality into two separate objects that inherit from the same base parent. Then have your child objects inherit from the 'sub-parents'. Both the car and bicycle can inherit from a `pVehicle` parent. The engine specific logic can remain in `pCar` and be excluded from `pBicycle`.

```
                        pVehicle
                            |
           ----------------------------------
           |                                |
         pCar                           pBicycle
           |                                |
    -----------------               -----------------
    |               |               |               |
oHatchback         oSuv       oMountainBike      oRoadBike
```

If this works for your use case then great! But what happens if there is a third set of functionality that is applicable to only a sub set of each of these two groups? What if we wanted to include a boat? A boat cannot move on the land and is neither a car nor a bicycle so it would need it's own parent `pBoat`. However boats can have an engine like a car or be powered manually like a bicycle.

So how do we split this hierarchy? Add new categories? (`pMotorisedLand`, `pManualLand`, `pMotorisedWater`, `pManualSea`). Now add a plane and a glider...

At some point either the names of your objects will become quite abstract and specific or you have to have a simpler hierarchy with redundant or duplicated logic. Neither option is good so how is this solved?


### Composition over inheritance

Composition over inheritance is a technique favoured in object orientated programming where a class will be 'composed' of other objects to perform its duties or hold data.

In inheritance typically a child object will have an `is-a` relationship with the parent object e.g. a car (child) `is-a` vehicle (parent). Objects are related by what they are and as we saw in the previous section this is not always the best idea.

Composition is more like a `has-a` or `uses-a` relationship e.g. a car `has-an` engine. Objects are composed of other objects based on what the object itself can do. 

##### Engine.gml
```gml
function Engine() constructor {
    engineSize = 1.5;

    setEngineSize = function (newEngineSize) {
        engineSize = newEngineSize;
    }

    getEngineSize = function () {
        return engineSize;
    }
}
```

##### pCar::Create
```gml
event_inherited();

engine = new Engine();
```

When using composition think carefully about dependencies. It may be necessary to compose objects by using dependency injection techniques as outlined in [chapter 3]((/chapter-03-dependency-injection/chapter-03-dependency-injection.md)). You should judge this on a case by case basis and apply the dependency injection if the dependency is going to cause problems down the line.

Now lets look at which of the points in the first section composition covers.

#### Code re-use

If you have logic encapsulated in another object then it is trivial to make instances of the object and re-use them in multiple different objects. For example if we had an engine object this can be injected into both a `pCar` and a `pBoat`.

#### Overriding and polymorphic behaviour

These two have been combined into one as they both happen by the same mechanism. Any object forms part of the composition can be replaced with another object that satisfies the duck typing requirement. This means that an existing object (behaviour) on the parent can be changed (overridden).

This is one advantage that composition has over inheritance which is static. Using composition you can swap out the object to change the behaviour at runtime.

#### Extension

Extension is the only point which is not addressed by composition. We'll look at an alternative method in the next section which can address this. But overall composition is a useful technique that you should be aware of.

### Direct object manipulation

Instead of using composition, in GameMaker we have an option of directly manipulating an object or struct that is not possible in many strongly typed, object orientated languages. The features in question are:

1. New properties (variables) can be added to an object or struct at runtime. 
2. Functions are first class allowing them to be assigned to variables.

This means we can override methods on an object by simply assigning a new method to the variable that stored the original method.

#### DirectManipulationTest.gml
```gml
function OverrideExample() constructor {
    methodToOverride = function () {
        show_debug_message("original");
    }
}

// Create instance and test original method
var test = new OverrideExample();
test.methodToOverride();    // Prints 'original'

// Create new method to override original behaviour
var overridingMethod = method(test, function () {
    show_debug_message("overridden");
});

// Override method
test.methodToOverride = overridingMethod;
test.methodToOverride();    // Prints 'overridden'
```
Note that the method needs to be bound to the object so that the `self` context refers to the object and not the creating scope. We can also extend an object by adding new methods or variables to the object.

#### DirectManipulationTest.gml
```gml
function ExtensionExample() constructor {
    baseMethod = function () {
        show_debug_message("original");
    }
}

// Create instance
var test = new ExtensionExample();

// Create new method to extend original behaviour and
// bind it to the context of the instance
var extendingMethod = method(test, function () {
    show_debug_message("new behaviour");
});

// Extend class and test both methods
test.extendedMethod = extendingMethod;
test.baseMethod();          // Prints 'original'
test.extendedMethod();      // Prints 'new behaviour'
```

This is very powerful but if this not used in a clear and explicit manner then it can lead to code which is confusing and hard to debug. By this I mean we don't want to be adding or overriding properties from any old object. This is similar to the reasoning we use in the second chapter which argues against direct property access, the `with` statement and adding new properties.

So what is a good way to exploit these features? 

### Mixins

We need to formalise which properties will be extended or overridden so they can be applied in a repeatable way and referred to when reading or debugging the code.

Enter mixins, a way of re-using code between classes. You can think of a mixin as a sort of small self contained class that contains methods and variables. When a mixin is applied to an object all of its properties are copied over to the object, the properties have been 'mixed-in' or included rather than inherited.

In GameMaker we will use a constructor function to define a mixin. There doesn't need to be anything special about the constructor to be a mixin, just be aware that we are not copying over any static variables.

We are going to create a function `Mixin.apply` which will apply a mixin to an object or struct. It does this by creating an instance of the mixin using the constructor function. It will then copy over all of the properties to the target object thus applying the mixin.

##### MixinTest.gml
```gml
// A test struct class
function OriginalClass() constructor {
    valueToOverride = 1;
    
    valueOverrideExample = function () {
         show_debug_message(value);
    }

    methodToOverride = function () {
        show_debug_message("original");
    }
}

// A mixin
function MixinTest() constructor {
    valueToOverride = 7;

    methodToOverride = function () {
        show_debug_message("overridden");
    }

    extendingMethod = function () {
        show_debug_message("new behaviour");
    }
}
```

##### oMixinTest::Create
```gml
var original = new OriginalClass();
original.valueOverrideExample();        // Prints '1'
original.methodToOverride();            // Prints 'original'

// Apply mixin
Mixin.apply(original, MixinTest);

original.valueOverrideExample();        // Prints '7'
original.methodToOverride();            // Prints 'overridden'
original.extendingMethod();             // Prints 'new behaviour'
```

Notice that we are using a static utility class called `Mixin` to hold all of the mixin related code. This type of class is described in more detail in [Appendix B](/appendix-gamemaker-patterns/appendix-gamemaker-patterns.md#b-static-classes).

##### Mixin.gml
```gml
function Mixin() constructor {
    static apply = function(target, mixinId) {
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
    }
}
// Instantiate statics
var mixin = new Mixin();
```

First an instance of the mixin is created using the constructor function. Then we copy across all the keys to the target. Note that this is only a shallow copy but this is all that is required as the mixin instance is discarded afterwards. Methods are rebound to the target object using `method`.

This is enough to get going with mixins. There are a few ways to make use of them.

1. Apply the mixin in the create event of an object or a constructor function.

    This can be useful for code re-use or inheritance like situations. Every single instance of the object or struct will have same pre-defined mixins. This is a way to beat the problems encountered with the complex inheritance hierarchy detailed in an earlier section. You can apply mixins freely to any object that needs it without polluting those that do not.

2. Apply the mixin from the creating instance.

    This can be useful for applying different behaviours at runtime. The creating instance can control which version of the mixin is applied to the object or struct. This allows us to achieve polymorphic behaviour.

3. Apply the mixin during the lifetime of the instance to mark it as a type.

    You could use a mixin to add permanent behaviour to an instance at some point during it's lifetime. Or just to mark it as a type. 

To get #3 working we'll need to have a mechanism of seeing what mixins have been applied to an instance. We will then be able to check if an object is of the right 'type' before we attempt to run a method that may or may not exist. Or we can treat an object differently depending on which mixins have been applied.

##### Mixin.gml
```gml
#macro APPLIED_MIXINS "__mixins"

function Mixin() constructor {
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
        }
    }
}
// Instantiate statics
var mixin = new Mixin();
```

We will store an array on the mixin target under the name `__mixins` if it does not already exist. This will contain the class names of all mixins applied to the instance. The mixin name can be found by calling `script_get_name` on the mixin's constructor function.

We can also add a mechanism to keep track all instances of a mixin that have been created. We can then use this to loop through all instances of the mixin as you might using the object's asset name.

##### Mixin.gml
```gml
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
}
// Instantiate statics
var mixin = new Mixin();
```

A new struct variable `registeredInstances` has been added to the static class to keep track of the mixins. The key will be the name of the mixin class and the value is an array of all instances that have had the mixin applied to it.

Now we just need to create a methods to retrieve/manage the `registeredInstances` and to check the types applied to specific instances.

##### Mixin.gml
```gml
#macro APPLIED_MIXINS "__mixins"

function Mixin() constructor {
    static registeredInstances = {};

    static apply = function(target, mixinId) {
        // ...
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
                array_push(cleaned, instance);
            }
        }
        
        // Update stored list of instances
        registeredInstances[$ mixinName] = cleaned;
        
        return cleaned;
    }
}
// Instantiate statics
var mixin = new Mixin();
```

`Mixin.get` can be used to get a list of all active instances that have had the mixin applied. This could then be looped over to check for collisions.

`Mixin.is` can be used to check whether an object or struct is of a specific mixin type. This can be used as a safety check before calling a specific method on the target or to run some specific logic if the object is the correct type e.g. destroy an object if it is of mixin type `Broken`. Note that this is making use of the `get_value` and `object_exists` functions defined in [Appendix D](/appendix-gamemaker-patterns/appendix-gamemaker-patterns.md).

One last word on this implementation of mixins. Since the static class sticks around the entire length of the game it is necessary to to manually remove any instances that no longer exist. For brevity in this tutorial I have chosen to check for this each time `Mixin.get` is called.

Depending on your circumstances you may need to do this more of less frequently; and the best time to do it may not be on retrieval each time. It might be enough to add a `cleanUp` method that runs through all the keys of `registeredInstances` and call this whenever the room changes.

##### Mixin.gml
```gml
#macro APPLIED_MIXINS "__mixins"
function Mixin() constructor {
    static registeredInstances = {};

    static apply = function(target, mixinId) {
        // ...
    }

    static is = function (target, mixinId) {
        // ...
    }

    static getAll = function (mixinId) {
        // ...
    }

    static cleanUp = function () {
        var mixinNames = variable_struct_get_names(registeredInstances);
        for (var i = 0; i < array_length(mixinNames); i++) {
            var mixinName = mixinNames[i];
            var instances = registeredInstances[$ mixinName];
            
            var cleaned = [];
            for (var j = 0; j < array_length(instances); j++) {
                var instance = instances[j];
                if (object_exists(instance)) {
                    array_push(cleaned, instance);
                }
            }
            
            registeredInstances[$ mixinName] = cleaned;
        }
    }
}
// Instantiate statics
var mixin = new Mixin();
```

### When to use inheritance

We still need inheritance in GameMaker. Firstly, it can be a good tool when your hierarchy of objects is straightforward, small and well defined. If later on you feel like you are encountering issues with inheritance you can refactor to use the methods outlined above.

Secondly, inheritance is the only way to run collision functions over a group of objects at the same time. Especially using the polymorphic capabilities of inheritance.

If you have an array of objects with unknown types (such as when using `Mixin.get`) then you need to loop over them and perform the check on each instance separately. This will be slower than using an object asset name but you may find it adequate for your requirements. Ideally though, you would be using collision functions with an object asset id.

This makes your choice of inheritance very important for optimising collisions. If for a particular collision check you only want to check enemies, then you would need all your different enemies to inherit from a parent `pEnemy`. As we've discussed previously inheritance might be too rigid a solution to capture the behaviours of all your enemies so you can look to include other options mentioned in this chapter to fulfil that role.

Finally don't be afraid to mix and match inheritance and the other techniques in this chapter at the same time. It doesn't need to be one or the other. Even mixins can inherit from other mixins using constructor inheritance! Let the problem you are working on guide you. If you encounter resistance using inheritance look for other options.

## [← Previous](/chapter-05-data-binding/chapter-05-data-binding.md)

## Footnotes

[^1]: Rooms can also use inheritance but this is not relevant for this chapter.
