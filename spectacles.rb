#!/opt/local/bin/ruby1.9 -w
require 'matrix'
require 'graph'

# We should literally be using generators here (for pattern generation) and calling animate on the generator

# Pass Spectacles a data object (right now, it's a graph) about which it assumes some interface ...
class Spectacles
  
  def initialize stack, data
    @energy_k = 0 # we could collect the kinetic energy of the graph
    @stack = stack 
    @stack.app do
      @d = data;
      @d.vertices_edit!({:group=>"float"},{:x_=>Vector[300,300],:dx_=>Vector[0.0,0.0],:clicked=>false})
      @d.each_vertex {|v| v[:x_] += Vector[rand*50-100,rand*50-100] }
    end
    @clicked=false
  end
  
  Coulomb = 150
  Spring = 1
  Damping = 0.3 # 1 - friction_k
  
  attr_reader :clicked, :d
  attr_accessor :d
  
  def init_check!(v) # FIXME this is dirty, should know which elements are added ...
     v[:x_]=Vector[300,300] unless v[:x_]
     v[:dx_]=Vector[0.0,0.0] unless v[:dx_]
     v[:clicked]=false unless v[:clicked]
  end
  
  def coulomb_repulsion(x1_, x2_)
    dx_ = x1_ - x2_
    l = 2 * (dx_[0] * dx_[0] + dx_[1] * dx_[1]);
    dx_.map {|dx| dx == 0 ? 0 : Coulomb * dx / l }
  end
  
  def hooke_attraction(x1_, x2_, proportion)
    dx_ = x1_ - x2_
    dx_.map {|dx| dx == 0 ? 0 : - dx / (Spring * proportion) } # linear decrease?
  end
  
  def forces v1
    this = self
    init_check! v1;
    @stack.app do 
      net_force = Vector[0.0,0.0]
      @d.each_vertex {|v2| this.init_check! v2; net_force += this.coulomb_repulsion(v1[:x_],v2[:x_]) }
      @d.connections(v1).each {|v2| net_force += this.hooke_attraction(v1[:x_],v2[:x_],@d.size) }
      v1[:dx_] = (v1[:dx_] + net_force) * Damping 
    end
  end
  
  def physics
    this = self
    @stack.app { @d.each_vertex {|v| this.forces v } }
    @stack.app do
      @d.each_vertex do |v| 
        v[:x_] = this.inbounds(v[:x_]+v[:dx_]) unless (v[:fixed]==true || v[:clicked]==true)
      end
    end
  end
  
  def inbounds item # TODO don't assume that the window size is fixed, or a square!
    item.map {|x| if x<0 then 0 elsif x>@stack.height then @stack.height else x end }
  end
  
  def grab_vertex x, y
    @stack.app do
      @d.each_vertex do |v| 
        if (v[:x_][0]>x-5 && v[:x_][0]<x+5 && v[:x_][1]>y-5 && v[:x_][1]<y+5) then v[:clicked]=true end
      end
    end
    @clicked=true
  end
  
  def letgo_vertex
    this = self
    @stack.app do
      @d.gv({:clicked=>true})[:clicked]=false
    end
    @clicked=false
  end
  
  def draw_vertices
    @stack.app { @d.each_vertex {|v| oval(v[:x_][0], v[:x_][1], 10, :center=>'true') } } 
  end
  
  def draw_edges
    @stack.app { @d.each_edge {|e| line(@d.gv(e[1])[:x_][0], @d.gv(e[1])[:x_][1], @d.gv(e[2])[:x_][0], @d.gv(e[2])[:x_][1], :strokewidth=>2) } }
  end
  
  def draw_all
    this = self
    @stack.app { background "#DFA"; this.draw_vertices; this.draw_edges }
  end
  
  def see!
    this = self
    @stack.app do
      animate(60) { |frame| this.physics; clear { this.draw_all } }
      click        { |button,top,left| this.grab_vertex(top, left) }
      release      { |button,top,left| this.letgo_vertex }
      motion       { |top, left| if this.clicked then @d.gv({:clicked=>true})[:x_]=Vector[top,left] end }
    end
  end
end

Shoes.app :title=>"Spectacles!" do
  background rgb(0.122,0.176,0.157)
  $gr = Graph.new
  $graph_rules = ""
  $open=false
  stack :margin=>10 do
    #background rgb(0.027,0.043,0.039)
    background rgb(0.153,0.008,0.0)
    title strong( "What shall we spectate?" ), :align => 'center', :stroke=>rgb(0.761,0.22,0.0)
  end
  flow :margin=>10 do
    background "#DAF"
    @filename = "No file selected"
    button("Open?") do
      #@filename = ask_open_file
      @filename="/Users/zara/Programming/Cognition/spectacles/test.txt"
      @file = File.read(@filename)
      @p1.text = @filename
      @eb.text = @file
    end
    button("See!") do
      graph_read = @eb.text
      @eb.text = ""
      $graph_rules << graph_read << "\n"
      @p3.text = $graph_rules
      graph_read.each_line {|line| $gr.instance_eval(line)}
      @pretty_graph = $gr.dup
      @pretty_graph.each_vertex {|v| v.delete_if{|k,v| k == :x_ || k == :dx_ || k == :clicked } }
      @p2.text = @pretty_graph.to_s
      if $open == false then
        $win = window :resizable=>false, :height=>600, :width=>600 do
          $spectacle = Spectacles.new(self, $gr)
          $spectacle.see!
        end
        $win.start { $open=true }
      end
    end
    button("Clear") do 
      $graph_rules = ""
      $gr = Graph.new
      @filename = "No file selected"
      @p1.text = @filename
      @eb.text = ""
      @p2.text = ""
      @p3.text = ""
    end
  end
  stack :margin=>10 do
    background gray
    @p1 = para @filename, :size=>10, :stroke=>white, :align=>'center'
    @eb = edit_box("Nothing")
    @eb.style :width=>1.0, :height=>200, :align=>'center', :margin=>20
  end
  flow :margin=>10 do
    stack :width=>0.5, :margin=>5 do
      background "#AFD"
      para "Description", :align=>'center'
      @p2 = para :size=>10
    end
    stack :width=>0.5, :margin=>5 do
      background "#ADF"
      para "Rules", :align=>'center'
      @p3 = para :size=>10
    end
  end
end
