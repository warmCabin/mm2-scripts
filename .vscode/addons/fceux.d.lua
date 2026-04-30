--- @meta

emu = {}
FCEU = emu

--- Advance the emulator by one frame. It's like pressing the frame advance button
--- once.
---
--- Most scripts use this function in their main game loop to advance frames. Note
--- that you can also register functions by various methods that run "dead",
--- returning control to the emulator and letting the emulator advance the frame.
--- For most people, using frame advance in an endless while loop is easier to
--- comprehend so I suggest  starting with that. This makes more sense when
--- creating bots. Once you move to creating auxillary libraries, try the
--- register() methods.
function emu.frameadvance() end

--- Registers a callback function to run immediately after each frame gets
--- emulated. It runs at a similar time as (and slightly before) gui.register
--- callbacks, except unlike with gui.register it doesn't also get called again
--- whenever the screen gets redrawn. Similar caveats as those mentioned in
--- emu.registerbefore apply.
--- @param func function The function to be called after each frame.
function emu.registerafter(func) end

--- Registers a callback function to run immediately before each frame gets
--- emulated. This runs after the next frame's input is known but before it's used,
--- so this is your only chance to set the next frame's input using the next
--- frame's would-be input. For example, if you want to make a script that filters
--- or modifies ongoing user input, such as making the game think "left" is
--- pressed whenever you press "right", you can do it easily with this.
---
--- Note that this is not quite the same as code that's placed before a call to
--- emu.frameadvance. This callback runs a little later than that. Also, you cannot
--- safely assume that this will only be called once per frame. Depending on the
--- emulator's options, every frame may be simulated multiple times and your
--- callback will be called once per simulation. If for some reason you need to
--- use this callback to keep track of a stateful linear progression of things
--- across frames then you may need to key your calculations to the results of
--- emu.framecount.
---
--- Like other callback-registering functions provided by FCEUX, there is only one
--- registered callback at a time per registering function per script. If you
--- register two callbacks, the second one will replace the first, and the call to
--- emu.registerbefore will return the old callback. You may register nil instead
--- of a function to clear a previously-registered callback. If a script returns
--- while it still has registered callbacks, FCEUX will keep it alive to call
--- those callbacks when appropriate, until either the script is stopped by the
--- user or all of the callbacks are de-registered.
--- @param func function The function to be called before each frame.
function emu.registerbefore(func) end

--- Registers a callback function that runs when the script stops. Whether the
--- script stops on its own or the user tells it to stop, or even if the script
--- crashes or the user tries to close the emulator, FCEUX will try to run
--- whatever Lua code you put in here first. So if you want to make sure some code
--- runs that cleans up some external resources or saves your progress to a file
--- or just says some last words, you could put it here. (Of course, a forceful
--- termination of the application or a crash from inside the registered exit
--- function will still prevent the code from running.)
---
--- Suppose you write a script that registers an exit function and then enters an
--- infinite loop. If the user clicks "Stop" your script will be forcefully
--- stopped, but then it will start running its exit function. If your exit
--- function enters an infinite loop too, then the user will have to click "Stop"
--- a second time to really stop your script. That would be annoying. So try to
--- avoid doing too much inside the exit function.
---
--- Note that restarting a script counts as stopping it and then starting it
--- again, so doing so (either by clicking "Restart" or by editing the script
--- while it is running) will trigger the callback. Note also that returning from
--- a script generally does NOT count as stopping (because your script is still
--- running or waiting to run its callback functions and thus does not stop...),
--- even if the exit callback is the only one you have registered.
--- @param func function The function to be called when the script exits.
function emu.registerexit(func) end

--- Executes a power cycle.
function emu.poweron() end

--- Executes a (soft) reset.
function emu.softreset() end

--- Set the emulator to given speed. The mode argument can be one of these:
--- "normal", "nothrottle" (same as turbo on fceux), "turbo", "maximum"
--- @param mode 'normal'|'nothrottle'|'turbo'|'maximum'
function emu.speedmode(mode) end

--- Pauses the emulator.
function emu.pause() end

--- Unpauses the emulator.
function emu.unpause() end

--- Calls given function, restricting its working time to given number of lua
--- cycles. Using this method you can ensure that some heavy operation (like Lua
--- bot) won't freeze FCEUX.
--- @param count number
--- @param func function
function emu.exec_count(count, func) end

--- Windows-only. Calls given function, restricting its working time to given
--- number of milliseconds (approximate). Using this method you can ensure that
--- some heavy operation (like Lua bot) won't freeze FCEUX.
--- @param time number
--- @param func function
function emu.exec_time(time, func) end

--- Toggles the drawing of the sprites and background planes. Set to false or nil
--- to disable a pane, anything else will draw them.
--- @param sprites boolean
--- @param background boolean
function emu.setrenderplanes(sprites, background) end

--- Displays given message on screen in the standard messages position. Use
--- gui.text() when you need to position text.
--- @param message string
function emu.message(message) end

--- Returns the framecount value. The frame counter runs without a movie running
--- so this always returns a value.
--- @return number
function emu.framecount() end

--- Returns the number of lag frames encountered. Lag frames are frames where the
--- game did not poll for input because it missed the vblank. This happens when
--- it has to compute too much within the frame boundary. This returns the number
--- indicated on the lag counter.
--- @return number
function emu.lagcount() end

--- Returns true if currently in a lagframe, false otherwise.
--- @return boolean
function emu.lagged() end

--- Sets current value of lag flag.
--- Some games poll input even in lag frames, so standard way of detecting lag
--- (used by FCEUX and other emulators) does not work for those games, and you
--- have to determine lag frames manually.
--- First, find RAM addresses that help you distinguish between lag and non-lag
--- frames (e.g. an in-game frame counter that only increments in non-lag
--- frames). Then register memory hooks that will change lag flag when needed.
--- @param value boolean
function emu.setlagflag(value) end

--- Returns true if emulation has started, or false otherwise. Certain operations
--- such as using savestates are invalid to attempt before emulation has started.
--- You probably won't need to use this function unless you want to make your
--- script extra-robust to being started too early.
--- @return boolean
function emu.emulating() end

