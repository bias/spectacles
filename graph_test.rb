#!/opt/local/bin/ruby1.9 -w

require 'test/unit'
require 'graph'

class Hash_Test < Test::Unit::TestCase
  def setup; @h = {:a=>1,:b=>2}; @g = {:a=>1} end
  def test_sub; assert_equal(true, @g.keys_sub(@h)) end
end

class Graph_Test < Test::Unit::TestCase
  def setup; 
    @h = Graph.new()
    @g = Graph.new(); 
    @v1 = @g.add_vertex( {:name=>"v1"} ); 
    @v2 = @g.add_vertex( {:name=>"v2"} ); 
    @e = @g.add_edge( {:name=>"e1"}, {:name=>"v1"}, {:name=>"v2"} ) 
  end
  def test_init
    assert_equal(
      "Vertices[\n{:name=>\"v1\", :id=>1}, \n{:name=>\"v2\", :id=>2}], \nEdges[\n[{:name=>\"e1\", :id=>1}, {:name=>\"v1\"}, {:name=>\"v2\"}]]", 
      @g.to_s )
    assert_equal(0, @h.v_id)
    assert_equal(0, @h.order)
    assert_equal(0, @h.e_id)
    assert_equal(0, @h.size)
  end
  # def test_load
  #   @g1 = Graph.load("Vertices[\n{:name=>\"v1\", :id=>1}, \n{:name=>\"v2\", :id=>2}], \nEdges[\n[{:name=>\"e1\", :id=>1}, {:name=>\"v1\"}, {:name=>\"v2\"}]]")
  #   assert_equal(
  #     "Vertices[\n{:name=>\"v1\", :id=>1}, \n{:name=>\"v2\", :id=>2}], \nEdges[\n[{:name=>\"e1\", :id=>1}, {:name=>\"v1\"}, {:name=>\"v2\"}]]",
  #     @g1.to_s
  #     )
  #   #assert(@g1==@g)
  # end
  # def test_marshal
  #   @filename = "unit_marshel_dump"
  #   @f = File.open(@filename, "w")
  #   Marshal.dump(@g, @f)
  #   @f.close
  #   @file_contents = File.read(@filename)
  #   #Marshal.load()
  # end
  def test_add_vertex; # implicitly tests: current_vID, order, to_s
    assert_equal("v1", @v1[:name])
    assert_equal(1, @v1[:id])
    assert_equal("v2", @v2[:name])
    assert_equal(2, @v2[:id])
    assert_equal(2, @g.v_id)
    assert_equal(2, @g.order)
    assert_raise(ArgumentError) { @g.add_vertex(1) }
  end
  #def test_add_vertices; assert(nil) end
  def test_add_edge
    assert_equal("e1", @e[0][:name])
    assert_equal("v1", @e[1][:name])
    assert_equal("v2", @e[2][:name])
    assert_equal(1, @e[0][:id])
    assert_equal(1, @g.e_id)
    assert_equal(1, @g.size)
    assert_raise(ArgumentError) { @g.add_edge( {:name=>"e1"}, "v1", {:name=>"v2"}) }
    assert_raise(ArgumentError) { @g.add_edge( {:name=>"e1"}, {:name=>"v1"}, "v2") }
    assert_raise(ArgumentError) { @g.add_edge( {:name=>"e1"}, "v1", "v2") }
    assert_raise(ArgumentError) { @g.add_edge( "e1", "v1", "v2") }
    assert_raise(ArgumentError) { @g.add_edge( "e1", {:name=>"v1"}, "v2") }
  end
  #def test_add_edges; assert(nil) end
  def test_each_vertex
    i=1; @g.each_vertex {|v| assert_equal(i, v[:id]); i+=1}
  end
  def test_each_edge
    i=1; @g.each_edge {|e| assert_equal(i, e[0][:id]); i+=1}
  end
  def test_select_vertices; end
  def test_get_vertex
    v1 = @g.get_vertex({:name=>"v1"})
    assert_equal("{:name=>\"v1\", :id=>1}", v1.inspect)
    @g.add_vertex({:name=>"v1"})
    assert_raise(ArgumentError) { @g.get_vertex({:name=>"v1"}) }
  end
  def test_get_vertices
    @g.add_vertex({:name=>"v1",:new=>"true"})
    vset = @g.get_vertices({:name=>"v1"})
    set_expect = Set.new; set_expect << {:name=>"v1",:id=>1} << {:name=>"v1",:id=>3,:new=>"true"}
    assert_equal(set_expect, vset)
  end
  def test_vertices_edit! # doesn't update edges associated with vertex changes (but IDs don't change), returns vertex set
    vmod = @g.vertices_edit!({:name=>"v1"}, {:name=>"v3",:new=>"true"})
    s = Set.new; s << {:name=>"v3",:id=>1,:new=>"true"}
    assert_equal(s, vmod)
  end
  def test_targets
    vset = @g.targets( @g.gv({:name=>"v1"}) )
    set_expect = Set.new; set_expect << {:name=>"v2", :id=>2}
    assert_equal(set_expect, vset)
    @g.add_vertex({:name=>"v3"})
    @g.add_edge( {:name=>"e2"}, {:name=>"v1"}, {:name=>"v3"})
    vset = @g.targets( @g.gv({:name=>"v1"}) )
    set_expect << {:name=>"v3", :id=>3}
    assert_equal(set_expect, vset)
  end
  def test_sources
    vset = @g.sources( @g.gv({:name=>"v2"}) )
    set_expect = Set.new; set_expect << {:name=>"v1", :id=>1}
    assert_equal(set_expect, vset)
    @g.add_vertex({:name=>"v3"})
    @g.add_edge( {:name=>"e2"}, {:name=>"v3"}, {:name=>"v2"})
    vset = @g.sources( @g.gv({:name=>"v2"}) )
    set_expect << {:name=>"v3", :id=>3}
    assert_equal(set_expect, vset)
  end 
  def test_connections
    vset = @g.connections( @g.gv({:name=>"v2"}) )
    set_expect = Set.new; set_expect << {:name=>"v1", :id=>1}
    assert_equal(set_expect, vset)
    @g.add_vertex({:name=>"v3"})
    @g.add_edge( {:name=>"e2"}, {:name=>"v2"}, {:name=>"v3"})
    vset = @g.connections( @g.gv({:name=>"v2"}) )
    set_expect << {:name=>"v3", :id=>3}
    assert_equal(set_expect, vset)
  end
end