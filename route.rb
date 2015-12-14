require './dualcube'
require 'yaml'

class Route
  def reset_fault
    @dc.fault = Array.new(@dc.size){|v| v = 0}
    @dc.set_probability
  end

  def set_fault(arr)
    arr.each{|n| @dc.fault[n] = 1}
    @dc.set_probability
  end

  def test_routing
    result = Hash.new{|h,k| h[k]=Hash.new{|_h,_k| _h[_k]=[]}}
    for node in 1...@dc.size
      position = @dc.get_position(0, node)
      puts position
      result[position][node].push exec_routing(0, node)
    end
    result
  end

  def simulation(dim, ratio=:all, round=10000)
    res = []
    @dc = Dualcube.new(dim)

    cnt = 0
    round.times do
      cnt += 1 if random_routing(ratio) == true
    end
    res.push "fault=#{ratio}: #{cnt}/#{round}"
    pp res
  end

  def random_routing(ratio)
    s, d = 0, 0
    while !@dc.connect?(s, d)
      @dc.set_fault(ratio)
      s, d = (0...@dc.size).to_a.sample(2)
    end
    @dc.set_probability

    res = exec_routing(s, d)
    res.last
  end

  def exec_routing(s, d)
    c, before, next_node, cnt = s, -1, -1, 0
    res = [[s, d]]
    while(true)
      return res.push true if c == d
      cnt += 1

      res.push next_node = @dc.get_next_node(c, d, before)

      if next_node == -1 || cnt > 100
        res.push "loop" if cnt > 100
        res.push false
        #pp res
        #@dc.print_nodes
        return res
      else
        before = c
        c = next_node
      end
    end
  end

  def create_situations(dim, ratio, cnt)
    result = {}

    cnt.times do |i|
      s, d = 0, 0
      @dc = Dualcube.new(dim)

      while !@dc.connect?(s, d)
        @dc.set_fault(ratio)
        s, d = (0...@dc.size).to_a.sample(2)
      end
      result[i] = {s: s, d: d, fault: @dc.fault}
    end

    open("./situations/situation_#{dim}_#{(ratio*10).to_i}.yml","w") do |f|
      YAML.dump(result, f)
    end
  end
end
