// Copyright (C) 2023 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import gpio
import pixel-display show *
import pixel-display.two-color show *
import spi

BYTE-LOCATIONS_ ::= #[
  00, 01, 06, 07, 08, 09, 14, 15, 16, 17, 22, 23, 24, 25, 30, 31,
  02, 03, 04, 05, 10, 11, 12, 13, 18, 19, 20, 21, 26, 27, 28, 29,
]

REVERSE_ ::= ByteArray 256:
  ((it >> 7) & 1) | ((it >> 5) & 2) | ((it >> 3) & 4) | ((it >> 1) & 8) | ((it << 1) & 16) | ((it << 3) & 32) | ((it << 5) & 64) | ((it << 7) & 128);

/**
A driver for the Ikea OBEGRÄNSAD display.
*/
class Driver extends AbstractDriver:
  flags ::= FLAG-2-COLOR
  width ::= 16
  height ::= 16
  buffer_ ::= ByteArray 32
  // If the bus is set, then we opened it and also need to deallocate the device.
  bus_/spi.Bus? := null
  spi_/spi.Device?
  en_/gpio.Pin? ::= null
  is-portrait_/bool := false

  /**
  Constructs a new driver that prints the display to the console.
  */
  constructor:
    spi_ = null

  /**
  Constructs a new driver.

  If $en is provided, it will be used to turn the display to full brightness. If null,
    then the user is responsible to set the enable pin to 0. Using a PWM, the
    brightness can then be controlled.
  */
  constructor --cla/gpio.Pin --clk/gpio.Pin --data/gpio.Pin --en/gpio.Pin?:
    en_ = en
    if en:
      en.set 1
      en.configure --output
      en.set 1
    bus_ = spi.Bus --clock=clk --mosi=data
    spi_ = bus_.device --cs=cla --frequency=20_000 --mode=1

  close:
    if bus_:
      spi_.close
      bus_.close
      bus_ = null

  draw_two_color l/int t/int r/int b/int pixels/ByteArray -> none:
    assert: l == 0 and t == 0
    assert: r == 16 and b == 16
    if spi_:
      BYTE-LOCATIONS_.size.repeat: | i |
        if i & 1 == 0:
          buffer_[BYTE-LOCATIONS_[i]] = REVERSE_[pixels[i]]
        else:
          buffer_[BYTE-LOCATIONS_[i]] = pixels[i]
    else:
      buffer_.replace 0 pixels

  commit l t r b -> none:
    if spi_:
      spi_.write buffer_
      // We delay the enable-pin until the first writing of the buffer.
      // If the power supply isn't able of delivering enough power for the LEDs and
      // the esp32 the esp32 would end up in a brown-out restart before a program
      // could update the display with fewer pixels.
      if en_: en_.set 0
      return
    if is-portrait_:
      for x := 0; x < 16; x++:
        txt := ""
        for offset := 16; offset >= 0; offset -= 16:
          for column := 7; column >= 0; column--:
            byte := buffer_[offset + x]
            bit := (byte >> column) & 1
            txt += bit == 1 ? "#" : " "
        print txt
    else:
      for offset := 0; offset < 32; offset += 16:
        for line := 0; line < 8; line++:
          txt := ""
          for x := 0; x < 16; x++:
            byte := buffer_[offset + x]
            bit := (byte >> line) & 1
            txt += bit == 1 ? "##" : "  "
          print txt
    print ""

  base-transform --inverted/bool --portrait/bool? -> Transform:
    result := super --inverted=(not inverted) --portrait=portrait
    is-portrait_ = portrait
    result = result.rotate-left.rotate-left.translate -width -height
    return result
