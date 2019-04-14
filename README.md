# md_transformer

The md_transformer gem provides a way to read, modify, and write Markdown much as a hash with header keys and markdown content values.

This code:
```ruby
require 'md_transformer'

# Create a new markdown object and manipulate it
md = MdTransformer.markdown("# md_transformer\nThe md_transformer gem...\n")
md['md_transformer']['Installation'] = "Add this line to your application's Gemfile"
md['md_transformer']['Usage'] = ''
md['md_transformer']['Usage']['Creating a Markdown object'] = 'The `MdTransformer`...'
md.write('my_new_readme.md')
```

Generates a Markdown file at `my_new_readme.md` with the following content:
```md
# md_transformer
The md_transformer gem...
## Installation
Add this line to your application's Gemfile
## Usage
### Creating a Markdown object
The `MdTransformer`...
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'md_transformer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install md_transformer

## Usage

### Creating a Markdown object
The `MdTransformer` module has several helper methods for creating a new `MdTransformer::Markdown` object.

#### Create from Content
Use the `MdTransformer.markdown` method to create a new `MdTransformer::Markdown` object from a string.
```ruby
md_object = MdTransformer.markdown("# My document\nInformation is good.\n\n## More information\n> Detailed data\n")
```

> The `md` method is also available as an alias to `markdown`

#### Create from File
Use the `MdTransformer.markdown_file` method to create a new `MdTransformer::Markdown` object from a file.
```ruby
md_object = MdTransformer.markdown_file('README.md')
md_object = MdTransformer.markdown_file('/full/path/to/README.md')
```
> The `md_file` method is also available as an alias to `markdown_file`

### Manipulating the Markdown document
The `MdTransformer::Markdown` object can be used similarly to a `Hash`. Headers are treated as keys that refer to sections of the Markdown document.

#### Markdown can be Accessed as a Hash
```ruby
# Create Markdown object from a string
md1 = MdTransformer.markdown("# Title\nContent\n## Sub-heading\nSub-content\n## Sub-heading 2\nMore content\n")

# Get all heading keys for the Title heading
md1['Title'].keys
# => ["Sub-heading", "Sub-heading 2"]

# Get the content of the Title heading
md1['Title'].content
# => "Content\n"

# Get the content of the Sub-heading
md1['Title']['Sub-heading'].content
# => "Sub-content\n"

# Dig for a key
md1.dig('Title', 'Sub-heading').content
# => "Sub-content\n"

# Output a section as a string
md1['Title'].to_s
# => "# Title\nContent\n## Sub-heading\nSub-content\n## Sub-heading 2\nMore content\n"

# Update the content of a section
md1['Title']['Sub-heading'] = "Here is new content!\n"
md1['Title']['Sub-heading'].content
# => "Here is new content!"
```

#### Markdown can be Compared
```ruby
# Create Markdown objects from a string
md1 = MdTransformer.markdown("# Title\nContent\n## Sub-heading\nSub-content\n")
md2 = MdTransformer.markdown("# Title\nContent\n## Sub-heading\nSub-content 2\n")

md1 == md2
# => false

# Set the ## Sub-heading content on md2 to match md1
md2['Title']['Sub-heading'] = 'Sub-content'

md1 == md2
# => true
```

#### Markdown can be Enumerated
```ruby
# Create Markdown object from a string
md1 = MdTransformer.markdown("# Title\nContent\n## Sub-heading\nSub-content\n## Sub-heading 2\nMore content\n")

md1['Title'].map { |k, v| "#{k}!" }
# => ["Sub-heading!", "Sub-heading 2!"]
```

### Rendering the Markdown document

#### Viewing the content of the document
Use the `to_s` method to convert the `MdTransformer::Markdown` object into valid Markdown content.
```ruby
# Show the current markdown document
puts md_object

# Assign the markdown document content to a string
string_content = md_object.to_s
```

#### Writing the document to a file
Use the `write` method to write the current `MdTransformer::Markdown` object's content to a file.
```ruby
md_object.write('test.md')
md_object.write('/my/long/directory/README.md')
```

### Need More Help?
Please take a look at the [API documentation](https://www.rubydoc.info/github/wheatevo/md_transformer/master).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wheatevo/md_transformer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