--- Returns true if emulator is paused, false otherwise.
--- @return boolean
function emu.paused() end

--- Returns whether the emulator is in read-only state.
--- While this variable only applies to movies, it is stored as a global variable
--- and can be modified even without a movie loaded. Hence, it is in the emu
--- library rather than the movie library.
--- @return boolean
function emu.readonly() end

--- Sets the read-only status to read-only if argument is true and read+write if
--- false.
--- Note: This might result in an error if the medium of the movie file is not
--- writeable (such as in an archive file).
--- While this variable only applies to movies, it is stored as a global variable
--- and can be modified even without a movie loaded. Hence, it is in the emu
--- library rather than the movie library.
--- @param state boolean
function emu.setreadonly(state) end

--- Returns the path of fceux.exe as a string.
--- @return string
function emu.getdir() end

--- Loads the ROM from the directory relative to the lua script or from the
--- absolute path. Hence, the filename parameter can be absolute or relative path.
--- If the ROM can't be loaded, loads the most recent one.
--- @param filename string
function emu.loadrom(filename) end

--- Adds a Game Genie code to the Cheats menu. Returns false and an error message
--- if the code can't be decoded. Returns false if the code couldn't be added.
--- Returns true if the code already existed, or if it was added.
--- Usage: emu.addgamegenie("NUTANT")
--- Note that the Cheats Dialog Box won't show the code unless you close and reopen
--- it.
--- @param str string
--- @return boolean
function emu.addgamegenie(str) end

--- Removes a Game Genie code from the Cheats menu. Returns false and an error
--- message if the code can't be decoded. Returns false if the code couldn't be
--- deleted. Returns true if the code didn't exist, or if it was deleted.
--- Usage: emu.delgamegenie("NUTANT")
--- Note that the Cheats Dialog Box won't show the code unless you close and
--- reopen it.
--- @param str string
--- @return boolean
function emu.delgamegenie(str) end

--- Puts a message into the Output Console area of the Lua Script control window.
--- Useful for displaying usage instructions to the user when a script gets run.
--- @param str string
function emu.print(str) end

--- Returns the separate RGB components of the given screen pixel, and the
--- palette. Can be 0-255 by 0-239, but NTSC only displays 0-255 x 8-231 of it.
--- If getemuscreen is false, this gets background colors from either the screen
--- pixel or the LUA pixels set, but LUA data may not match the information used
--- to put the data to the screen. If getemuscreen is true, this gets background
--- colors from anything behind an LUA screen element.
--- Usage is local r,g,b,palette = emu.getscreenpixel(5, 5, false) to retrieve
--- the current red/green/blue colors and palette value of the pixel at 5x5.
--- Palette value can be 0-63, or 254 if there was an error.
--- You can avoid getting LUA data by putting the data into a function, and
--- feeding the function name to emu.registerbefore.
--- @param x number
--- @param y number
--- @param getemuscreen boolean
--- @return number, number, number, number
function emu.getscreenpixel(x, y, getemuscreen) end

--- Closes FCEUX. Useful for run-and-close scripts like automatic screenshots
--- taking.
function emu.exit() end


bit = {}

--- Bitwise AND
--- @param a number
--- @param b number
--- @return number
function bit.band(a, b) end

--- Bitwise OR
--- @param a number
--- @param b number
--- @return number
function bit.bor(a, b) end

--- Bitwise left shift
--- @param x number
--- @param amt number
--- @return number
function bit.lshift(x, amt) end

--- Bitwise right shift
--- @param x number
--- @param amt number
--- @return number
function bit.rshift(x, amt) end

--- Binary logical AND of all the given integers.
--- @vararg number
--- @return number
function AND(...) end

--- Binary logical OR of all the given integers.
--- @vararg number
--- @return number
function OR(...) end

--- Binary logical XOR of all the given integers.
--- @vararg number
--- @return number
function XOR(...) end

--- Returns an integer with the given bits turned on. Parameters should be
--- smaller than 31.
--- @vararg number
--- @return number
function BIT(...) end


rom = {}

--- Get the base filename of the ROM loaded.
--- @return string
function rom.getfilename() end

--- Get a hash of the ROM loaded, for verification. If type is "md5", returns a
--- hex string of the MD5 hash. If type is "base64", returns a base64 string of
--- the MD5 hash, just like the movie romChecksum value.
--- @param type 'md5'|'base64'
--- @return string
function rom.gethash(type) end

--- Get an unsigned byte from the actual ROM file at the given address.
--- This includes the header! It's the same as opening the file in a hex-editor.
--- @param address number
--- @return number
function rom.readbyte(address) end

--- test
rom.readbyteunsigned = rom.readbyte

--- Get a signed byte from the actual ROM file at the given address. Returns a
--- byte that is signed.
--- This includes the header! It's the same as opening the file in a hex-editor.
--- @param address number
--- @return number
function rom.readbytesigned(address) end

--- Write the value to the ROM at the given address. The value is modded with 256
--- before writing (so writing 257 will actually write 1). Negative values
--- allowed.
--- Editing the header is not available.
--- @param address number
--- @param value number
function rom.writebyte(address, value) end


memory = {}

--- Get an unsigned byte from the RAM at the given address. Returns a byte
--- regardless of emulator. The byte will always be positive.
--- @param address number
--- @return number
function memory.readbyte(address) end

memory.readbyteunsigned = memory.readbyte

--- Get a length bytes starting at the given address and return it as a string.
--- Convert to table to access the individual bytes.
--- @param address number
--- @param length number
--- @return string
function memory.readbyterange(address, length) end

--- Get a signed byte from the RAM at the given address. Returns a byte
--- regardless of emulator. The most significant bit will serve as the sign.
--- @param address number
--- @return number
function memory.readbytesigned(address) end

--- Get an unsigned word from the RAM at the given address. Returns a 16-bit
--- value regardless of emulator. The value will always be positive.
--- If you only provide a single parameter (addressLow), the function treats it as
--- address of little-endian word. if you provide two parameters, the function
--- reads the low byte from addressLow and the high byte from addressHigh, so you
--- can use it in games which like to store their variables in separate form (a
--- lot of NES games do).
--- @param addressLow number
--- @param addressHigh number | nil
--- @return number
function memory.readword(addressLow, addressHigh) end

