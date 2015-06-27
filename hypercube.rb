class Graph
  def initialize
    puts "Graph Init"
  end
end

class Hypercube < Graph
  def initialize
    puts "Hypercube Init"
  end
end

p graph = Graph.new
p hc = Hypercube.new
