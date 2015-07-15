require 'benchmark'
require './hypercube'

hc = Hypercube.new(6, 0)
hc.init_fault
result = Benchmark.realtime do
  hc.get_cluster_status
end

p result
