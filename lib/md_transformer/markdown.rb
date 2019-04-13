require 'fileutils'
require 'md_transformer/markdown/section'

module MdTransformer
  # Class representing a parsed markdown file
  class Markdown
    attr_accessor :title
    attr_reader :content

    LOWEST_CHILD_PRECEDENCE = 7

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
      parse(value)
    end

    def keys
      @children.map(&:title)
    end

    # Retrieves the markdown value at a given key if it exists (or nil)
    def [](key)
      @children.find { |c| c.title == key }
    end

    # Sets the markdown value at a given key
    def []=(key, value)
      child = self[key]
      unless child
        # Key does not exist, create a new child
        @children.push(Markdown.new(value, title: key, parent: self))
        return
      end
      child.content = value
    end

    def to_s
      title_str = @title.to_s.empty? ? '' : "#{'#' * level} #{@title}\n"
      "#{title_str}#{@content}#{@children.map(&:to_s).join}"
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

    private

    # Parses the provided markdown string content into a nested data structure by header section
    def parse(content)
      @children = []
      @content = ''

      # Parse all direct children and create new markdown objects
      sections = parse_sections(content)

      # No children!
      if sections.empty?
        @content = content
        return
      end

      # Populate content prior to found headers
      @content = content[0..sections.first.location.begin - 1] if sections.first.location.begin > 0

      # Go through the headers sequentially to find all direct children (base on header level vs. current level)
      last_child_level = LOWEST_CHILD_PRECEDENCE

      sections.each do |s|
        # Finish parsing if we encounter a sibling (same level) or aunt/uncle (higher level)
        break if s.level <= level

        if s.level <= last_child_level
          @children.push(Markdown.new(s.content, title: s.title, parent: self))
          last_child_level = s.level
        end
      end
    end

    def code_blocks(content)
      block_regex = /^([`~]{3}.*?^[`~]{3})$/m
      content.enum_for(:scan, block_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
    end

    def parse_sections(content)
      code_ranges = code_blocks(content)
      header_regex = /^(\#{1,6}\s+.*)$/
      header_ranges = content.enum_for(:scan, header_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
      header_ranges.reject! { |header_range| code_ranges.any? { |code_range| code_range.include?(header_range.begin) } }
      header_ranges.each_with_index do |h, i|
        content_end = content.length
        header_ranges[i] = { header: h, content: ((h.end + 1)..(content_end - 1)) }
      end
      header_ranges.map! do |h|
        Section.new(
          content[h[:header]].match(/^#+\s+(.*)$/)[1],
          level: content[h[:header]].split.first.count('#'),
          location: h[:header].begin..h[:content].end,
          content: content[h[:content]]
        )
      end
    end
  end
end
