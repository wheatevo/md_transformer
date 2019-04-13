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
    end
  end
end
