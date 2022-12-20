coins = 0;

player = instance_create_layer(64, 96, layer, oPlayer);
uiHud = instance_create_layer(32, 32, layer, oHud);

init = function () {
	player.coinCollected.connect(self, addCoin);
}

getCoins = function () {
	return coins;
}

addCoin = function (coin) {
	coins += coin.getValue();
	uiHud.setCoins(coins);
}

init();
