# The primary namespace for `netstring.cr`.
class Netstring
  # The current version of `netstring.cr`.
  VERSION = "0.1.0"

  # The default maximum netstring size, taken from the reference implementation.
  NETSTRING_MAX = 999999999_u32

  # Returns the body of the netstring, as a slice.
  getter data

  # Raised on any error while parsing a netstring.
  class ParseError < Exception
  end

  private def initialize(@data : Bytes = data)
  end

  private def self.parse_length_and_separator(input, max)
    length = 0_u32

    # The first iteration is unrolled, since we require at least one digit.
    if byte = input.read_byte
      digit = byte - '0'.ord
      length += digit

      raise ParseError.new "expected 0-9 in length, got '#{byte.chr}'" if digit < 0 || digit > 9
    else
      raise ParseError.new "expected length prefix, got EOF"
    end

    loop do
      # Done up here so that we catch the single-digit case, e.g. "2:xx,"
      raise ParseError.new "length exceeds #{max} bytes" if length > max

      byte = input.read_byte

      raise ParseError.new "expected length prefix, got EOF" unless byte

      break if byte == ':'.ord

      digit = byte - '0'.ord

      if length.zero?
        raise ParseError.new "length prefix is zero-padded"
      elsif digit < 0 || digit > 9
        raise ParseError.new "expected 0-9 in length, got '#{byte.chr}'"
      end

      length *= 10
      length += digit
    end

    length
  end

  private def self.test_terminator(input)
    term = input.read_byte

    raise ParseError.new "expected terminator ',', got EOF" unless term
    raise ParseError.new "expected terminator ',', got '#{term.chr}'" unless term == ','.ord
  end

  private def self.parse_data_and_terminator(input, length)
    data = Bytes.new(length)

    if length > 0
      nread = input.read(data)

      raise ParseError.new "expected #{length} bytes, got #{nread}" if nread < length
    end

    test_terminator input

    data
  end

  # Returns a new `Netstring` based on *input*.
  #
  # *max* is a user-specifiable maximum size for *input*, which can be
  # set either above or below the default `NETSTRING_MAX`.
  #
  # Raises a `ParseError` on any parser failure.
  #
  # ```
  # ns = Netstring.parse "3:foo,"
  # ns.size # => 3
  # ns.data # => Bytes[102, 111, 111]
  # ns.to_s # => "foo"
  # ```
  def self.parse(input : String, max : UInt32 = NETSTRING_MAX)
    input = IO::Memory.new input
    parse input, max: max
  end

  # Like the other `parse`, but takes an `IO` instead.
  # See `parse`.
  def self.parse(input : IO, max : UInt32 = NETSTRING_MAX)
    length = parse_length_and_separator input, max
    data = parse_data_and_terminator input, length

    new data
  end

  # Returns the size of the parsed netstring.
  def size
    data.size
  end

  # Returns a string containing the encoded contents of the netstring.
  #
  # NOTE: This will not fix or deduce the correct encoding for you. It assumes UTF-8.
  def to_s(io)
    str = String.new data
    str.to_s(io)
  end
end
