require 'yaml'
require 'pry'

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
    calc_prob_3
  end

  def get_next_node(c, d, before)
    distance  = self.get_distance(c, d)
    position  = self.get_position(c, d)
    cross     = self.get_cross_neighbor(c)
    neighbors = @neighbors[c].reject{|n| @fault[n]==1 || n==before}
    pre_nodes = self.get_preffered_nodes(c, d).reject do |n|
                  @fault[n]==1 || n==before || n==cross
                end
    spr_nodes = neighbors.reject{|n| pre_nodes.include?(n) || n==cross}
    next_node = -1;

    # 前方/後方隣接節点がどちらも存在しない場合、経路選択失敗とする
    return -1 if neighbors.size == 0

    # 目的節点と現在節点が隣接していたら経路選択成功
    return d if self.get_distance(c, d) == 1 && @fault[d] != 1

    case position
    when :position_1
      if pre_nodes.empty?
        next_node = get_detour_node_1(spr_nodes, cross, distance)
      else
        next_node = get_shortest_path_node_1(pre_nodes, distance)
      end
    when :position_2
      intmed = self.get_intermediate_node(c, d)

      # case 1
      if c == intmed
        if @fault[cross] == 0
          next_node = cross
        else
          spr_nodes.each do |n|
            next_node = n if @fault[self.get_cross_neighbor(n)] == 0
          end
        end
      # case 2
      elsif self.neighbor?(c, intmed)
        if @prob_2[:cross][intmed][distance-1] > 0
          next_node = intmed
        else
          next_node = get_detour_node_2(spr_nodes, cross, d)
        end
      # case 3
      else
        if pre_nodes.empty?
          # detour 1
          if spr_nodes.empty?
            next_node = cross
          # detour 2
          else
            next_node = get_highest_probability(spr_nodes, self.get_distance(c, intmed)+1, :prob_1)
          end
        else
          next_node = get_highest_probability(pre_nodes, self.get_distance(c, intmed)-1, :prob_1)
        end
      end
    when :position_3
      intmed = self.get_intermediate_node(c, d)

      # case 1
      if c == intmed
        cube_node = get_detour_node_3(spr_nodes, cross, distance)
        if @prob_2[:cube][cross][distance-1] > 0
          next_node = cross
        else
          next_node = cube_node
        end
      elsif pre_nodes.empty?
        if self.get_preffered_nodes(c, d).include?(cross) && @fault[cross]==0
          next_node = cross
        else
          next_node = get_detour_node_3(spr_nodes, cross, distance)
        end
      else
        next_node = get_shortest_path_node_3(pre_nodes, cross, distance)
      end
    end

    # Final check
    return fault[next_node] == 1 || before == next_node ? -1 : next_node
  end

  private
  def load_cache(pattern)
    data = YAML.load_file("cache/pre_prob_#{@dim}.yml")
    data[pattern]
  end

  def get_shortest_path_node_1(pre_nodes, distance)
    get_highest_probability(pre_nodes, distance-1, :prob_1)
  end

  def get_shortest_path_node_3(pre_nodes, cross, distance)
    cube_node  = get_highest_probability(pre_nodes, distance-1, :prob_3, :cross)
    cube_prob  = cube_node == -1 ? 0.0 : @prob_3[:cross][cube_node][distance-1]
    cross_prob = @prob_2[:cube][cross][distance-1]
    return cube_prob >= cross_prob ? cube_node : cross
  end

  def get_detour_node_1(spr_nodes, cross, distance)
    if spr_nodes.size > 0
      get_highest_probability(spr_nodes, distance+1, :prob_1)
    else
      @fault[cross]==0 ? cross : -1
    end
  end

  def get_detour_node_2(spr_nodes, cross, d)
    distance = self.get_distance(cross, d)
    intmed = self.get_intermediate_node(cross, d)
    distance = intmed == cross ? distance + 2 : distance

    if @prob_3[:cube][cross][distance] > 0
      cross
    else
      # 本当は確率値を確かめる必要があるが、一旦後方節点のうちクロスが死んでいないものを選択
      spr_nodes.each {|n| return n if @prob_2[:cross][n][1] > 0}
      return -1 # 無ければ失敗
    end
  end

  def get_detour_node_3(spr_nodes, cross, distance)
    get_highest_probability(spr_nodes, distance+1, :prob_3, :cross)
  end

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
    for distance in 3..(@addlen+1)
      @size.times do |node|
        cross = self.get_cross_neighbor(node)
        if fault[node] == 1 || fault[cross] == 1
          @prob_3[:cross][node][distance] = 0.0
        else
          @prob_3[:cross][node][distance] = @prob_2[:cube][cross][distance-1]
        end
      end
    end
  end

  def calc_prob_3_cube
    for distance in 4..@addlen
      @size.times do |node|
        neighbors = self.get_cube_neighbors(node)
        if fault[node] == 1
          @prob_3[:cube][node][distance] = 0.0
        else
          temp_prob = 1
          neighbors.each do |neighbor|
            temp_prob *= (1-@prob_3[:cross][neighbor][distance-1])
            if distance != 4
              temp_prob *= (1-@pre_prob_3[distance]*@prob_3[:cube][neighbor][distance-1])
            end
          end
          @prob_3[:cube][node][distance] = 1 - temp_prob
        end
      end
    end
  end

  def get_highest_probability(nodes, distance, prob_type, direction=:cube)
    max = 0.0; key = -1
    nodes.map do |node|
      case prob_type
      when :prob_1
        prob = @prob_1[node][distance]
      when :prob_2
        prob = @prob_2[direction][node][distance]
      when :prob_3
        prob = @prob_3[direction][node][distance]
      end

      if max < prob
        max = prob
        key = node
      end
    end
    key
  end
end
