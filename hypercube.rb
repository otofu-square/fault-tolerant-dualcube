require './bit_counter'
require './node_printer'

class Hypercube
  attr_reader :dim, :size, :addlen, :neighbors, :fault

  def initialize(dim, ratio=0.0)
    @dim       = dim
    @size      = 2**dim
    @addlen    = dim
    @neighbors = set_neighbors
    @fault     = set_fault(ratio)
  end

  include NodePrinter

  def neighbor?(a, b)
    neighbors[a].include?(b)
  end

  def get_distance(a, b)
    Integer::count_bit(a^b)
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

  def set_fault(ratio)
    fault = Array.new(size, 0)
    (0...size).to_a.sample((size*ratio).floor).each { |i| fault[i] = 1 }
    fault
  end
end
