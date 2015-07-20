#require './hypercube'

module CompleteRouting
  # def get_cube_status
  #   # 3次元ハッシュを定義
  #   connect_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }

  #   (@dim+1).times do |cnt|
  #     @size.times do |current|
  #       next if @fault[current] == 1 # 自身が故障していたらスルー

  #       @neighbors[current].each do |neighbor|
  #         if cnt == 0
  #           connect_nodes[current][1].push(neighbor) unless @fault[neighbor] == 1
  #         else
  #           connect_nodes[neighbor].each_value do |nodes|
  #             nodes.each do |node|
  #               next if 0 == distance = Hypercube::get_distance(current, node)
  #               connect_nodes[current][distance].push(node) unless connect_nodes[current][distance].include?(node)
  #             end
  #           end
  #         endt
  #       end
  #     end
  #   end

  #   preffered_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }
  #   @size.times do |node|
  #     forward = Hash.new { |hash,key| hash[key] = [] }
  #     connect_nodes[node][1].each do |neighbor|
  #       # 直径+1
  #       tmp = Hash.new { |hash,key| hash[key] = [] }
  #       for cnt in 2..connect_nodes[node].length
  #         connect_nodes[node][cnt].each do |conn|
  #           if cnt == 2
  #             tmp[cnt].push(conn) if Hypercube::get_distance(neighbor, conn) == 1
  #           else
  #             # 距離cnt>2の到達可能ノードの算出
  #             tmp[cnt-1].each do |i|
  #               tmp[cnt].push(conn) if Hypercube::get_distance(i, conn) == 1 && !tmp[cnt].include?(conn)
  #             end

  #             # 迂回可能ノードの算出
  #             connect_nodes[node][cnt-1].each do |i|
  #               tmp[cnt].each do |j|
  #                 forward[neighbor].push(i) if Hypercube::get_distance(i, j) == 1 && !tmp[cnt-1].include?(i)
  #               end
  #             end
  #           end
  #         end
  #       end
  #       preffered_nodes[node][neighbor] = tmp.values.flatten!
  #     end
  #     # 迂回ノードを追加
  #     forward.each do |neighbor, val|
  #       val.each do |fw|
  #         preffered_nodes[node][neighbor].push(fw) unless preffered_nodes[node].values.flatten.include?(fw)
  #       end
  #     end
  #   end
  #   preffered_nodes
  # end

  def decide_next_node(s, d)
    return if get_distance(s, d) == 1

    case 
    when same_cluster?(s, d) # 2点が同じクラスタに位置する場合
      @preffered_nodes[s].each do |key, val|
        next_node = key if val.include?(d)
      end
      # next_nodeが定まらなかった場合
      next_node = get_cross_neighbor(s) if !defined?(next_node) && fault[get_cross_neighbor(s)] == 0
    when !same_class?(s, d)  # 2点が異なるクラスに位置する場合
      if get_node_id(s) == get_cluster_id(d)
        next_node = get_cross_neighbor(s) if fault[get_cross_neighbor(s)] == 0
      else
        @preffered_nodes[s].each do |key, val|
          # 中間目的接点に向かう
          next_node = key if val.include?(get_intermediate_node(s, d))
        end
        # next_nodeが定まらなかった場合
        next_node = get_cross_neighbor(s) if fault[get_cross_neighbor(s)] == 0
      end
    else # 同じクラスの異なるクラスタにある場合
    end
      
  end

  def get_status_for_dualcube
    (2**@dim).times do |cluster_id|
      get_cluster_status(0, cluster_id)
      get_cluster_status(1, cluster_id)
    end
  end

  def get_cluster_status(class_id, cluster_id)
    # 3次元ハッシュを定義
    connect_nodes = Hash.new { |hash,key| hash[key] = Hash.new { |hash,key| hash[key] = [] } }
    cluster_nodes = self.get_cluster_nodes(class_id, cluster_id)

    # cross neigborの胡椒状況を格納
    cluster_nodes.each do |node|
      @cross_status[node].push(node) if fault[get_cross_neighbor(node)] == 0
    end

    (@dim+1).times do |round|
      cluster_nodes.each do |current|
        next if @fault[current] == 1 # 自身が故障していたらスルー

        @neighbors[current].each do |neighbor|
          next if neighbor == get_cross_neighbor(current)
          if round == 0
            unless @fault[neighbor] == 1
              connect_nodes[current][1].push(neighbor)
              @cross_status[current].push(neighbor) if @fault[get_cross_neighbor(neighbor)] == 0
            end
          else
            connect_nodes[neighbor].each_value do |nodes|
              nodes.each do |node|
                next if 0 == distance = get_distance(current, node)
                unless connect_nodes[current][distance].include?(node)
                  connect_nodes[current][distance].push(node)
                  @cross_status[current].push(node) if fault[get_cross_neighbor(node)] == 0
                end
              end
            end
          end
        end
      end
    end

    cluster_nodes.each do |node|
      forward = Hash.new { |hash,key| hash[key] = [] }
      connect_nodes[node][1].each do |neighbor|
        # 直径+1
        tmp = Hash.new { |hash,key| hash[key] = [] }
        for cnt in 2..connect_nodes[node].length
          connect_nodes[node][cnt].each do |conn|
            if cnt == 2
              tmp[cnt].push(conn) if get_distance(neighbor, conn) == 1
            else
              # 距離cnt>2の到達可能ノードの算出
              tmp[cnt-1].each do |i|
                tmp[cnt].push(conn) if get_distance(i, conn) == 1 && !tmp[cnt].include?(conn)
              end

              # 迂回可能ノードの算出
              connect_nodes[node][cnt-1].each do |i|
                tmp[cnt].each do |j|
                  forward[neighbor].push(i) if get_distance(i, j) == 1 && !tmp[cnt-1].include?(i)
                end
              end
            end
          end
        end
        @preffered_nodes[node][neighbor] = tmp.values.flatten!
      end
      # 迂回ノードを追加
      forward.each do |neighbor, val|
        val.each do |fw|
          @preffered_nodes[node][neighbor].push(fw) unless @preffered_nodes[node].values.flatten.include?(fw)
        end
      end
    end
  end
end
