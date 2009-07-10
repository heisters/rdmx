#!/usr/bin/env ruby

require 'rubygems'

module Rdmx
end
%w(
  rdmx/dmx
  rdmx/universe
  rdmx/fixture
  rdmx/animation
).each{|r|require File.dirname(__FILE__)+"/#{r}"}
