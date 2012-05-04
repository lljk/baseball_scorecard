Scorecard Generator

Hey there - 

  If you care about baseball half as much as I do, this might be interesting to you - if not, well I'm sorry...

  Assuming you do give a rat's behind about baseball, odds are you've scored a game or two...  I've been living abroad for a good long while - and the truth is that folks where I am are clueless about baseball... their loss.  Anyway, here's an app I worked out to generate scorecards so I can check out the games the next day in a way that's sensible (to me at least...) even if i can't actually talk to anyone about it ;)

INSTALL:

gem install 'baseball_scorecard'

RUN:

scorecard

  Select a team and date, and click 'find games.'  If games for the given team and date are found, a box where you can select the game time (if there's a double header that day,) and a 'build scorecards' button will appear.  Click 'build scorecards,' and give the thing a little while to cook....  it's got a bunch of data to get and crunch!

  Everyone scores games a little differently, so here are some notes about my notation:

  Balls and strikes are shown in the upper left hand corner of each at bat cell, fielding or hit location in the lower left.  Rbi's are shown in the upper right corner, and outs in the lower right.

  Base hits are shown as a darkened path to the base, runners with darkened bases.

  The result of each at bat is shown in the center, and is noted as follows:

  1B - Single
  2B - Double
  3B - Triple
  HR - Home Run
  BB - Walk
  IBB - Intentional Walk
  HBP - Hit by Pitch
  K - Strikeout Swinging
  (backwards)K - Strikeout Looking
  F - Fly Out
  P - Pop Out
  L - Line Out
  G - Ground Out
  FC - Force Out / Fielder's Choice
  DP - Double Play
  TP - Triple Play
  SB - Stolen Base
  E - Error

  If a batter had more than one at bat in an inning, '+AB' is shown below the at bat result.

  Hovering over a particular at bat cell will show the description of the at bat.  Hovering over a batter will show their season and career stats.

  So i guess that's about it...  I've still got some work to do on the thing, but hopefully it'll mostly work!

  Go Shoes...
  Go Sox!!!

  - j
