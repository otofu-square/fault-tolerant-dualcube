require 'benchmark'
require './dualcube'
require 'pp'

dim = 2
ratio = 0.2

dc = Dualcube.new(dim, ratio)
dc.set_probability
pp dc.probability
