#!/opt/local/bin/ruby1.9 -w
require './graph.rb'

# We should literally be using generators here (for pattern generation) and calling animate on the generator

# Pass Spectacles a data object about which it assumes some interface ...
class Spectacles
  def initialize stack, data
    @repel_force = 0.001
    @spring_force = 1
    @stack = stack 
    @stack.app { @d = data; @d.vertices_edit!({:group=>1},{:x=>200,:y=>200,:xv=>0.0,:yv=>0.0}) }
  end
  attr_reader :repel_force, :spring_force
  def forces v1
    this = self
    xvel, yvel = 0, 0
    @stack.app do 
      @d.each_vertex do |v2|
        dx, dy = v1[:x]-v2[:x], v1[:y]-v2[:y]
        # lx, ly = dx * dx.abs, dy * dy.abs
        # v1[:xv] += if lx != 0 then this.repel_force / lx else rand*2-1 end
        # v1[:yv] += if ly != 0 then this.repel_force / ly else rand*2-1 end
        l = 2 * (dx * dx + dy * dy)
        xvel = if l != 0 then (dx * 150.0) / l else rand-0.5 end 
        yvel = if l != 0 then (dy * 150.0) / l else rand-0.5 end
      end
      @d.each_edge do |e|
        if @d.get_vertex(e[1])[:id] == v1[:id] then 
          # dx pos => force pulls x1 to x2, dx neg => force pulls x1 to x2 (neg)
          # v2 = @d.get_vertex(e[2])
          # dx, dy = v2[:x] - v1[:x], v2[:y] - v1[:y]
          # xaccel = if dx != 0 then this.spring_force * dx/dx.abs else rand*2-1 end
          # yaccel = if dy != 0 then this.spring_force * dy/dy.abs else rand*2-1 end
          # v1[:xv] += xaccel
          # v1[:yv] += yaccel
          # v2[:xv] += -xaccel
          # v2[:xv] += -xaccel
        end
        v1[:xv] = xvel
        v1[:yv] = yvel
      end
    end
  end
  def physics
    this = self
    @stack.app { @d.each_vertex {|v| this.forces v } }
    @stack.app { @d.each_vertex {|v| (v[:x]+=v[:xv]; v[:y]+=v[:yv]) unless v[:fixed]=='true'} }
  end
  def draw_vertices
    @stack.app { @d.each_vertex {|v| oval(v[:x],v[:y],20,:center=>'true')} } 
  end
  def draw_edges
    @stack.app do 
      @d.each_edge do |e| 
        line(@d.get_vertex(e[1])[:x], @d.get_vertex(e[1])[:y], @d.get_vertex(e[2])[:x], @d.get_vertex(e[2])[:y], :strokewidth=>5)
      end
    end
  end
  def draw_all
    this = self
    physics
    @stack.app { background "#DFA"; this.draw_vertices; this.draw_edges }
  end
  def see!
    this = self
    @stack.app { animate(10) { clear { this.draw_all } } }
  end
end

Shoes.app :title => "Spectacles!" do
  @g = Graph.new
  @g.add_vertex( {:name=>"v1",:group=>1,:fixed=>'true'} ) # need multi vertex add
  @g.add_vertex( {:name=>"v2",:group=>1,:fixed=>'false'} ) 
  @g.add_vertex( {:name=>"v3",:group=>1,:fixed=>'false'} )
  @g.add_vertex( {:name=>"v4",:group=>1,:fixed=>'false'} )
  @g.add_vertex( {:name=>"v5",:group=>1,:fixed=>'false'} )
  @g.add_vertex( {:name=>"v6",:group=>1,:fixed=>'false'} )
  @g.add_edge( {:name=>"e1"}, {:name=>"v1"}, {:name=>"v2"} ) # need multi edge add
  @g.add_edge( {:name=>"e2"}, {:name=>"v1"}, {:name=>"v3"} )
  @g.add_edge( {:name=>"e3"}, {:name=>"v1"}, {:name=>"v4"} )
  @g.add_edge( {:name=>"e4"}, {:name=>"v1"}, {:name=>"v5"} )
  @g.add_edge( {:name=>"e5"}, {:name=>"v1"}, {:name=>"v6"} )
  @spectacle = Spectacles.new self, @g
  @spectacle.see!
end
