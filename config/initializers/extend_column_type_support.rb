# Redefine ActiveRecord::ConnectionAdapters::Column#simplified_type.
#
# Reference: Paolo Perrotta, Metaprogramming Ruby 2, Chapter 11, "The
# Fall of alias_method_chain".
#
module ActiveRecord
  module ConnectionAdapters
    module DomainSupport
      # Deprecation Warning: The ActiveRecord::ConnectionAdapters::Column#simplified_type method doesn't exist in Rails > 4.1.8 and this initializer will then have to be rewritten.
      def simplified_type(field_type)
        case field_type 
        when /level_of_access/i
          :integer
        when /statnames/i
          :text
        else
          super(field_type)
        end
      end
    end

    class Column
      prepend DomainSupport
    end
  end
end
