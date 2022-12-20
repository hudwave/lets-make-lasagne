coins = 0;

player = instance_create_layer(64, 96, layer, oPlayer);
uiHud = instance_create_layer(32, 32, layer, oHud);

init = function () {
	player.coinCollected.connect(self, addCoin);
	data_bind(self, "coins", uiHud, "coins");
}

getCoins = function () {
	return coins;
}

setCoins = function (newCoins) {
	coins = newCoins;
}

addCoin = function (coin) {
	setCoins(coins + coin.getValue());
}

init();
