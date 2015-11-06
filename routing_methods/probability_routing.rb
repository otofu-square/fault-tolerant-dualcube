module SimpleProbability
  def set_probability
    cross_weight = @dim

    for round in 1..(2*@dim+2)
      @size.times do |node|
        if round == 1
          @probability[node][round] = @fault[node] == 1 ? 0 : 1
        else
          cnt = 0
          @neighbors[node].each do |neighbor|
            break if @fault[node] == 1
            if self.get_cross_neighbor(node) == neighbor
              cnt += @probability[neighbor][round-1]*cross_weight
            else
              cnt += @probability[neighbor][round-1]
            end
          end
          @probability[node][round] = cnt.to_f/(@dim+cross_weight.to_f)
        end
      end
    end
  end

  def routing_by_probability(s, d)
  end
end
