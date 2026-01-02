1. Origin story -- What sparked this project 12+ years ago? Were you frustrated with 
  off-the-shelf loggers? Did a sounding rocket team need something better? Personal
  challenge?

The rollercoasterometer was inspired by Space Mountain. Most other roller coasters are
able to be seen. Space Mountain is unique for being in the dark. I wanted something to
trace the tracks. Other roller coasters could in principle use GPS, but Space Mountain,
being indoors, can't. I designed and implemented a fiber optic strain gauge accelerometer
for my senior project (2000-2001), thinking that something like that could be smuggled on
board in a back pack. This was about the time that MEMS sensors were becoming available, 
but they were out of reach for my budget. Fast forward several years to 2009. At this 
point, MEMS sensors were in their "Moore's Law" phase -- smaller, cheaper, more accurate, 
more axes, etc etc etc. I designed a breadboard-based "rollercoasterometer" which used several
Sparkfun breakout boards for several IMU and magnetic sensors plus a GPS, combined with a 
Sparkfun Logomatic with custom firmware. At the time I was working with SDO/EVE which includes
a sounding rocket component (documented in another page of the portfolio) and brought the
rollercoasterometer with me during various business trips, including one to the Cape for the
final Comprehensive Performance Test. The PI for SDO/EVE, Tom Woods, saw it, was impressed, 
and suggested that I put it on his sounding rocket. During the Cape trip I took it to Disney
World during a down day and successfully measured several roller coasters. However, in its
form, it was too large and heavy to fly.

While programming the Logomatic, I discovered that it was a quite powerful microcontroller
in its own right. Many people learned microcontrollers from Arduino. I got, used, and learned
from Arduino as well, but my first processor was the Logomatic and its controller, the LPC2148.
I learned about all of its additional features that the standard firmware didn't use. The stock
firmware is only capable of recording either ADC measurements or UART text streams, but not
both. I needed both since my IMUs were analog and the UART was connected to the GPS.

So, the Rocketometer is the natural evolution of the Rollercoasterometer. It is 0.9x2.1", less than
an ounce with 100mAh battery, and contains the next generation (2011-2012) digital IMU sensors. The 
Rocketometer doesn't have a GPS because stock civilian GPS units aren't designed for the 
dynamics a model rocket (or sounding rocket) experiences, and furthermore the sounding rocket mission
was inside an aluminum shell with controlled RF emission. They wouldn't have let me fly a GPS,
and it wouldn't have worked. Even so, the Rocketometer has a UART and can receive GPS and PPS
data and record it. It works fine as a rollercoasterometer.

Note that nowadays most smartphones contain sensors as good as those in the rocketometer, and I use
them along with a custom app to do my "rollercoasterometry" these days. I turn on the app, put the
phone in my pocket, and record the ride. This just didn't exist yet in 2009-2013.

2. The big technical constraints you had to wrestle -- Size, weight, power budget? 
   Vibration/shock levels you designed for? Sampling rate goals vs. what was actually 
   achievable? Any “this will never work” moments you solved?

The biggest technical constraint is that the rocketometer had no telemetry and no control
from the time I handed it to Dr Woods for integration into the sounding rocket. It had to
work completely unattended for months. This drove some design decisions:

* Power -- The rocketometer receives power from the rest of the payload, in the form of a +5VDC
  line. But, the payload is explicitly powered down before sounding rocket reentry, meaining
  that I needed to supply my own power for at least 10 minutes. The rocketometer used its charging
  circuit to top up its 100mAh battery from the provided 5V, then seamlessly uses the rail and battery
  during a mission. Once supplied power drops, the device seamlessly transitions to using the battery
  which provided 30 additional minutes of recording time, plenty enough for reentry.
* Data volume -- At the time, 16GB microSD cards were the state of the art. Furthermore, the card
  and filesystem driver in the firmware used FAT32, limiting files to just under 4GiB. To handle this, 
  the data stream was broken into 2GiB chunks. Each power cycle of the device started a new series
  of recording files, and each file was a 2GiB chunk of packet data. I wasn't sure how long the device
  would be powered up before, during, or after the launch campaign, so I designed a low-rate mode
  where it only sampled 1/10 as fast. The device would check whether it was vertical by watching its
  own IMU reaction to gravity. Whenever it measured vertical, it automatically shifted to high rate
  for the next 30min. It checked verticality every second, so the 30min timer started when the 
  sounding rocket burned out. I had paid attention to the Genesis spacecraft which had a flaw in its
  IMUs, which were installed backwards, and as a consequence didn't pop its parachute. So I programmed
  the rocketometer to declare vertical if the rocket was either nose-up or nose-down. It was a good thing
  since it was installed inverted from how I thought and vertical was being read as nose down. The
  raw data didn't depend on this, and the verticality detector worked, so the part recorded the flight
  just fine
* Software reliability -- I ran the part for days, accumulating runtime. If the part ever crashed,
  I used the debugging tools I could to find the issue and fix it. As it turns out, there were no
  crashes.

3. Key design decisions you’re still proud of -- Why bare-metal instead of an RTOS? Specific IMU 
   choice and why? Power sequencing tricks? Mechanical mounting/isolation? Anything you did that
   was unusually clever for the era?
Bare metal was a design decision I inherited from the Logomatic. The Rocketometer was in a sense a
re-spin of the open-source Sparkfun Logomatic. I took its design, added the sensors based on the 
reference design in each sensor's datasheet, and integrated the whole thing on a much smaller board.
The firmware eventually contained not one byte of Sparkfun code (I even rewrote the linker script 
and Makefiles) but that was more ship-of-Theseus. Bare metal is still the right way to go on this
part, and I leveraged my experience with AIM/CIPS flight software for a realtime bare-metal executive.

