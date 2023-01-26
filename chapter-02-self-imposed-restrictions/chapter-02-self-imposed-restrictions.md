# Lets make lasagne

# How to throw away the spaghetti code


## Chapter 2: Self imposed coding restrictions and good practices


Before we talk about ways to minimise coupling it's important look at some other aspects of GameMaker that could contribute to code problems. Until recently, GameMaker's programming language (GML) behaved in a mostly imperative fashion but had a lot of limitations e.g. each script file is a single function. The language is designed around this paradigm (scripts execute in the calling object's scope, `other` keyword, `with` statement). Due to the limitations, I'm genuinely impressed that people managed to create such amazing and complicated games before! I dread to think how difficult it would have been to read, refactor, maintain and debug such a large codebase.

Luckily, we now have first class functions and lightweight objects (structs) which open up a whole world of possibilities and much cleaner code. GML has become a sort of hybrid imperative, functional and part object orientated language (it's still missing some defining features of each paradigm though). All these options in GML gives us the freedom to write code in many ways, but this also gives us the freedom to do stupid things. Therefore we need to be disciplined and impose some restrictions on ourselves so that we don't end up writing bad code.

Below are some rules that I adhere to when writing GML. This is just my own opinion and it works for me. There is no right or wrong way to make a game in GameMaker so go with what works for you. However, you might find that by sticking to these rules, you'll end up naturally writing cleaner code.

### Direct property access

GameMaker allows us to directly access the properties (instance variables and methods) of an object from a second object and make changes to them. If you're careful and working solo this might be ok; but if you are working in a team then it is important to know which variables you can change on some object without causing something obscure to fail.

A private variable is a variable that you do not want to be modified by an external object. Often they are crucial to the inner workings of an object and if an outside object changes it incorrectly the object can stop working.

There is no language concept of private variables in GML to prevent access to them. So we need to impose this restriction on ourselves.

Some people like to prefix their private variables with an underscore to differentiate them like `_privateVariable`. I generally do not use an underscore for private variables, only for private methods. Instead for variables I will create getter and setter methods.

##### getter method 
```gml
getCoins = function () {
	return coins;
}
```

##### setter method
```gml
setCoins = function (newCoins) {
	coins = newCoins;
}
```

This has a number of advantages over direct access:
1. If a getter does not exist then you cannot read the variable. If a setter does not exist then you cannot change the value of the variable. This communicates clearly the level of access allowed to anyone reading the code.
2. You can add additional code to the setter to do validation of the new value to ensure it will not break the object.
    ```gml
	maxHealth = 50;
	health = maxHealth;

	setHealth = function (newHealth) {
		if (newHealth > maxHealth) {
			newHealth = maxHealth;
		}
		health = newHealth;
	}
	```
3. You can create a 'computed' getter that performs some calculation each time it is accessed. This is useful if you have a value that changes often and needs to be up to date when accessed. 
    ```gml
	queue = [6, 3, 1, 5];

	getLast = function () {
		return queue[array_length(queue) - 1];
	}
	```
4. You can perform perform some additional side effect upon getting or setting the value e.g. logging something or checking to see if some threshold has been passed.
    ```gml
		potionCount = 4;
		potion = new Potion();

		getPotion() {
			if (potionCount > 0) {
				potionCount--;
				return potion;
			}
		}
	```
5. The getter value does not need to be calculated until it is actually needed. You can check to see if the value is `undefined` when the getter is called and calculate it if required. This is called lazy instantiation. This might be useful if the calculation of a value is particularly costly but might never be needed.
    ```gml
	largeBuffer = undefined;

	getLargeBuffer() {
		if (largeBuffer == undefined) {
			largeBuffer = buildLargeBuffer();
		}

		return largeBuffer;
	}
	```
6. Getters and setters can be used as callback functions. This has so many potential uses. You can update or retrieve a value using the callback. 
7. It is now trivial to debug when a value is set or read. Simply set a break point in the setter or getter.
8. You can use fluent style setters to configure objects. See [Appendix E](/appendix-gamemaker-patterns/appendix-gamemaker-patterns.md#e-fluent-style-api) for more details.
9. Autocomplete can be used to get a nice filtered list of all properties you can read or modify. By typing `object.set` or `object.get` you will see a filtered list of just the setters or getters on `object`. If you use direct property access you will also see loads of other variables and methods that may not be relevant.
10. Getters and setters can be overridden to add new behaviour. We will use this fact in Chapter 5 to create a data binding system.

The disadvantages are:
1. You need to write more code and that takes effort, I sympathise 😩
2. It takes slightly longer to write `.getVariable()` than just `.variable`
3. It creates up to two functions in memory for each instance variable (This is negligible though. Stop worrying about performance and prioritise code first!)

Using getters and setters still doesn't prevent us from accessing the properties directly so we need a bit of self control to make sure we stick to this method and actually write/use the getters/setters.

You might look at that list of advantages and go "Meh, that's not for me, I would rather just access things directly as it's quicker". That's fine, just think carefully about the moment where you update or read a value. Is there any extra code in the calling object that you are using that should really be the responsibility of the object you are accessing, the potion example above for instance? If so think about moving it into a setter or getter method to encapsulate this logic.

This tutorial will continue in the style of using getters and setters so we'll re-write the scenario code now to use them.

##### oGame::Create
```gml
coins = 0;

getCoins = function () {
	return coins;
}

setCoins = function (newCoins) {
	coins = newCoins;
}
```

##### oPlayer::Step
```gml
if (place_meeting(x, y, oCoin)) {
	// Increase the coin total
	var currentCoins = oGame.getCoins();
	oGame.setCoins(++currentCoins);

	// Start process of destroying coin
	with (coin) {
		audio_play_sound(collectSound, 10, false);
		instance_destroy();
	}
}
```

##### oHud::Draw GUI
```gml
draw_text(x, y,  "Coins: " + string(oGame.getCoins()));
```

### Encapsulation of logic

When you start working with GameMaker as a beginner, you might write most of the logic that controls your objects in the step event. Possibly with many branching if statements to handle different cases that arise and calls to script functions to run additional logic.

Most beginner tutorials are written in this way because it is simple to understand for beginners and easy to implement. There's nothing inherently wrong with this approach, it is how GameMaker is designed to work after all. Learning to program and make a game is difficult enough for a beginner without adding on additional nuances such as programming styles! But if you find that your step events are becoming quite long and complicated then read on.

First we need to change how we think about the humble GameMaker object. If you are familiar with object orientated programming languages we are going to treat the object's create event as if it were a class definition file. This will contain instance variable definitions and methods that operate on these variables.

Think back to the different parts of the complicated step event and what this is actually doing. If you can describe sections of this in a few words e.g. take damage, then it is a candidate to go into a method instead. This is much more descriptive and makes reading the code easier.

Thinking in terms of operations and methods has benefits beyond readability. We can now shift the entire perspective of how we code in GameMaker. Instead of approaching code in a linear and direct fashion where we modify other objects directly from our current object; instead we will call a method on the other object and allow the object to modify itself. This is called encapsulation where we will place logic that operates on the object's data on the object itself.

Lets look at an example from the scenario. In the player's step event we are allowing the player object to calculate a new coin total and then set the number coins tracked by the game controller. The operation here is that a coin is being added to the game controller. The player object only needs to inform the game controller that a coin has been collected, not work out a new total. We can add a method to the game controller called `addCoin`. The setter we had previously is no longer needed so lets remove that too.

##### oGame::Create
```gml
// Variable definitions
coins = 0;

// Methods
getCoins = function () {
	return coins;
}

addCoin = function () {
	coins++;
}
```

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);
if (coin != noone) {
	// Increase the coin total
	oGame.addCoin();

	// Start process of destroying coin
	with (coin) {
		audio_play_sound(collectSound, 10, false);
		instance_destroy();
	}
}
```

The logic for adding coins is now encapsulated in the game controller. If we follow our self imposed restrictions of not accessing the variable directly then there is now no way to change the value of coins arbitrarily. We can only read it using the getter, or add a single coin using the predefined method.

One additional advantage of encapsulating the logic in the game controller is that coins can be now added by objects other than the player. Imagine you have a shop and you sell an item for money. The shop object can call `addCoin` in the same way the player can. You don't need to duplicate the logic in other places.

In general I would recommend keeping events other than the create event as lean as possible by encapsulating logic in methods in the create event.

### The `with` statement

The `with` statement allows you to switch to the context of another object and process code as if it were running in the equivalent event of that object. For example in the scenario code, when the player collides with the coin we are switching to the coin's context to play a sound then destroy it.

It is important that you are careful with what logic you put in the `with` statement. It is possible to add logic that that is core to way an object functions or behaves but then it is being stored in a separate file. If all your code related to one object is spread across multiple files then it becomes more difficult to update the object and harder to see why some side effect is happening when reading your code. Your code base just became tangled!

In the scenario code, since we are only using `with` with a single instance so we do not need to use it at all. We'll replace the with statement with a new method on the coin instead so that it can be destroyed.

##### oCoin::Create
```gml
collectSound = sndCoin;

collectCoin = function () {
	audio_play_sound(collectSound, 10, false);
	instance_destroy();
}
```

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);
if (coin != noone) {
	// Increase the coin total
	oGame.addCoin();

	// Start process of destroying coin
	coin.collectCoin();
}
```

However `with` is more often used as a way to loop over all objects of a specific type. This is the most efficient way to do this in GameMaker. Additionally `with` maintains access to any locally scoped variables for the duration of it's block. So you will invariably end up with a use case for `with`.

When using `with`, always keep in mind what logic you are putting inside it. Is it the responsibility of the original object that called `with` to run the code or does it belong in the callee? If it belongs to the callee add it to a method and then call that instead. Think about what you would do if you had not switched contexts if that makes it easier. This should be straightforward if you are already designing your objects with this in mind.

```gml
with (oEnemy) {
	take_damage(other.weapon.strength);
}
```

This will invoke the method `take_damage` on `oEnemy` and access some damage value on the caller using `other`.

If you would prefer a more functional solution to looping over objects in GameMaker then take a look at the method `for_object` in [Appendix D](/appendix-gamemaker-patterns/appendix-gamemaker-patterns.md#d-convenience-methods). This is a wrapper around `with` that applies a callback function to each object. 

It makes use of the `with` statement to provide the fast looping logic but ensures that the callback function is run in the same context that it was written in. This allows us to access our own variables on `self` rather than `other`.

```gml
for_objects(oEnemy, function (instance) {
	instance.take_damage(weapon.strength);
});
```
Comparing this to the above use of the `with` statement, it feels a lot more natural to me. You might have a preference for `with` so go with what works for you. `for_objects` is not a perfect solution by any means but it can handle most of the use cases that you would normally use `with` for:

1. Looping over objects in an efficient manner.
2. Ability to `break` out of the loop by returning `true` from the callback function.
3. Ability to `continue` to the next object immediately by returning `false` or `undefined` from the callback function (i.e. `return false` or just `return`).
4. Access to locally scoped variables that are passed to `for_object` as optional arguments.

I need to expand on this last point for a moment as this is a major difference between the two methods.

1. `with` has access to all local variables in scope. For `for_object`, you need to specify exactly which local variables you want to access to as optional arguments. These are then passed as arguments to the callback function. This is slightly clunky but works!
2. `with` can both read and write to local variables that hold primitive types such as reals, booleans and strings. When these are passed to a function, such as in the `for_objects` callback, the function will receive a copy of the value. If you change this value it will not affect the original.

To get around this you can store any local primitives you need to write to, in a struct and pass that to `for_objects`. Structs and arrays are passed by reference rather than by value so when a change is made to them it is changing the same object that was passed into the function. This is a workaround but if you need that functionality you can make still make use of it.

```
var locals = { count: 0 };

for_objects(oInstance, function (instance, locals) {
	locals.count++;
}, locals);

show_debug_message(locals.count)		// Prints '1' assuming one instance of oInstance
```

The performance of `for_objects` is only marginally slower than the using `with` directly when compiled using YYC and so for the majority of use cases this is not going to cause any problems. If you need every last ounce of performance then you should use `with` directly. If you are not having performance issues then there is no need to optimise this prematurely as the difference is so small.

### Pre-define all variables in objects
In GameMaker it is possible to add new variables to an object or constructor struct after it has been created such as in the step event of an object. To make the code easier to understand all variables that an object requires during it's lifetime should be pre-defined, even if the value is `undefined`.

For a constructor function all variables should be defined in the function itself. For an object you can define variables in 'Variable Definitions' section of the object inspector, or by defining them in the create event.

It is also possible to define variables by passing in a struct in the `instance_create_` methods. However I would be careful with this method as it may not always be clear what variables have been added to the instance. You can imagine that if you have two different files that instantiate the instances with different variables then it could become messy.

It is also possible to add new properties from another object. But similar to the reasoning before in the `with` statement, this can lead to confusing code that is harder to maintain. If all the variables are pre-defined anyone reading the code has a clear picture of everything the object can do.

Note that this doesn't apply to regular structs that are used as a map/dictionary like data container. You can set keys on these at any time otherwise its use as a data structure would be pretty limited.

In the next chapter we will look at our first method of decoupling.

## [← Previous](/chapter-01-introduction/chapter-01-introduction.md) | [Next →](/chapter-03-dependency-injection/chapter-03-dependency-injection.md)
