require 'benchmark'
require './hypercube'

hc = Hypercube.new(5, 0.1)
result = Benchmark.realtime do
  hc.get_cluster_status
end

p result
p hc.print_status