memory.readwordunsigned = memory.readword

--- The same as memory.readword, except the returned value is signed, i.e. its
--- most significant bit will serve as the sign.
--- @param addressLow number
--- @param addressHigh number | nil
--- @return number
function memory.readwordsigned(addressLow, addressHigh) end

--- Write the value to the RAM at the given address. The value is modded with 256
--- before writing (so writing 257 will actually write 1). Negative values
--- allowed.
--- @param address number
--- @param value number
function memory.writebyte(address, value) end

--- Returns the current value of the given hardware register.
--- For example, memory.getregister("pc") will return the main CPU's current
--- Program Counter.
--- Valid registers are: "a", "x", "y", "s", "p", and "pc".
--- @param cpuregistername 'a'|'A'|'x'|'X'|'y'|'Y'|'s'|'S'|'p'|'P'|'pc'|'PC'
--- @return number
function memory.getregister(cpuregistername) end

--- Sets the current value of the given hardware register.
--- For example, memory.setregister("pc",0x200) will change the main CPU's
--- current Program Counter to 0x200.
--- Valid registers are: "a", "x", "y", "s", "p", and "pc".
--- You had better know exactly what you're doing or you're probably just going
--- to crash the game if you try to use this function. That applies to the other
--- memory.write functions as well, but to a lesser extent.
--- @param cpuregistername 'a'|'A'|'x'|'X'|'y'|'Y'|'s'|'S'|'p'|'P'|'pc'|'PC'
--- @param value number
function memory.setregister(cpuregistername, value) end

--- Registers a function to be called immediately whenever the given memory
--- address range is read from/written to.
--- address is the address in CPU address space (0x0000 - 0xFFFF).
--- size is the number of bytes to "watch". For example, if size is 100 and
--- address is 0x0200, then you will register the function across all 100 bytes
--- from 0x0200 to 0x0263. A write to any of those bytes will trigger the
--- function. Having callbacks on a large range of memory addresses can be
--- expensive, so try to use the smallest range that's necessary for whatever it
--- is you're trying to do. If you don't specify any size then it defaults to 1.
--- The callback function will receive three arguments (address, size, value)
--- indicating what write operation triggered the callback. If you don't care
--- about that extra information then you can ignore it and define your callback
--- function to not take any arguments. Since 6502 writes are always single byte,
--- the "size" argument will always be 1.
--- You may use a memory.write function from inside the callback to change the
--- value that just got written. However, keep in mind that doing so will trigger
--- your callback again, so you must have a "base case" such as checking to make
--- sure that the value is not already what you want it to be before writing it.
--- Another, more drastic option is to de-register the current callback before
--- performing the write.
--- If func is nil that means to de-register any memory write callbacks that the
--- current script has already registered on the given range of bytes.
--- @overload fun(address: number, func: function|nil)
--- @overload fun(address: number, size: number, func: function|nil)
function memory.register(address, size, func) end

memory.registerread = memory.register

memory.registerwrite = memory.register

--- Registers a function to be called immediately whenever the emulated system
--- runs code located in the given memory address range.
--- Since "address" is the address in CPU address space (0x0000 - 0xFFFF), this
--- doesn't take ROM banking into account, so the callback will be called for any
--- bank, and in some cases you'll have to check current bank in your callback
--- function.
--- The information about memory.register applies to this function as well. The
--- callback will receive the same three arguments, though the "value" argument
--- will always be 0.
--- @overload fun(address: number, func: function|nil)
--- @overload fun(address: number, size: number, func: function|nil)
function memory.registerexec(address, size, func) end


joypad = {}

--- Returns a table of every game button, where each entry is true if that button
--- is currently held (as of the last time the emulation checked), or false if it
--- is not held. This takes keyboard inputs, not Lua. The table keys look like
--- this (case sensitive):
--- up, down, left, right, A, B, start, select
--- Where a Lua truthvalue true means that the button is set, false means the
--- button is unset. Note that only "false" and "nil" are considered a false
--- value by Lua. Anything else is true, even the number 0.
--- @param player 1|2
--- @return table<string, boolean>
function joypad.get(player) end

--- joypad.read left in for backwards compatibility with older versions of
--- FCEU/FCEUX.
joypad.read = joypad.get

--- Returns a table of every game button, where each entry is true if that button
--- is held at the moment of calling the function, or false if it is not held.
--- This function polls keyboard input immediately, allowing Lua to interact with
--- user even when emulator is paused.
--- As of FCEUX 2.2.0, the function only works in Windows. In Linux this function
--- will return nil.
--- @param player 1|2
--- @return table<string, boolean>
function joypad.getimmediate(player) end

joypad.readimmediate = joypad.getimmediate

--- Returns a table of only the game buttons that are currently held. Each entry
--- is true if that button is currently held (as of the last time the emulation
--- checked), or nil if it is not held.
--- @param player 1|2
--- @return table<string, boolean>
function joypad.getdown(player) end

joypad.readdown = joypad.getdown

--- Returns a table of only the game buttons that are not currently held. Each
--- entry is nil if that button is currently held (as of the last time the
--- emulation checked), or false if it is not held.
--- @param player 1|2
--- @return table<string, boolean>
function joypad.getup(player) end

joypad.readup = joypad.getup

--- Set the inputs for the given player. Table keys look like this (case
--- sensitive):
--- up, down, left, right, A, B, start, select
--- There are 4 possible values: true, false, nil, and "invert".
--- true - Forces the button on
--- false - Forces the button off
--- nil - User's button press goes through unchanged
--- "invert" - Reverses the user's button press
--- Any string works in place of "invert". It is suggested as a convention to use
--- "invert" for readability, but strings like "inv", "Weird switchy mechanism",
--- "", or "true or false" works as well as "invert".
--- nil and "invert" exists so the script can control individual buttons of the
--- controller without entirely blocking the user from having any control. Perhaps
--- there is a process which can be automated by the script, like an optimal
--- firing pattern, but the user still needs some manual control, such as moving
--- the character around.
--- @param player 1|2
--- @param input table<string, boolean|nil|'invert'>
function joypad.set(player, input) end

