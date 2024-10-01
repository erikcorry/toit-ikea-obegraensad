// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the TESTS_LICENSE file.

import font show Font
import gpio
import obegraensad as ikea
import pixel-display show *
import pixel-display.two_color show *
import system

// Replace with correct pins.
CLA ::= 27
CLK ::= 26
DATA ::= 33
EN := 32

MSG ::= "Hello, world!"

with-driver [block]:
  if system.platform == system.PLATFORM-FREERTOS:
    cla := gpio.Pin CLA
    clk := gpio.Pin CLK
    data := gpio.Pin DATA
    en := gpio.Pin EN
    driver := ikea.Driver --cla=cla --clk=clk --data=data --en=en
    try:
      block.call driver
    finally:
      driver.close
      en.close
      data.close
      clk.close
      cla.close
  else:
    driver := ikea.Driver
    try:
      block.call driver
    finally:
      driver.close

main:
  with-driver: | driver/ikea.Driver |
    sans10 := Font.get "sans10"
    display := PixelDisplay.two-color driver --portrait=true
    display.background = WHITE

    // If it is rotated wrong, experiment with --landscape and --inverted.
    text := Label --x=8 --y=13 --text="" --font=sans10 --alignment=ALIGN-CENTER --color=BLACK
    display.add text

    display.draw

    MSG.size.repeat: | i |
      char := MSG[i]
      if char:  // Skip for UTF-8 trailing bytes.
        c := "$(%c char)"
        text.text = c
        display.draw
        sleep --ms=1000
    text.text = ""
    display.draw
