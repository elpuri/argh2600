argh2600
========
![Pitfall! screenshot](https://dl.dropboxusercontent.com/u/15525442/atari.jpg)

Somewhat complete implementation of the legendary Atari 2600 VCS in synthesizable VHDL. In the photo and the video the design is being run on a Altera Cyclone II device (DE2 board). 

### Features
* Real composite color video output (no component or VGA output)
* Joystick emulation with a PS2 keyboard
* Audio output using an AC97 codec
* Supports 4K cartridges

Here's some poor quality Youtube evidence:

[![demo video](http://img.youtube.com/vi/2uOF36kC1Qw/0.jpg)](http://www.youtube.com/watch?v=2uOF36kC1Qw)

### Blah blah
When I originally got the idea of recreating a game console lodged between my ears, I thought Atari 2600 would be a really simple machine to do because it's so primitive. Right? No. The difficult part is getting TIA (the graphics chip) right, or more specifically getting the timings right. In retrospect I would pick a console that has a bit more autonomous and less timing sensitive graphics hardware.

The project uses T65 the VHDL 65xx implementation from opencores.org. Everything else is written by me. Originally I planned to write also the 6507 from scratch, but wisely decided against it. Timing (which is still off) is absolutely esssential to get even the basic games working. Getting both the 6507 and TIA timing right at the same time would've probably been really frustrating. I'm planning to write my own 65xx at some point though, but I want to write some gameconsole cores first to test it against.

One thing that proved out to be invaluable along the way was [Stella](http://stella.sourceforge.net/). I would highly recommend using it for anyone planning to embark on this same journey.

### TODO
* More accurate register access timing (unsurprisingly this is really important for games)
* There's something wrong in RIOT as some games (for example Smurfs) utilizing the timers fail to sync
* Build a wing board to connect real joysticks to the board
* Bank switching for 4K+ cartridges
* Serial/USB/whatever loader for switching cartridges without resynthesis