--- joypad.write left in for backwards compatibility with older versions of
--- FCEU/FCEUX.
joypad.write = joypad.set

gui = {}

--- Draw one pixel of a given color at the given position on the screen.
--- @param x number
--- @param y number
--- @param color any
function gui.pixel(x, y, color) end

gui.drawpixel = gui.pixel

gui.setpixel = gui.pixel

gui.writepixel = gui.pixel

--- Returns the separate RGBA components of the given pixel set by gui.pixel.
--- This only gets LUA pixels set, not background colors.
--- Usage is local r,g,b,a = gui.getpixel(5, 5) to retrieve the current
--- red/green/blue/alpha values of the LUA pixel at 5x5.
--- See emu.getscreenpixel() for an emulator screen variant.
--- @param x number
--- @param y number
--- @return number, number, number, number
function gui.getpixel(x, y) end

--- Draws a line between the two points. The x1,y1 coordinate specifies one end
--- of the line segment, and the x2,y2 coordinate specifies the other end. If
--- skipfirst is true then this function will not draw anything at the pixel
--- x1,y1, otherwise it will. skipfirst is optional and defaults to false. The
--- default color for the line is solid white, but you may optionally override
--- that using a color of your choice.
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param color any
--- @param skipfirst boolean | nil
function gui.line(x1, y1, x2, y2, color, skipfirst) end

gui.drawline = gui.line

--- Draws a rectangle between the given coordinates of the emulator screen for
--- one frame. The x1,y1 coordinate specifies any corner of the rectangle
--- (preferably the top-left corner), and the x2,y2 coordinate specifies the
--- opposite corner.
--- The default color for the box is transparent white with a solid white
--- outline, but you may optionally override those using colors of your choice.
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param fillcolor any
--- @param outlinecolor any
function gui.box(x1, y1, x2, y2, fillcolor, outlinecolor) end

gui.drawbox = gui.box

gui.rect = gui.box

gui.drawrect = gui.box

--- Draws a given string at the given position. textcolor and backcolor are
--- optional. See 'on colors' at the end of this page for information. Using nil
--- as the input or not including an optional field will make it use the default.
--- @param x number
--- @param y number
--- @param str string
--- @param textcolor any
--- @param backcolor any
function gui.text(x, y, str, textcolor, backcolor) end

gui.drawtext = gui.text

--- Returns the separate RGBA components of the given color.
--- For example, you can say local r,g,b,a = gui.parsecolor('orange') to retrieve
--- the red/green/blue values of the preset color orange. (You could also omit
--- the a in cases like this.) This uses the same conversion method that FCEUX
--- uses internally to support the different representations of colors that the
--- GUI library uses. Overriding this function will not change how FCEUX
--- interprets color values, however.
--- @param color any
--- @return number, number, number, number
function gui.parsecolor(color) end

--- Makes a screenshot of the FCEUX emulated screen, and saves it to the
--- appropriate folder. Performs identically to pressing the Screenshot hotkey.
function gui.savescreenshot() end

--- Makes a screenshot of the FCEUX emulated screen, and saves it to the
--- appropriate folder. However, this one receives a file name for the screenshot.
--- @param name string
function gui.savescreenshotas(name) end

--- Takes a screen shot of the image and returns it in the form of a string which
--- can be imported by the gd library using the gd.createFromGdStr() function.
--- This function is provided so as to allow FCEUX to not carry a copy of the gd
--- library itself. If you want raw RGB32 access, skip the first 11 bytes
--- (header) and then read pixels as Alpha (always 0), Red, Green, Blue, left to
--- right then top to bottom, range is 0-255 for all colors.
--- If getemuscreen is false, this gets background colors from either the screen
--- pixel or the Lua pixels set, but Lua data may not match the information used
--- to put the data to the screen. If getemuscreen is true, this gets background
--- colors from anything behind a Lua screen element.
--- Warning: Storing screen shots in memory is not recommended. Memory usage will
--- blow up pretty quick. One screen shot string eats around 230 KB of RAM.
--- @param getemuscreen boolean
--- @return string
function gui.gdscreenshot(getemuscreen) end

--- Draws an image on the screen. gdimage must be in truecolor gd string format.
--- Transparency is fully supported. Also, if alphamul is specified then it will
--- modulate the transparency of the image even if it's originally fully opaque.
--- (alphamul=1.0 is normal, alphamul=0.5 is doubly transparent, alphamul=3.0 is
--- triply opaque, etc.)
--- dx,dy determines the top-left corner of where the image should draw. If they
--- are omitted, the image will draw starting at the top-left corner of the
--- screen.
--- gui.gdoverlay is an actual drawing function (like gui.box and friends) and
--- thus must be called every frame, preferably inside a gui.register'd function,
--- if you want it to appear as a persistent image onscreen.
--- @param dx number | nil
--- @param dy number | nil
--- @param str string
--- @param sx number | nil
--- @param sy number | nil
--- @param sw number | nil
--- @param sh number | nil
--- @param alphamul number | nil
function gui.gdoverlay(dx, dy, str, sx, sy, sw, sh, alphamul) end

gui.image = gui.gdoverlay

gui.drawimage = gui.gdoverlay

--- Scales the transparency of subsequent draw calls. An alpha of 0.0 means
--- completely transparent, and an alpha of 1.0 means completely unchanged
--- (opaque). Non-integer values are supported and meaningful, as are values
--- greater than 1.0. It is not necessary to use this function (or the
--- less-recommended gui.transparency) to perform drawing with transparency,
--- because you can provide an alpha value in the color argument of each draw
--- call. However, it can sometimes be convenient to be able to globally modify
--- the drawing transparency.
--- @param alpha number
function gui.opacity(alpha) end

--- Scales the transparency of subsequent draw calls. Exactly the same as
--- gui.opacity, except the range is different: A trans of 4.0 means completely
--- transparent, and a trans of 0.0 means completely unchanged (opaque).
--- @param trans number
function gui.transparency(trans) end

