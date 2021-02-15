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
    @comments = []
    file_content = module_and_class_commenter self.file_content

    @comments << "#{@nested_modules.join}\n" if @nested_modules.count > 1
    @comments << "#{@nested_classes.join}\n" if @nested_classes.count > 1

    file_content = file_content.map do |line|
      line = @comments.join + line if line.start_with? 'module', 'class'
      line
    end
    File.write file_write_path, file_content.join
  end

  private

  def module_and_class_commenter(file_content)
    @nested_modules = ["# nested modules:"]
    @nested_classes = ["# nested classes:"]
    private_protected_method_names(file_content)

    file_content = file_content.map do |line|
      space_count = starting_space_count(line)

      line = commenter_of(:module, space_count, line)
      line = commenter_of(:class, space_count, line)
      method_commenter(line, space_count)
    end
    file_content
  end

  def commenter_of(obj_name, space_count, line)
    obj_name = obj_name.to_sym
    space = total_space(space_count)
    name_by_space = "#{space}#{obj_name}"

    return line unless line.start_with?(name_by_space)
    return line if line.include?('<<')

    inheritance = ''
    name = line.split[1]
    inheritance = " inherited from #{line.split.last}" if line.include? '<'
    if space_count > 0
      case obj_name
      when :module
        @nested_modules << "#{@nested_modules.count > 1 ? ', ' : ' '}#{name}"
      when :class
        @nested_classes << "#{@nested_classes.count > 1 ? ', ' : ' '}#{name}"
      end
      "#{space}# #{obj_name} #{name}#{inheritance}\n" + line
    else
      @comments << "# #{obj_name} #{name}#{inheritance}\n"
      line
    end
  end

  def method_commenter(line, space_count)
    space = total_space(space_count)
    class_method_finder(line, space)

    return line unless line.start_with?("#{space}def ")

    method_name = line.gsub("#{space}def ", '').tr '()', ' '
    args = method_name.split ' '
    method_name = args.delete args.first
    parameters = args.empty?
    args = args.map(&:strip).join ' ' unless parameters

    if method_name == 'initialize'
      "#{space}# constructor '#{method_name}'"\
      "#{" parameter(s): (#{args})" unless parameters}\n#{line}"
    elsif method_name.include?('self.') || @is_class_method
      method_name = method_name.split('.').last if method_name.include?('self.')
      "#{space}# class method "\
      "'#{method_name}'#{" parameter(s): (#{args})" unless parameters}\n#{line}"
    elsif @protected_names.include?(line) || @protected_names.include?(method_name)
      "#{space}# protected method "\
      "'#{method_name}'#{" parameter(s): (#{args})" unless parameters}\n#{line}"
    else
      is_private = @private_names.include?(line) || @private_names.include?(method_name)
      "#{space}# #{is_private ? 'private' : 'public'} method '#{method_name}'"\
      "#{" parameter(s): (#{args})" unless parameters}\n#{line}"
    end
  end

  def class_method_finder(line, space)
    if line.start_with?("#{space}class") && line.end_with?("self\n") && line.include?('<<')
      @is_class_method = true
      @space = space
    elsif @is_class_method && line.start_with?("#{@space}end")
      @is_class_method = @space = nil
    end
  end

  def private_protected_method_names(file_content)
    @private_names = []; @protected_names = []
    file_content.each do |line|
      space_count = starting_space_count(line)
      space = total_space(space_count)
      adder_name_of(:private, line, space)
      adder_name_of(:protected, line, space)
    end
  end

  def adder_name_of(name, line, space)
    name = name.to_sym
    return unless name == :private || name == :protected

    if line.start_with? "#{space}#{name}\n", "#{space}#{name} "
      line_split = line.split
      if line_split.count > 1
        line_split.delete name
        line_split = line_split.map { |e| e.delete ':,' }
        case name
        when :private
          @private_names += line_split
        else
          @protected_names += line_split
        end
      else
        case name
        when :private
          @is_private = true
          @is_protected = nil
          @space_of_private = space
        else
          @is_protected = true
          @is_private = nil
          @space_of_protected = space
        end
      end
    elsif line.start_with? "#{@space_of_private}def", "#{@space_of_protected}def"
      @private_names << line if @is_private
      @protected_names << line if @is_protected
    end
  end

  def starting_space_count(line)
    count = 0
    line.each_char do |c|
      break unless c == ' '
      count += 1
    end
    count
  end

  def total_space(space_count)
    ' ' * space_count
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
