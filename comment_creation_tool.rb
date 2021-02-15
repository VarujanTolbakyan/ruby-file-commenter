require 'active_support/inflector'
require_relative 'my_string'

class CommentCreationTool
  attr_reader :file_read_path, :file_write_path, :file_content

  def initialize(file_read_path, file_write_path)
    @file_read_path = file_read_path
    @file_write_path = file_write_path
    @file_content = File.readlines file_read_path
  end

  def self.result(file_read_path, file_write_path)
    new(file_read_path, file_write_path).result
  end

  def result
    @comments = {}
    @comments_keys = []
    file_content = module_and_class_commenter self.file_content

    file_content = file_content.map do |line|
      line = @comments[line] + line if @comments[line]
      line
    end
    File.write file_write_path, file_content.join
  end

  private

  def module_and_class_commenter(file_content)
    @nested_modules = ''
    @nested_classes = ''

    private_protected_method_names(file_content)

    file_content = file_content.map do |line|
      space_count = line.starting_space_count

      line = add_comment(:module, space_count, line)
      line = add_comment(:class, space_count, line)

      when_start_end(line)
      method_commenter(line, space_count)
    end
    file_content
  end

  def add_comment(obj_name, space_count, line)
    obj_name = obj_name.to_sym
    space = start_spaces(space_count)
    name_by_space = "#{space}#{obj_name}"

    return line unless line.start_with?(name_by_space)
    return line if line.has? '<<'

    inheritance = ''
    name = line.rm_chr('<').split
    name.delete 'end'
    inheritance = " inherited from #{name.last.rm_chr ';'}" if line.has? '<'
    name = name[1].rm_chr ';'

    if space_count > 0
      case obj_name
      when :module
        @nested_modules << "#{@nested_modules.empty? ? ' ' : ', '}#{name}"
      when :class
        @nested_classes << "#{@nested_classes.empty? ? ' ' : ', '}#{name}"
      end
      "#{space}# #{obj_name} #{name}#{inheritance}\n#{line}"
    else
      @comments_keys << line
      @comments[line] = "# #{obj_name} #{name}#{inheritance}\n"
      line
    end
  end

  def method_commenter(line, space_count)
    space = start_spaces(space_count)
    class_method_finder(line, space)

    return line unless line.start_with?("#{space}def ")

    method_name = line.rm_chr("#{space}def ").tr '()', ' '
    method_name = method_name.rm_chr ';'
    args = method_name.split
    args.delete 'end'
    method_name = args.delete args.first
    args = args.map(&:strip).join ' ' unless args.empty?

    function_comment(line, method_name, args, space)
  end

  def class_method_finder(line, space)
    if line.start_with?("#{space}class") && line.end_with?("<< self\n", "<<self\n")
      @is_class_method = true
      @space = space
    elsif @is_class_method && line.start_with?("#{@space}end")
      @is_class_method = nil
      @space = nil
    end
  end

  def private_protected_method_names(file_content)
    @private_names = []
    @protected_names = []

    file_content.each do |line|
      space_count = line.starting_space_count
      space = start_spaces space_count
      adder_method_name 'private', line, space
      adder_method_name 'protected', line, space
      adder_method_name 'public', line, space
    end
  end

  def adder_method_name(visibility, line, space)
    return unless visibility.or_eql? 'private', 'protected', 'public'

    if line.start_with? "#{space}#{visibility}\n", "#{space}#{visibility} "
      line_split = line.split
      if line_split.count > 1
        line_split.delete visibility
        line_split = line_split.map { |e| e.delete ':,' }
        case visibility
        when 'private'
          @private_names += line_split
        when 'protected'
          @protected_names += line_split
        end
      else
        cases_of_method_visibility(visibility, space)
      end
    elsif line.start_with? "#{@space_of_private}def", "#{@space_of_protected}def"
      @private_names << line if @is_private
      @protected_names << line if @is_protected
    end
  end

  def function_comment(line, name, args, space)
    is_private = multiple_includes? @private_names, line, name

    if space == ''
      "# method '#{name}'#{parameters args}\n#{line}"
    elsif name == 'initialize'
      "#{space}# constructor '#{name}'#{parameters args}\n#{line}"
    elsif name.has?('self.') || @is_class_method
      name = name.split('.').last if name.has?('self.')
      "#{space}##{is_private ? ' private' : ''} class method "\
      "'#{name}'#{parameters args}\n#{line}"
    elsif multiple_includes? @protected_names, line, name
      "#{space}# protected method '#{name}'#{parameters args}\n#{line}"
    else
      "#{space}# #{is_private ? 'private' : 'public'} method "\
      "'#{name}'#{parameters args}\n#{line}"
    end
  end

  def start_spaces(space_count)
    ' ' * space_count
  end

  def nested(name)
    return unless name.or_eql? 'class', 'module'

    nested = name == 'class' ? @nested_classes : @nested_modules

    nested.empty? ? '' : "# nested #{name.pluralize}:#{nested}\n"
  end

  def when_start_end(line)
    return unless line.start_with? 'end'

    key = @comments_keys.last
    if key
      @comments[key] += nested('class') + nested('module')
      @nested_classes = ''
      @nested_modules = ''
    end
  end

  def parameters(args)
    return '' if args.empty?

    " parameter(s): (#{args})"
  end

  def multiple_includes?(object, *elements)
    result = []
    elements.each do |element|
      result << object.include?(element)
    end
    result.any?
  end

  def cases_of_method_visibility(visibility, space)
    case visibility
    when 'private'
      @is_private = true
      @is_protected = nil
      @is_public = nil
      @space_of_private = space
    when 'protected'
      @is_protected = true
      @is_private = nil
      @is_public = nil
      @space_of_protected = space
    else
      @is_public = true
      @is_private = nil
      @is_protected = nil
      @space_of_public = space
    end
  end
end

file_read_path = ARGV[0]
file_write_path = ARGV[1]

all_is_ok = 'Congratulations all is good! 👍👍👍'
test_source = 'test_source.rb'
test_result = 'test_result.rb'

if file_read_path && file_write_path
  CommentCreationTool.result file_read_path, file_write_path
  puts file_read_path
  puts all_is_ok
  puts "see result in #{file_write_path}"
elsif file_read_path.nil? && file_write_path.nil?
  CommentCreationTool.result test_source, test_result
  puts all_is_ok
  puts "\n################### Before ####################\n\n #{File.read test_source}"
  puts "\n################### After #####################\n\n #{File.read test_result}"
else
  puts "please fill in correctly as shown in the example run\
  `ruby ~/Directory/comment_creation_tool.rb ~/where/from/read/the/file\
  ~/where/to/write/the/file`"
end
