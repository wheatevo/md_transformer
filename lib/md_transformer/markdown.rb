require 'fileutils'
require 'md_transformer/markdown/section'

module MdTransformer
  # Class representing a parsed markdown file
  class Markdown
    include Comparable
    include Enumerable

    # @return [String] the title of the Markdown object
    attr_accessor :title

    # @return [String] the content of the Markdown object
    attr_reader :content

    # @return [Array] the array of child objects
    attr_reader :children

    # @return [MdTransformer::Markdown, nil] nil or the parent of the current Markdown object
    attr_reader :parent

    # The lowest valid precedence of a header, allows for up to H6 (###### Header)
    LOWEST_PRECEDENCE = 6

    # Creates a new Markdown object
    # @param source [String] the markdown content or path to a markdown file
    # @param options [Hash] the options hash
    # @option options [Boolean] :file whether to treat the passed source as a file path
    # @option options [MdTransformer::Markdown] :parent the parent of the new object
    # @option options [String] :title the title of the new object
    # @return [MdTransformer::Markdown] the new Markdown object
    def initialize(source = '', options = {})
      @parent = options[:parent]
      @title = options[:title] || ''
      if options[:file]
        raise InvalidMarkdownPath, "Could not find markdown file at #{source}" unless File.exist?(source)

        source = File.read(source)
        @title ||= options[:file]
      end
      parse!(source)
    end

    # Updates the current object's Markdown content
    # @param value [String] the new content
    # @return [String] the newly added content
    def content=(value)
      # Reflow the content headers based on the child's levels (raise exception if level exceeds 6)
      m = Markdown.new(value.to_s)

      # Reassign the parent of the children to the current object and ensure the new depth is valid
      @children = m.children
      @children.each do |c|
        c.instance_variable_set(:@parent, self)
        validate_levels(c)
      end

      @content = m.content
    end

    # Gets all child object keys
    # @return [Array] the array of child keys
    def keys
      @children.map(&:title)
    end

    # Checks for whether a child object has a given key
    # @param key [String] the key of the child object
    # @return [Boolean] whether the passed key exists
    def key?(key)
      !self[key].nil?
    end

    # Gets all child object values
    # @return [Array] the array of child objects
    def values
      @children
    end

    # Checks for whether a child object has a given value
    # @param value [String] the value to check for
    # @return [Boolean] whether the passed value exists
    def value?(value)
      !@children.find { |c| c == value }.nil?
    end

    # Digs through the hash for the child object at the given nested key(s)
    # @param key [String] the first key to check
    # @param rest [Array<String>] any number of nested string keys for which to find
    # @return [MdTransformer::Markdown, nil] the found child object or nil
    def dig(key, *rest)
      value = self[key]
      return value if value.nil? || rest.empty?

      value.dig(*rest)
    end

    # Retrieves the child object at a given key if it exists
    # @param key [String] the key of the child object
    # @return [MdTransformer::Markdown, nil] the found child object or nil
    def [](key)
      @children.find { |c| c.title == key }
    end

    # Sets the value of the child object at a given key. If the key does not exist, a new child object is created.
    # @param key [String] the key of the child object
    # @param value [String] the new value of the child object
    # @return [String] the newly assigned value
    def []=(key, value)
      child = self[key] || Markdown.new('', title: key, parent: self)
      child.content = value.to_s
      @children.push(child) unless key?(key)
    end

    # Creates a string representing the markdown document's content from current content and all child content
    # @param options [Hash] the options hash
    # @option options [Boolean] :title (true) whether to include the title of the current object in the output
    # @return [String] the constructed Markdown string
    def to_s(options = { title: true })
      title_str = root? ? '' : "#{'#' * level} #{@title}\n"
      md_string = "#{options[:title] ? title_str : ''}#{@content}#{@children.map(&:to_s).join}"
      md_string << "\n" unless md_string.end_with?("\n")
      md_string
    end

    # Writes the current markdown object to a file
    # @param path [String] the path to the new file
    # @param options [Hash] the options hash
    # @option options [Boolean] :create_dir (true) whether to create the parent directories of the path
    # @return [Integer] the length of the newly created file
    def write(path, options: { create_dir: true })
      FileUtils.mkdir_p(File.dirname(path)) if options[:create_dir]
      File.write(path, to_s)
    end

    # Checks whether the current object is the root of the Markdown object
    # @return [Boolean] whether the current object is the root
    def root?
      @parent.nil?
    end

    # Calculates the current nesting level of the Markdown object
    # @return [Integer] the nesting level of the object (0 for the root, +1 for each additional level)
    def level
      return 0 if root?

      @parent.level + 1
    end

    # For a block { |k, v| ... }
    # @yield [k, v] Gives the key and value of the object
    def each
      return enum_for(__method__) unless block_given?

      @children.each do |child|
        yield child.title, child
      end
    end

    # Compares Markdown objects with other objects through string conversion
    # @param other [Object] object to compare
    # @return [Integer] the result of the <=> operator on the string values of both objects
    def <=>(other)
      to_s <=> other.to_s
    end

    private

    # Validates that all children have valid precedence levels and raises an exception if they are not
    # @param child [MdTransformer::Markdown] child object ot validate
    # @return [MdTransformer::Markdown] the validated child object
    def validate_levels(child)
      if child.level >= LOWEST_PRECEDENCE
        raise HeaderTooDeep, "#{child.title} header level (h#{child.level}) is beyond h#{LOWEST_PRECEDENCE}"
      end

      child.children.each { |c| validate_levels(c) }
      child
    end

    # Parses the provided markdown string content into a the current object's content and children
    # @param content [String] the string Markdown content to parse
    def parse!(content)
      @children = []
      @content = ''

      # Parse all direct children and create new markdown objects
      sections = Section.generate_sections(content)

      # No children!
      if sections.empty?
        @content = content
        return
      end

      # Populate content prior to found headers
      @content = content[0..sections.first.header_location.begin - 1] if sections.first.header_location.begin > 0

      parse_children!(sections)
    end

    # Parses all available sections into direct children of the current object
    # @param sections [Array] the array of Markdown::Section objects to parse
    def parse_children!(sections)
      # Go through the headers sequentially to find all direct children (base on header level vs. current level)
      last_child_level = LOWEST_PRECEDENCE + 1

      sections.each do |s|
        # Finish parsing if we encounter a sibling (same level) or aunt/uncle (higher level)
        break if s.level <= level

        if s.level <= last_child_level
          @children.push(Markdown.new(s.content, title: s.title, parent: self))
          last_child_level = s.level
        end
      end
    end
  end
end
