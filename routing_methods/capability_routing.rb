module CapabilityRouting
  def set_capability
    capability = Array.new(size) { Array.new(dim+1) }

    for round in 1..dim
      size.times do |node|
        if round == 1
          capability[node][round] = fault[node] == 1 ? 0 : 1
        else
          cnt = 0
          neighbors[node].each do |neighbor|
            cnt += 1 if capability[neighbor][round-1] == 1
          end
          capability[node][round] = cnt > (dim-round) && fault[node] == 0 ? 1 : 0
        end
      end
    end

    capability
  end

  def set_capability_for_dualcube
    (2**@dim).times do |cluster_id|
      set_capability_for_cluster(0, cluster_id)
      set_capability_for_cluster(1, cluster_id)
    end
  end

  def print_capability(cap)
    size.times do |i|
      puts "%0#{dim}b : #{cap[i]}" % i
    end
  end

  private
  def set_capability_for_cluster(class_id, cluster_id)
    cluster_node = self.get_cluster_nodes(class_id, cluster_id)

    for round in 1..@dim
      cluster_node.each do |node|
        if round == 1
          @capability[node][round]   = fault[node] == 1 ? 0 : 1
          @capability[node][round-1] = fault[self.get_cross_neighbor(node)] == 1 ? 0 : 1
        else
          cnt = 0
          neighbors[node].each do |neighbor|
            next if neighbor == self.get_cross_neighbor(node)
            cnt += 1 if @capability[neighbor][round-1] == 1
          end
          @capability[node][round] = cnt > (@dim-round) && fault[node] == 0 ? 1 : 0
        end
      end
    end
  end
end

# module DirectedCapabilityRouting
#   def set_capability
#     capability = Array.new(size) { Array.new(dim) { Array.new(dim+1) } }

#     for round in 1..dim
#       @size.times do |node|
#         @neighbors[node].each do |target|
#           if round == 1
#             capability[node][target][round] = fault[node] == 1 ? 0 : 1
#           else
#             cnt = 0
#             @neighbors[node].each do |neighbor|
#               cnt += 1 if capability[neighbor][round-1] == 1 && !
#             end
#             capability[node][round] = cnt > (dim-round) && fault[node] == 0 ? 1 : 0
#           end
#         end
#       end
#     end

#     capability
#   end

#   def set_capability_for_dualcube
#     (2**@dim).times do |cluster_id|
#       set_capability_for_cluster(0, cluster_id)
#       set_capability_for_cluster(1, cluster_id)
#     end
#   end

#   def print_capability(cap)
#     size.times do |i|
#       puts "%0#{dim}b : #{cap[i]}" % i
#     end
#   end

#   private
#   def set_capability_for_cluster(class_id, cluster_id)
#     cluster_node = self.get_cluster_nodes(class_id, cluster_id)

#     for round in 1..@dim
#       cluster_node.each do |node|
#         if round == 1
#           @capability[node][round]   = fault[node] == 1 ? 0 : 1
#           @capability[node][round-1] = fault[self.get_cross_neighbor(node)] == 1 ? 0 : 1
#         else
#           cnt = 0
#           neighbors[node].each do |neighbor|
#             next if neighbor == self.get_cross_neighbor(node)
#             cnt += 1 if @capability[neighbor][round-1] == 1
#           end
#           @capability[node][round] = cnt > (@dim-round) && fault[node] == 0 ? 1 : 0
#         end
#       end
#     end
#   end
# end
