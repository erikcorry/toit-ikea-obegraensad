// Copyright (C) 2023 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import pixel-display show *
import pixel-display.two-color show *
import spi

BYTE-LOCATIONS_ ::= #[
    00, 01, 06, 07, 08, 09, 14, 15, 16, 17, 22, 23, 24, 25, 30, 31,
    02, 03, 04, 05, 10, 11, 12, 13, 18, 19, 20, 21, 26, 27, 28, 29]

REVERSE_ ::= ByteArray 256:
  ((it >> 7) & 1) | ((it >> 5) & 2) | ((it >> 3) & 4) | ((it >> 1) & 8) | ((it << 1) & 16) | ((it << 3) & 32) | ((it << 5) & 64) | ((it << 7) & 128);

class Driver extends AbstractDriver:
  flags ::= FLAG-2-COLOR
  width ::= 16
  height ::= 16
  buffer_ ::= ByteArray 32
  spi_/spi.Device?

  constructor .spi_/spi.Device?=null:

  draw_two_color l/int t/int r/int b/int pixels/ByteArray -> none:
    assert: l == 0 and t == 0
    assert: r == 16 and b == 16
    if spi_:
      BYTE-LOCATIONS_.size.repeat: | i |
        if i & 1 == 0:
          buffer_[BYTE-LOCATIONS_[i]] = pixels[i]
        else:
          buffer_[BYTE-LOCATIONS_[i]] = REVERSE_[pixels[i]]
    else:
      buffer_.replace 0 pixels

  commit l t r b -> none:
    if spi_:
      spi_.write buffer_
      return
    for offset := 0; offset < 32; offset += 16:
      for line := 0; line < 8; line++:
        txt := ""
        for x := 0; x < 16; x++:
          byte := buffer_[offset + x]
          bit := (byte >> line) & 1
          txt += bit == 1 ? " " : "#"
        print txt
    print ""
