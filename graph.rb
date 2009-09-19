#!/opt/local/bin/ruby1.9 -w

require 'set'

class Hash
  def keys_sub other_hash; self.keys.to_set.subset?( other_hash.keys.to_set ) end
end

# todo consider making edge a hash of hashes
class Graph
  def initialize; @v_id = 0; @e_id = 0; @vertices = Set.new; @edges = Set.new end
  attr_reader :v_id, :e_id, :vertices, :edges
  def order; @vertices.size end
  def size; @edges.size end
  def to_s; 
    s = "(Vertices["
    if @vertices.empty? then s << "], Edges[ " else @vertices.each {|v| s << v.to_s+", " } end
    s.sub!(/\}, $/,"}], Edges[")
    if @edges.empty? then s << "])" else @edges.each {|e| s << e.to_s+", " } end
    s.sub(/], $/,"]])")
  end
  def each_vertex; @vertices.each {|v| yield v} end
  def each_edge; @edges.each {|e| yield e} end
  def add_vertex(properties);
    if properties.is_a? Hash then 
      @vertices.add(properties) ? (@v_id+=1; properties[:id] = @v_id; properties) : nil
    else
      raise(ArgumentError, "arg was \'"+properties.class.to_s+"\', but add_vertex takes \'Hash\'")
    end
  end
  def add_edge(prop_hash, s_rules_hash, t_rules_hash); 
    if ( prop_hash.is_a?(Hash) && s_rules_hash.is_a?(Hash) && t_rules_hash.is_a?(Hash) ) then
      @edges.add([prop_hash, s_rules_hash, t_rules_hash]) ? (@e_id+=1; prop_hash[:id] = @e_id; [prop_hash, s_rules_hash, t_rules_hash]) : nil
    else
      raise(ArgumentError, "args were \'"+s_rules_hash.class.to_s+","+t_rules_hash.class.to_s+"\', but add_vertex takes \'Hash,Hash\'")
    end
  end
  def get_vertex(select_hash);
    vset = Set.new; vreturn = Hash.new
    each_vertex do |v| 
      count = select_hash.size
      select_hash.each {|key,value| count -=1 if (v[key] == value)}
      (vset << v; vreturn = v) if count == 0
    end
    if vset.size == 1 then return vreturn else raise(ArgumentError, "Select hash \'#{select_hash}\' wasn't unique!") end
  end
  def get_vertices(select_hash);
    vset = Set.new;
    each_vertex do |v| 
      count = select_hash.size
      select_hash.each {|key,value| count -=1 if (v[key] == value)}
      vset << v if count == 0
    end
    return vset
  end
  def vertices_edit!(select_hash, edit_hash)
    vset = Set.new
    each_vertex do |v| 
      count = select_hash.size
      select_hash.each {|key,value| count -=1 if (v[key] == value)}
      (v.merge!(edit_hash); vset << v) if count == 0
    end
    return vset
  end
end
