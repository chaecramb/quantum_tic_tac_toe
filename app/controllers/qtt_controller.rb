class QttController < ApplicationController

  def new
    @qtt = Qtt.new
  end

  def create
    qtt = Qtt.create(qtt_params)
    redirect_to qtt
  end

  def show
    @qtt = Qtt.find(params[:id])
    @board = @qtt.board_symbols
    @player1 = @qtt.player1
    @player2 = @qtt.player2
    @current_player = @qtt.whose_turn
    @symbol = @qtt.symbol_for_player(@current_player)
  end

  def update
    @qtt = Qtt.find(params[:id])
    if params[:collapse] 
      move = QttMove.find(params[:collapse])
      # @qtt.collapse_move(move)
      @qtt.new_collapse(move)
    else
      player = @qtt.whose_turn
      square1 = params[:squares].split(',').first.to_i
      square2 = params[:squares].split(',').last.to_i
      @qtt.make_move(player, square1, square2)
    end
 
    redirect_to @qtt 
  end


  private
  def qtt_params
    params.require(:qtt).permit(:player1, :player2)
  end
end