require 'benchmark'
require './dualcube'
require 'yaml'
require 'pp'

def print_node(address)
  puts "%4d : #{get_binary_address(address)} [f=#{fault[address]}]" % address
end

dim = ARGV[0].to_i
dc = Dualcube.new(dim)

result = Hash.new { |h,k| h[k] = Hash.new { |h_,k_| h_[k_] = [] } }
for curr in 0...(dc.size)
  for tgt in 0...(dc.size)
    next if curr == tgt
    distance = dc.get_distance(curr, tgt)
    result[curr][distance].push tgt
  end
end

# 異なるクラスのノードに経路を取る場合の隣接節点が前方隣接節点に含まれる確率(クロスネイバー除く)
res_1 = Hash.new { |h,k| h[k] = Hash.new { |h_,k_| h_[k_] = 0 } }
node = 0
cnt = 0
for distance in 1..(2*dim+2)
  result[node][distance].each do |data|
    if !dc.same_class?(node, data) && !(dc.get_node_id(node)==dc.get_cluster_id(data))
      cnt += 1
      intmed = dc.get_intermediate_node(node, data)
      prefferred = dc.get_preffered_nodes(node, intmed)
      prefferred.each do |pre|
        next if pre == dc.get_cross_neighbor(node)
        res_1[distance][pre] += 1
      end
    end
  end
  res_1[distance]["max"] = cnt
  cnt = 0
end

# 同じクラスの異なるクラスタに経路を取る場合の隣接節点が前方隣接節点に含まれる確率(クロスネイバー除く)
res_2 = Hash.new { |h,k| h[k] = Hash.new { |h_,k_| h_[k_] = 0 } }
node = 0
cnt = 0
for distance in 1..(2*dim+2)
  result[node][distance].each do |data|
    if dc.same_class?(node, data) && dc.get_cluster_id(node)!=dc.get_cluster_id(data) &&
    dc.get_node_id(node)!=dc.get_node_id(data)
      cnt += 1
      intmed = dc.get_intermediate_node(node, data)
      prefferred = dc.get_preffered_nodes(node, intmed)
      prefferred.each do |pre|
        next if pre == dc.get_cross_neighbor(node)
        res_2[distance][pre] += 1
      end
    end
  end
  res_2[distance]["max"] = cnt
  cnt = 0
end

# 確率値の計算
res1 = {}
res2 = {}
res3 = {}

for distance in 1..(dim)
  res1[distance] = distance.to_f / dim.to_f
end

res_1.each do |hash|
  distance = hash.first
  res2[distance] = hash[1][1].to_f / hash[1]["max"].to_f if hash[1]["max"] != 0
end

res_2.each do |hash|
  distance = hash.first
  res3[distance] = hash[1][1].to_f / hash[1]["max"].to_f if hash[1]["max"] != 0
end

res = {pre_prob_1: res1, pre_prob_2: res2, pre_prob_3: res3}

open("cache/pre_prob_#{dim}.yml", "w") do |e|
  YAML.dump(res, e)
end

File.open("cache/pre_prob_#{dim}.yml") { |file| pp YAML.load(file) }
