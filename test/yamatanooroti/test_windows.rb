require 'yamatanooroti'

class Yamatanooroti::TestWindows < Test::Unit::TestCase
  def test_load
    if Yamatanooroti.win?
      assert_nothing_raised do
        Yamatanooroti::WindowsTestCase
      end
    else
      assert_raise(LoadError) do
        Yamatanooroti::WindowsTestCase
      end
    end
  end
end

class Yamatanooroti::TestWindowsCodepage < Yamatanooroti::TestCase
  if Yamatanooroti.win?
    def test_codepage
      start_terminal_with_cp(5, 30, ['ruby', '-e', 'puts(Encoding.find(%Q[locale]).name)'], codepage: 932)
      sleep 0.5
      close
      omit "codepage 932 not supported" if !codepage_success?
      assert_equal(['Windows-31J', '', '', '', ''], result)
    end
  end
end
