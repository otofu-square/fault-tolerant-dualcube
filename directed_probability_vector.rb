require 'yaml'
require 'pry'

module DirectedProbabilityVector
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
    calc_prob_3
  end

  def get_next_node(c, d, before)
    # 前方/後方隣接節点がどちらも存在しない場合、経路選択失敗とする
    return -1 if neighbors.size == 0

    # 目的節点と現在節点が隣接していたら経路選択成功
    return d if self.get_distance(c, d) == 1 && @fault[d] != 1

    case position
    when :position_1
      next_node = route_on_position_1(c, d, before)
    when :position_2
      next_node = route_on_position_2(c, d, before)
    when :position_3
      next_node = route_on_position_3(c, d, before)
    end

    # Final check
    return fault[next_node] == 1 || before == next_node ? -1 : next_node
  end

  private
  def get_initial_state(c, d, before)
    distance  = self.get_distance(c, d)
    cross     = self.get_cross_neighbor(c)
    neighbors = @neighbors[c].reject{|n| @fault[n]==1 || n==before}
    pre_nodes = self.get_preffered_nodes(c, d).reject do |n|
                  @fault[n]==1 || n==before || n==cross
                end
    spr_nodes = neighbors.reject{|n| pre_nodes.include?(n) || n==cross}

    [distance, cross, neighbors, pre_nodes, spr_nodes]
  end

  def route_on_position_1(c, d, before)
    distance, cross, neighbors, pres, sprs = get_initial_state(c, d, before)

    if pres.empty?
      next_node = get_highest_probability(c, pres, distance-1, :prob_1)
    else
      if sprs.size > 0
        next_node = get_highest_probability(c, sprs, distance+1, :prob_1)
      else
        next_node = @fault[cross]==0 ? cross : -1
      end
    end
    next_node
  end

  def route_on_position_2(c, d, before)
    distance, cross, neighbors, pres, sprs = get_initial_state(c, d, before)
    intmed = self.get_intermediate_node(c, d)
    next_node = -1

    # case 1
    if c == intmed
      if @fault[cross] == 0
        next_node = cross
      else
        sprs.each do |n|
          next_node = n if @fault[self.get_cross_neighbor(n)] == 0
        end
      end
    # case 2
    elsif self.neighbor?(c, intmed)
      if @prob_2[:cross][intmed][c][distance-1] > 0
        next_node = intmed
      else
        next_node = get_detour_node_2(sprs, c, d, cross)
      end
    # case 3
    else
      if pres.empty?
        # detour 1
        if sprs.empty?
          next_node = cross
        # detour 2
        else
          next_node = get_highest_probability(c, sprs, self.get_distance(c, intmed)+1, :prob_1)
        end
      else
        next_node = get_highest_probability(c, pres, self.get_distance(c, intmed)-1, :prob_1)
      end
    end
    next_node
  end

  def get_detour_node_2(spr_nodes, c, d, cross)
    distance = self.get_distance(cross, d)
    intmed = self.get_intermediate_node(cross, d)
    distance = intmed == cross ? distance + 2 : distance

    if @prob_3[:cube][cross][c][distance] > 0
      cross
    else
      spr_nodes.each {|n| return n if @prob_2[:cross][n][1] > 0}
      return -1
    end
  end

  def route_on_position_3(c, d, before)
    distance, cross, neighbors, pres, sprs = get_initial_state(c, d, before)
    intmed = self.get_intermediate_node(c, d)

    # case 1
    if c == intmed
      if @prob_2[:cube][cross][c][distance-1] > 0
        next_node = cross
      else
        next_node = get_highest_probability(c, sprs, distance+1, :prob_3, :cross)
      end
    elsif pres.empty?
      if @fault[cross] == 0
        next_node = cross
      else
        next_node = get_highest_probability(c, sprs, distance+1, :prob_3, :cross)
      end
    else
      cube_node  = get_highest_probability(c, pres, distance-1, :prob_3, :cross)
      cube_prob  = cube_node == -1 ? 0.0 : @prob_3[:cross][cube_node][distance-1]
      cross_prob = @prob_2[:cube][cross][c][distance-1]
      next_node = cube_prob >= cross_prob ? cube_node : cross
    end
    next_node
  end

  def calc_prob_1
    for distance in 1..@dim
      @size.times do |node|
        next if fault[node] == 1

        @neighbors[node].each do |target|
          cube_neighbors = self.get_cube_neighbors(node).reject{|n| n==target}

          if fault[target] == 1
            @prob_1[node][target][distance] = 0.0
            next
          end

          if distance == 1
            num_of_fault = 0
            cube_neighbors.reject{|n| n==target}.each do |neighbor|
              num_of_fault += 1 if fault[neighbor] == 1
            end
            @prob_1[node][target][distance] = (cube_neighbors.size-num_of_fault)/cube_neighbors.size.to_f
          else
            temp_prob = 1.0
            cube_neighbors.reject{|n| n==target}.each do |neighbor|
              next if fault[neighbor] == 1.0
              temp_prob *= 1.0 - @pre_prob_1[distance]*@prob_1[neighbor][node][distance-1]
            end
            @prob_1[node][target][distance] = 1.0 - temp_prob
          end
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
          @prob_2[:cross][node][distance] = distance == 1 ? 1.0 : @prob_1[cross][node][distance-1]
        end
      end
    end
  end

  def calc_prob_2_cube
    for distance in 2..@addlen
      @size.times do |node|
        @neighbors[node].each do |target|
          cube_neighbors = self.get_cube_neighbors(node).reject{|n| n==target}

          # 故障していれば確率値は0とする
          if fault[node] == 1 || fault[target] == 1
            @prob_2[:cube][node][target][distance] = 0.0
            next
          end

          if distance == 2
            cnt = 0
            cube_neighbors.each do |neighbor|
              cnt += 1 if @prob_2[:cross][neighbor][1] == 1.0
            end
            @prob_2[:cube][node][target][2] = cnt / cube_neighbors.size.to_f
          else
            temp_prob = 1.0
            cube_neighbors.each do |neighbor|
              temp_prob *=  1.0-@pre_prob_2[distance]*@prob_2[:cube][neighbor][node][distance-1]
              if distance < @dim+3
                temp_prob *= 1.0-@prob_2[:cross][neighbor][distance-1]
              end
            end
            @prob_2[:cube][node][target][distance] = 1.0 - temp_prob
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
    for distance in 3..(2*@dim+2)
      @size.times do |node|
        cross = self.get_cross_neighbor(node)
        if fault[node] == 1 || fault[cross] == 1
          @prob_3[:cross][node][distance] = 0.0
        else
          @prob_3[:cross][node][distance] = @prob_2[:cube][cross][node][distance-1]
        end
      end
    end
  end

  def calc_prob_3_cube
    for distance in 4..(2*@dim+2)
      @size.times do |node|
        @neighbors[node].each do |target|
          cube_neighbors = self.get_cube_neighbors(node).reject{|n| n==target}

          # 故障していれば確率値は0とする
          if fault[node] == 1 || fault[target] == 1
            @prob_3[:cube][node][target][distance] = 0.0
            next
          end

          temp_prob = 1.0
          cube_neighbors.each do |neighbor|
            temp_prob *= 1.0-@prob_3[:cross][neighbor][distance-1]
            if distance != 4
              temp_prob *= 1.0-@pre_prob_3[distance]*@prob_3[:cube][neighbor][node][distance-1]
            end
          end
          @prob_3[:cube][node][target][distance] = 1.0 - temp_prob
        end
      end
    end
  end

  def get_highest_probability(curr, nodes, distance, prob_type, direction=:cube)
    max = 0.0; key = -1
    nodes.map do |node|
      case prob_type
      when :prob_1
        prob = @prob_1[node][curr][distance]
      when :prob_2
        prob = @prob_2[direction][node][curr][distance]
      when :prob_3
        prob = @prob_3[direction][node][curr][distance]
      end

      if max < prob
        max = prob
        key = node
      end
    end
    key
  end

  def load_cache(pattern)
    data = YAML.load_file("cache/pre_prob_#{@dim}.yml")
    data[pattern]
  end
end
