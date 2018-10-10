require "spec"
require "../src/netstring"

describe Netstring do
  describe ".parse" do
    it "takes a String" do
      ns = Netstring.parse "3:foo,"

      ns.size.should eq 3
      ns.to_s.should eq "foo"

      ns = Netstring.parse "3:foo,", max: 4_u32

      ns.size.should eq 3
      ns.to_s.should eq "foo"
    end

    it "takes an IO" do
      ns = Netstring.parse IO::Memory.new("4:quux,")

      ns.size.should eq 4
      ns.to_s.should eq "quux"

      ns = Netstring.parse IO::Memory.new("4:quux,"), max: 5_u32

      ns.size.should eq 4
      ns.to_s.should eq "quux"
    end

    it "parses an empty netstring" do
      ns = Netstring.parse "0:,"

      ns.size.should eq 0
      ns.to_s.should eq ""

      ns = Netstring.parse "0:,", max: 0_u32

      ns.size.should eq 0
      ns.to_s.should eq ""
    end

    it "fails on empty input" do
      expect_raises Netstring::ParseError, /expected length prefix, got EOF/ do
        Netstring.parse ""
      end
    end

    it "fails on a missing size" do
      expect_raises Netstring::ParseError, /expected 0-9 in length, got ':'/ do
        Netstring.parse ":badinput,"
      end
    end

    it "fails on sizes with leading zeros" do
      expect_raises Netstring::ParseError, /length prefix is zero-padded/ do
        Netstring.parse "02:xx,"
      end

      expect_raises Netstring::ParseError, /length prefix is zero-padded/ do
        Netstring.parse "002:xx,"
      end
    end

    it "fails on a non-numeric size" do
      expect_raises Netstring::ParseError, /expected 0-9 in length, got 'a'/ do
        Netstring.parse "3a:foo,"
      end
    end

    it "fails on a missing separator" do
      expect_raises Netstring::ParseError, /expected 0-9 in length, got 'f'/ do
        Netstring.parse "3foo,"
      end
    end

    it "fails on missing terminators" do
      expect_raises Netstring::ParseError, /expected terminator ',', got EOF/ do
        Netstring.parse "0:"
      end

      expect_raises Netstring::ParseError, /expected terminator ',', got EOF/ do
        Netstring.parse "3:foo"
      end

      expect_raises Netstring::ParseError, /expected terminator ',', got EOF/ do
        Netstring.parse "4:foo,"
      end

      expect_raises Netstring::ParseError, /expected terminator ',', got 'b'/ do
        Netstring.parse "3:foobar,"
      end
    end

    it "fails on short input" do
      expect_raises Netstring::ParseError, /expected 4 bytes, got 3/ do
        Netstring.parse "4:xx,"
      end
    end

    it "fails on oversized inputs" do
      expect_raises Netstring::ParseError, /length exceeds #{Netstring::NETSTRING_MAX} bytes/ do
        Netstring.parse "#{Netstring::NETSTRING_MAX + 1}:doesn't matter what goes here,"
      end

      custom_max = 10_u32
      expect_raises Netstring::ParseError, /length exceeds #{custom_max} bytes/ do
        Netstring.parse "#{custom_max + 1}:lol,", max: custom_max
      end
    end
  end
end
