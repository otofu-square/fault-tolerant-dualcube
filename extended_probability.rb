require 'yaml'

module ExtendedProbability
  attr_accessor :prob_1, :prob_2, :prob_3

  def set_probability
    @pre_prob_1 = load_cache(:pre_prob_1)
    @pre_prob_2 = load_cache(:pre_prob_2)
    @pre_prob_3 = load_cache(:pre_prob_3)
    @prob_1 = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    @prob_2 = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    @prob_3 = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}

    calc_prob_1
    calc_prob_2
    pp @prob_2
  end

  private
  def calc_prob_1
    for distance in 1..@dim
      @size.times do |node|
        next if fault[node] == 1
        if distance == 1
          num_of_fault = 0
          self.get_cube_neighbors(node).each do |neighbor|
            num_of_fault += 1 if fault[neighbor] == 1
          end
          @prob_1[node][distance] = (@dim-num_of_fault)/@dim.to_f
        else
          temp_prob = 1
          self.get_cube_neighbors(node).each do |neighbor|
            next if fault[neighbor] == 1
            temp_prob *= 1 - @pre_prob_1[distance]*@prob_1[neighbor][distance-1]
          end
          @prob_1[node][distance] = 1 - temp_prob
        end
      end
    end
  end

  def calc_prob_2
    calc_prob_2_cross
    calc_prob_2_cube
  end

  def calc_prob_2_cross
    for distance in 1..(@dim+1)
      @size.times do |node|
        cross = self.get_cross_neighbor(node)
        if fault[node] == 1 || fault[cross] == 1
          @prob_2[:cross][node][distance] = 0.0
        else
          @prob_2[:cross][node][distance] = distance == 1 ? 1.0 : @prob_1[node][distance-1]
        end
      end
    end
  end

  def calc_prob_2_cube
    for distance in 2..@addlen
      @size.times do |node|
        neighbors = self.get_cube_neighbors(node)
        if fault[node] == 1
          @prob_2[:cube][node][distance] = 0.0
        else
          if distance == 2
            cnt = 0
            neighbors.each do |neighbor|
              cnt += 1 if @prob_2[:cross][neighbor][1] == 1.0
            end
            @prob_2[:cube][node][2] = cnt / @dim.to_f
          else
            temp_prob = 1
            neighbors.each do |neighbor|
              temp_prob *=  (1-@pre_prob_2[distance]*@prob_2[:cube][neighbor][distance-1])
              if distance < @dim+3
                temp_prob *= (1-@prob_2[:cross][neighbor][distance-1])
              end
            end
            @prob_2[:cube][node][distance] = 1 - temp_prob
          end
        end
      end
    end
  end

  def calc_prob_3
    calc_prob_3_cross
    calc_prob_3_cube
  end

  def calc_prob_3_cross
  end

  def calc_prob_3_cube
  end

  def load_cache(pattern)
    data = YAML.load_file("cache/pre_prob_#{@dim}.yml")
    data[pattern]
  end
end
