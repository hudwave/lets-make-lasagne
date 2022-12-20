moveAndAnimate();

var coin = instance_place(x, y, oCoin);

if (coin != noone) {
	// Emit signal that coin has been collected
	coinCollected.emit(coin);

	// Start process of destroying coin
	coin.collectCoin();
}
