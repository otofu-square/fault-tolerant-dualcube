class Hypercube
  attr_reader   :dim, :size
  attr_accessor :neighbor


  def initialize(dim)
    @dim        = dim
    @size       = 2**dim
    @neighbor ||= get_neighbors
    #️ @fault      = set_fault
  end

  def get_neighbors
    neighbors = Array.new
    for address in 0...size
      for i in 0...dim
        neighbors[address] ||= Array.new
        neighbors[address].push address^(2**i)
      end
    end
    neighbors
  end

  def get_binary_address(address)
    "#{address} : %0#{dim}b" % address
  end

  def print_nodes
    for i in 0...size
      puts get_binary_address(i)
    end
  end
end

hypercube = Hypercube.new(4)
hypercube.print_nodes
