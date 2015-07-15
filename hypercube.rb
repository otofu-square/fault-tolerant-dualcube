require './bit_counter'
require './node_printer'
require './capability_routing'
require './complete_routing'

class Hypercube
  attr_reader :dim, :size, :addlen, :neighbors
  attr_accessor :fault, :capability, :status

  include NodePrinter
  include CapabilityRouting
  include CompleteRouting

  def initialize(dim, ratio=0.0)
    @dim        = dim
    @size       = 2**dim
    @addlen     = dim
    @neighbors  = set_neighbors
    @ratio      = ratio
    @fault      = Array.new(size, 0)
    @capability = []
    @status     = []
  end

  def neighbor?(a, b)
    neighbors[a].include?(b)
  end

  def self.get_distance(a, b)
    Integer::count_bit(a^b)
  end

  def set_fault(args)
    args.each { |node| fault[node.to_i(2)] = 1 }
  end

  def init_fault
    (0...size).to_a.sample((size*@ratio).floor).each { |i| @fault[i] = 1 }
  end

  private
  def set_neighbors
    neighbors = Array.new
    for address in 0...size
      for i in 0...dim
        neighbors[address] ||= Array.new
        neighbors[address].push address^(2**i)
      end
    end
    neighbors
  end
end
