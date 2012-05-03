require 'markaby'
require 'green_shoes'
require 'gameday'
require 'team'
require 'batter'
require 'launchy'

require "./baseball_scorecard/card_generator.rb"
require "./baseball_scorecard/version.rb"

module BaseballScorecard

  Shoes.app width: 300, height: 225, title: "Scorecard Generator" do
	
		Shoes::App.class_eval{include CardGenerator}
	
		background(image "baseball_scorecard/images/baseball.png")
	
		teams = Team.teams
		team_list = ["Select Team"]
		teams.each{|t|
			team_list << t[1][0..1].join(' ')
		}
		
		team_lbox = list_box(width: 250, items: team_list){|list| @team = list.text}
		team_lbox.choose("Select Team")
		team_lbox.move(25, 25)
		
		yesterday = (Time.now - 86400).strftime("%B %d %Y").split
		
		month_lbox = list_box(width: 120, items: %w[January February March April May June July August September October November December]){|list|
			@month = list.text
		}
		month_lbox.choose(yesterday[0])
		month_lbox.move(25, 65)
	
		day_lbox = list_box(width: 50, items: (1..31).to_a){|list|
			@day = list.text
		}
		day_lbox.choose(yesterday[1].to_i)
		day_lbox.move(149, 65)
		
		year_lbox = list_box(width: 72, items: (1926..(yesterday[2].to_i)).to_a){|list|
			@year = list.text
		}
		year_lbox.choose(yesterday[2].to_i)
		
		year_lbox.move(275 - year_lbox.width, 65)
		
		find_btn = button("find games"){
			unless @team == "Select Team"
				@status_line.text = "searching for games..."
				p "fetching game..."###
				@games = nil
				
				Thread.new do
					teams.each{|t|
						@team.split.each{|w|
							if t[1].include?(w); selected = true; else selected = false; end
							@team_abrev = t[0] if selected
						}
					}
					
					GamedayUtil.set_fetcher('remote')
					team = Team.new(@team_abrev)
					
					sel_date = "#{@year} #{@month} #{@day}"
					date = Time.parse(sel_date).strftime("%Y %m %d").split
					
					begin
						@games = team.games_for_date(date[0], date[1], date[2])
					rescue ArgumentError
						@status_line.text = "no games found for team and date"
						p "no games found"
					rescue Exception => e
						@status_line.text = "error finding games"; p e
					end
					
					if @games
						times = []
						@games.each{|g|
							time = Time.parse(g.time).strftime("%I:%M %p")
							time.slice!(0) if time[0] == "0"
							times << time
						}
			
						games_lbox = list_box(width: 250, items: times){|list| @game = @games[times.index(list.text)]}
						games_lbox.choose(times[0])
						games_lbox.move(25, 105)
						
						b_btn = button("build scorecards"){init_cards(@game)}
						b_btn.style(width: 120)
						b_btn.move(155, 145)
						@status_line.text = "games(s) found"
					else
						p "now what do i do?"
					end		#if
				end		#Thread
			else
				@status_line.text = "Select a Team"
			end		#unless
		}		#find_btn
		find_btn.style(width: 120)
		find_btn.move(25, 145)
		
		flow width: 300 do
			nofill
			@status_box = flow{
				fill white
				rect(25, 190, 250, 20, curve: 5)
				@status_line = inscription "Select Team and Date", top: 191, align: "center"
			}
		end
	
	end		#Shoes.app
end		#module
