coins = 0;

player = instance_create_layer(64, 96, layer, oPlayer);
player.setGameController(self);

uiHud = instance_create_layer(32, 32, layer, oHud);

getCoins = function () {
	return coins;
}

addCoin = function () {
	coins++;
	uiHud.setCoins(coins);
}
