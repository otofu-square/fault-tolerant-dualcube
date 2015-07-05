require './bit_counter'
require './node_printer'

class Hypercube
  attr_reader :dim, :size, :addlen, :neighbors, :fault
  attr_accessor :status

  def initialize(dim, ratio=0.0)
    @dim       = dim
    @size      = 2**dim
    @addlen    = dim
    @neighbors = set_neighbors
    @fault     = set_fault(ratio)
    @status    = Array.new
  end

  include NodePrinter

  def neighbor?(a, b)
    neighbors[a].include?(b)
  end

  def get_distance(a, b)
    Integer::count_bit(a^b)
  end

  def get_cluster_status
    dim.times do |cnt|
      size.times do |current|
        status[current] ||= Array.new
        next if self.fault[current] == 1 # 自身が故障していたらスルー

        neighbors[current].each do |neighbor|
          if cnt == 0
            status[current].push(neighbor) unless fault[neighbor] == 1
          else
            status[neighbor].each do |node|
              unless (status[current].include?(node))
                status[current].push(node)
              end
            end
          end
        end
      end
    end
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
