require "minitest/autorun"
require_relative "../../lib/collapser"
class CollapserTest < MiniTest::Test

  def setup
    @board = MiniTest::Mock.new
    @collapser = Collapser.new(@board)
  end

  def test_knows_if_not_circular
    @board.expect :moves_hash, [
      ['x1'],
      ['x1'],
      [],
      [],
      [],
      [],
      [],
      [],
      []
    ]
    assert_equal false, @collapser.is_circular(0,'x1')
  end


end