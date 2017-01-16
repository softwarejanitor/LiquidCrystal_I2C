// LiquidCrystal_I2C Esquilo library ported from Arduino

// When the display powers up, it is configured as follows:
//
// 1. Display clear
// 2. Function set:
//    DL = 1; 8-bit interface data
//    N = 0; 1-line display
//    F = 0; 5x8 dot character font
// 3. Display on/off control:
//    D = 0; Display off
//    C = 0; Cursor off
//    B = 0; Blinking off
// 4. Entry mode set:
//    I/D = 1; Increment by 1
//    S = 0; No shift
//
// Note, however, that resetting the Arduino doesn't reset the LCD, so we
// can't assume that its in that state when a sketch starts (and the
// LiquidCrystal constructor is called).

// commands
const LCD_CLEARDISPLAY = 0x01;
const LCD_RETURNHOME = 0x02;
const LCD_ENTRYMODESET = 0x04;
const LCD_DISPLAYCONTROL = 0x08;
const LCD_CURSORSHIFT = 0x10;
const LCD_FUNCTIONSET = 0x20;
const LCD_SETCGRAMADDR = 0x40;
const LCD_SETDDRAMADDR = 0x80;

// flags for display entry mode
const LCD_ENTRYRIGHT = 0x00;
const LCD_ENTRYLEFT = 0x02;
const LCD_ENTRYSHIFTINCREMENT = 0x01;
const LCD_ENTRYSHIFTDECREMENT = 0x00;

// flags for display on/off control
const LCD_DISPLAYON = 0x04;
const LCD_DISPLAYOFF = 0x00;
const LCD_CURSORON = 0x02;
const LCD_CURSOROFF = 0x00;
const LCD_BLINKON = 0x01;
const LCD_BLINKOFF = 0x00;

// flags for display/cursor shift
const LCD_DISPLAYMOVE = 0x08;
const LCD_CURSORMOVE = 0x00;
const LCD_MOVERIGHT = 0x04;
const LCD_MOVELEFT = 0x00;

// flags for function set
const LCD_8BITMODE = 0x10;
const LCD_4BITMODE = 0x00;
const LCD_2LINE = 0x08;
const LCD_1LINE = 0x00;
const LCD_5x10DOTS = 0x04;
const LCD_5x8DOTS = 0x00;
    
// flags for backlight control
const LCD_BACKLIGHT = 0x08;
const LCD_NOBACKLIGHT = 0x00;

const En = 0x04;  // B00000100 Enable bit
const Rw = 0x02;  // B00000010 Read/Write bit
const Rs = 0x01;  // B00000001 Register select bit

class LiquidCrystal_I2C
{
    _i2c = null;
    _addr = null;
    _cols = 16;
    _rows = 2;
    _charsize = 0;
    _backlightval = LCD_BACKLIGHT;

    _displayfunction = 0;
    _displaycontrol = 0;
    _displaymode = 0;

    constructor (i2c, lcd_addr, lcd_cols, lcd_rows, charsize)
    {
        _i2c = i2c;
        _addr = lcd_addr;
        _cols = lcd_cols;
        _rows = lcd_rows;
        _charsize = charsize;
        _backlightval = LCD_BACKLIGHT;
    }
}

function LiquidCrystal_I2C::begin()
{
    i2c.address(_addr);
    _displayfunction = LCD_4BITMODE | LCD_1LINE | LCD_5x8DOTS;

    if (_rows > 1) {
        _displayfunction = _displayfunction | LCD_2LINE;
    }

    // for some 1 line displays you can select a 10 pixel high font
    if ((_charsize != 0) && (_rows == 1)) {
        _displayfunction = _displayfunction | LCD_5x10DOTS;
    }

    // SEE PAGE 45/46 FOR INITIALIZATION SPECIFICATION!
    // according to datasheet, we need at least 40ms after power rises above 2.7V
    // before sending commands. Arduino can turn on way befer 4.5V so we'll wait 50
    delay(50);

    // Now we pull both RS and R/W low to begin commands
    expanderWrite(_backlightval);    // reset expander and turn backlight off (Bit 8 =1)
    delay(1000);

    // put the LCD into 4 bit mode
    // this is according to the hitachi HD44780 datasheet
    // figure 24, pg 46

    // we start in 8bit mode, try to set 4 bit mode
    write4bits(0x03 << 4);
    udelay(4500); // wait min 4.1ms

    // second try
    write4bits(0x03 << 4);
    udelay(4500); // wait min 4.1ms

    // third go!
    write4bits(0x03 << 4);
    udelay(150);

    // finally, set to 4-bit interface
    write4bits(0x02 << 4);

    // set # lines, font size, etc.
    command(LCD_FUNCTIONSET | _displayfunction);

    // turn the display on with no cursor or blinking default
    _displaycontrol = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF;
    display();

    // clear it off
    clear();

    // Initialize to default text direction (for roman languages)
    _displaymode = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT;

    // set the entry mode
    command(LCD_ENTRYMODESET | _displaymode);

    home();
}

/********** high level commands, for the user! */
function LiquidCrystal_I2C::clear()
{
    command(LCD_CLEARDISPLAY);  // clear display, set cursor position to zero
    udelay(2000);  // this command takes a long time!
}

