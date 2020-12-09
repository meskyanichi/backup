require "spec_helper"

describe Backup::Compressor::PBzip2 do
  before do
    Backup::Compressor::PBzip2.any_instance.stubs(:utility).returns("pbzip2")
  end

  it "should be a subclass of Compressor::Base" do
    expect(Backup::Compressor::PBzip2
      .superclass).to eq(Backup::Compressor::Base)
  end

  describe "#initialize" do
    let(:compressor) { Backup::Compressor::PBzip2.new }

    after { Backup::Compressor::PBzip2.clear_defaults! }

    it "should load pre-configured defaults" do
      Backup::Compressor::PBzip2.any_instance.expects(:load_defaults!)
      compressor
    end

    context "when no pre-configured defaults have been set" do
      it "should use default values" do
        expect(compressor.level).to eq(false)

        expect(compressor.instance_variable_get(:@cmd)).to eq("pbzip2")
        expect(compressor.instance_variable_get(:@ext)).to eq(".bz2")
      end

      it "should use the values given" do
        compressor = Backup::Compressor::PBzip2.new do |c|
          c.level = 5
        end
        expect(compressor.level).to eq(5)

        expect(compressor.instance_variable_get(:@cmd)).to eq("pbzip2 -5")
        expect(compressor.instance_variable_get(:@ext)).to eq(".bz2")
      end
    end # context 'when no pre-configured defaults have been set'

    context "when pre-configured defaults have been set" do
      before do
        Backup::Compressor::PBzip2.defaults do |c|
          c.level = 7
          c.processors = 2
        end
      end

      it "should use pre-configured defaults" do
        expect(compressor.level).to eq(7)
        expect(compressor.processors).to eq(2)

        expect(compressor.instance_variable_get(:@cmd)).to eq("pbzip2 -7 -p2")
        expect(compressor.instance_variable_get(:@ext)).to eq(".bz2")
      end

      it "should override pre-configured defaults" do
        compressor = Backup::Compressor::PBzip2.new do |c|
          c.level = 6
          c.processors = 1
        end
        expect(compressor.level).to eq(6)

        expect(compressor.instance_variable_get(:@cmd)).to eq("pbzip2 -6 -p1")
        expect(compressor.instance_variable_get(:@ext)).to eq(".bz2")
      end
    end # context 'when pre-configured defaults have been set'
  end # describe '#initialize'
end
