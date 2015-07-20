require './bit_counter'
require './node_printer'
require './complete_routing'
# require './probability_routing'
# require './capability_routing'

class Dualcube
  attr_reader   :dim, :size, :addlen, :neighbors, :fault
  attr_accessor :capability, :probability, :preffered_nodes, :cross_status

  def initialize(dim, ratio=0.0)
    @dim             = dim
    @size            = 2**(2*dim+1)
    @addlen          = 2*dim+1
    @neighbors       = set_neighbors
    @fault           = set_fault(ratio)
    # @probability     = Hash.new { |hash,key| hash[key] = {} }
    @preffered_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }
    @cross_status    = Hash.new { |hash,key| hash[key] = [] }
    # @capability  = Array.new(@size) { Array.new(@dim+1) }
    # @directed_ca = Array.new(@size) { Array.new(@dim) { Array.new(@dim+1) } }
  end

  include NodePrinter
  # include SimpleProbability
  include CompleteRouting
  # include CapabilityRouting

  def neighbor?(a, b)
    neighbors[a].include?(b)
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

  def same_class?(a, b)
    get_class_id(a) == get_class_id(b)
  end

  def same_cluster?(a, b)
    same_class?(a, b) && get_cluster_id(a) == get_cluster_id(b)
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

  def get_cluster_nodes(class_id, cluster_id)
    cluster_nodes = []

    (2**@dim).times do |i|
      if class_id == 1
        cluster_nodes.push (1<<(2*@dim)) + (i<<@dim) + cluster_id
      else
        cluster_nodes.push (cluster_id<<@dim) + i
      end
    end

    cluster_nodes
  end

  def get_intermediate_node(s, d)
    if get_class_id(s) == 1
      (1<<(2**@dim)) + (get_cluster_id(d)<<@dim) + get_cluster_id(s)
    else
      (get_cluster_id(s)<<@dim) + get_cluster_id(d)
    end
  end

  private
  def set_neighbors
    neighbors = Array.new
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
