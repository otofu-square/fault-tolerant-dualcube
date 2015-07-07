module CompleteRouting
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
end