function LiquidCrystal_I2C::home()
{
    command(LCD_RETURNHOME);  // set cursor position to zero
    udelay(2000);  // this command takes a long time!
}

function LiquidCrystal_I2C::setCursor(col, row)
{
    if (row > _rows) {
        row = _rows - 1;    // we count rows starting w/0
    }

    local pos = col;
    if (row == 1) {  // row offsets
        pos += 0x40;
    } else if (row == 2) {
        pos += 0x14;
    } else if (row == 3) {
        pos += 0x54;
    }
    command(LCD_SETDDRAMADDR | pos);
}

// Turn the display on/off (quickly)
function LiquidCrystal_I2C::noDisplay()
{
    _displaycontrol = _displaycontrol & ~LCD_DISPLAYON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal_I2C::display()
{
    _displaycontrol = _displaycontrol | LCD_DISPLAYON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// Turns the underline cursor on/off
function LiquidCrystal_I2C::noCursor()
{
    _displaycontrol = _displaycontrol & ~LCD_CURSORON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal_I2C::cursor()
{
    _displaycontrol = _displaycontrol | LCD_CURSORON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// Turn on and off the blinking cursor
function LiquidCrystal_I2C::noBlink()
{
    _displaycontrol = _displaycontrol & ~LCD_BLINKON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal_I2C::blink()
{
    _displaycontrol = _displaycontrol | LCD_BLINKON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// These commands scroll the display without changing the RAM
function LiquidCrystal_I2C::scrollDisplayLeft()
{
    command(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVELEFT);
}

function LiquidCrystal_I2C::scrollDisplayRight()
{
    command(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVERIGHT);
}

// This is for text that flows Left to Right
function LiquidCrystal_I2C::leftToRight()
{
    _displaymode = _displaymode | LCD_ENTRYLEFT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This is for text that flows Right to Left
function LiquidCrystal_I2C::rightToLeft()
{
    _displaymode = _displaymode & ~LCD_ENTRYLEFT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This will 'right justify' text from the cursor
function LiquidCrystal_I2C::autoscroll()
{
    _displaymode = _displaymode | LCD_ENTRYSHIFTINCREMENT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This will 'left justify' text from the cursor
function LiquidCrystal_I2C::noAutoscroll()
{
    _displaymode = _displaymode & ~LCD_ENTRYSHIFTINCREMENT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// Allows us to fill the first 8 CGRAM locations
// with custom characters
function LiquidCrystal_I2C::createChar(location, charmap)
{
    location = location & 0x7;  // we only have 8 locations 0-7
    command(LCD_SETCGRAMADDR | (location << 3));
    local ci;
    for (ci = 0; ci < 8; ci++) {
        write(charmap[ci]);
    }
}

// Turn the (optional) backlight off/on
function LiquidCrystal_I2C::noBacklight()
{
    _backlightval = LCD_NOBACKLIGHT;
    expanderWrite(0);
}

function LiquidCrystal_I2C::backlight()
{
    _backlightval = LCD_BACKLIGHT;
    expanderWrite(0);
}

/*********** mid level commands, for sending data/cmds */

function LiquidCrystal_I2C::command(value)
{
    send(value, 0);
}

function LiquidCrystal_I2C::write(value)
{
    send(value, Rs);
    return 1;
}


/************ low level data pushing commands **********/

// write either command or data
function LiquidCrystal_I2C::send(value, mode)
{
    local highnib = value & 0xf0;
    local lownib = (value << 4) & 0xf0;
    write4bits((highnib) | mode);
    write4bits((lownib) | mode);
}

function LiquidCrystal_I2C::write4bits(value)
{
    expanderWrite(value);
    pulseEnable(value);
}

function LiquidCrystal_I2C::expanderWrite(_data)
{
    //i2c.address(_addr);
    //i2c.write8((_data) | _backlightval);
    local writeBlob = blob(1);
    writeBlob[0] = ((_data) | _backlightval);
    i2c.address(_addr);
    i2c.write(writeBlob);
}

function LiquidCrystal_I2C::pulseEnable(_data)
{
    expanderWrite(_data | En);  // En high
    udelay(1);  // enable pulse must be >450ns

    expanderWrite(_data & ~En);  // En low
    udelay(50);  // commands need > 37us to settle
}

function LiquidCrystal_I2C::load_custom_character(char_num, rows)
{
    createChar(char_num, rows);
}

function LiquidCrystal_I2C::setBacklight(new_val)
{
    if (new_val) {
        backlight();  // turn backlight on
    } else {
        noBacklight();  // turn backlight off
    }
}

function LiquidCrystal_I2C::printstr(c)
{
    // This function is not identical to the function used for "real" I2C displays
    // it's here so the user sketch doesn't have to be changed
    print(c);
}

function LiquidCrystal_I2C::print(str)
{
    local loopc;
    local strLen = str.len();
    //print("len=" + strLen);
    local strBlob = blob(strLen);
    strBlob.seek(0, 'b');
    strBlob.writestr(str);
    strBlob.seek(0, 'b')
    for (loopc = 0; loopc < strLen; loopc++) {
        local ch = strBlob.readn('b');
        write(ch);
    }
}

