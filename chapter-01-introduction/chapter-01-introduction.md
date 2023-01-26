# Lets make lasagne

# How to throw away the spaghetti code


## Chapter 1 - Introduction to dependencies


### Introduction

GameMaker is great for rapidly prototyping stuff[^1]. You have complete global access to absolutely everything. This can save time but can also create a huge tangled mess if you're not careful.

We're going to closely examine one scenario to show why global access can be bad and how we can write nice clean code instead. The scenario is deliberately simple so that it's easy to follow. There are accompanying source files for each chapter. The code reflects how the project should look at the end of the chapter. This chapter doesn't contain any changes so if you want to follow along and write the code yourself, take the project from the chapter 1 folder and add to it from there.

This tutorial is aimed at intermediate GameMaker programmers who know there is something clunky or not quite right with their code but don't know how to take it to the next level.

It will introduce some concepts that help solve certain problems you might face when designing systems in your game. These are only tools however, learning when and where to apply them and when to ignore them will come with experience. And it IS valid to ignore them when it makes sense to do so. We need to learn what these tools are though first so lets begin!

### The scenario

The player object just collected a coin so we need to update the coin count. That lives in the game controller.

##### oGame::Create
```gml
coins = 0;
```

So lets just call that directly from the player and increase the count. We can also play a sound and destroy the coin.

##### oPlayer::Step
```gml
var coin = instance_place(x, y, oCoin);

if (coin != noone) {
    // Increase the coin total
    oGame.coins++;
    
    // Start process of destroying coin
    with (coin) {
        audio_play_sound(collectSound, 10, false);
        instance_destroy();
    }
}
```

We also need to update the text displayed in the UI. We may as well just read that directly from the game controller in my HUD renderer.

##### oHud::Draw GUI
```gml
draw_text(x, y, "Coins: " + string(oGame.coins));
```

This works right? Why would you bother doing this in any other way? It's simple, quick and easy!


### Wrong! Also what is a dependency?

This might be ok for a small prototype project but if you want to expand the scope of your project or you come up with a new way of doing things then your player object and UI are well and truly tied to the game controller. This is called coupling, where there is a dependency relationship between the two objects.

Imagine we want to test that the coin disappears and plays a sound when the player touches it. We could create a test room and add the player and a coin. We would get a crash when the player touches the coin as it tries to access the non-existant game controller.

To get the test to work we also need to setup the game controller  (which may have other dependencies itself). Alternatively you would need to have a specific check in the player to see if the game controller instance exists and only adjust the coin count if it is present.

##### oPlayer::Step
```gml
if (instance_exists(oGame)) {
    // Increase the coin total
    oGame.coins++;
}
```

Both of these solutions work but they are bad. It's time consuming to setup test environments with all the correct dependencies. Adding special checks that are unnecessary for the game itself is just polluting the codebase for no reason. If you have to do this for several other dependencies it quickly gets out of hand or becomes very messy.

What we need to do is untangle the spaghetti, in programming terms this is called decoupling. Instead of spaghetti we are aiming for nice separated lasagne sheets, with a delicious loose coupling layer of bolognese sauce between[^2].

Strong coupling of dependencies can lead to tangled spaghetti code. We want to be in a position where making a change to one object doesn't cause massive ripples throughout the codebase. In the simplest terms, in GameMaker a dependency is when an object needs to call another external object to complete its task. The fewer dependencies you rely on the less likely your code will break when changes are made.

Now, its impossible to write code without any dependencies at all but there are strategies to minimise their coupling. These will be discussed in future chapters.

## [Next →](/chapter-02-self-imposed-restrictions/chapter-02-self-imposed-restrictions.md)

## Footnotes

[^1]: It's also just great!

[^2]:The analogy breaks down if you inspect it too closely so don't look too hard! Also sorry to any Italians reading for butchering your food culture 😜🍝.
