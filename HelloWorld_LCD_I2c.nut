require("I2C");

// Create an I2C instance
i2c <- I2C(0);

// Load the library.
dofile("sd:/LiquidCrystal_I2C.nut");

// Create the object.
local lcd = LiquidCrystal_I2C(i2c, 0x27, 16, 2, 0);

// initialize the LCD
lcd.begin();

// Turn on the blacklight and print a message.
lcd.backlight();
lcd.print("Hello, world!");

