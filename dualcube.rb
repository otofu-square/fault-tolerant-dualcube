require './lib/bit_counter'
require './lib/node_printer'
require './extended_probability'

class Dualcube
  attr_reader   :dim, :size, :addlen, :neighbors, :fault
  attr_accessor :capability, :probability, :preffered_nodes, :cross_status

  include NodePrinter
  include ExtendedProbability

  def initialize(dim, ratio=0.0)
    @dim             = dim
    @size            = 2**(2*dim+1)
    @addlen          = 2*dim+1
    @neighbors       = set_neighbors
    @fault           = set_fault(ratio)
  end

  def create_node_id(class_id, cluster_id, node_id)
    if class_id == 1
      (class_id<<2*@dim) + (node_id<<@dim) + (cluster_id)
    else
      (class_id<<2*@dim) + (cluster_id<<@dim) + (node_id)
    end
  end

  def get_class_id(address)
    address>>(2*dim)
  end

  def get_cluster_id(address)
    get_class_id(address) == 1 ? (address)&(2**dim-1) : (address>>dim)&(2**dim-1)
  end

  def get_node_id(address)
    get_class_id(address) == 1 ? (address>>dim)&(2**dim-1) : (address)&(2**dim-1)
  end

  def get_distance(a, b)
    if same_class?(a, b) && get_cluster_id(a) != get_cluster_id(b)
      Integer::count_bit(a^b) + 2
    else
      Integer::count_bit(a^b)
    end
  end

  def get_cross_neighbor(a)
    a^(1<<(2*@dim))
  end

  def get_cube_neighbors(a)
    @neighbors[a].reject{|e| e==self.get_cross_neighbor(a)}
  end

  def get_cluster_nodes(class_id, cluster_id)
    Array(0...2**@dim).map {|i| create_node_id(class_id, cluster_id, i)}
  end

  def get_intermediate_node(s, d)
    if same_class?(s, d)
      create_node_id(get_class_id(s), get_cluster_id(s), get_node_id(d))
    else
      create_node_id(get_class_id(s), get_cluster_id(s), get_cluster_id(d))
    end
  end

  def get_nodes_by_distance(curr_node, distance)
    Array(0...@size).reject{|node| distance != get_distance(curr_node, node)}
  end

  def get_preffered_nodes(s, d)
    @neighbors[s].reject{|n| get_distance(n, d) >= get_distance(s, d)}
  end

  def get_position(c, d)
    return :position_1 if same_cluster?(c, d)
    return :position_2 if !same_cluster?(c, d) && !same_class?(c, d)
    return :position_3 if !same_cluster?(c, d) && same_class?(c, d)
  end

  def neighbor?(a, b)
    neighbors[a].include?(b)
  end

  def same_class?(a, b)
    get_class_id(a) == get_class_id(b)
  end

  def same_cluster?(a, b)
    same_class?(a, b) && get_cluster_id(a) == get_cluster_id(b)
  end

  private
  def set_neighbors
    neighbors = []
    for address in 0...size
      for i in 0...dim
        neighbors[address] ||= Array.new
        get_class_id(address) == 1 ? data = i+dim : data = i
        neighbors[address].push address^(2**data)
      end
      neighbors[address].push address^(1<<(2*dim)) # cross neighbor
    end
    neighbors
  end

  def set_fault(ratio)
    fault = Array.new(size, 0)
    (0...size).to_a.sample((size*ratio).floor).each { |i| fault[i] = 1 }
    fault
  end
end
