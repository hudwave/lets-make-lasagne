moveAndAnimate();

var coin = instance_place(x, y, oCoin);

if (coin != noone) {
	// Increase the coin total
	gameController.addCoin();

	// Start process of destroying coin
	coin.collectCoin();
}
