require 'test/unit'
require_relative 'windows/windows-definition'
require_relative 'windows/windows'
require_relative 'windows/conhost'

module Yamatanooroti::WindowsTestCaseModule
  def write(str)
    @terminal.write(str)
  end

  def close
    @terminal.close
  end

  def result
    @terminal.result
  end

  def codepage_success?
    @terminal.codepage_success?
  end

  def start_terminal(height, width, command, wait: 0.01, timeout: 2, startup_message: nil, codepage: nil)
    @timeout = timeout
    @wait = wait
    @result = nil

    @terminal = Yamatanooroti::ConhostTerm.setup_console(height, width, @wait)
    @terminal.setup_cp(codepage) if codepage
    @terminal.launch(command)

    case startup_message
    when String
      wait_startup_message { |message| message.start_with?(startup_message) }
    when Regexp
      wait_startup_message { |message| startup_message.match?(message) }
    end
  end

  private def wait_startup_message
    wait_until = Time.now + @timeout
    chunks = +''
    loop do
      wait = wait_until - Time.now
      if wait.negative?
        raise "Startup message didn't arrive within timeout: #{chunks.inspect}"
      end

      chunks = @terminal.retrieve_screen.join("\n").sub(/\n*\z/, "\n")
      break if yield chunks
      sleep @wait
    end
  end

  private def retryable_screen_assertion_with_proc(check_proc, assert_proc, convert_proc = :itself.to_proc)
    retry_until = Time.now + @timeout
    screen = if @result
      convert_proc.call(@result)
    else
      loop do
        screen = convert_proc.call(@terminal.retrieve_screen)
        break screen if Time.now >= retry_until
        break screen if check_proc.call(screen)
        sleep @wait
      end
    end
    assert_proc.call(screen)
  end

  def assert_screen(expected_lines, message = nil)
    lines_to_string = ->(lines) { lines.join("\n").sub(/\n*\z/, "\n") }
    case expected_lines
    when Array
      retryable_screen_assertion_with_proc(
        ->(actual) { expected_lines == actual },
        ->(actual) { assert_equal(expected_lines, actual, message) }
      )
    when String
      retryable_screen_assertion_with_proc(
        ->(actual) { expected_lines == actual },
        ->(actual) { assert_equal(expected_lines, actual, message) },
        lines_to_string
      )
    when Regexp
      retryable_screen_assertion_with_proc(
        ->(actual) { expected_lines.match?(actual) },
        ->(actual) { assert_match(expected_lines, actual, message) },
        lines_to_string
      )
    end
  end
end

class Yamatanooroti::WindowsTestCase < Test::Unit::TestCase
  include Yamatanooroti::WindowsTestCaseModule
end