--- Register a function to be called between a frame being prepared for
--- displaying on your screen and it actually happening. Used when that 1 frame
--- delay for rendering is not acceptable.
--- @param func? function
function gui.register(func) end

--- Brings up a modal popup dialog box (everything stops until the user dismisses
--- it). The box displays the message tostring(msg). This function returns the
--- name of the button the user clicked on (as a string).
--- type determines which buttons are on the dialog box, and it can be one of the
--- following: 'ok', 'yesno', 'yesnocancel', 'okcancel', 'abortretryignore'.
--- type defaults to 'ok' for gui.popup, or to 'yesno' for input.popup.
--- icon indicates the purpose of the dialog box (or more specifically it dictates
--- which title and icon is displayed in the box), and it can be one of the
--- following: 'message', 'question', 'warning', 'error'.
--- icon defaults to 'message' for gui.popup, or to 'question' for input.popup.
--- Try to avoid using this function much if at all, because modal dialog boxes
--- can be irritating.
--- Linux users might want to install xmessage to perform the work. Otherwise the
--- dialog will appear on the shell and that's less noticeable.
--- @param message string
--- @param type 'ok'|'yesno'|'yesnocancel'|'okcancel'|'abortretryignore' | nil
--- @param icon 'message'|'question'|'warning'|'error' | nil
--- @return string
function gui.popup(message, type, icon) end

ppu = {}

--- Get an unsigned byte from the PPU at the given address. Returns a byte
--- regardless of emulator. The byte will always be positive.
--- @param address number
--- @return number
function ppu.readbyte(address) end

--- Get a length bytes starting at the given address and return it as a string.
--- Convert to table to access the individual bytes.
--- @param address number
--- @param length number
--- @return string
function ppu.readbyterange(address, length) end

--- @class InputState
--- @field xmouse number
--- @field ymouse number
--- @field leftclick boolean | nil
--- @field rightclick boolean | nil
--- @field middleclick boolean | nil
--- @field capslock boolean | nil
--- @field numlock boolean | nil
--- @field scrolllock boolean | nil
--- @field ["0"] boolean | nil
--- @field ["1"] boolean | nil
--- @field ["2"] boolean | nil
--- @field ["3"] boolean | nil
--- @field ["4"] boolean | nil
--- @field ["5"] boolean | nil
--- @field ["6"] boolean | nil
--- @field ["7"] boolean | nil
--- @field ["8"] boolean | nil
--- @field ["9"] boolean | nil
--- @field A boolean | nil
--- @field B boolean | nil
--- @field C boolean | nil
--- @field D boolean | nil
--- @field E boolean | nil
--- @field F boolean | nil
--- @field G boolean | nil
--- @field H boolean | nil
--- @field I boolean | nil
--- @field J boolean | nil
--- @field K boolean | nil
--- @field L boolean | nil
--- @field M boolean | nil
--- @field N boolean | nil
--- @field O boolean | nil
--- @field P boolean | nil
--- @field Q boolean | nil
--- @field R boolean | nil
--- @field S boolean | nil
--- @field T boolean | nil
--- @field U boolean | nil
--- @field V boolean | nil
--- @field W boolean | nil
--- @field X boolean | nil
--- @field Y boolean | nil
--- @field Z boolean | nil
--- @field F1 boolean | nil
--- @field F2 boolean | nil
--- @field F3 boolean | nil
--- @field F4 boolean | nil
--- @field F5 boolean | nil
--- @field F6 boolean | nil
--- @field F7 boolean | nil
--- @field F8 boolean | nil
--- @field F9 boolean | nil
--- @field F10 boolean | nil
--- @field F11 boolean | nil
--- @field F12 boolean | nil
--- @field F13 boolean | nil
--- @field F14 boolean | nil
--- @field F15 boolean | nil
--- @field F16 boolean | nil
--- @field F17 boolean | nil
--- @field F18 boolean | nil
--- @field F19 boolean | nil
--- @field F20 boolean | nil
--- @field F21 boolean | nil
--- @field F22 boolean | nil
--- @field F23 boolean | nil
--- @field F24 boolean | nil
--- @field backspace boolean | nil
--- @field tab boolean | nil
--- @field enter boolean | nil
--- @field shift boolean | nil
--- @field control boolean | nil
--- @field alt boolean | nil
--- @field pause boolean | nil
--- @field escape boolean | nil
--- @field space boolean | nil
--- @field pageup boolean | nil
--- @field pagedown boolean | nil
--- @field end boolean | nil
--- @field home boolean | nil
--- @field left boolean | nil
--- @field up boolean | nil
--- @field right boolean | nil
--- @field down boolean | nil
--- @field numpad0 boolean | nil
--- @field numpad1 boolean | nil
--- @field numpad2 boolean | nil
--- @field numpad3 boolean | nil
--- @field numpad4 boolean | nil
--- @field numpad5 boolean | nil
--- @field numpad6 boolean | nil
--- @field numpad7 boolean | nil
--- @field numpad8 boolean | nil
--- @field numpad9 boolean | nil
--- @field ["numpad*"] boolean | nil
--- @field insert boolean | nil
--- @field delete boolean | nil
--- @field ["numpad+"] boolean | nil
--- @field ["numpad-"] boolean | nil
--- @field ["numpad."] boolean | nil
--- @field ["numpad/"] boolean | nil
--- @field semicolon boolean | nil
--- @field plus boolean | nil
--- @field minus boolean | nil
--- @field comma boolean | nil
--- @field period boolean | nil
--- @field slash boolean | nil
--- @field backslash boolean | nil
--- @field tilde boolean | nil
--- @field quote boolean | nil
--- @field leftbracket boolean | nil
--- @field rightbracket boolean | nil
input = {}

--- Reads input from keyboard and mouse. Returns pressed keys and the position of
--- mouse in pixels on game screen.
--- @return InputState
function input.get() end

input.read = input.get

input.popup = gui.popup

--- @class savestate_object
local savestate_object = {}

savestate = {}

