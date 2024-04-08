require 'test/unit'
require 'vterm'
require 'pty'
require 'io/console'

module Yamatanooroti::VTermTestCaseModule
  def start_terminal(height, width, command, wait: 0.1, startup_message: nil)
    @wait = wait * (ENV['YAMATANOOROTI_WAIT_RATIO']&.to_f || 1.0)
    @result = nil

    @pty_output, @pty_input, @pid = PTY.spawn('bash', '-c', %[stty rows #{height.to_s} cols #{width.to_s}; "$@"], '--', *command)

    @vterm = VTerm.new(height, width)
    @vterm.set_utf8(true)

    @screen = @vterm.screen
    @screen.reset(true)

    case startup_message
    when String
      @startup_message = ->(message) { message.start_with?(startup_message) }
    when Regexp
      @startup_message = ->(message) { startup_message.match?(message) }
    else
      @startup_message = nil
    end

    sync
  end

  def write(str)
    sync
    str_to_write = +String.new(encoding: Encoding::ASCII_8BIT)
    str.chars.each do |c|
      byte = c.force_encoding(Encoding::ASCII_8BIT).ord
      if c.bytesize == 1 and byte.allbits?(0x80) # with Meta key
        c = (byte ^ 0x80).chr
        str_to_write << "\e"
        str_to_write << c
      else
        str_to_write << c
      end
    end
    @pty_input.write(str_to_write)
    sync
  end

  def close
    sync
    @pty_input.close
    sync
    Process.kill('KILL', @pid)
    Process.waitpid(@pid)
  end

  private def sync
    startup_message = +'' if @startup_message
    loop do
      sleep @wait
      chunk = @pty_output.read_nonblock(1024)
      if @startup_message
        startup_message << chunk
        if @startup_message.(startup_message)
          @startup_message = nil
          chunk = startup_message
        else
          redo
        end
      end
      @vterm.write(chunk)
      chunk = @vterm.read
      @pty_input.write(chunk)
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      retry if @startup_message
      break
    rescue Errno::EIO # EOF
      retry if @startup_message
      break
    rescue IO::EAGAINWaitReadable # emtpy buffer
      retry if @startup_message
      break
    end
  end

  def result
    return @result if @result
    @result = []
    rows, cols = @vterm.size
    rows.times do |r|
      @result << +''
      cols.times do |c|
        cell = @screen.cell_at(r, c)
        if cell.char # The second cell of fullwidth char will be nil.
          if cell.char.empty?
            # There will be no char to the left of the rendered area if moves
            # the cursor.
            @result.last << ' '
          else
            @result.last << cell.char
          end
        end
      end
      @result.last.gsub!(/ *$/, '')
    end
    @result
  end

  def assert_screen(expected_lines, message = nil)
    actual_lines = result
    case expected_lines
    when Array
      assert_equal(expected_lines, actual_lines, message)
    when String
      assert_equal(expected_lines, actual_lines.join("\n").sub(/\n*\z/, "\n"), message)
    end
  end
end

class Yamatanooroti::VTermTestCase < Test::Unit::TestCase
  include Yamatanooroti::VTermTestCaseModule
end
