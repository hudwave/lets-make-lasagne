# Lets make lasagne

# A Lesson In loose coupling: How to throw away the spaghetti code


## Chapter 2: Self imposed coding restrictions and good practices


Before we talk about ways to minimise coupling it's important look at some other aspects of Gamemaker that could contribute to code problems. Until recently, Gamemaker's programming language (GML) behaved in a mostly imperative fashion but had a lot of limitations e.g. each script file is a single function! The language is designed around this paradigm (scripts execute in the calling object's scope, `other` keyword, `with` statement). Due to the limitations, I'm genuinely impressed that people managed to create such amazing and complicated games before! I dread to think how difficult it would have been to read, refactor, maintain and debug such a large codebase.

Luckily, we now have first class functions and lightweight objects (structs) which open up a whole world of possibilities and much cleaner code. GML has become a sort of hybrid imperative, functional and part object orientated language (it's still missing some defining features of each paradigm though). All these options in GML gives us the freedom to write code in many ways, but this means we can also do a lot of stupid things. Therefore we need to be disciplined and impose some restrictions on ourselves so that we don't end up writing bad code.

Below are some rules that I adhere to when writing GML. This is just my own opinion and it works for me. There is no right or wrong way to make a game in Gamemaker so go with what works for you. However, you might find that by sticking to these rules, you'll end up naturally writing cleaner code.

### Direct property access

Gamemaker allows us to directly access the instance variables of an object from a second object and make changes to them. If you're careful and working solo this might be ok; but if you are working in a team then it is important to know which variables you can change without causing something obscure to fail.

There is no language concept of private variables in GML to prevent access to them. So we need to impose this restriction on ourselves.

Some people like to prefix their private variables with an underscore like `_privateVariable`. I generally do not use an underscore for private variables, only for private methods. Instead for variables I will create getter and setter methods.

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
2. You can add additional code to the setter to do validation of the new value or perform some additional side effect.
3. The getter value does not need to be calculated until it is actually needed. You can check to see if the value is `undefined` when the getter is called and calculate it if required. This is called lazy instantiation. This might be useful if the calculation of a value is particularly costly but might never be needed.
4. Getters and setters can be used as callback functions.
5. We will do something cool by overriding the setters in Chapter 5. This is only possible if you are consistent and write all of your code around getters and setters.

The disadvantages are:
1. You need to write more code and that takes effort, I sympathise 😩
2. It creates up to two functions in memory for each instance variable (This is negligible though. Stop worrying about performance and write good code first!)

Using getters and setters still doesn't prevent us from accessing the properties directly so we need a bit of self control to make sure we stick to this method and actually write the getters/setters.

We'll re-write the scenario code to use setters and getters.

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
	var currentCoins = oGame.getCoins();
	oGame.setCoins(++currentCoins);
}
```

##### oHud::Draw GUI
```gml
draw_text(x, y,  "Coins: " + string(oGame.getCoins()));
```

### Encapsulation of logic

When you start working with Gamemaker as a beginner, you might write most of the logic that controls your objects in the step event. Possibly with many branching if statements to handle different cases that arise and calls to script functions to run additional logic.

Most beginner tutorials are written in this way because it is simple to understand for beginners and easy to implement. There's nothing inherently wrong with this approach, it is how Gamemaker is designed to work after all. Learning to program and make a game is difficult enough for a beginner without adding on additional complexities such as architectural design choices! But if you find that your step events are becoming quite long and complicated then read on.

First we need to change how we think about the humble Gamemaker object. If you are familiar with object orientated programming languages we are going to treat the object's create event as if it were a class definition file. This will contain instance variable definitions and methods that operate on these variables.

Think back to the different parts of the complicated step event and what this is actually doing. If you can describe sections of this in a few words e.g. take damage, then it should go into a method instead. This is much more descriptive and makes reading the code easier.

Thinking in terms of operations and methods has benefits beyond readability. We can now shift the entire perspective of how we code in Gamemaker. Instead of approaching code in a linear and direct fashion where we modify other objects directly from our current object; instead we will call a method on the other object and allow the object to modify itself. This is called encapsulation where we will place logic that operates on the object's data on the object itself.

Lets look at an example from the scenario. In the player's step event we are allowing the player object to calculate a new coin total and then set the number coins tracked by the game controller. The operation here is that a coin is being added to the game controller. The player object only needs to inform the game controller that a coin has been collected, not work out a new total. We can add a method to the game controller called `addCoin`.

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

The logic for adding coins is now encapsulated in the game controller. If we follow our self imposed restrictions of not accessing the variable directly then there is now no way to change the value of coins arbitrarily. We can only read it using the setter, or add a single coin using the predefined method.

One additional advantage of encapsulating the logic in the game controller is that coins can be now added by objects other than the player. Imagine you have a shop and you sell an item for money. The shop object can call `addCoin` in the same way the player can. You don't need to duplicate the logic in other places.

In general I would recommend keeping events other than the create event as lean as possible by encapsulating logic in methods in the create event.

### The `with` statement

The `with` statement allows you to switch to the context of another object and process code as if it were running in the equivalent event of that object. For example in the scenario code, when the player collides with the coin we are switching to the coin's context to play a sound then destroy it.

I believe the `with` statement should be avoided in almost all cases if you want clean code[^1]. It is a remnant of the old way of working in Gamemaker and is directly opposed to the encapsulation principle in outlined in the previous section.

The main problem is that you can create logic that that is core to way an object functions or behaves and then store it in the file of an entirely different object. This is spaghetti code by design! If all your code related to one object is spread across multiple files then it becomes more difficult to update the object and harder to see why some side effect is happening when reading your code. Your code base just became tangled!

We'll replace the with statement with a new method to the coin so that it can be destroyed.

##### oCoin::Create
```gml
collectCoin = function () {
	audio_play_sound(sndCoin, 10, false);
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

`with` is often used as a convenient way to loop over all objects of a specific type. This can also be done using `instance_number` and `instance_find`. It's a bit more verbose but fits better with the style of encapsulating an object's logic in methods.

```gml
for (var i = 0; i < instance_number(oCoin); ++i) {
    var coin = instance_find(oCoin, i);
	instance_destroy(coin);
}
```

In the next chapter we will look at our first method of decoupling.

## [← Previous](chapter-02-self-imposed-restrictions/chapter-02-self-imposed-restrictions.md) | [Next →](chapter-03-dependency-injection/chapter-03-dependency-injection.md)

## Footnotes

[^1]: If you know what you're doing with `with` go ahead and use it!
