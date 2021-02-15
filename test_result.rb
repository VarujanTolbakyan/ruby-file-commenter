# method 'foo' parameter(s): (a, b)
def foo(a, b)
end

# class Foo
class Foo
  private

  # private method 'private_method_1' parameter(s): (param1)
  def private_method_1(param1)
  end

  private

  # private method 'private_method_2' parameter(s): (param1, param2, param3)
  def private_method_2(param1, param2, param3)
  end

  protected

  # protected method 'protected_method_1'
  def protected_method_1
  end

  public

  # public method 'public_method_1'
  def public_method_1
  end

  # public method 'public_method_2'
  def public_method_2
  end
end

# module Admins
# nested classes: User
# nested modules: UserBase
module Admins
  # module UserBase
  module UserBase
    # class User
    class User
      # constructor 'initialize' parameter(s): (first_name, last_name)
      def initialize(first_name, last_name)
        @first_name = first_name
        @last_name = last_name
      end

      # public method 'full_name'
      def full_name
        @first_name + @last_name
      end

      # public method 'job'
      def job
        #------#---
      end

      private

      # private method 'age'
      def age
        ##-------#
      end
    end

    # public method 'owner'
    def owner
      #--------#-----
    end

    # public method 'description' parameter(s): (list, count)
    def description list, count
      #---------#------
    end
  end
end

# method 'foo1' parameter(s): (a, b)
def foo1(a, b)
end

# module ABC
# nested classes: Bar, XYZError, Resource, Store
# nested modules: XYZ, ClassMethods, Nested
module ABC
  # class Bar inherited from ABCBase
  class Bar < ABCBase
    private

    # private method 'private_method_3'
    def private_method_3
    end

    protected

    # protected method 'protected_method_2'
    def protected_method_2
    end
  end

  # module XYZ
  module XYZ
    # module ClassMethods
    module ClassMethods
      # public method 'foo'
      def foo
      end
    end

    class << self
      private

      # private class method 'private_class_method'
      def private_class_method
      end

      public

      # class method 'public_class_method'
      def public_class_method
      end
    end

    # class XYZError inherited from StandardError 
    class XYZError < StandardError; end

    # module Nested
    module Nested
      # class method 'nested_module_method'
      def self.nested_module_method
      end

      # class Resource
      class Resource
        # class method 'public_class_method'
        def self.public_class_method
        end

        # private method 'other_private_method'
        def other_private_method
        end

        private :other_private_method

        public

        # public method 'other_public_method'
        def other_public_method
        end

        private

        # private class method 'private_class_method' parameter(s): (param)
        def self.private_class_method(param)
        end

        # class Store
        class Store
          protected

          # protected method 'protected_setter=' parameter(s): (p)
          def protected_setter=(p)
          end

          public

          # public method 'property_1'
          def property_1
          end

          # public method 'setter=' parameter(s): (property)
          def setter=(property)
          end

          # public method 'add' parameter(s): (object)
          def add(object)
            push << self
          end
        end

        public

        # public method 'pubilic_method'
        def pubilic_method
        end
      end
    end
  end
end
