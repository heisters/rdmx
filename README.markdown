Rdmx: Ruby DMX512
=================

Rdmx is a simple Ruby library for talking DMX512-A over serial ports (or USB
ports that look like serial ports) and a DSL for easily animating the DMX
fixtures.

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
      puts "blinking red and green, then green and blue"
      100.times do
        frame{@universe[0..-1] = 255, 255, 0}
        frame{@universe[0..-1] = 0, 120, 255}
      end
    end

    fade = Animation.new do
      puts "fading in blue"
      ramp(0..255, 10){|v|@universe[0..-1] = 0, 0, v}
    end

    xfade = Animation.new do
      puts "cross-fading red and blue"
      frame do
        ramp(255..0, 10) do |v|
          @universe.fixtures.each{|f|f.red = v}
        end
        ramp(0..255, 10) do |v|
          @universe.fixtures.each{|f|f.blue = v}
        end
      end
    end

    layers = Animation.new do
      puts "foreground/background blending with green fading in"
      layers = Layers.new 2, @universe
      ramp(0..255, 10) do |v|
        layers[0][0..-1] = 255, 0, 255
        layers[1][0..-1] = 255, v, 255
        layers.apply!
      end
    end

    blink.go!
    fade.go!
    xfade.go!
    layers.go!
