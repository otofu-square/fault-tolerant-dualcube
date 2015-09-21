require 'pp'
require './dualcube.rb'

def test(dc, curr_node, distance)
  cnt = Hash.new
  nodes = dc.get_nodes_by_distance(curr_node, distance)

  nodes.each do |node|
    intmed = dc.get_intermediate_node(curr_node, node)
    cnt[intmed] ||= 0
    cnt[intmed] += 1
  end
  cnt
end

dc = Dualcube.new(2)


