module MdTransformer
  class Markdown
    # Class representing a section of a markdown file (header with content)
    class Section
      attr_reader :title

      attr_reader :level

      attr_reader :location

      attr_reader :content

      def initialize(title, options = {})
        @title = title
        @level = options[:level] || 0
        @location = options[:location].nil? ? 0..0 : options[:location]
        @content = options[:content] || ''
      end

      def self.parse_sections(content)
        headers = header_ranges(content)
        headers.each_with_index do |h, i|
          content_end = content.length
          headers[i] = { header: h, content: ((h.end + 1)..(content_end - 1)) }
        end
        headers.map! { |h| create_section_from_header(h, content) }
      end

      class << self
        private

        def header_ranges(content)
          code_ranges = code_blocks(content)
          hdr_regex = /^(\#{1,6}\s+.*)$/
          hdr_ranges = content.enum_for(:scan, hdr_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
          hdr_ranges.reject { |hdr_range| code_ranges.any? { |code_range| code_range.include?(hdr_range.begin) } }
        end

        def code_blocks(content)
          block_regex = /^([`~]{3}.*?^[`~]{3})$/m
          content.enum_for(:scan, block_regex).map { Regexp.last_match.begin(0)..Regexp.last_match.end(0) }
        end

        def create_section_from_header(header, content)
          Section.new(
            content[header[:header]].match(/^#+\s+(.*)$/)[1],
            level: header_level(content[header[:header]]),
            location: header[:header].begin..header[:content].end,
            content: content[header[:content]]
          )
        end

        def header_level(header)
          header.split.first.count('#')
        end
      end
    end
  end
end
