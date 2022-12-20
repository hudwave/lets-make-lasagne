coinCollected = new Signal();

moveAndAnimate = function () {
	var keyLeft = keyboard_check(vk_left) || keyboard_check(ord("A"));
	var keyRight = keyboard_check(vk_right) || keyboard_check(ord("D"));
	var keyUp = keyboard_check(vk_up) || keyboard_check(ord("W"));
	var keyDown = keyboard_check(vk_down) || keyboard_check(ord("S"));

	var inputDirection = point_direction(0, 0, keyRight - keyLeft, keyDown - keyUp);
	var inputMagnitude = (keyRight - keyLeft != 0) || (keyDown - keyUp != 0);
	
	x += lengthdir_x(inputMagnitude * 2, inputDirection);
	y += lengthdir_y(inputMagnitude * 2, inputDirection);
	
	if (keyLeft) {
		sprite_index = sPlayerWalkLeft;
	}
	else if (keyRight) {
		sprite_index = sPlayerWalkRight;
	}
	else if (keyUp) {
		sprite_index = sPlayerWalkUp;
	}
	else if (keyDown) {
		sprite_index = sPlayerWalkDown;
	}
	else {
		sprite_index = sPlayerIdle;
	}
}