The thing that would count as "unusually clever" was my firmware's documentation of itself. Long
ago I put a feature into the rollercoasterometer which could dump the microcontroller's flash memory.
My thought was that this way I can see the machine code and debug it that way. But I realized that
there is a better way. I added a feature to the Makefile to make an archive of the entire source code
and hardware design files, then attach the archive to the binary firmware. The linker script put the
archive into a section and pointed some symbols at it, and the firmware at runtime interpreted those
symbols as pointers and dumped the firmware archive as packets. This way each packet stream contains
the source code of the device that generated it.

4. The sounding rocket flight -- Which program/vehicle was it (NASA Sounding Rocket, university, 
commercial)? What was your role on the payload team? Apogee of 285.1424 km is insane — was that a
record or near-record for that vehicle class? Any tense moments during integration or launch?

The rocket was `NASA 36.290 UE WOODS/UNIV. OF COLORADO` . This is a Terrier-Black Brant IX, two stage
sounding rocket. We launched from White Sands launch complex 36 on 2013-10-21. I assisted with ground
integration -- there are always more hands needed and not enough time in a sounding rocket launch. I
learned our telemetry system and made sure the realtime display worked, and then on launch day I was
the space weather observer. We didn't want to launch during a solar flare, so I watched our in-space
SDO/EVE realtime data and made the call and hour, 30 min, and 1 min before launch that no solar flares
were in progress.

The flight was completely smooth, being the sixth that this team had conducted. The tensest moment
for the rocketometer was when I got it back, took the MicroSD card out of it, put it in my laptop, and
the laptop said "What card?" It took a few minuted before it recognized the card, but once it did,
I had 419MiB of data, including 54.4MiB of data from the flight (and 64 other power cycles). I was able
to verify the launch acceleration pulse and then knew I had good data.

5. Data highlights -- What’s the coolest thing the data revealed? Cleanest plot you ever pulled off 
the SD card? Did it catch something the principal experiment missed? Any post-flight “holy crap, 
look at that spike” moments?

The data showed a 12G first stage, -1.5G between stages, about 8G second stage, and spikes of up to
25G during reentry. That was the most surprising thing -- zero G at 2100m/s, through a 25G spike, 
down to 1G terminal velocity in under 25 seconds. The upper atmosphere is a wall -- that's what 
exponential decay (or growth coming back down) does for you. It surprises a lot of people that 
reentry is so harsh. The scientists and engineers knew about the reentry and designed for it, but 
it's still surprising that reentry is more "violent" than launch. The sensor I launched had a range
of +-16G, which I knew was close to what was expected during launch. I included a secondary +-250G 
sensor to catch data where the primary sensor saturated.

Also, the pressure sensor was rated from 0.3 to 1.3 bar, but did record 0 bar during the in-space
portion of the flight. It's just that the exact readings below 0.3 bar can't be trusted.

6. Failures or near-failures -- Be honest — any flights where it didn’t work perfectly? What broke,
and what did you change for the next one? SpaceX loves people who’ve debugged real hardware in the
field.

Alan Stern said about New Horizons at Pluto, that during the encounter, they don't want to learn
anything new about the spacecraft, only about Pluto. All of the bugs/"interesting features" are
to be known before encounter during rehearsals etc and fixed, worked around, or planned for.
I basically achieved that. The nose-down reading could have scuttled it, but the worst case
would have been recording the flight at 1/10 of design data rate, not "no data". By the time of the
sounding rocket, this exact device had flown in a model rocket, run for days on end, and was as
good as I could make it.

7. Longevity angle -- You said it’s 12 years old and still works — have you powered it up recently?
Flown it again? Still have the exact as-flown code running on the bench?

The flight was 12 years ago. The primary mission was for me to collect a piece of space-flown 
hardware as a "trophy". I still have it, mounted on a plaque for my mantel. It is only a trophy now.
I think that it still works, but the last time I fired it up was about 3 years ago, and I didn't
test the sensors, just the microcontroller.

8. Personal touches -- The embroidered patch — whose idea? Did you design it? Any other fun 
artifacts (stickers, T-shirts, war stories from the range)?

Every space mission needs a patch, and I designed one for this mission. It's pretty typical for
space mission patches. It has an oval shape with a picture of a 1950's sci-fi rocket with flames
coming out of it, connected to a voltmeter by two wires. The rocket represents the "rocket-" part
and the voltmeter represents the "-ometer" part. The rocket is high above the curved horizon of Earth.
In the background, there are 3 big and 2 small stars to the left of the rocket, and 1 big and
7 small stars to the right. This represents kwan3217. The border has the text "Rocketometer 36.290"
on the top of the oval, and "NASA - CU/LASP - SKHFTTADD" on the bottom where crew names (for manned flights)
or organization names (for unmanned flights) go. NASA and CU/LASP are obvious. SKHFTTADD is "St Kwan's Home
for the Terminally ADD", which is a pseudo-organization I made for myself.

I made several tab shirts with this patch embroidered into it, and also made some stickers which I stuck
on the tail fin of the first stage and on a window in the blockhouse next to stickers from all of their
other missions.

9. SpaceX hook -- When you imagine a Starship flight test engineer looking at this page, what do
you most want them to think? What part of Rocketometer feels closest to the instrumentation
challenges on Starship or Raptor test stands?

The biggest application to SpaceX is that I am a competent hardware and software designer, able
to integrate parts with "glue logic" like the custom PCB and microcontroller firmware, and that
I incorporate the NASA philosophy that I learned from the projects at LASP and conducted an 
experiment/built an instrument/implemented a project from beginning to end.

10. One-sentence elevator pitch -- If you had 10 seconds with Elon or a Starship avionics lead, how would you describe Rocketometer in one breath?

Custom microcontroller board with integrated IMU, battle-tested in space flight.
