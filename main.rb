require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INIT_BALANCE_AMOUNT = 500

helpers do
  def cal_total(cards)
    arr = cards.map { |card| card[1] }

    sum = arr.inject(0) do |sum, value|
      if value == "A"
        sum += 11
      else
        sum += value.to_i == 0 ? 10 : value.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if sum <= BLACKJACK_AMOUNT
      sum -= 10
    end
    sum
  end

  def card_image(card)
    suit = case card[0]
    when "C" then 'clubs'
    when "D" then "diamonds"
    when "H" then "hearts"
    when "S" then "spades"
    end

    value = card[1]
    if ["A", "J", "Q", "K"].include?(value)
      value = case card[1]
      when "A" then "ace"
      when "J" then "jack"
      when "Q" then "queen"
      when "K" then "king"
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_btn = false
    session[:player_balance] = session[:player_balance] + session[:per_bet]
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end


  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_btn = false
    session[:player_balance] = session[:player_balance] - session[:per_bet]
    @loser = "<strong>#{session[:player_name]} loses!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_btn = false
    @winner = "<strong>It is a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_btn = true


end


get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_balance] = INIT_BALANCE_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    "You must enter a name"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:per_bet] = nil
  erb :bet
end

post '/game/make_bet' do
  amount = params[:amount]
  balance = session[:player_balance]
  if amount.nil? || amount.to_i <= 0
    @error = "Must be a bit."
    halt erb(:bet)
  elsif amount.to_i > balance
    @error = "You don't get enough money."
    halt erb(:bet)
  else
    session[:per_bet] = amount.to_i
    redirect '/game'
  end
end


get '/game' do
  session[:turn] = session[:player_name]
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!
  session[:dealer_cards] = []
  session[:player_cards] = []
  2.times do
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
  end
  erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  total = cal_total(session[:player_cards])
  if total == BLACKJACK_AMOUNT
    winner!("You hit Blackjack!")
  elsif  total > BLACKJACK_AMOUNT
    loser!("Sorry, you busted.")
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  erb :game, layout: false

  redirect '/game/dealer'
end



get '/game/dealer' do
  session[:turn] = "dealer"

  @show_hit_or_stay_btn = false
  total = cal_total(session[:dealer_cards])
  if total == BLACKJACK_AMOUNT
    loser!("Sorry, dealer hit blackjack.")
  elsif total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{total}. You win!")
  elsif total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_btn = true
  end
  erb :game, layout:false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end


get '/game/compare' do
  player_total = cal_total(session[:player_cards])
  dealer_total = cal_total(session[:dealer_cards])


  if player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and dealer stayed at #{dealer_total}")
  elsif dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and dealer stayed at #{player_total}")
  end

  erb :game, layout: false
end


get '/game_over' do
  erb :game_over
end
