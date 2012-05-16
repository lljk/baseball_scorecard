#  2012  J. Kaiden
#  please see the gameday_copyright.txt file

class Array		#makes green_shoes play nice with gameday_api ;)
  def clear; _clear end
end

module CardGenerator
	
	def init_cards(game)
		@image_dir = "file://#{File.join(File.expand_path(File.dirname(__FILE__)), "images")}"
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
		bases_file = File.join(@image_dir, 'bases')
		bases.each_with_index{|b, i|
			if b
				bases_file << "-#{(i+1).to_s}"
			end
		}
		bases_file << '.png'
		@elements << bases_file	#[0]

		event_image = nil
		case atbat.event
			when "Single"
				note = "1B"; event_image = File.join(@image_dir, 'hit_1B.png')
				get_fldg(atbat.des)
			when "Double"
				note = "2B"; event_image = File.join(@image_dir, 'hit_2B.png')
				get_fldg(atbat.des)
			when "Triple"
				note = "3B"; event_image = File.join(@image_dir, 'hit_3B.png')
				get_fldg(atbat.des)
			when "Home Run"
				note = "HR"; event_image = File.join(@image_dir, 'hit_HR.png')
				get_fldg(atbat.des)
			when "Walk"; note = "BB"
			when "Intent Walk"; note = "IBB"
			when "Hit By Pitch"; note = "HBP"
			when "Strikeout"
				if atbat.des.include?("called")
					note = "KC"
				else
					note = "K"
				end
			when "Flyout"; note = "F"; get_fldg(atbat.des)
			when "Groundout"; note = "G"; get_fldg(atbat.des)
			when "Pop Out"; note = "P"; get_fldg(atbat.des)
			when "Lineout"; note = "L"; get_fldg(atbat.des)
			when "Forceout"; note = "FO"; get_fldg(atbat.des)
			when "Field Error"; note = "E"; get_fldg(atbat.des)
		end		#case
		if atbat.event.include?("DP") || atbat.des.include?("double play")
			note = "DP"; get_fldg(atbat.des)
		end
		if atbat.event.include?("TP") || atbat.des.include?("triple play")
			note = "TP"; get_fldg(atbat.des)
		end
		if atbat.des.include?("sacrifice")
			note = "SAC"; get_fldg(atbat.des)
		end
		if atbat.des.include?("fielder's choice")
			note = "FC"; get_fldg(atbat.des)
		end
		if atbat.des.include?("ground-rule")
			note = "GR"; get_fldg(atbat.des)
		end
		
		@elements << note #[1]
		@elements << event_image #[2]
		
		outs = nil
		unless atbat.o == "0" || atbat.o == last_atbat.o
			outs = atbat.o
		end
		@elements << outs #[3]
		
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
			
			f.puts '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
			"http://www.w3.org/TR/html4/loose.dtd">'
			f.puts "<html>"
				f.puts "<head>"
					f.puts "<meta content=\"text/html; charset=ISO-8859-1\" http-equiv=\"content-type\">"
					f.puts "<title>\"#{team_abrev} Scorecard\"</title>"
				f.puts "</head>"
				
				bg_img = File.join(@image_dir, 'grass.jpg')
				f.puts "<body style=\"background-image: url('#{bg_img}')\">"
					f.puts "<h1 style=\"text-align: center; color: white; font-family: Arial\">"
						f.puts "<big>#{@visiting_team} #{@visiting_score} - #{@home_team} #{@home_score}</big>"
					f.puts "</h1>"
					
					f.puts "<h2 style=\"text-align: center; color: white; font-family: Arial;\">"
							f.puts "<big>#{@date}</big>"
					f.puts "</h2>"#
					
					f.puts "<img src=\"#{File.join(@image_dir, "team_images", "#{team_abrev.downcase}.png")}\" style=\"position: relative; top: -60px; left: 10px;\">"
	
					f.puts "<table style=\"position: relative; top: -55px; text-align: left; width: 100px;\" cellpadding=\"2\" cellspacing=\"2\">"
						f.puts "<tbody>"
						
							f.puts "<tr>"
							f.puts "<td></td>"
							inning_num = 1
							@game.innings.length.times{
								f.puts "<td style=\"vertical-align: top; font-family: Arial; color: white; text-align: center; width: 75px; font-weight: bold;\">"
									f.puts "<big>#{inning_num}</big>"
								f.puts "</td>"
								inning_num += 1
							}
							f.puts "</tr>"
							
						batters.each_with_index{|batter, batter_index|
							unless batter.batting_order == 0
								f.puts "<tr>"
									
									f.puts "<td title=\"#{batter.stats}\">"
											f.puts "<pre style=\"font-family: Arial; color: white; padding-right: 7px; font-weight: bold; text-align: right;\"><big>#{batter.batting_order}\n#{batter.name}\n##{batter.number} #{batter.position}</big></pre>"
									f.puts "</td>"
									
									batter.innings.each_with_index{|inning, inning_index|
										if inning.empty?
											f.puts "<td style=\"width: 96px; height: 96px;\">"
											f.puts "<img src=\"#{File.join(@image_dir, 'bases_no_ba.png')}\" style=\"position: relative; top: 0; left: 0\"></img>"##
											f.puts "</td>"
										else
											atbat = batter.innings[inning_index][-1]
											get_elements(home_or_away, batter_index, inning_index)
											description = ""
											if batter.innings[inning_index].length > 1
												batter.innings[inning_index].each_with_index{|ab, ab_index|
													description << "At Bat #{ab_index + 1}: #{ab.des}\n"
												}
											else
												description = atbat.des
											end
											f.puts "<td style=\"width: 96px; height: 96px;\" title=\"#{description}\">"
												f.puts "<div style=\"position: relative; width: 96px; height: 96px; background-transparent;\">"
													bases_bg = File.join(@image_dir, 'bases_bg.png')
													f.puts "<img src=\"#{bases_bg}\" width=\"96px\" height=\"96px\" style=\"position: absolute; top: 0; left: 0\">"
													f.puts "<img src=\"#{@elements[2]}\" width=\"96px\" height=\"96px\" style=\"position: absolute; top: 0; left: 0\">" if @elements[2]
													f.puts "<img src=\"#{@elements[0]}\" width=\"96px\" height=\"96px\" style=\"position: absolute; top: 0; left: 0\">"
													
													f.puts "<p style=\"font-family: Arial; text-align: center; position: absolute; top: 21px; width: 96px; font-weight: bold;\"><big>#{@elements[1]}</big></p>"
													f.puts "<p style=\"font-family: Arial; position: absolute; top: -12px; text-align: left; padding-left: 7px;\"><small>#{atbat.b}-#{atbat.s}</small></p>"
													f.puts "<p style=\"font-family: Arial; position: absolute; top: 56px; text-align: left; padding-left: 7px;\"><small>#{@fldg}</small></p>" if @fldg
													f.puts "<p style=\"font-family: Arial; position: absolute; top: -12px; width: 89px; text-align: right;\"><small>#{@elements[4]}<small>RBI</small></small></p>" if @elements[4]
													f.puts "<p style=\"font-family: Arial; position: absolute; top: 53px; width: 85px; text-align: right; color: rgb(153, 0, 0); font-weight: bold;\">#{@elements[3]}</p>" if @elements[3]
													f.puts "<p style=\"font-family: Arial; text-align: center; position: absolute; top: 37px; width: 93px; color: rgb(0, 153, 0);\">+AB</p>" if batter.innings[inning_index].length > 1
													f.puts "<p style=\"font-family: Arial; text-align: center; position: absolute; top: 7px; width: 96px; color: rgb(0, 153, 0);\">SB</p>" 	if atbat.des.include?('steals')
												f.puts "</div>"	#ab_cell
											f.puts "</td>"
										end		#if inning.empty?
									}		#batter.innings.each_with_index
								f.puts "</tr>"
							end		#unless
						}		#batters.each_with_index
					f.puts "</tbody>"
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
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.w}-#{pitcher.l}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.era}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.inn}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.bf}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.so}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.bb}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.h}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.r}</td>"
								f.puts "<td style=\"width: 150px; text-align: center\">#{pitcher.er}</td>"
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