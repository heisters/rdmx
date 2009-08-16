require 'rubygems'

module Rdmx; end

%w(
  core_ext
  dmx
  universe
  fixture
  animation
  layers
).each{|r|require File.dirname(__FILE__)+"/lib/#{r}"}
