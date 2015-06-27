class Hypercube
  attr_reader   :dim, :size
  attr_accessor :neighbor


  def initialize(dim)
    @dim      = dim
    @size     = 2**dim
    @neighbor = Array.new
  end

  def get_neighbor
    neighbor = Array.new
    for address in 0...size
      for i in 0...dim
        neighbor[address] ||= Array.new
        neighbor[address].push address^(2**i)
      end
    end
    neighbor
  end
end

hypercube = Hypercube.new(4)
p hypercube.get_neighbor
