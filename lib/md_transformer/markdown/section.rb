module MdTransformer
  class Markdown
    # Class representing a section of a markdown file (header with content)
    class Section
      # @return [String] the title of the section
      attr_reader :title

      # @return [Integer] the precedence level of the section
      attr_reader :level

      # @return [Range] the section header's location in the original content
      attr_reader :header_location

      # @return [String] the section's content
      attr_reader :content

      # Creates the Section object
      # @param title [String] the title of the section
      # @param options [Hash] the options hash
      # @option options [Integer] :level (0) the precedence level of the section
      # @option options [Range] :header_location (0..0) the section header's location in the original content
      # @option options [String] :content ('') the content of the section
      # @return [MdTransformer::Markdown::Section] the new Section object
      def initialize(title, options = {})
        @title = title
        @level = options[:level] || 0
        @header_location = options[:header_location].nil? ? 0..0 : options[:header_location]
        @content = options[:content] || ''
      end

      # Generates an array of Section objects from string Markdown content
      # @param content [String] the markdown content to parse
      # @return [Array] the array of generated Section objects
      def self.generate_sections(content)
        headers = header_locations(content)
        headers.each_with_index do |h, i|
          content_end = content.length
          headers[i] = { header: h, content: ((h.end + 1)..(content_end - 1)) }
        end
        headers.map! { |h| create_section_from_header(h, content) }
      end

      class << self
        private

        # Gathers header locations for given content
        # @param content [String] the markdown content to parse
        # @return [Array] the array of all header locations given as ranges
        def header_locations(content)
          code_ranges = code_locations(content)
          hdr_regex = /^(\#{1,6}\s+.*)$/
          hdr_ranges = content.enum_for(:scan, hdr_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
          hdr_ranges.reject { |hdr_range| code_ranges.any? { |code_range| code_range.include?(hdr_range.begin) } }
        end

        # Gathers code block locations for given content
        # @param content [String] the markdown content to parse
        # @return [Array] the array of all code block locations given as ranges
        def code_locations(content)
          block_regex = /^([`~]{3}.*?^[`~]{3})$/m
          content.enum_for(:scan, block_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
        end

        # Creates a new Section object from a header hash
        # @param header [Hash] hash containing :header and :content keys representing header and content locations
        # @param content [String] the markdown content to parse
        # @return [MdTransformer::Markdown::Section] the new Section object
        def create_section_from_header(header, content)
          Section.new(
            content[header[:header]].match(/^#+\s+(.*)$/)[1],
            level: header_level(content[header[:header]]),
            header_location: header[:header].begin..header[:content].end,
            content: content[header[:content]]
          )
        end

        # Determines the precedence level of a header
        # @param header [String] the header string to parse
        # @return [Integer] the calculated precedence level
        def header_level(header)
          header.split.first.count('#')
        end
      end
    end
  end
end
