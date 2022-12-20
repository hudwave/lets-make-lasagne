# Lets make lasagne

# A Lesson In loose coupling: How to throw away the spaghetti code


## Lesson 1 - Introduction to dependencies


### Introduction

Gamemaker is great for rapidly prototyping stuff[^1]. You have complete global access to absolutely everything. This can save time but can also create a huge tangled mess if you're not careful.

We're going to closely examine one scenario to show why global access can be bad and how we can write nice clean code instead. The scenario is deliberately simple so that it's easy to follow what gets changed between each chapter.

There are accompanying source files for each chapter. The code reflects how the project should look at the end of the chapter. This chapter doesn't contain any changes so if you want to follow along and write the code yourself in future chapters take the project from the chapter 1 folder and add to it from there.

This tutorial is aimed at intermediate programmers who know there is something wrong or clunky with their code but don't know how to take it to the next level.

It will introduce some concepts that help solve certain problems you might face when designing systems in your game. These are only tools however, learning when and where to apply them and when to ignore them completely will come with experience. And it IS valid to ignore them when it makes sense to do so. We need to learn what the tools are though first so lets begin!

### The scenario

My player object just collected a coin so I need to update the coin count. That lives in the game controller.

##### oGame::Create
```gml
coins = 0;
```

So lets just call that directly from the player and increase the count.

##### oPlayer::Step
```gml
if (place_meeting(x, y, oCoin)) {
	oGame.coins++;
}
```

I also need to update the text displayed in the UI. I may as well just read that directly from the game controller in my HUD renderer.

##### oHud::Draw GUI
```gml
draw_text(x, y, "Coins: " + string(oGame.coins));
```

This works right? Why would I bother doing this in any other way? It's simple, quick and easy!


### Wrong! Also what is a dependency?

This might be ok for a small prototype project but if you want to expand the scope of your project or you come up with a new way of doing things then your player object and UI are well and truly tied to the game controller. This is called coupling, where there is a dependency relationship between the two objects.

Even just testing some aspect of the player in isolation as the only object in the room becomes difficult as you would need to setup the game controller first in the test room (which may have other dependencies itself). Alternatively you will need to have a specific check in the player to see if the game controller instance has been created and only adjust the coin count if it is present.

##### oPlayer::Step
```gml
if (instance_exists(oGame)) {
	oGame.coins++;
}
```

Both of these solutions work but they are bad. And you may have to do this for many other dependencies as well. It quickly gets out of hand and is messy.

What we need to do is untangle the spaghetti, in programming terms this is called decoupling. Instead of spaghetti we are aiming for nice separated lasagne sheets, with a delicious loose coupling layer of bolognese sauce between[^2].

Strong coupling of dependencies is one of the most likely causes of spaghetti code. In the simplest terms, in Gamemaker a dependency is when an object needs to call another external object to complete its task.

Now, its impossible to write code without any dependencies but there are strategies to minimise their coupling. These will be discussed in future chapters.

## Footnotes

[^1]: It's also just great!

[^2]:The analogy breaks down if you inspect it too closely so don't look too hard! Also sorry to any Italians reading, for any incorrect or offensive food terminology 😜🍝.
