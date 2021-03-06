module Neo4j
  module Rails
    module Relationships

      # TODO, reuse for incoming relationships ?
      class OutgoingRelationship #:nodoc:
        include Enumerable

        def initialize(from_node, mapper)
          @from_node = from_node
          @mapper    = mapper
        end

        def <<(other)
          @mapper.create_relationship_to(@from_node, other)
          self
        end

        def size
          @mapper.dsl.all_relationships(@from_node).size
        end

        def each(&block)
          @mapper.each_node(@from_node, :outgoing, &block)
        end
      end


      def write_changed_relationships #:nodoc:
        @relationships.each_value do |mapper|
          mapper.persist
        end
      end

      def valid_relationships? #:nodoc:
        !@relationships.values.find {|mapper| !mapper.valid?}
      end

      def _decl_rels_for(type) #:nodoc:
        dsl = super
        @relationships[type] ||= Mapper.new(type, dsl, self)
      end


      def clear_relationships #:nodoc:
        @relationships = {}
      end


      # If the node is persisted it returns a Neo4j::NodeTraverser
      # otherwise create a new object which will handle creating new relationships in memory.
      # If not persisted the traversal method like prune, expand, filter etc. will not be available
      #
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      #
      def outgoing(rel_type)
        if persisted?
          super
        else
          dsl = _decl_rels_for(rel_type)
          OutgoingRelationship.new(self, dsl)
        end
      end
    end
  end
end
