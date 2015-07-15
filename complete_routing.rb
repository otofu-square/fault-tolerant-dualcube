require './hypercube'

module CompleteRouting
  def get_cluster_status
    # 3次元ハッシュを定義
    connect_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }

    (@dim+1).times do |cnt|
      @size.times do |current|
        next if @fault[current] == 1 # 自身が故障していたらスルー

        @neighbors[current].each do |neighbor|
          if cnt == 0
            connect_nodes[current][1].push(neighbor) unless @fault[neighbor] == 1
          else
            connect_nodes[neighbor].each_value do |nodes|
              nodes.each do |node|
                next if 0 == distance = Hypercube::get_distance(current, node)
                connect_nodes[current][distance].push(node) unless connect_nodes[current][distance].include?(node)
              end
            end
          end
        end
      end
    end

    preffered_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }
    @size.times do |node|
      forward = Hash.new { |hash,key| hash[key] = [] }
      connect_nodes[node][1].each do |neighbor|
        # 直径+1
        tmp = Hash.new { |hash,key| hash[key] = [] }
        for cnt in 2..connect_nodes[node].length
          connect_nodes[node][cnt].each do |conn|
            if cnt == 2
              tmp[cnt].push(conn) if Hypercube::get_distance(neighbor, conn) == 1
            else
              # 距離cnt>2の到達可能ノードの算出
              tmp[cnt-1].each do |i|
                tmp[cnt].push(conn) if Hypercube::get_distance(i, conn) == 1 && !tmp[cnt].include?(conn)
              end

              # 迂回可能ノードの算出
              connect_nodes[node][cnt-1].each do |i|
                tmp[cnt].each do |j|
                  forward[neighbor].push(i) if Hypercube::get_distance(i, j) == 1 && !tmp[cnt-1].include?(i)
                end
              end
            end
          end
        end
        preffered_nodes[node][neighbor] = tmp.values.flatten!
      end
      # 迂回ノードを追加
      forward.each do |neighbor, val|
        val.each do |fw|
          preffered_nodes[node][neighbor].push(fw) unless preffered_nodes[node].values.flatten.include?(fw)
        end
      end
    end
    preffered_nodes
  end
end