--- Create a new savestate object. Optionally you can save the current state to
--- one of the predefined slots(1-10) using the range 1-9 for slots 1-9, and 10
--- for 0, QWERTY style. Using no number will create an "anonymous" savestate.
--- Note that this does not actually save the current state! You need to create
--- this value and pass it on to the load and save functions in order to save it.
--- Anonymous savestates are temporary, memory only states. You can make them
--- persistent by calling memory.persistent(state). Persistent anonymous states
--- are deleted from disk once the script exits.
--- @param slot number | nil
--- @return savestate_object
function savestate.object(slot) end

--- savestate.create is identical to savestate.object, except for the numbering
--- for predefined slots(1-10, 1 refers to slot 0, 2-10 refer to 1-9). It's being
--- left in for compatibility with older scripts, and potentially for platforms
--- with different internal predefined slot numbering.
--- @param slot number | nil
--- @return savestate_object
function savestate.create(slot) end

--- Save the current state object to the given savestate. The argument is the
--- result of savestate.create(). You can load this state back up by calling
--- savestate.load(savestate) on the same object.
--- @param savestate savestate_object
function savestate.save(savestate) end

--- Load the the given state. The argument is the result of savestate.create()
--- and has been passed to savestate.save() at least once.
--- If this savestate is not persistent and not one of the predefined states, the
--- state will be deleted after loading.
--- @param savestate savestate_object
function savestate.load(savestate) end

--- Set the given savestate to be persistent. It will not be deleted when you
--- load this state but at the exit of this script instead, unless it's one of
--- the predefined states. If it is one of the predefined savestates it will be
--- saved as a file on disk.
--- @param savestate savestate_object
function savestate.persist(savestate) end

--- Registers a callback function that runs whenever the user saves a state. This
--- won't actually be called when the script itself makes a savestate, so none of
--- those endless loops due to a misplaced savestate.save.
--- As with other callback-registering functions provided by FCEUX, there is only
--- one registered callback at a time per registering function per script. Upon
--- registering a second callback, the first is kicked out to make room for the
--- second. In this case, it will return the first function instead of nil,
--- letting you know what was kicked out. Registering nil will clear the
--- previously-registered callback.
--- @param func function
function savestate.registersave(func) end

--- Registers a callback function that runs whenever the user loads a previously
--- saved state. It's not called when the script itself loads a previous state, so
--- don't worry about your script interrupting itself just because it's loading
--- something.
--- The state's data is loaded before this function runs, so you can read the RAM
--- immediately after the user loads a state, or check the new framecount.
--- Particularly useful if you want to update lua's display right away instead of
--- showing junk from before the loadstate.
--- @param func function
function savestate.registerload(func) end

--- Accuracy not yet confirmed.
--- Intended Function, according to snes9x LUA documentation:
--- Returns the data associated with the given savestate (data that was earlier
--- returned by a registered save callback) without actually loading the rest of
--- that savestate or calling any callbacks. location should be a save slot
--- number.
--- @param location number
function savestate.loadscriptdata(location) end


movie = {}

--- Loads and plays a movie from the directory relative to the Lua script or from
--- the absolute path. If read_only is true, the movie will be loaded in
--- read-only mode. The default is read+write.
--- A pauseframe can be specified, which controls which frame will auto-pause the
--- movie. By default, this is off. A true value is returned if the movie loaded
--- correctly.
--- @param filename string
--- @param read_only boolean | nil
--- @param pauseframe number | nil
--- @return boolean
function movie.play(filename, read_only, pauseframe) end

movie.playback = movie.play

movie.load = movie.play

--- Starts recording a movie, using the filename, relative to the Lua script.
--- An optional save_type can be specified. If set to 0 (default), it will record
--- from a power on state, and automatically do so. This is the recommended
--- setting for creating movies. This can also be set to 1 for savestate or 2
--- for saveram movies.
--- A third parameter specifies an author string. If included, it will be
--- recorded into the movie file.
--- @param filename string
--- @param save_type 0|1|2|nil
--- @param author string | nil
--- @return boolean
function movie.record(filename, save_type, author) end

movie.save = movie.record

--- Returns true if a movie is currently loaded and false otherwise. (This should
--- be used to guard against Lua errors when attempting to retrieve movie
--- information).
--- @return boolean
function movie.active() end

--- Returns the current frame count. (Has the same affect as emu.framecount)
--- @return number
function movie.framecount() end

--- Returns the current state of movie playback. Returns one of the following:
--- "record", "playback", "finished", "taseditor", nil
--- @return 'record'|'playback'|'finished'|'taseditor'|nil
function movie.mode() end

--- Turn the rerecord counter on or off. Allows you to do some brute forcing
--- without inflating the rerecord count.
--- @param counting boolean
function movie.rerecordcounting(counting) end

--- Stops movie playback. If no movie is loaded, it throws a Lua error.
function movie.stop() end

movie.close = movie.stop

--- Returns the total number of frames of the current movie. Throws a Lua error
--- if no movie is loaded.
--- @return number
function movie.length() end

--- Returns the filename of the current movie with path. Throws a Lua error if no
--- movie is loaded.
--- @return string
function movie.name() end

movie.getname = movie.name

--- Returns the filename of the current movie with no path. Throws a Lua error if
--- no movie is loaded.
--- @return string
function movie.getfilename() end

--- Returns the rerecord count of the current movie. Throws a Lua error if no
--- movie is loaded.
--- @return number
function movie.rerecordcount() end

--- Performs the Play from Beginning function. Movie mode is switched to
--- read-only and the movie loaded will begin playback from frame 1.
--- If no movie is loaded, no error is thrown and no message appears on screen.
function movie.replay() end

movie.playbeginning = movie.replay

--- FCEUX keeps the read-only status even without a movie loaded.
--- Returns whether the emulator is in read-only state.
--- While this variable only applies to movies, it is stored as a global variable
--- and can be modified even without a movie loaded. Hence, it is in the emu
--- library rather than the movie library.
--- @return boolean
function movie.readonly() end

movie.getreadonly = movie.readonly

movie.setreadonly = emu.setreadonly

--- Returns true if there is a movie loaded and in record mode.
--- @return boolean
function movie.recording() end

--- Returns true if there is a movie loaded and in play mode.
--- @return boolean
function movie.playing() end

