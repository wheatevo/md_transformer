require 'fileutils'
require 'md_transformer/markdown/section'

module MdTransformer
  # Class representing a parsed markdown file
  class Markdown
    include Comparable
    include Enumerable

    attr_accessor :title
    attr_reader :content
    attr_reader :children
    attr_reader :parent

    LOWEST_PRECEDENCE = 6

    def initialize(source = '', options = {})
      @parent = options[:parent]
      @children = []
      @title = options[:title] || ''
      if options[:file]
        raise InvalidMarkdownPath, "Could not find markdown file at #{source}" unless File.exist?(source)

        source = File.read(source)
      end
      parse(source)
    end

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

    def keys
      @children.map(&:title)
    end

    def key?(key)
      !self[key].nil?
    end

    def values
      @children
    end

    def value?(value)
      !@children.find { |c| c == value }.nil?
    end

    def dig(key, *rest)
      value = self[key]
      return value if value.nil? || rest.empty?

      value.dig(*rest)
    end

    # Retrieves the markdown value at a given key if it exists (or nil)
    def [](key)
      @children.find { |c| c.title == key }
    end

    # Sets the markdown value at a given key
    def []=(key, value)
      child = self[key] || Markdown.new('', title: key, parent: self)
      child.content = value.to_s
      @children.push(child) unless key?(key)
    end

    # Creates a string representing the markdown document's content
    def to_s(options = { title: true })
      title_str = @title.to_s.empty? ? '' : "#{'#' * level} #{@title}\n"
      md_string = "#{options[:title] ? title_str : ''}#{@content}#{@children.map(&:to_s).join}"
      md_string << "\n" unless md_string.end_with?("\n")
      md_string
    end

    def write(filename, options: { create_dir: true })
      FileUtils.mkdir_p(File.dirname(filename)) if options[:create_dir]
      File.write(filename, to_s)
    end

    def root?
      @parent.nil?
    end

    def level
      return 0 if root?

      @parent.level + 1
    end

    def each
      return enum_for(__method__) unless block_given?
      @children.each do |child|
        yield child.title, child
      end
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    private

    def validate_levels(child)
      if child.level >= LOWEST_PRECEDENCE
        raise HeaderTooDeep, "#{child.title} header level (h#{child.level}) is beyond h#{LOWEST_PRECEDENCE}"
      end

      child.children.each { |c| validate_levels(c) }
    end

    # Parses the provided markdown string content into a nested data structure by header section
    def parse(content)
      @children = []
      @content = ''

      # Parse all direct children and create new markdown objects
      sections = Section.parse_sections(content)

      # No children!
      if sections.empty?
        @content = content
        return
      end

      # Populate content prior to found headers
      @content = content[0..sections.first.location.begin - 1] if sections.first.location.begin > 0

      parse_children(sections)
    end

    def parse_children(sections)
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
