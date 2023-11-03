
sw_sin_gen
==========

About
-----
A ADAT & S/SPDIF sin generator for the xcore.ai mc audio board.

This application outputs simultaneous ADAT and S/PDIF streams.

The S/PDIF stream samples synchronised to the channel status block start. This makes it easier to check if samples are correct on the receiver side.

Channel 1 (left)  has one full scale sine period over 96 samples.
Channel 2 (right) has two full scale sine period over 96 samples.

ADAT channels 3-8 carry 0 sample data.

This will result in the following frequency sine waves being played at each sample rate:

SR    Freq Ch1  Freq Ch2
44.1  459Hz     919Hz
48    500Hz     1kHz
88.2  919Hz     1.84kHz
96    1kHz      2kHz
176.4 1.84kHz   3.67kHz
192   2kHz      4kHz

Usage
-----

The sample frequency can be changed in the sequence 44.1 - 48 - 88.2 - 96 - 176.4 - 192kHz by pressing Button 0.

The LEDs will flash to indicate the new sample rate. One flash means 44.1, two flashes 48, three 88.2 .. etc.

Build
-----

Build using www.github.com/xmos/xcommon_cmake

Set environment varable XMOS_CMAKE_PATH to the location of xcommon_cmake (e.g. export XMOS_CMAKE_PATH=~/xcommon_cmake

cmake -B build (This will grab all required dependencies such as lib_spdif etc)

cd build
xmake

Runnnig
-------

xrun --xscope ../bin/app_sin_gen.xe

