require 'yamatanooroti'

class Yamatanooroti::TestMultiplatform < Yamatanooroti::TestCase
  def setup
    start_terminal(5, 30, ['ruby', 'bin/simple_repl'])
    sleep 0.5
  end

  def test_example
    write(":a\n")
    close
    assert_screen(['prompt> :a', '=> :a', 'prompt>', '', ''])
    assert_screen(<<~EOC)
      prompt> :a
      => :a
      prompt>
    EOC
  end

  def test_result
    write(":a\n")
    close
    assert_equal(['prompt> :a', '=> :a', 'prompt>', '', ''], result)
  end

  def test_auto_wrap
    write("12345678901234567890123\n")
    close
    assert_screen(['prompt> 1234567890123456789012', '3', '=> 12345678901234567890123', 'prompt>', ''])
    assert_screen(<<~EOC)
      prompt> 1234567890123456789012
      3
      => 12345678901234567890123
      prompt>
    EOC
  end
end

class Yamatanooroti::TestMultiplatformMultiByte < Yamatanooroti::TestCase
  def setup
    if Yamatanooroti.win?
      start_terminal_with_cp(5, 30, ['ruby', 'bin/simple_repl'], codepage: 932)
    else
      start_terminal(5, 30, ['ruby', 'bin/simple_repl'])
    end
    sleep 0.5
  end

  def test_fullwidth
    omit "multibyte char not supported by env" if Yamatanooroti.win? and !codepage_success?
    write(":あ\n")
    close
    assert_equal(['prompt> :あ', '=> :あ', 'prompt>', '', ''], result)
  end

  def test_two_fullwidth
    omit "multibyte char not supported by env" if Yamatanooroti.win? and !codepage_success?
    write(":あい\n")
    close
    assert_equal(['prompt> :あい', '=> :あい', 'prompt>', '', ''], result)
  end
end
