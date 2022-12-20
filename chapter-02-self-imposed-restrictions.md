# Lets make lasagne

# A Lesson In loose coupling: How to throw away the spaghetti code


## Lesson 2: Self imposed coding restrictions


Gamemaker gives us the freedom to do stupid things. Before we talk about ways to minimise coupling it's important look at other aspects of Gamemaker that could contribute to code problems. We have to be disciplined and impose some restrictions on ourselves so that we don't end up writing bad code.

### Direct property access

Gamemaker allows us to directly access the instance variables of an object from a second object and make changes to them. If you're careful and working solo this might be ok; but if you are working in a team then knowing which variables you are allowed to change without causing something obscure to fail is important.

There is no language concept of private variables which would restrict access to them so we need to impose this restriction on ourselves.

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
2. It creates two functions in memory for each instance variable (This is negligible though. Stop worrying about performance and write good code first!)

Using getters and setters still doesn't prevent us from accessing the properties directly so we need a bit of self control to make sure we stick to this method and actually write the getters/setters.

We'll re-write the scenario code in Lesson 1 to use setters and getters.

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


### The `with` statement and logic encapsulation

The `with` statement allows you to switch to the context of another object and process code as if it were running in the equivalent event of that object. For example when the player collides with the coin we may want to play a sound then destroy it.

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);

if (coin != noone) {
	// Increase the coin total
	var currentCoins = oGame.getCoins();
	oGame.setCoins(++currentCoins);

	// Start process of destroying coin
	with (coin) {
		audio_play_sound(sndCoin, 10, false);
		instance_destroy();
	}
}
```

I believe the `with` statement should be avoided in almost all cases if you want clean code!

The main reason for this is you can create logic that modifies an object and then stores it in a different file, this encouraging spaghetti code by design! If all your code related to one object is spread across multiple files then it becomes more difficult to update the object and harder to see why some side effect is happening when reading your code.

Just setting some values and calling methods already on the object is probably ok. But if you can describe what you are doing to the object in a few words e.g. take damage, then it should probably go in a method instead. This is much more descriptive and makes reading the code easier. However if you know what you're doing, go ahead!

If you need to loop over all instances of the object you can use a for loop instead, using the example from the manual to loop over all instances.

```gml
for (var i = 0; i < instance_number(oCoin); ++i)
{
    var coin = instance_find(oCoin, i);
	instance_destroy(coin);
}
```

On a similar note, in the scenario code why are we allowing the player object to directly set the number coins tracked by the game controller. The player object only needs to inform the game controller that a coin has been collected, not work out a new total. It is often useful to think in terms of operations that can be applied or carried out by objects. These operations can be defined in methods on an object.

We are going to remove the coin setter and add a method to add a single coin instead. We'll also add a method to the coin so that it can be destroyed.

##### oCoin::Create
```gml
collectCoin = function () {
	audio_play_sound(sndCoin, 10, false);
	instance_destroy();
}
```

##### oGame::Create
```gml
coins = 0;

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
	coin.collectCoin();
}
```

If we follow our self imposed restrictions of not accessing the variable directly then there is now no way to change the value of coins arbitrarily. We can only read it using the setter, or add a single coin using the predetermined method.

If there was no setter or getter then we would not be able to view or change the value at all.

In the next chapter we will look at our first method of decoupling.
