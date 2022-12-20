enum CoinType {
	BRONZE = 1,
	SILVER = 5,
	GOLD = 10,
}

value = coinType;

switch (coinType) {
	case CoinType.BRONZE:
		sprite_index = sBronzeCoin;
		break;
	case CoinType.SILVER:
		sprite_index = sSilverCoin;
		break;
	case CoinType.GOLD:
		sprite_index = sGoldCoin;
		break;	
}

collectCoin = function () {
	audio_play_sound(sndCoin, 10, false);
	instance_destroy();
}