require 'benchmark'
require './hypercube'

hc = Hypercube.new(7)
result = Benchmark.realtime do
  hc.get_cluster_status
end

p result
gets

hc.print_nodes
hc.print_status