--- Returns true if the movie recording or loaded started from 'Start'.
--- Returns false if the movie uses a save state.
--- Opposite of movie.isfromsavestate()
--- @return boolean
function movie.ispoweron() end

--- Returns true if the movie recording or loaded started from 'Now'.
--- Returns false if the movie was recorded from a reset.
--- Opposite of movie.ispoweron()
--- @return boolean
function movie.isfromsavestate() end

--- FCEUX passes arguments as one big string instead of the standard table.
arg = ""

debugger = {}

--- Simulates a breakpoint hit, pauses emulation and brings up the Debugger window.
--- Use this function in your handlers of custom breakpoints.
function debugger.hitbreakpoint() end

--- Returns an integer value representing the number of CPU cycles elapsed since the
--- poweron or since the last reset of the cycles counter.
--- @return integer
function debugger.getcyclescount() end

--- Returns an integer value representing the number of CPU instructions executed
--- since the poweron or since the last reset of the instructions counter.
--- @return integer
function debugger.getinstructionscount() end

--- Resets the cycles counter.
function debugger.resetcyclescount() end

--- Resets the instructions counter.
function debugger.resetinstructionscount() end

--- Gets the offset (usually the CPU address) of a debug symbol.
--- Returns -1 if the symbol is not found.
--- @param name string
--- @param bank integer | nil
--- @return integer
function debugger.getsymboloffset(name, bank) end


taseditor = {}

--- Registers a callback function ("Auto Function") that runs periodically. The Auto
--- Function can be registered and will be called even when TAS Editor isn't
--- engaged.
--- When FCEUX is unpaused, your function will be called at the end of every frame
--- (running 60 times per second on NTSC and 50 times per second on PAL).
--- When FCEUX is paused, your function will be called 20 times per second.
--- User can switch on/off auto-calling by checking "Auto function" checkbox in TAS
--- Editor GUI.
--- Like other callback-registering functions provided by FCEUX, there is only one
--- registered callback at a time per registering function per script. If you
--- register two callbacks, the second one will replace the first, and the call to taseditor.registerauto() will return the old callback. You may register nil instead of a function to clear a previously-registered callback.
--- If a script returns while it still has registered callbacks, FCEUX will keep it
--- alive to call those callbacks when appropriate, until either the script is
--- stopped by the user or all of the callbacks are de-registered.
--- @param func function
function taseditor.registerauto(func) end

--- Registers a callback function ("Manual Function") that can be called manually by
--- TAS Editor user. The function can be registered even when TAS Editor isn't
--- engaged.
--- The Manual function doesn't depend on paused or unpaused FCEUX status. It will
--- be called once every time user presses Run function button in TAS Editor GUI.
--- You can provide a new name for this button.
--- The Manual function cannot be run more often than TAS Editor window updates
--- (60/50 FPS or 20FPS when emulator is paused).
--- In FCEUX code Manual function runs right after Auto Function.
--- You can use this feature to create new tools for TAS Editor. For example, you
--- can write a script that reverses currently selected input, so user will be able to
--- reverse input by selecting a range and clicking Run function button.
--- Like other callback-registering functions provided by FCEUX, there is only one
--- registered callback at a time per registering function per script. If you
--- register two callbacks, the second one will replace the first, and the call to taseditor.registermanual() will return the old callback. You may call taseditor.registermanual(nil) to clear a previously-registered callback.
--- If a script returns while it still has registered callbacks, FCEUX will keep it
--- alive to call those callbacks when appropriate, until either the script is
--- stopped by the user or all of the callbacks are de-registered.
--- @param func function
--- @param name string?
function taseditor.registermanual(func, name) end

--- Returns true if TAS Editor is currently engaged, false if otherwise.
--- Also when TAS Editor is engaged, movie.mode() returns "taseditor" string.
--- @return boolean
function taseditor.engaged() end

--- Returns true if given frame is marked in TAS Editor, false if not marked.
--- If TAS Editor is not engaged, returns false.
--- @param frame number
--- @return boolean
function taseditor.markedframe(frame) end

--- Returns index number of the Marker under which given frame is located.
--- Returns -1 if TAS Editor is not engaged.
--- @param frame number
--- @return number
function taseditor.getmarker(frame) end

--- Sets Marker on given frame. Returns index number of the Marker created.
--- If that frame is already marked, no changes will be made, and the function will
--- return the index number of existing Marker.
--- You can set markers even outside input range.
--- If TAS Editor is not engaged, returns -1.
--- @param frame number
--- @return number
function taseditor.setmarker(frame) end

--- Removes marker from given frame. If that frame was not marked, no changes will
--- be made.
--- If TAS Editor is not engaged, no changes will be made.
--- @param frame number
function taseditor.removemarker(frame) end

