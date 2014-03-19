require 'plexus'
module CloudCapacitor

  class DeploymentSpaceBuilder

    def self.graph_by_price(configurations:, max_price:, max_num_instances:4)
      graph_by_prop(configurations, max_price, max_num_instances, "price")
    end

    def self.graph_by_mem(configurations:, max_price:, max_num_instances:4)
      graph_by_prop(configurations, max_price, max_num_instances, "mem")
    end

    def self.graph_by_cpu(configurations:, max_price:, max_num_instances:4)
      graph_by_prop(configurations, max_price, max_num_instances, "cpu")
    end

    private
    def self.graph_by_prop(configurations, max_price, max_num_instances, prop_method)
      configs = configurations.sort { |x,y| x.method(prop_method).call() <=> y.method(prop_method).call() }
      dg = Plexus::Digraph.new

      config_groups = array_by_price(configurations, max_price, max_num_instances)
      config_groups = config_groups.sort {|x,y| x.method(prop_method).call() <=> y.method(prop_method).call()}
      #config_groups.each {|config_group| puts"#{config_group}"}

      prop = config_groups[0].method(prop_method).call()
      vertexes = []
      vertexes_old = nil

      i = 0
      until i >= config_groups.size() do
        if(equal(prop, config_groups[i].method(prop_method).call(), 0.01))
          vertexes << config_groups[i]
        else
          add_edges(vertexes_old, vertexes, dg, prop_method)
          prop = config_groups[i].method(prop_method).call()
          vertexes_old = Array.new(vertexes)
          vertexes = []
          i = i - 1
        end
        i += 1
      end

      add_edges(vertexes_old, vertexes, dg, prop_method)

      graph = Plexus::DirectedPseudoGraph.new(dg)

      #puts"graph vertices - #{graph.vertices.size}, graph edges - #{graph.edges.size}"

      graph
    end

    def self.equal(prop, prop2, error)
      diff = prop2 - prop
      if (diff < error)
        return true
      else
        return false
      end
    end

    def self.array_by_price(configs, max_price, max_num_instances)
      config_groups = []

      for i in 0..configs.size()-1
        vm_types = []
        for j in 1..max_num_instances
          vm_types << configs[i]

          config_group = ConfigurationGroup.new(:configurations => vm_types)
          if(config_group.price < max_price)
            config_groups << config_group
          end
        end

      end

      config_groups
    end
    
    def self.new_edge(source, target, label)
      #puts "source #{source} - target #{target} - label #{label.round(2)}"
      Plexus::Arc.new(source, target, label.round(2))
    end

    def self.add_edges(vertexes_old, vertexes, arcs, prop_method)
      if(!vertexes_old.nil? && !vertexes.nil?)
        vertexes_old.each do |vertex_old|
          vertexes.each do |vertex|
            arcs << new_edge(vertex_old, vertex, vertex.method(prop_method).call() - vertex_old.method(prop_method).call())
            arcs << new_edge(vertex, vertex_old, vertex_old.method(prop_method).call() - vertex.method(prop_method).call())
          end
        end
      end
      #puts ""
    end
  end
end
