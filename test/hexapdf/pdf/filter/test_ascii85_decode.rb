# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/pdf/filter/ascii85_decode'

describe HexaPDF::PDF::Filter::ASCII85Decode do

  include StandardFilterTests

  before do
    @obj = HexaPDF::PDF::Filter::ASCII85Decode
    @all_test_cases ||= [['Nov shmoz ka pop.', ':2b:uF(fE/H6@!3+E27</c~>'],
     ['Nov shmoz ka pop.1', ':2b:uF(fE/H6@!3+E27</hm~>'],
     ['Nov shmoz ka pop.12', ':2b:uF(fE/H6@!3+E27</ho*~>'],
     ['Nov shmoz ka pop.123', ':2b:uF(fE/H6@!3+E27</ho+;~>'],
     ["\0\0\0\0Nov shmoz ka pop.", 'z:2b:uF(fE/H6@!3+E27</c~>'],
     ["Nov \x0\x0\x0\x0shmoz ka pop.", ':2b:uzF(fE/H6@!3+E27</c~>']
    ]
    @decoded = @all_test_cases[0][0]
    @encoded = @all_test_cases[0][1]
  end

  describe "decoder" do
    it "works with single byte input on specially crated input" do
      assert_equal("Nov \0\0\0", collector(@obj.decoder(feeder(':2b:u!!!!~>', 1))))
    end

    it "ignores whitespace in the input" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded.dup.scan(/./).map {|a| "#{a} \r\t"}.join("\n")))))
    end

    it "works without the EOD marker" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded.sub(/~>/, '')))))
    end

    it "ignores data after the EOD marker" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded.dup + "~>abcdefg"))))
    end

    it "fails if the input contains invalid characters" do
      assert_raises(HexaPDF::MalformedPDFError) { collector(@obj.decoder(feeder(':2bwx!'))) }
    end

    it "fails if the input contains values outside the BASE85 range" do
      assert_raises(HexaPDF::MalformedPDFError) { collector(@obj.decoder(feeder('uuuuu'))) }
    end

    it "fails if the last rest contains a 'z' character" do
      assert_raises(HexaPDF::MalformedPDFError) { collector(@obj.decoder(feeder('uuz'))) }
    end

    it "fails if the last rest contains a '~' character" do
      assert_raises(HexaPDF::MalformedPDFError) { collector(@obj.decoder(feeder('uu~'))) }
    end

    it "fails if the last rest contains values outside the BASE85 range" do
      assert_raises(HexaPDF::MalformedPDFError) { collector(@obj.decoder(feeder('uuu>', 1))) }
    end
  end

end
