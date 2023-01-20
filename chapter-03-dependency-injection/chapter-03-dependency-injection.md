# Lets make lasagne

# How to throw away the spaghetti code


## Chapter 3: Dependency Injection


This first one is a classic, dependency injection. As the name suggests, it is a mechanism of inserting dependencies into an object rather than creating them directly inside it or globally accessing them. You may be doing this already as it is quite simple. Dependency injection is usually done by passing the dependency in as a constructor argument

##### For objects:
```gml
instance_create_layer(x, y, layer, oPlayer, { gameController: oGame });
```

##### For structs:
```gml
new ConstructorFunction(oGame);
```

Or by setting the value using a setter method
```gml
var player = instance_create_layer(x, y, layer, oPlayer);
player.setGameController(oGame);
```

The advantage of doing things this way is the object being passed the dependency no longer has to create or configure the dependency itself. It is generally not the responsibility of an object to create or configure another object that it just wants to use. This is known as separation of concerns, we have separated the construction and configuration of the object from its use.

The injected object can also be easily changed at runtime (if using setters) to provide different behaviors (search for "Duck Typing", "Strategy Pattern" or "Composition Over Inheritance" for ideas). For example if you had an enemy spawner object that handles when and where to spawn an enemy, but relies on an enemy builder object to create the enemy. You could pass the spawner a different enemy builder object to adjust the difficulty depending on how many points the player has.

Dependencies do need to be created somewhere though. Usually dependencies will be created nearer the top of the hierarchy of objects such as in controller objects.

In Gamemaker we have the option to create objects via code or by placing them directly in the room editor. If an object requires use of another object that has been created in the room, then the line of code that finds the object should be considered equivalent to a statement that creates an object i.e. it is a dependency. This is another self imposed coding restriction that we will abide by. We should find dependencies in the controller and inject them into objects that need them.

Just a quick reminder that you don't have to follow the principles outlined in this tutorial to the letter every time. There may be situations where you feel it's not worth the effort to inject the dependency, perhaps the dependency won't ever change and is only ever relevant to the current object. Just be sure to refactor if it ever does become a problem.

Lets look at how dependency injection changes our scenario code.

##### oPlayer::Create
```gml
// Variable to store the injected game controller
gameController = undefined;

setGameController = function (newGameController) {
	gameController = newGameController;
}
```

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);

if (coin != noone) {
	// Increase the coin total
	gameController.addCoin();

	// Start process of destroying coin
	coin.collectCoin();
}
```

##### oHud::Create
```gml
coins = 0

setCoins = function (newCoins) {
	coins = newCoins;
}
```

##### oHud::Draw GUI
```gml
draw_text(x, y, "Coins: " + string(coins));
```

##### oGame::Create
```gml
coins = 0;

player = instance_create_layer(x, y, layer, oPlayer);
player.setGameController(self);

uiHud = instance_create_layer(x, y, layer, oHud);

getCoins = function () {
	return coins;
}

addCoin = function () {
	coins++;
	uiHud.setCoins(coins);
}
```

We have added a setter on the player to allow the game controller to inject itself into the player. Now the player object is now loosely coupled to the game controller. What gets passed into the player could be the game controller or it could be some other object that acts as a proxy for it. From the player object's perspective it doesn't know or care. As long as it can call a method `addCoin` on the injected object it's happy and the code will not crash.

We have also removed the need for the dependency entirely from the UI Renderer. Instead we will simply set the value it displays when a coin is added.

Both objects are instantiated by the controller now, so don't forget to remove the instances from the room. If you prefer to keep the instances in the room you can have the game controller find the instances in the room and store a reference to them instead of creating them like so.

```
player = oPlayer;
player.setGameController(self);

uiHud = oHud;
```

### Testing with mocks

Lets demonstrate how this solves our problem in the example of the testing the player in an isolated context.

We want to test that when the player touches a coin that the coin is destroyed. If we set up the room with just the player and a coin then we will get an error when the player touches the coin. This is because it will try to add a coin to the game controller.

What we need to do is pass in a dummy or mock version of the game controller that has a method `addCoin` which does nothing. We will use a struct for this.

```gml
var mockGameController = {
	addCoin: function () {

	}
};
```

This process of creating the dummy game controller is called mocking. There are whole books written about the subject so I won't go into too much detail. For simplicity we'll set this up in the room creation code.

##### rTest:Creation Code
```gml
var mockGameController = {
	addCoin: function () {

	}
};

oPlayer.setGameController(mockGameController);
```

The player can now pick up a coin without it crashing. This would become tiresome if we had to mock a large number of dependencies or if the mock needs to be more complex. In the next chapter we will see a better way to decouple the player and the game controller.

## [← Previous](/chapter-02-self-imposed-restrictions/chapter-02-self-imposed-restrictions.md) | [Next →](/chapter-04-signals/chapter-04-signals.md)
