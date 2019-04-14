require 'md_transformer/version'
require 'md_transformer/markdown'

# Module containing classes relating to parsing and using Markdown content similarly to a hash
module MdTransformer
  # Base error class for MdTransformer
  class Error < ::StandardError; end

  # Error indicating that a passed markdown path cannot be found or read
  class InvalidMarkdownPath < MdTransformer::Error; end

  # Error indicating that a parsed header will exceed the maximum level (over h6)
  class HeaderTooDeep < MdTransformer::Error; end

  class << self
    # Creates a new Markdown object from given content
    # @param content [String] the markdown content
    # @return [MdTransformer::Markdown] the new Markdown object
    def markdown(content)
      Markdown.new(content)
    end

    # Creates a new Markdown object from a file
    # @param path [String] path to the markdown file to open
    # @return [MdTransformer::Markdown] the new Markdown object
    def markdown_file(path)
      Markdown.new(path, file: true)
    end

    alias md markdown
    alias md_file markdown_file
  end
end
