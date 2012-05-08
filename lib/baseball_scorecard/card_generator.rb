#  2012  J. Kaiden
#  please see the gameday_copyright.txt file

class Array		#makes green_shoes play nice with gameday_api ;)
  def clear; _clear end
end

module CardGenerator
	
	def init_cards(game)
		@imagedir = "file:///#{File.join(File.dirname(__FILE__), "images")}"
		Thread.new{init_batting_arrays(game)}
	end
	
	def init_batting_arrays(game)
		@game = game
		@gid = @game.gid
		@status_line.text = "getting lineups..."
		p "fetching lineups..."###
		begin
			@home = @game.get_batters("home")
			@visitors = @game.get_batters("away")
			@home_pitchers = @game.get_pitchers("home")
			@visiting_pitchers = @game.get_pitchers("away")
		rescue Exception => e
			@status_line.text = "Error getting lineups"; p e
		end
		@status_line.text = "getting innings..."
		p "fetching innings..."###
		begin
			innings = @game.get_innings
		rescue Exception => e
			@status_line.text = "Error getting innings"; p e
		end
		@status_line.text = "getting atbats..."
		p "fetching atbats..."
		begin
			@atbats = @game.get_atbats
		rescue Exception => e
			@status_line.text = "Error getting atbats"; p e
		end
		@status_line.text = "getting team info..."
		p "getting team info..."###
		begin
			teams = Team.get_teams_for_gid(@gid)
			@visiting_team = "#{teams[0].city} #{teams[0].name}"
			@visiting_abrev = teams[0].abrev.upcase
			@home_team = "#{teams[1].city} #{teams[1].name}"
			@home_abrev = teams[1].abrev.upcase
		rescue Exception => e
			@status_line.text = "Error getting team info"; p e
		end

		@date = "#{Date::MONTHNAMES[@game.month.to_i]} #{@game.day}, #{@game.year}"
		box = @game.boxscore
		line = box.linescore
		@visiting_score = line.away_team_runs
		@home_score = line.home_team_runs
		
		@visiting_batters = []
		@home_batters = []
		
		@status_line.text = "building cards..."
		p "building arrays..."##
		
		Struct.new("Batter", :name, :number, :position, :id, :batting_order, :innings, :stats)
		@total = (@home.length + @visitors.length).to_f
		@processed = 0.0
		
		def build_array(home_or_away)
			case home_or_away
				when 'home'; batters = @home; batting_array = @home_batters
				when 'away'; batters = @visitors; batting_array = @visiting_batters
			end
			
			batters.each{|ba|
				@processed += 1.0
				@status_line.text = "#{((@processed/ @total) * 100).round.to_s}%"##
				
				b = Batter.new; b.load_from_id(@gid, ba.pid)
				xd = b.instance_variable_get("@xml_data")

				xd.split("<").each{|entry|
					if entry.include?("season")
						@season_stats = entry.delete('/>').delete('"').gsub('season', 'SEASON:').gsub('=', ': ')
					elsif entry.include?("career")
						@career_stats = entry.delete('/>').delete('"').gsub('career', 'CAREER:').gsub('=', ': ')
					end
				}
				stats = "#{@season_stats}\n#{@career_stats}"

				number = b.jersey_number
				inning_arrays = []
				@game.innings.length.times{
					inning_arrays << []
				}
				batter = Struct::Batter.new(ba.batter_name, number, ba.pos, ba.pid, (ba.bo.to_i / 100).round, inning_arrays, stats)
				batting_array << batter
			}		#batters.each
		end		#build_array
		
		begin
			build_array('home')
			build_array('away')
		rescue Exception => e
			@status_line.text = "Error building arrays"; p e
		end
		
		def set_inning(home_or_away, ab)
			case home_or_away
				when 'home'; batting_array = @home_batters
				when 'away'; batting_array = @visiting_batters
			end
			
			inning = ab.inning.to_i
			player_id = ab.batter_id
			
			batting_array.each{|batter|
				if batter.id == player_id
					batter.innings[inning - 1] << ab
				end
			}
		end		#set_inning
		
		begin
			innings.each{|i|
				i.top_atbats.each{|ab| set_inning('away', ab)}
				i.bottom_atbats.each{|ab| set_inning('home', ab)}
			}
		rescue Exception => e
			@status_line.text = "Error setting innings"; p e
		end
	
		@status_line.text = "arrays built"
		p "arrays built"##
		init_html('home')
		init_html('away')
		
	end		#init_batting_arrays
	
	def get_elements(home_or_away, batter_index, inning_index)
		@elements = []
		@fldg = nil
		
		if home_or_away == 'home'
			batting_array = @home_batters
		else
			batting_array = @visiting_batters
		end
		atbat = batting_array[batter_index].innings[inning_index][-1]
		next_atbat = @atbats[atbat.num.to_i]
		last_atbat = @atbats[atbat.num.to_i - 2]
		
		bases = []
		if next_atbat
			bases << next_atbat.pitches[0].on_1b << next_atbat.pitches[0].on_2b << next_atbat.pitches[0].on_3b
		else
			bases << atbat.pitches[0].on_1b << atbat.pitches[0].on_2b << atbat.pitches[0].on_3b
		end
		bases_file = File.join(@imagedir, "bases")
		bases.each_with_index{|b, i|
			if b
				bases_file << "-#{(i+1).to_s}"
			end
		}
		bases_file += ".png"
		@elements << bases_file	#[0]
		
		case atbat.event
			when "Single"
				event_image = File.join(@imagedir, "hit_1B.png")
				get_fldg(atbat.des)
			when "Double"
				event_image = File.join(@imagedir,  "hit_2B.png")
				get_fldg(atbat.des)
			when "Triple"
				event_image = File.join(@imagedir,  "hit_3B.png")
				get_fldg(atbat.des)
			when "Home Run"
				event_image = File.join(@imagedir,  "hit_HR.png")
				get_fldg(atbat.des)
			when "Walk"
				event_image = File.join(@imagedir,  "hit_BB.png")
			when "Intent Walk"
				event_image = File.join(@imagedir, "hit_IBB.png")
			when "Hit By Pitch"
				event_image = File.join(@imagedir,  "hit_HBP.png")
			when "Strikeout"
				if atbat.des.include?("called")
					event_image = File.join(@imagedir,  "out_called.png")
				else
					event_image = File.join(@imagedir,  "out_strikes.png")
				end
			when "Flyout"
				event_image = File.join(@imagedir,  "out_fly.png")
				get_fldg(atbat.des)
			when "Groundout"
				event_image = File.join(@imagedir,  "out_ground.png")
				get_fldg(atbat.des)
			when "Pop Out"
				event_image = File.join(@imagedir,  "out_pop.png")
				get_fldg(atbat.des)
			when "Lineout"
				event_image = File.join(@imagedir,  "out_line.png")
				get_fldg(atbat.des)
			when "Forceout"
				event_image = File.join(@imagedir,  "out_force.png")
				get_fldg(atbat.des)
			when "Field Error"
				event_image = File.join(@imagedir, "error.png")
				get_fldg(atbat.des)
		end		#case
		if atbat.event.include?("DP")
			event_image = File.join(@imagedir,  "out_double-play.png")
			get_fldg(atbat.des)
		end
		if atbat.event.include?("TP")
			event_image = File.join(@imagedir,  "out_triple-play.png")
			get_fldg(atbat.des)
		end
		
		@elements << event_image #[1]
		
		outs_image = nil
		unless atbat.o == "0" || atbat.o == last_atbat.o
			outsfile = "outs_#{atbat.o}.png"
			outs_image = File.join(@imagedir, outsfile)
		end
		@elements << outs_image #[2]
		
		@elements.insert(3, @fldg) if @fldg  #[3]
		
		rbi = atbat.des.scan(/scores/).length
		@elements.insert(4, rbi) unless rbi == 0  #[4]
		
	end		#get_elements
	
	def get_fldg(des)
		fldg = []
		fldg.insert(des.index("pitcher"), "1") if des.include?("pitcher")
		fldg.insert(des.index("catcher"), "2") if des.include?("catcher")
		fldg.insert(des.index("first baseman"), "3") if des.include?("first baseman")
		fldg.insert(des.index("second baseman"), "4") if des.include?("second baseman")
		fldg.insert(des.index("third baseman"), "5") if des.include?("third baseman")
		fldg.insert(des.index("shortstop"), "6") if des.include?("shortstop")
		fldg.insert(des.index("left field"), "7") if des.include?("left field")
		fldg.insert(des.index("center field"), "8") if des.include?("center field")
		fldg.insert(des.index("right field"), "9") if des.include?("right field")
		@fldg = fldg.compact.join("-")
	end
	
	def init_html(home_or_away)
	@status_line.text = "building html"
	p "writing html"###
	
	case home_or_away
		when 'home'
		batters = @home_batters; pitchers = @home_pitchers; team_abrev = @home_abrev
		when 'away'
		batters = @visiting_batters; pitchers = @visiting_pitchers; team_abrev = @visiting_abrev
	end
	
	File.open("scorecard_#{home_or_away}.html", "w"){|f|
	
		f.puts "<html>"
			f.puts "<head title=\"#{team_abrev} Scorecard\"></head>"
			f.puts "<body style=\"background-image: url(#{File.join(@imagedir, 'grass.jpg')})\">"
				
				f.puts "<h1 style=\"padding-top: 5\">"
					f.puts "<pre style=\"color: white; font-family: arial; text-align: center\">"
						f.puts "#{@visiting_team} #{@visiting_score} - #{@home_team} #{@home_score}"
					f.puts "</pre>"
				f.puts "</h1>"
				
				f.puts "<h2>"
					f.puts "<pre style=\"color: white; font-family: arial; text-align: center\">"
						f.puts @date
					f.puts "</pre>"
					f.puts "<img src=\"#{File.join(@imagedir, 'team_images', "#{team_abrev.downcase}.png")}\" style=\"position: absolute; left: 20; top:85\">"
				f.puts "</h2>"
				
				f.puts "<table>"
				
					f.puts "<tr>"
					f.puts "<td></td>"
					inning_num = 1
					@game.innings.length.times{
						f.puts "<td style=\"color: white; font-family: arial; font-size: 125%; text-align: center\">"
							f.puts inning_num
						f.puts "</td>"
						inning_num += 1
					}
					f.puts "</tr>"
					
				batters.each_with_index{|batter, batter_index|
						unless batter.batting_order == 0
							f.puts "<tr>"
							
								f.puts "<td style=\"width: 150\" title=\"#{batter.stats}\">"
									f.puts "<pre style=\"color: white; font-family: arial; font-size: 125%; text-align: right; padding-right: 20\">"
										f.puts "#{batter.batting_order}\n#{batter.name}\n##{batter.number} #{batter.position}"
									f.puts "</pre>"
								f.puts "</td>"
								
								batter.innings.each_with_index{|inning, inning_index|
									if inning.empty?
										f.puts "<td>"
										f.puts "<img src=\"#{File.join(@imagedir, 'bases_no_ba.png')}\" style=\"position: relative; top: 0; left: 0\"></img>"
										f.puts "</td>"
									else
										atbat = batter.innings[inning_index][-1]
										get_elements(home_or_away, batter_index, inning_index)
										description = ""#
										if batter.innings[inning_index].length > 1#
											batter.innings[inning_index].each_with_index{|ab, ab_index|#
												description << "At Bat #{ab_index + 1}: #{ab.des}\n"#
											}#
										else
											description = atbat.des
										end
										f.puts "<td style=\"position: relative; top: 0; left: 0\" title=\"#{description}\">"
											f.puts "<img src=\"#{File.join(@imagedir, 'bases_bg.png')}\" style=\"position: absolute; top: 0; left: 0\"></img>"
											f.puts "<img src= #{@elements[1]} style=\"position: absolute; top: 0; left: 0\"></img>" if @elements[1]
											f.puts "<img src= #{@elements[0]} style=\"position: absolute; top: 0; left: 0\"></img>"
											f.puts "<img src= #{@elements[2]} style=\"position: absolute; top: 69; left: 69\"></img>" if @elements[2]
											f.puts "<pre style=\"position: absolute; top: -7; left: 7; font-family: arial; font-size: small\">"
												f.puts "#{atbat.b}-#{atbat.s}"
											f.puts "</pre>"
											if @fldg
												f.puts "<pre style=\"position: absolute; top: 60; left: 7; font-family: arial; font-size: small\">"
													f.puts @fldg
												f.puts "</pre>"
											end
											if @elements[4]
												f.puts "<pre style=\"position: absolute; top: -7; left: 65; font-family: arial; font-size: small\">"
													f.puts @elements[4]
												f.puts "</pre>"
												f.puts "<pre style=\"position: absolute; top: -1; left: 72; font-family: arial; font-size: x-small\">"
													f.puts "RBI"
												f.puts "</pre>"
											end
											if batter.innings[inning_index].length > 1
												f.puts "<pre style=\"position: absolute; top: 6; left: 32; font-family: arial; font-weight: bold\">"
													f.puts "+AB"
												f.puts "</pre>"
											end
											if atbat.des.include?('steals')
												f.puts "<pre style=\"position: absolute; top: 6; left: 37; font-family: arial; font-weight: bold\">"
													f.puts "SB"
												f.puts "</pre>"
											end
											
										f.puts "</td>"
									end		#if inning.empty?
								}		#batter.innings.each_with_index
							f.puts "</tr>"
						end		#unless
					}		#batters.each_with_index
					
				f.puts "</table>"
				
				f.puts "<hr style=\"padding-top: 10\"></hr>"
				f.puts "<h2 style=\"color: white; font-family: arial; text-align: center\">Pitching</h2>"
				
				f.puts "<table>"
				
					f.puts "<tr>"
						f.puts "<td></td>"
						%w[W-L ERA IP AB K BB H R ER].each{|entry|
							f.puts "<td style=\"width: 150; color: white; font-family: arial; font-size: 125%; text-align: center\">"
								f.puts entry
							f.puts "</td>"
						}
					f.puts "</tr>"
					
					pitchers.each{|pitcher|
						f.puts "<tr style=\"color: white; font-family: arial\">"
							f.puts "<td style=\"font-size: 125%; text-align: right; padding-right: 20\">"
								f.puts pitcher.pitcher_name
							f.puts "</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.w}-#{pitcher.l}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.era}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.inn}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.bf}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.so}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.bb}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.h}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.r}</td>"
							f.puts "<td style=\"width: 150; text-align: center\">#{pitcher.er}</td>"
						f.puts "</tr>"
					}
				f.puts "</table>"
				
			f.puts "</body>"
		f.puts "</html>"
		
	}	#close file
	
	@status_line.text = "html built"
	p "html built"##
	Launchy.open("./scorecard_#{home_or_away}.html")
end		#init_html()
	
end		#module CardGenerator