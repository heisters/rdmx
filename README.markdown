Rdmx: Ruby DMX512
=================

Rdmx is a simple Ruby library for talking DMX512-A over serial ports (or USB
ports that look like serial ports) and a DSL for easily animating the DMX
fixtures.

Author: [Ian Smith-Heisters](http://idiosyncra.tc)

Installation
------------

I haven't bothered to write a gemspec, so:

    git submodule add git://github.com/heisters/rdmx.git vendor/rdmx

Features
--------

* DMX: implementation of the DMX512-A protocol (write only)
* Universes: abstraction for universes of 512 channels, talked to over a DMX
  serial port
* Fixtures: abstraction for fixtures that use more than one channel each
* Animation: DSL for easily creating animations
* Layers: Another level of abstraction to facilitate blending of animations

Example
-------

    require 'vendor/rdmx/rdmx'

    include Rdmx

    class Led < Fixture
      self.channels = :red, :green, :blue
    end

    @universe = Universe.new('/dev/tty.usbserial-ENRVOTH6', Led => 50)

    blink = Animation.new do
      frame.new do
        puts "blinking red and green, then green and blue"
        100.times do
          @u.first[0..-1] = 255, 255, 0; continue
          @u.first[0..-1] = 0, 120, 255; continue
        end
      end
    end

    fade = Animation.new do
      frame.new do
        puts "fading in blue"
        (0..255).over(10.seconds).each{|v|@u.first[0..-1] = 0, 0, v.to_f.round; continue}
      end
    end

    xfade = Animation.new do
      frame.new do
        puts "cross-fading red and blue"
        (255..0).over(10.seconds).each do |v|
          @u.first.fixtures.each{|f|f.red = v.to_f.round}
          continue
        end

      frame.new do
        (0..255).over(10.seconds).each do |v|
          @u.first.fixtures.each{|f|f.blue = v.to_f.round}
          continue
        end
      end
    end

    ll = Layers.new 2, @u.first
    layers = Animation.new do
      frame.new do
        puts "foreground/background blending with green fading in"
        (0..255).over(10.seconds).each do |v|
          ll.first[0..-1] = 255, 0, 255
          ll.last[0..-1] = 255, v.to_f.round, 255
          ll.apply!
          continue
        end
      end
    end

    blink.go!
    fade.go!
    xfade.go!
    layers.go!

License
-------

Copyright (c) 2009, Ian Smith-Heisters

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

