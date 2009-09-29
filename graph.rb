#!/opt/local/bin/ruby1.9 -w

require 'set'
# require 'rubygems' 
# require 'backports' # the big guns if we can't add better to_s to hash ...

class Hash
  def keys_sub other_hash; self.keys.to_set.subset?( other_hash.keys.to_set ) end
  def values_sub other_hash; self.values.to_set.subset?( other_hash.values.to_set ) end
  def keyvalue_sub other_hash; keys_sub(other_hash) && values_sub(other_hash) end
end

# todo consider making edge a hash of hashes
class Graph
  def initialize; @v_id = 0; @e_id = 0; @vertices = Set.new; @edges = Set.new end
  def initialize_copy(orig)
    @vertices = Set.new
    orig.vertices.each {|v| @vertices << v.dup }
    @edges = Set.new
    orig.edges.each {|e| @edges << e.dup }
  end
  attr_reader :v_id, :e_id, :vertices, :edges
  def order; @vertices.size end
  def size; @edges.size end
  def to_s; 
    s = "Vertices[\n"
    if @vertices.empty? then s << "], \nEdges[\n" else @vertices.each {|v| s << v.inspect+", \n" } end
    s.sub!(/\}, \n$/,"}], \nEdges[\n")
    if @edges.empty? then s << "]" else @edges.each {|e| s << e.inspect+", \n" } end
    s.sub(/\], \n$/,"]]")
  end
  #def _dump(limit); to_s end
  # def self.dynamic_load(str) 
  #   edges = false
  #   str.each_line do |line| 
  #     if line =~ /^Edges/ then edges = true end
  #     if edges then
  #       #
  #     else
  #       #
  #     end
  #   end
  #   return Graph.new
  # end
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
  def gv(sh); get_vertex sh end
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
  # gets vertices that match e, for every e, if e has subhash of v
  def targets v
    vset = Set.new
    each_edge {|e| vset |= get_vertices(e[2]) if e[1].keyvalue_sub(v) }
    return vset
  end
  def sources v
    vset = Set.new
    each_edge {|e| vset |= get_vertices(e[1]) if e[2].keyvalue_sub(v) }
    return vset
  end
  def connections v
    return sources(v)|targets(v)
  end
end
