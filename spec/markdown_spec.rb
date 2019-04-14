RSpec.describe MdTransformer::Markdown do
  describe '#initialize' do
    context 'when initialized with no arguments' do
      it 'returns a new MdTransformer::Markdown instance' do
        expect(described_class.new).to be_a(MdTransformer::Markdown)
      end
    end

    context 'when initialized with a string source' do
      it 'returns a new MdTransformer::Markdown instance' do
        expect(described_class.new("# Title\nMy document")).to be_a(MdTransformer::Markdown)
      end
    end

    context 'when initialized with a file source that exists and the :file option' do
      it 'returns a new MdTransformer::Markdown instance' do
        expect(described_class.new(@basic_md_path, file: true)).to be_a(MdTransformer::Markdown)
      end
    end

    context 'when initialized with a file source that does not exist and the :file option' do
      it 'raises an InvalidMarkdownPath exception' do
        expect { described_class.new('not_a_file.md', file: true) }.to raise_error(MdTransformer::InvalidMarkdownPath)
      end
    end
  end

  describe '#content=' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when string content is passed' do
      it 'replaces existing content' do
        expect(md.content = "My new content\n").to eq("My new content\n")
        expect(md.to_s).to eq("My new content\n")
      end

      it 'replaces existing nested content' do
        expect(md['H1-1']['H2-1'].content = "More new content\n").to eq("More new content\n")
        expect(md['H1-1']['H2-1'].to_s).to eq("## H2-1\nMore new content\n")
      end
    end

    context 'when Markdown content is passed' do
      it 'replaces existing content with the passed markdown content' do
        md.content = described_class.new("# H1\nMy new content\n")
        expect(md.to_s).to eq("# H1\nMy new content\n")
      end

      it 'replaces existing nested content with the passed markdown content and reflows header nesting' do
        md['H1-1'].content = described_class.new("# H1\nMy new content\n")
        expect(md['H1-1'].to_s).to eq("# H1-1\n## H1\nMy new content\n")
      end
    end

    context 'when string content is passed with too many header levels (results in h7+)' do
      it 'raises a HeaderTooDeep exception' do
        expect do
          md['H1-1'].content = "# t\n## t\n### t\n#### t\n##### t\n###### t\n"
        end.to raise_error(MdTransformer::HeaderTooDeep)
      end
    end
  end

  describe '#keys' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when children exist' do
      it 'returns an array of all direct descendent keys' do
        expect(md.keys).to eq(['H1-1'])
        expect(md['H1-1'].keys).to eq(['H2-1', 'H2-2', 'H2-3'])
      end
    end

    context 'when children do not exist' do
      it 'returns an empty array' do
        expect(md['H1-1']['H2-1'].keys).to eq([])
      end
    end
  end

  describe '#key?' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when the given key exists' do
      it 'returns true' do
        expect(md.key?('H1-1')).to be true
      end
    end

    context 'when the given key does not exist' do
      it 'returns false' do
        expect(md.key?('H1-5')).to be false
      end
    end
  end

  describe '#values' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when children exist' do
      it 'returns an array of all direct descendent values' do
        md['H1-1'].values.each do |v|
          expect(v.parent).to eq(md['H1-1'])
          expect(v).to be_a(described_class)
        end
      end
    end

    context 'when children do not exist' do
      it 'returns an empty array' do
        expect(md['H1-1']['H2-1'].values).to eq([])
      end
    end
  end

  describe '#value?' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when the value exists in direct descendent values' do
      it 'returns true' do
        expect(md['H1-1']['H2-2'].value?(md['H1-1']['H2-2']['H3-1'])).to be true
      end
    end

    context 'when the value does not exist in direct descendent values' do
      it 'returns false' do
        expect(md['H1-1']['H2-2'].value?('Not a member')).to be false
      end
    end
  end

  describe '#dig' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when the key to be dug exists' do
      it 'returns the Markdown object' do
        expect(md.dig('H1-1', 'H2-2', 'H3-1')).to be_a(described_class)
      end
    end

    context 'when the key to be dug does not exist' do
      it 'returns nil' do
        expect(md.dig('H1-1', 'H2-5', 'H4-1')).to be nil
      end
    end
  end

  describe '#[]' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when the key to be retrieved does not exist' do
      it 'returns nil in a base path' do
        expect(md['Invalid header']).to be_nil
      end

      it 'returns nil in a nested path' do
        expect(md['H1-1']['Not a path, sorry']).to be_nil
      end
    end

    context 'when the key to be retrieved does exist' do
      it 'returns the value at a path' do
        expect(md['H1-1']).to be_a(MdTransformer::Markdown)
        expect(md['H1-1'].to_s).to eq(@basic_md_content)
      end

      it 'returns the value in a nested path' do
        expect(md['H1-1']['H2-2']['H3-1']).to be_a(MdTransformer::Markdown)
        expect(md['H1-1']['H2-2']['H3-1'].to_s).to eq("### H3-1\nH3-1-content\n\n")
      end
    end
  end

  describe '#[]=' do
    let(:md) { described_class.new(@basic_md_content) }

    context 'when the key to be retrieved does not exist' do
      it 'creates the key and returns the new value' do
        expect(md['H1-new'] = "Look at this fancy content...\n").to eq("Look at this fancy content...\n")
        expect(md['H1-new'].to_s).to eq("# H1-new\nLook at this fancy content...\n")
      end
    end

    context 'when the key to be retrieved does exist' do
      it 'updates the key and returns the new value' do
        expect(md['H1-1'] = "Much shorter, ahh...\n").to eq("Much shorter, ahh...\n")
        expect(md['H1-1'].to_s).to eq("# H1-1\nMuch shorter, ahh...\n")
      end
    end

    context 'when the key to be retrieved does not exist and headered content is passed' do
      it 'reflows the content, updates the key, and returns the new value' do
        expect(md['H1-new'] = "# My new content\n## child 1\n").to eq("# My new content\n## child 1\n")
        expect(md['H1-new'].to_s).to eq("# H1-new\n## My new content\n### child 1\n")
      end
    end

    context 'when the key to be retrieved does exist and headered content is passed' do
      it 'reflows the content, updates the key, and returns the new value' do
        expect(md['H1-1'] = "# My new content\n## child 1\n").to eq("# My new content\n## child 1\n")
        expect(md['H1-1'].to_s).to eq("# H1-1\n## My new content\n### child 1\n")
      end
    end
  end

  describe '#to_s' do
    context 'when initialized with a markdown file with a normal hierarchy' do
      let(:md) { described_class.new(@basic_md_path, file: true) }
      it 'returns identical content to the original file' do
        expect(md.to_s).to eq(@basic_md_content)
      end
    end

    context 'when initialized with a markdown file with an incorrect hierarchy' do
      let(:md) { described_class.new(@skip_md_path, file: true) }
      it 'corrects skipped heading levels in the output file' do
        expect(md.to_s).to eq(@skip_fixed_md_content)
      end
    end
  end

  describe '#write' do
    context 'when initialized with no content' do
      let(:md) { described_class.new }
      it 'writes an empty file containing a single newline' do
        empty_md = File.join(@temp_dir, 'empty.md')
        md.write(empty_md)
        expect(File.exist?(empty_md)).to be true
        expect(File.read(empty_md)).to eq("\n")
      end
    end
  end

  describe '#root?' do
    let(:md) { described_class.new(@basic_md_path, file: true) }
    context 'when the current object is the root of the Markdown file' do
      it 'returns true' do
        expect(md.root?).to be true
      end
    end

    context 'when the current object is not the root of the Markdown file' do
      it 'returns false' do
        expect(md['H1-1'].root?).to be false
      end
    end
  end

  describe '#level' do
    let(:md) { described_class.new(@basic_md_path, file: true) }
    context 'when the current object is the root of the Markdown file' do
      it 'returns 0' do
        expect(md.level).to eq(0)
      end
    end

    context 'when the current object 2 levels beneath the root' do
      it 'returns 2' do
        expect(md['H1-1']['H2-1'].level).to eq(2)
      end
    end
  end

  describe '#each' do
    let(:md) { described_class.new(@basic_md_path, file: true) }
    context 'when no block is passed' do
      it 'returns an enumerator for the object' do
        expect(md.each).to be_a(Enumerator)
      end
    end

    context 'when a block with 2 args is passed' do
      it 'returns the key and value of each child element' do
        md.each do |k, v|
          expect(k).to be_a(String)
          expect(v).to be_a(described_class)
        end
      end
    end
  end

  describe '#==' do
    let(:md) { described_class.new(@basic_md_path, file: true) }
    let(:md2) { md.dup }
    context 'when 2 objects are passed with equivalent content' do
      it 'returns true' do
        expect(md == md2).to be true
      end
    end

    context 'when 2 objects are passed with differing content' do
      it 'returns false' do
        md2['H1-1'] = 'Nope'
        expect(md == 'Not the same content').to be false
      end
    end
  end
end
