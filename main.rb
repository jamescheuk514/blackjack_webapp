require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redircet '/new_player'
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
  suits = ["H", "D", "C", "S"]
  values = ["A", "2", "3", "4", "5", "6", "7","8", "9", "10", "J", "Q", "K"]
  session[:deck] = suits.product(values).shuffle!
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end




post '/set_bet' do
  session[:new_bet] = params[:new_bet]
  redirect '/game'
end
