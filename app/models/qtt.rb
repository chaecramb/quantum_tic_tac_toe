class Qtt < ActiveRecord::Base
  has_many :qtt_moves

  WINNING_LINES = [ [0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6] ]

  def turn
    QttMove.where(qtt_id: self.id).size / 2 + 1
  end

  def board
    # empty_board.tap do |board|
    #   qtt_moves.each do |move|
    #     board[move.square] << move if move
    #   end
    # end
    empty_board.tap do |board|
      QttMove.where("qtt_id = ?", self.id).each do |move|
        board[move.square] << move if move
      end
    end
  end

  def classical_board
    board.map do |square|
      square.map do |move| 
        move && ( move.symbol if move.collapsed == true)
      end
    end.map {|square| square.compact}.map {|square| square.empty? ? nil : square.select{|m| m.is_a?(String)}}.flatten
  end

  def board_symbols
    board.map do |square|
      square.map do |move| 
        move && ((move.collapsed == true) ? move.symbol[0] : move.symbol unless move.collapsed == false)
      end
    end.map{|square| square.compact}
  end

  def legal_move(squares)
    # check if there is a collapsed move in either square, if so raise
    squares.each do |square|
      board[square].each do |move|
        raise "Illegal move" if (move.collapsed == true)
      end
    end
  end

  def make_move(player, square1, square2)
    legal_move([square1, square2])
    if player == whose_turn
      move1 = QttMove.create(square: square1, symbol: (symbol_for_player(player) + turn.to_s), player: player)
      move2 = QttMove.create(square: square2, symbol: (symbol_for_player(player) + turn.to_s), player: player)
      move1.partner_id, move2.partner_id = move2.id, move1.id
      qtt_moves << move1 << move2
      qtt_moves.last.partner = qtt_moves.last(2).first
      qtt_moves.last(2).first.partner = qtt_moves.last
      # collapse if collapse?
    else
      raise "It's not #{player}'s turn!"
    end
  end

  def collapse
    move = select_move_to_collapse
    new_collaspe(move)
    # collapse_move(move)
    # collapse_path(cyclic_paths_from_move(move, [move, move.partner]).flatten.drop(1))
    # collapse_entangled
    # *** collapse_entangled ***
    # they will be the qtt_moves that no longer have partners and aren't already collapsed
  end

  def collapse_entagled
    qtt_moves.each do |move|
      # select qtt_moves that don't have a collapsed partner
    end
  end

  def select_move_to_collapse
    # puts "#{whose_turn} select a move to measure"
    cycle = players_moves_in_cycle(whose_turn)
    @first_move_in_cycle = cycle.first
    cycle.each do |move|
      @first_move_in_cycle = move if (move.symbol < @first_move_in_cycle.symbol)
    end
    # puts "Collapse #{@first_move_in_cycle.symbol} into #{@first_move_in_cycle.square}, or #{@first_move_in_cycle.partner.square}?"
    # (@first_move_in_cycle.square == gets.to_i) ? @first_move_in_cycle : @first_move_in_cycle.partner
    [@first_move_in_cycle, @first_move_in_cycle.partner]
  end

  def collapse_move(move)
    move.collapsed = true 
    move.save
    partner = move.partner
    partner.collapsed = false 
    partner.save
    remove_unobserved(move.square)
    # binding.pry
    collapse_path(cyclic_paths_from_move(move, [move, move.partner]).flatten.drop(1))
  end

  def collapse_path(path)
    (path.size - 1).times do |i|
      move = path[i+1].partner
      move.collapsed = true
      move.save
      partner = move.partner
      partner.collapsed = false
      partner.save
    end
  end

  def remove_unobserved(square)
    qtt_moves.each do |m|
      if m.square == square
        if m.collapsed != true
          m.collapsed = false 
          m.save
          partner = m.partner
          partner.collapsed = true
          partner.save
        end
      end
    end
  end

  def players_moves_in_cycle(player)
    path = cyclic_paths_from_move(qtt_moves.last, [qtt_moves.last, qtt_moves.last.partner]).flatten.uniq
    all_moves_in_cycle = path.map {|move| move.square}.uniq.map{|square| board[square]}.flatten
    # qtt_moves.select do |move|
    #   (all_moves_in_cycle.include? move) && (move.player == player)
    # end.uniq
  end

  def moves_in_cycle
    path = cyclic_paths_from_move(qtt_moves.last, [qtt_moves.last, qtt_moves.last.partner]).flatten.uniq
    all_moves_in_cycle = path.map {|move| move.square}.uniq.map{|square| board[square]}.flatten
    # qtt_moves.select do |move|
    #   (all_moves_in_cycle.include? move) && (move.player == player)
    # end.uniq
  end

  def moves_in_cycle
    path = cyclic_paths_from_move(qtt_moves.last, [qtt_moves.last, qtt_moves.last.partner]).flatten.uniq
    all_moves_in_cycle = path.map {|move| move.square}.uniq.map{|square| board[square]}.flatten
    h = Hash.new
    all_moves_in_cycle.map{|m|m.square}.each{|square|h[square]=[]}
    (all_moves_in_cycle.map{|m|m.square}.zip all_moves_in_cycle.map{|m|m.symbol}).each{|p|h[p[0]] << p[1]}
    h
  end

  def whose_turn
    return player1 if qtt_moves.empty?
    qtt_moves.last.player == player1 ? player2 : player1
  end

  def last_move_square
    qtt_moves && qtt_moves.last.square
  end

  def last_spooky_partner_square
    qtt_moves && qtt_moves.last(2).first.square
  end

  def moves_in_same_square(query_move, excluded_moves = nil)
    qtt_moves && (qtt_moves - [query_move]).select do |move|
      move.square == query_move.square
    end 
  end

  # path = [move.square, move.partner.square]

  # def cyclic?(move, path)
  #   moves_in_same_square(move.partner).each do |m|
  #     potential_path = path.dup
  #     potential_path << m.partner.square
  #     break true if (path.uniq.size != path.size)
  #     cyclic? m.partner, potential_path
  #   end
  #   false
  # end

  def cyclic_paths_from_move(move, path)
    return path if path_repeats?(path)
    paths = []
    moves_in_same_square(move.partner).each do |m|
      potential_path = path.dup
      potential_path << m.partner
      paths << cyclic_paths_from_move(m, potential_path)
    end
    paths
  end

  def path_repeats?(path)
    squares = path.map {|move| move.square}
    squares.uniq.size != squares.size
  end

  def collapse?
    cyclic_paths_from_move(qtt_moves.last, [qtt_moves.last, qtt_moves.last.partner]).flatten.select {|move| move.collapsed == nil }.any?
  end

  def empty_board
    [[],[],[],[],[],[],[],[],[]]
  end

  def symbol_for_player(player)
    case player
    when player1
      ?X
    when player2
      ?O
    else
      raise "who?! that's not one of my players!"
    end
  end




  def new_collapse(move)
    # until no moves in square are nil 
    until board[move.square].map{|m|m.collapsed} == board[move.square].map{|m|m.collapsed}.compact do 
      move.collapsed = true
      move.save
      unmeasured_moves_in_square(move.square).each do |m|
        # all other moves in square = false
        m.collapsed  = false
        m.save
        # for each move that is now false call new collapse for its partner (which will be true)
        new_collapse(m.partner)
      end
    end
  end

  def unmeasured_moves_in_square(square)
    board[square].select {|move| move.collapsed != true}
  end

  def collapse_square(square)
    qtt_moves.each do |m|
      if m.square == square
        if m.collapsed != true
          m.collapsed = false 
          m.save
        end
      end
    end
  end

  def winning_game?
    !!WINNING_LINES.detect do |winning_line|
      %w(XXX OOO).include?(winning_line.map { |e| classical_board[e][0] if classical_board[e] }.join)
    end
  end

  def winning_lines
    WINNING_LINES.map do |winning_line|
      [winning_line, winning_line.map { |e| classical_board[e][0] if classical_board[e] }.join]
    end.select do |line|
      %w(XXX OOO).include? line[1]
    end
  end

  def ordered_symbols_in_winning_lines
    winning_lines.map do |line|
      line[0].map { |square| board[square].select {|move| ((move.symbol[0] == line[1][0]) && (move.collapsed == true))}}
    end.flatten.map {|move| move.symbol}.sort { |x,y| x[1]<=>y[1] }
  end

  def winner
    lines = winning_lines
    case
    when %w(XXX OOO).all? { |symbols| lines.flatten.include? symbols }
      "Narrow win for #{ordered_symbols_in_winning_lines.first[0] == "X" ? player1 : player2}!"
    when lines.size == 2
      "Double win for #{lines[0][1][0]== "X" ? player1 : player2}!"
    when lines.size == 1
      "Complete win for #{lines[0][1][0] == "X" ? player1 : player2}!"
    end
  end

  def dual_win?
    WINNING_LINES.select do |winning_line|
      %w(XXX OOO).include?(winning_line.map { |e| classical_board[e][0] if classical_board[e] }.join)
    end.size == 2
  end

  def drawn_game?
    classical_board.all? && !winning_game?
  end

end
