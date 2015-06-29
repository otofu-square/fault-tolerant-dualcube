module NodePrinter
  def print_node(address)
    puts "%4d : #{get_binary_address(address)} [f=#{fault[address]}]" % address
  end

  def print_nodes
    for address in 0...size
      print_node(address)
    end
  end

  def print_neighbors(address)
    print_node(address)
    neighbors[address].each do |i|
      print_node(i)
    end
  end

  private
  def get_binary_address(address)
    "%0#{dim}b" % address
  end
end