--- Returns string representing the Note of given Marker.
--- Returns nil if TAS Editor is not engaged.
--- If given index is invalid (if Marker with this index number doesn't exist),
--- returns note of the zeroth marker.
--- @param index number
--- @return string
function taseditor.getnote(index) end

--- Sets text of the Note of given Marker.
--- If given index is invalid (if Marker with this index number doesn't exist), no
--- changes will be made.
--- If TAS Editor is not engaged, no changes will be made.
--- @param index number
--- @param newtext string
function taseditor.setnote(index, newtext) end

--- Returns number from 0 to 9 representing current Branch.
--- Returns -1 if there's no Branches or if TAS Editor is not engaged.
--- @return number
function taseditor.getcurrentbranch() end

--- Returns string representing current recorder mode.
--- • "All"
--- • "1P"
--- • "2P"
--- • "3P"
--- • "4P"
--- Returns nil if TAS Editor is not engaged.
--- When you want to check Recorder's read-only state, use emu.readonly().
--- @return string
function taseditor.getrecordermode() end

--- Returns number representing current state of Superimpose checkbox in TAS Editor
--- GUI.
--- 0 – unchecked
--- 1 – checked
--- 2 – indeterminate (you can interpret is as half-checked)
--- If TAS Editor is not engaged, returns -1.
--- @return number
function taseditor.getsuperimpose() end

--- Returns the number of the frame where Playback cursor was before input was
--- changed.
--- If Playback didn't lose position during Greenzone invalidation, returns -1.
--- If TAS Editor is not engaged, returns -1.
--- @return number
function taseditor.getlostplayback() end

--- If TAS Editor's Playback is currently seeking, returns number of target frame.
--- If Playback is not seeking or if TAS Editor is not engaged, returns -1.
--- @return number
function taseditor.getplaybacktarget() end

--- Sends Playback cursor (current frame counter) to given frame.
--- If given frame wasn't found in TAS Editor Greenzone, starts seeking to the
--- frame.
--- If TAS Editor is not engaged, nothing will be done.
--- @param frame number
function taseditor.setplayback(frame) end

--- Stops Playback seeking and pauses emulation.
--- If Playback wasn't seeking, this function only pauses emulation.
--- If TAS Editor is not engaged, nothing will be done.
function taseditor.stopseeking() end

--- Returns a table (array) containing numbers of currently selected frames. These
--- numbers are sorted in ascending order.
--- If no frames are selected at the moment, returns nil.
--- If TAS Editor is not engaged, returns nil.
--- @return table
function taseditor.getselection() end

--- Changes current selection to the given set of frames. Frame number in your table
--- don't have to be sorted.
--- Call taseditor.setselection(nil) to clear selection.
--- If TAS Editor is not engaged, nothing will be done.
--- @param new_set table
function taseditor.setselection(new_set) end

--- Returns a number representing input of given joypad stored in current movie at
--- given frame.
--- If given frame is negative, returns -1.
--- If given frame is outside current input range, returns 0, which can be
--- interpreted as a blank frame (no buttons pressed at this frame yet).
--- Joypad value must be one of the following:
--- 0 – to get hardware commands (bit 0 = reset, bit 1 = poweron, bit 2 = FDS insert
--- disk, bit 3 = FDS switch side)
--- 1 – to get 1P buttons (bit 0 = A, bit 1 = B, bit 2 = Select, bit 3 = Start, bit 4 = Up, bit 5 = Down, bit 6 = Left, bit 7 = Right)
--- 2 – to get 2P buttons
--- 3 – to get 3P buttons
--- 4 – to get 4P buttons
--- You should handle returned number (if it's not equal to -1) as a byte, each bit
--- corresponds to one button (e.g. if bit 1 is set that means A button is pressed).
--- Use Bitwise Operations to retrieve the state of specific buttons.
--- If given joypad is outside [0-4] range, returns -1.
--- If TAS Editor is not engaged, returns -1.
--- @param frame number
--- @param joypad number
--- @return number
function taseditor.getinput(frame, joypad) end

--- Sends request to TAS Editor asking to change input of given joypad at given
--- frame.
--- Actual movie input won't be changed until the moment you call taseditor.applyinputchanges().
--- Using several consecutive requests and then calling applyinputchanges() at the end, you can change several frames of current movie in one moment.
--- When applying the pile of requests, TAS Editor will execute them in consecutive
--- order.
--- If given frame is negative, TAS Editor will ignore such request.
--- If given frame is outside current input range, TAS Editor will expand movie
--- during applyinputchanges() to fit the frame.
--- If given joypad is outside [0-4] range, TAS Editor will ignore such request.
--- Given input will be treated by TAS Editor as a sequence of bits representing
--- state of each button of given joypad (bit 0 = A, bit 1 = B, bit 2 = Select, bit 3 = Start, bit 4 = Up, bit 5 = Down, bit 6 = Left, bit 7 = Right).
--- If TAS Editor is not engaged, nothing will be done.
--- @param frame number
--- @param joypad number
--- @param input number
function taseditor.submitinputchange(frame, joypad, input) end

--- Sends request to TAS Editor asking to insert given number of blank frames before
--- given frame.
--- Actual movie won't be changed until the moment you call taseditor.applyinputchanges().
--- Insertion can move down some old input and Markers (if "[Bind Markers to Input]" option is checked by user).
--- If given number is less or equal to zero, TAS Editor will ignore such request.
--- If given frame is negative, TAS Editor will ignore such request.
--- If given frame is outside current input range, TAS Editor will expand movie
--- during applyinputchanges() to fit the frame.
--- If TAS Editor is not engaged, nothing will be done.
--- @param frame number
--- @param number number
function taseditor.submitinsertframes(frame, number) end

--- Sends request to TAS Editor asking to delete given number of frames starting
--- from given frame.
--- Actual movie won't be changed until the moment you call taseditor.applyinputchanges().
--- Deletion can move up some old input and Markers (if "[Bind Markers to Input]" option is checked by user).
--- If given number is less or equal to zero, TAS Editor will ignore such request.
--- If given frame is negative, TAS Editor will ignore such request.
--- If given frame is outside current input range, TAS Editor will expand movie
--- during applyinputchanges() to fit the frame.
--- If TAS Editor is not engaged, nothing will be done.
--- @param frame number
--- @param number number
function taseditor.submitdeleteframes(frame, number) end

--- Instantly applies the list of previously requested changes to current movie. If
--- these requests actually modified movie data, new item will appear in History Log
--- (so user can undo these changes), and Greenzone may become truncated, Playback
--- cursor may lose its position, auto-seeking may be triggered.
--- Returns number of frame where first actual changes occurred.
--- If no actual changes were found (for example, you asked TAS Editor to set
--- buttons that were already pressed), returns -1.
--- If pending list of changes is empty, returns -1.
--- You can provide a name that will be assigned to this change. This name will be
--- shown in History Log. If you don't provide a name, TAS Editor will use default
--- name ("Change").
--- After applying all requests TAS Editor clears the list of requests.
--- If TAS Editor is not engaged, nothing will be done.
--- @param name string?
--- @return number
function taseditor.applyinputchanges(name) end

--- Clears the list of previously requested changes, making TAS Editor forget about
--- them before you call applyinputchanges(). Use this function to discard previously submitted input changes.
--- It's also recommended to call this function before making several requests in a
--- row, so that you'll be sure that only your new changes will apply.
--- If TAS Editor is not engaged, nothing will be done.
function taseditor.clearinputchanges() end
