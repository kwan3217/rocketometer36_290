This documents the data produced by the Rocketometer during NASA Sounding Rocket Flight 36.290, 2013 Oct 21.

# Encoding format
The data was captured and encoded in the form of CCSDS packets. The exact structure of each packet is most completely documented in the source code.

# Source code
The Rocketometer contains an LPC2148 ARM-based MCU with 512kiB flash memory. As this was far more memory than I needed for the firmware, I worked out a way to attach the source code of the firmware as well as the hardware design to the firmware itself. The Rocketometer spits this out into the packet stream as one of the first things it does at startup. How's that for configuration control?

The source code package is in the form of a ZPAQ TAR archive. The folder includes all the C++ source code, Makefiles, and such for rebuilding the firmware, which will be identical to the firmware carried on the flight with the exception of the date stamp on the firmware.

The hardware design is in the form of an Eagle CAD board and schematic, editable with the Eagle freeware version (as that is what it was designed with). It also includes a bill of materials in the form of Digikey catalog numbers for all parts used on the board.

The source code package is attached to the firmware, along with pointers to exactly where in the firmware the package begins and ends. This enables the firmware to copy a piece of itself into the packet stream as multiple CCSDS packets.

# Time Stamp
The firmware uses one of the MCU counter/timers for timing. This counter is a 32-bit unsigned number which starts at zero during firmware bootup, and counts up to one less than 3.6 billion counts exactly, at which point it resets to zero. The counter nominally runs at 60MHz, so this counter resets once every 60 seconds. Each time-sensitive packet (almost all of them except for some startup packets) have this count in it, and the packets are generated at such a rate that it is possible to unambiguously unwind the counter and get an exact number of counts since startup. Unfortunately the time of startup was not marked in any absolute time scale such as UTC, so absolute timing has to be inferred from timestamped events in the data.

# Sensor data
The sensor data stream consists of three separate streams of packets:
1. The Fast packet includes the MPU6050 3-axis acceleration, 3-axis rotation, and temperature readings, along with the ADXL377 3-axis high-acceleration readings. These were read once every 3 milliseconds and timestamped as indicated above.
2. The Compass packet includes the HMC5883 3-axis magnetic readouts. These were measured at a multiple of the Fast packet period (see the source code for details)
3. The BMP packet includes the BMP180 pressure and temperature readouts, both raw and calibrated into physical units.
4. The Power packet stream includes one packet each time the external power state changed (including one at startup).
5. The Vertical packet stream includes data on the vertical sensing fast/slow packet rate (see the source code for details). I have verified that this worked as intended, and that the entire flight was recorded at the fast rate.

# Packet storage
Packet storage was on a 16GB microSD card. Less than 1GB was used between the time I delivered the Rocketometer and the time it was returned to me.

# Power
The board consumes something around 100mA, not counting charging. The charger can use and additional 100mA. The system has an internal battery in the form of a 100mAh LiPo cell. The Rocketometer is powered externally by a 5V line from the rocket payload. It charges the battery with its on-board LiPo charging circuit as necessary when external power is available, and runs off the battery when external power is off. The on-board switch is not accessible, so the board is on whenever the rest of the rocket payload is on, and only turns off once its battery discharges. The battery is made safe by its standard integrated safety circuit and the dedicated LiPo charging circuit.

# The Flight
The Rocketometer was integrated with the rest of the rocket payload months before the flight. After that time, no human interaction whatsoever took place. It was returned to me for readout a couple of hours after the flight was completed. In that time, it recorded 65 files, one for each time it was power-cycled. The one containing the flight was file RKTO0620.SDS . This file contains 54.4 MB of data covering well over an hour, from about 35 minutes before the flight until well after impact. External power was cut 585 seconds after launch, and the on-board battery sustained it for the rest of the flight.

# Rail data
The file RKTO0620.SDS starts after the rail was raised to almost vertical. Other records were taken when the rail was horizontal, in particular RKTO0600.SDS. This data has been processed into the same tables and published. Interesting things such as orientation of the Rocketometer relative to the rail can be determined from that.

It would have been nice for the Rocketometer to have been recording while the rail was raised from horizontal to vertical. Unfortunately this did not happen. Maybe next time...

For whatever reason, it seems that no magnetic data was recorded while the rail was horizontal. Apparently magnetic data is not recorded when the board is recording at low rate.

# Rocketometer coordinate system
All sensors were co-aligned, so each individual sensor matches the whole Rocketometer frame. The Rocketometer was mounted close to the spin axis of the rocket, with the +Z axis pointed towards the tail. Consequently the thrust acceleration was primarily read out as a -Z acceleration. It should be parallel to that axis to within normal mechanical tolerances, almost certainly quite a bit better than 1°.

Based on the rail data, the +X axis of the Rocketometer was pointed almost straight down when the rocket was hanging horizontally from the rail.

In the flight after burnout but before spindown, the rocket was coasting well above the atmosphere and spinning with constant angular momentum, nearly around its long axis. Therefore the entire sensed acceleration is pure centripetal. Therefore, the distance and direction from the accelerometer to the spin axis can be measured. I did this once, but I wasn't sure about the signs and therefore didn't record it.

# Processing into tables
The packet stream format is not convenient or quick for import into IDL. For this purpose, a packet dumper, extractFast, was written in pure C which reads a Rocketometer data file, parses out each kind of packet, and writes each different apid into a different file. All the fast packets are together, all the slow packets, all the compass, all the source code, etc are each in their own file. Since the most common case is that each apid has a consistent length, this apid file can be read quickly into IDL by a read_binary, treating it as a 2D array of 16-bit integers, where rows are individual packets, and columns are fields in the packet.

Each packet is assigned a global sequence number, and this number is one of the things written to the APID file. With this sequence number, the order of different packets in different files can be determined.

These APID files are then imported into IDL, where the timestamps are normalized, values are converted in endian-ness as needed, and in general the packets are parsed. As this is an array operation, it can be done several orders of magnitude faster than parsing each packet individually in IDL.

The published tables have the timestamp normalized (cycle ambiguity fixed, converted into seconds, offset from power-on to launch subtracted) but otherwise the data is as recorded by the Rocketometer in flight. In particular, no translation from raw DNs to physical units is performed.

# Included files
* `RKTO0620.SDS.zip` - raw flight data file, PKZIP compressed
* `RKTO0600.SDS.zip` - raw rail data file, PKZIP compressed
* `firmware.tar.gz` - Firmware package, as flown (from RKTO0620.SDS) but zpaq uncompressed and gzip recompressed
* `extractFast.c` - C program described above
* `apid list.ods` - Some documentation of the packet format, not know to be completely up-to-date. Use the source code as the final authority.
* `import_fast.pro` - IDL program which converts extractFast output to CSV tables, among other things.
* `RKTO0620_csv.zip` - Compressed archive containing the following files
   * `RKTO0620_fast.csv` - Comma separated values, fast packets as described above
   * `RKTO0620_bmp.csv` - Comma separated values, BMP180 temperature and pressure readings, raw and calibrated into physical units by the Rocketometer in-flight
   * `RKTO0620_hmc.csv` - Comma separated values, HMC5883 magnetic readings, as described above.
* `RKTO0600_csv.zip` - Compressed archive containing the following files
   * `RKTO0600_fast.csv` - Comma separated values, fast packets as described above
   * `RKTO0600_bmp.csv` - Comma separated values, BMP180 temperature and pressure readings, raw and calibrated into physical units by the Rocketometer on-board

