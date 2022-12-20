# Lets make lasagne

# A Lesson In loose coupling: How to throw away the spaghetti code


## Lesson 3: Dependency Injection


This first one is a classic - Dependency Injection. It's useful, although perhaps more so in a fully object orientated language and particularly for aiding unit testing. But it can still help to untangle some of our spaghetti and has other benefits too.

Dependency injection as the name suggests is a mechanism of inserting dependencies into an object rather than creating them directly inside it or globally accessing them. This is usually done by passing the dependency in as a constructor argument

##### For objects:
```gml
instance_create_layer(x, y, layer, oPlayer, { gameController: oGame });
```

##### For structs:
```gml
new ConstructorFunction(oGame);
```

Or by setting the value after creation
```gml
var player = instance_create_layer(x, y, layer, oPlayer);
player.setGameController(oGame);
```

The advantages of doing things this way is the object being passed the dependency does not have to create or configure the dependency (which may require other dependencies). It can also be passed different configurations when required or even a different version of the object that behaves in an entirely different way (search for "Duck Typing" or "Composition Over Inheritance" for ideas).

Dependencies do need to be created somewhere though. Usually dependencies will be created nearer the top of the hierarchy of objects such as in controller objects.

In Gamemaker we have the option to create objects via code or by placing them in the room editor. If an object requires another object that has been created in the room, then the line of code that finds the object should be considered equivalent to a statement that creates an object i.e. it is a dependency. This is another self imposed coding restriction that we will abide by. We should find dependencies in the controller and inject them into objects that need them.

One exception we'll make here is using the object asset name directly for things like collision. This is checking for collisions against a type and not a particular instance. But a line that gets the player directly using `oPlayer` to check it's health for example, would be considered a dependency.

Just a quick reminder that you don't have to follow the principles outlined in this tutorial to the letter every time. There may be situations where you feel it's not worth the effort to inject the dependency, perhaps the dependency won't ever change and is only ever relevant to the current object. Just be sure to refactor if it ever does become a problem.

Lets look at how dependency injection changes our scenario code.

##### oPlayer::Create
```gml
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

Now the player object is independent from from the game controller. What gets passed into the player could be the game controller or it could be some other object that acts as a proxy for it. From the player object's perspective it doesn't know or care. As long as it can call a method `addCoin` on the injected object it's happy.

We have also removed the need for the dependency entirely from the UI Renderer. Instead we will simply set the value it displays when a coin is added.

Both objects are instantiated by the controller now, so don't forget to remove the instances from the room. If you prefer to keep the instances in the room you can have the game controller find the instances in the room and store a reference to them instead of creating them.

```
player = oPlayer;
player.setGameController(self);

uiHud = oHud;
```

### Testing with mocks

Lets demonstrate how this solves our problem in the example of the testing the player in an isolated context.

We want to test that when the player touches a coin that the coin is destroyed. If we set up the room with just the player and a coin then we will get an error when the player touches the coin. This is because it will try to add a coin to the game controller.

What we need to do is pass in a dummy or mock version of the game controller that has a method `addCoin` which does nothing.

```gml
var mockGameController = {
	addCoin: function () {

	}
};
```

This process of creating the dummy game controller is called mocking and there are whole books written about the subject. So I won't go into too much detail here, but it does demonstrate how dependency injection is useful.

You could create a test object to set this up but for simplicity we'll set this up in the room creation code.

##### rTest:Creation Code
```gml
var mockGameController = {
	addCoin: function () {

	}
};

oPlayer.setGameController(mockGameController);
```

The player can now pick up a coin without it crashing. This would become tiresome if we had to mock a large number of dependencies or if the mock needs to be more complex. But there is a better way to decouple the player and the game controller as we will see in the next chapter. Even so, you may still find dependency injection useful for some problems.
