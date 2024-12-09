# 10moons-driver

Simple daemon driver for 10moons T503 tablet.

## About

Driver which provides basic functionality for 10moons T503 tablet:
 - 4 buttons on the tablet itself
 - Correct X and Y positioning
 - Pressure sensitivity

Tablet has 4096 levels in both axes and 2047 levels of pressure.

## How to use

### Git

Clone or download this repository.

```
git clone https://github.com/alex-s-v/10moons-driver.git
```

Then install all dependencies listed in _requirements.txt_ file either using python virtual environments or not.

```
python -m pip install -r requirements.txt
```

Connect tablet to your computer and then run _driver.py_ file with sudo privileges.

```
sudo python driver.py
```

**You need to connect your tablet and run the driver prior to launching a drawing software otherwise the device will not be recognized by it.**

### Debian

Go to releases -> 10moons-driver.deb

### Alpine

Go to releases -> 10moons-driver-alpine.tar.gz
Inside archive there's a signed apk file and keys.

## Configuring tablet

Configuration of the driver placed is placed in _/etc/10moons-driver/config.yaml_ or _/usr/share/10moons-driver/config.yaml_ file.

You may need to change the *vendor_id* and the *product_id* but I'm not sure (You device can have the same values as mine, but if it is not you can run the *lsusb* command to find yours).

Buttons assigned from in the order from left to right. You can assign to them any button on the keyboard and their combinations separating them with a plus (+) sign.

If you find that using this driver with your tablet results in reverse axis or directions (or both), you can modify parameters *swap_axis*, *swap_direction_x*, and *swap_direction_y* by changing false to true and another way around.

To list all the possible key codes you may run:
```
python -c "from evdev import ecodes; print([x for x in dir(ecodes) if 'KEY' in x])"
```

## Credits

Some parts of code are taken from: https://github.com/Mantaseus/Huion_Kamvas_Linux
The original code is provided from: https://github.com/alex-s-v/10moons-driver

## Known issues

Buttons on the pen itself do not work and hence not specified. I don't know if it's the issue only on my device or it's a common problem.

# License

[MIT](LICENSE.md)
