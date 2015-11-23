class Collapser
  attr_reader :board
  def initialize(board)
    @board = board
  end

  def is_circular(square, move_name)
    puts "board #{@board.moves_hash.inspect}"
  end
end