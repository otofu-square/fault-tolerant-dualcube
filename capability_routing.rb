module CapabilityRouting
  def set_capability
    capability = Array.new(size) { Array.new(dim+1) }

    for round in 1..dim
      size.times do |node|
        if round == 1
          capability[node][round] = fault[node] == 1 ? 0 : 1
        else
          cnt = 0
          neighbors[node].each do |neighbor|
            cnt += 1 if capability[neighbor][round-1] == 1
          end
          capability[node][round] = cnt > (dim-round) && fault[node] == 0 ? 1 : 0
        end
      end
    end

    capability
  end

  def print_capability(cap)
    size.times do |i|
      puts "%0#{dim}b : #{cap[i]}" % i
    end
  end
end
