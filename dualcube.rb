require './bit_counter'
require './node_printer'

class Dualcube
  attr_reader :dim, :size, :neighbors, :fault

  def initialize(dim, ratio=0.0)
    @dim       = dim
    @size      = 2**(2*dim+1)
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
        (address>>(2*dim)) == 1 ? data = i+dim : data = i
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

# dualcube = Dualcube.new(10, 0           .5)
# dualcube.print_nodes
# p dualcube.neighbor?(0, 3)
