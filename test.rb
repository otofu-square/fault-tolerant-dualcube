require 'benchmark'
require './dualcube'
require 'pp'

def print_node(address)
  puts "%4d : #{get_binary_address(address)} [f=#{fault[address]}]" % address
end

dim = 3
ratio = 0.0

dc = Dualcube.new(dim, ratio)

# source node
a = 0

result = Hash.new { |h,k| h[k] = [] }
for node in 1...(dc.size)
  distance = dc.get_distance(a, node)
  result[distance].push node
end

for distance in 1..(2*dim+2)
  puts distance
  result[distance].each do |data|
    puts ("%0#{dc.dim*2+1}b" % data) + (" : " + "%0#{dc.dim*2+1}b" % dc.get_intermediate_node(0, data))
  end
  puts
end
