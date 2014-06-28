require 'rubygems'
require 'sinatra'

set :sessions, true

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
      break if sum <= 21
      sum -= 10
    end
    sum
  end
end

before do
  @show_hit_or_stay_btn = true
end


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # create a deck and put it in session
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
  if cal_total(session[:player_cards]) > 21
    @show_hit_or_stay_btn = false
    @error = "Sorry, you busted."
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_or_stay_btn = false
  erb :game
end
