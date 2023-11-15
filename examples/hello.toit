// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the TESTS_LICENSE file.

import font show Font
import gpio
import ikea-obegraensad.driver as ikea
import pixel-display show *
import pixel-display.texture show TEXT-TEXTURE-ALIGN-CENTER
import pixel-display.two_color show *
import spi

// Replace with correct pins.
CLOCK ::= 2
DATA ::= 3
LATCH ::= 4

MSG ::= "Hello, world!"

main:
  sans10 := Font.get "sans10"
  //bus := spi.Bus --clock=(gpio.Pin CLOCK) --mosi=(gpio.Pin DATA)
  //device := bus.device --cs=(gpio.Pin LATCH) --frequency=20_000
  //driver := ikea.Driver device
  driver := ikea.Driver
  display := TwoColorPixelDisplay driver
  display.background=BLACK
  context := (display.context --no-landscape).with
      --color=WHITE
      --font=sans10
      --alignment=TEXT-TEXTURE-ALIGN-CENTER

  letter := display.text context 8 12 ""

  display.draw
  
  MSG.size.repeat: | i |
    c := MSG[i .. i + 1]
    letter.text = c
    display.draw
    sleep --ms=1000
  letter.text = ""
  display.draw
