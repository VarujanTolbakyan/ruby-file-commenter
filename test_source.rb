def foo(a, b)
end

class Foo
  private

  def private_method_1(param1)
  end

  private

  def private_method_2(param1, param2, param3)
  end

  protected

  def protected_method_1
  end

  public

  def public_method_1
  end

  def public_method_2
  end
end

module Admins
  module UserBase
    class User
      def initialize(first_name, last_name)
        @first_name = first_name
        @last_name = last_name
      end

      def full_name
        @first_name + @last_name
      end

      def job
        #------#---
      end

      private

      def age
        ##-------#
      end
    end

    def owner
      #--------#-----
    end

    def description list, count
      #---------#------
    end
  end
end

def foo1(a, b)
end

module ABC
  class Bar < ABCBase
    private

    def private_method_3
    end

    protected

    def protected_method_2
    end
  end

  module XYZ
    module ClassMethods
      def foo
      end
    end

    class << self
      private

      def private_class_method
      end

      public

      def public_class_method
      end
    end

    class XYZError < StandardError; end

    module Nested
      def self.nested_module_method
      end

      class Resource
        def self.public_class_method
        end

        def other_private_method
        end

        private :other_private_method

        public

        def other_public_method
        end

        private

        def self.private_class_method(param)
        end

        class Store
          protected

          def protected_setter=(p)
          end

          public

          def property_1
          end

          def setter=(property)
          end

          def add(object)
            push << self
          end
        end

        public

        def pubilic_method
        end
      end
    end
  end
end
