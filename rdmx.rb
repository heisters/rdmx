require 'rubygems'

module Rdmx; end

%w(
  dmx
  universe
  fixture
  animation
  layers
).each{|r|require File.dirname(__FILE__)+"/lib/#{r}"}
