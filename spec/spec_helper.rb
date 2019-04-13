require 'bundler/setup'
require 'md_transformer'
require 'fileutils'

temp_dir = File.expand_path('support/temp', File.dirname(__FILE__))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:example) do
    @basic_md_path = File.expand_path('support/basic.md', File.dirname(__FILE__))
    @basic_md_content = File.read(@basic_md_path)
    @skip_md_path = File.expand_path('support/skip.md', File.dirname(__FILE__))
    @skip_md_content = File.read(@skip_md_path)
    @skip_fixed_md_path = File.expand_path('support/skip_fixed.md', File.dirname(__FILE__))
    @skip_fixed_md_content = File.read(@skip_fixed_md_path)
    @temp_dir = temp_dir
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:all) do
    FileUtils.rm_rf(temp_dir)
  end
end
