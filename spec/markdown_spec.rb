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
      it 'writes an empty file' do
        empty_md = File.join(@temp_dir, 'empty.md')
        md.write(empty_md)
        expect(File.exist?(empty_md)).to be true
        expect(File.read(empty_md)).to be_empty
      end
    end
  end
end
