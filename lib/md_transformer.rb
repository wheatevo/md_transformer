require 'md_transformer/version'
require 'md_transformer/markdown'

module MdTransformer
  class Error < ::StandardError; end
  class InvalidMarkdownPath < MdTransformer::Error; end
  class HeaderTooDeep < MdTransformer::Error; end
end
