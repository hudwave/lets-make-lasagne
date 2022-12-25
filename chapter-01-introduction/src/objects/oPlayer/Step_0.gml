moveAndAnimate();

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
