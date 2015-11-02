module ExtendedProbability
  attr_accessor :probability1, :probability2, :probability3

  def set_probability
    @probability1 = Array.new(@size) { Hash.new() }
    @probability2 = hash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
    @probability3 = hash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }

    calc_probability_1
    calc_probability_2_cross
    @probability2
  end

  private
  def calc_probability_1
    (@addlen).times do |cnt|
      distance = cnt + 1
      break if cnt >= (@dim)

      @size.times do |node|
        next if fault[node] == 1

        if distance == 1
          num_of_fault = 0
          self.get_cube_neighbors(node).each do |neighbor|
            num_of_fault += 1 if fault[neighbor] == 1
          end
          @probability1[node][distance] = (@dim-num_of_fault)/@dim.to_f
        else
          temp_prob = 1
          self.get_cube_neighbors(node).each do |neighbor|
            next if fault[neighbor] == 1
            temp_prob *= 1 - (distance/@dim.to_f)*@probability1[neighbor][distance-1]
          end
          @probability1[node][distance] = 1 - temp_prob
        end
      end
    end
  end

  def calc_probability_2
    calc_probability_2_cross
    calc_probability_2_cube
  end

  def calc_probability_2_cross
    (@addlen).times do |cnt|
      distance = cnt + 1
      break if cnt >= (@dim+1)

      @size.times do |node|
        cross = self.get_cross_neighbor(node)
        if fault[node] == 1 || fault[cross] == 1
          @probability2[node]["cross"] = 0
        else
          @probability2[node]["cross"][distance] = distance == 1 ? 1 : @probability1[cross][distance-1]
        end
      end
    end
  end

  def calc_probability_2_cube
    (@addlen).times do |cnt|
      distance = cnt + 1
      break if cnt >= (@addlen)

      @size.times do |node|
        if fault[node] == 1
          @probability2[node]["cube"] = 0
        else

        end
      end
    end
  end

  def calc_probability_3
    calc_probability_3_cross
    calc_probability_3_cube
  end

  def calc_probability_3_cross
  end

  def calc_probability_3_cube
  end

  def preffered_probability(node, distance)
  end
end
