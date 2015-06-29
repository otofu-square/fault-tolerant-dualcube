class Hypercube
  attr_reader :dim, :size, :neighbors, :fault

  def initialize(dim, ratio=0.0)
    @dim      = dim
    @size     = 2**dim
    @neighbor = set_neighbors
    @fault    = set_fault(ratio)
  end

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
    (0...size).to_a.sample((size*ratio).floor).each {|i| puts i; puts fault[i] = 1}
    fault
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
