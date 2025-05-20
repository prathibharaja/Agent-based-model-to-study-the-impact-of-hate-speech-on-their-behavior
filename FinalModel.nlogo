; Gruppe 4
; Alexander Helwig
; Qingbo Qiao
; Prathibha Rajapaksha

globals [
  silent-pos-count ; number of silent turtles with positive opinion from previous run
  silent-neg-count ; number of silent turtles with negative opinion from previous run
  first? ; tracks if current attempt to end simulation is the first or second in a row
]

turtles-own [
  opinion     ; 1 = positive; -1 = negative
  self-censor ; threshhold for self-censoring [0; 1]; confidence needs to be higher than this for turtle to speak out
  confidence  ; confidence of the turtle based on majority opinion in neighbourhood [0; 1]
  silent?     ; if true, turtle doesn't speak out
  hater?      ; if true, turtle is a hater
  paragon?    ; if true, turtle is a paragon
  ban-pending?; if true, a ban of this turtle has been requested but not yet accepted or refused
  banned?     ; if true, the turtle has been banned and will always remain silent
  hate-speech-seen? ; added variable for calibration
]

to setup ; setup procedure creating the intitial state of the simulation
  clear-all
  if user-defined-seed? [random-seed seed] ; allows using user-defined seeds for validation
  setup-nodes
  setup-spatially-clustered-network
  ask n-of (number-of-nodes * negative-opinion-ratio) turtles [set opinion -1]  ; assign negative opinion to indirectly selected number of turtles
  ask n-of hater-count turtles with [opinion = -1] [ ; turn some of the turtles with negative opinion into haters (minimum is 1 based on slider)
    set hater? true
    set hate-speech-seen? true ; any hater will see the hate speech content they themselves create
  ]
  ask n-of paragon-count turtles with [opinion = 1] [set paragon? true] ; turn some of the turtles with positive opinion into paragons (minimum is 0 based on slider, so paragons aren't always present)
  ask turtles [update-color]
  ask links [set color white]
  set silent-pos-count 0 ; initialize both counters with 0. They are used as a criterion to stop the simulation early
  set silent-neg-count 0 ; see above
  set first? true
  reset-ticks
end

to setup-nodes ; creates specified amount of turtles and initialize them
  set-default-shape turtles "circle"
  create-turtles number-of-nodes [
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set opinion 1
    set self-censor random-float 1
    set confidence 1
    set silent? false
    set hater? false
    set paragon? false
    set ban-pending? false
    set banned? false
    set hate-speech-seen? false
  ]
end

to setup-spatially-clustered-network ; creates links between turtles and reshapes network for better visibility
  let num-links (average-node-degree * number-of-nodes) / 2
  while [count links < num-links]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [create-link-with choice]
    ]
  ]
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-nodes)) 1
  ]
end

to go ; procedure for a single step of the simulation
  if block-chance > 0 [block-haters] ; if blocking is enabled, this checks each link between an active hater and a turtle with positive opinion and tries to remove said link BEFORE confidence is calculated
  ask turtles [update-confidence] ; updated confidence is calculated for each turtle
  ask turtles [
    become-silent ; checks if the turtle becomes silent or vocal
    if ban-request-chance > 0 [process-bans] ; if bans have been activated in the model, requested bans are processed now AFTER turtles have become silent
    update-color ; changes color of turtles if necessary if their status changed
  ]
  add-hater-links ; haters attempt to gain new links; represents their increasing reach and influence over time
  if (count turtles with [paragon? = true and silent? = false] > 0 and paragon-link-chance > 0) [add-links] ; if the addition of new links to paragons is enabled, the creation of new  links between them and other turtles is attempted here
  tick
  if stop-check [ ; checks to see if termination requirements are fulfilled and if so, stops the go-loop
    if user-defined-seed? [show (count turtles with [hate-speech-seen? = true] / 3)] ; outputs model performance for valdiation during validation
    print (word "Visible opinion ratio: " (count turtles with [not silent? and opinion = -1] / count turtles with [not silent?]))
    print (word "Positive silent ratio: " (count turtles with [silent? and opinion = 1] / count turtles with [opinion = 1]))
    print (word "Negative silent ratio: " (count turtles with [silent? and opinion = -1] / count turtles with [opinion = -1]))
    stop
  ]
end

to add-hater-links; procedure for the creation of new links for active hater-turtles
  ask turtles with [hater? = true and silent? = false] [
    let rand random-float 1
    if rand < hater-link-chance [
      let counter 0
      while [counter < hater-link-count] [
        let choice (min-one-of (other turtles with [not link-neighbor? myself]) [distance myself])
        if choice != nobody [create-link-with choice]
        set counter (counter + 1)
      ]
    ]
  ]
end

to add-links ; procedure for the creation of new links for active paragon-turtles
  ask turtles with [paragon? = true and silent? = false] [ ; links will only be created for paragons that are still active in the network
    let rand random-float 1
    if rand < paragon-link-chance [ ; compare randomly generated number with the likelihood of creating new links originating from the currently selected paragon
      let counter 0 ; counter for newly created links
      while [counter < paragon-link-count] [ ; loop for link creation. Repeated until the chosen amount of links has been created (if possible)
        let choice (min-one-of (other turtles with [not link-neighbor? myself]) [distance myself]) ; chooses nearest not yet connected turtle as link-partner
        if choice != nobody [create-link-with choice] ; if valid partner has been found, link is created
        set counter (counter + 1)
      ]
    ]
  ]
end

to become-silent ; procedure that checks if a turtle becomes silent
  ifelse self-censor > confidence [set silent? true] [set silent? false] ; turtle becomes silent if its confidence lies below its own self-censor willingness
end

to block-haters ; procedure that simulates positive turtles blocking haters that they notice by removing the links between them based on chance
  ask links with [[opinion] of end1 = 1 and [hater?] of end2 = true and [silent?] of both-ends = [false false]] [ ; selects links created from a turtle with a positive opinion to a hater, with neither of them being silent
    let rand random-float 1
    if rand < block-chance [die] ; compares random number with chance of the positive opinion turtle blocking the hater. If successful, the link between the two is removed
  ]
  ask links with [[opinion] of end2 = 1 and [hater?] of end1 = true and [silent?] of both-ends = [false false]] [ ; same as above but for links that were created from a hater to a positive turtle
    let rand random-float 1
    if rand < block-chance [die]
  ]
end

to process-bans ; procedure that processes bans AFTER confidence has been updated
  ask turtles with [ban-pending? = true] [ ; selects turtles (haters) for which a ban has been requested during the current time step
    let rand random-float 1
    if rand < ban-success-rate [ ; compares randomly generated number with selected chance of a requested ban actually being enforced
      ask my-links [die] ; removes all links connecting the banned turtle with others
      set silent? true ; makes banned turtle silent
      set banned? true ; marks banned turtle as banned, which ensures that it will remain silent
    ]
    set ban-pending? false ; whether or not the ban was successful, the ban request is removed, though further requests are still possible
  ]
end

to request-bans ; procedure to simulate bans being requested BEFORE confidence is calculated
  ask link-neighbors with [hater? = true and silent? = false] [ ; selects outspoken haters among the neighbors of the currently selected turtle
    let rand random-float 1
    if rand < ban-request-chance [set ban-pending? true] ; compares randomly generated number with the chance of the turtle requesting a ban of the hater and flags that hater for ban processing after the confidence update, if successful
  ]
end

to update-color ; procedure to update the color of turtles to reflect potential status changes (silent = grey, positive opinion = blue, negative opinion = red, hater = yellow, paragon = green)
  ifelse silent? = true
  [
    set color grey
  ]
  [
    ifelse opinion = 1
    [
      ifelse paragon? = true [set color green] [set color blue]
    ]
    [
      ifelse hater? = true [set color yellow] [set color red]
    ]
  ]
end

to update-confidence ; procedure used for the calculation of the new confidence during each step
  if banned? = true [ ; automatically assigns confidence of 0 to banned turtles and ends this procedure early. This ensures that banned turtles will remain silent
    set confidence 0
    stop
  ]
  let d delta ; procedure call which calculates the change in confidence
  let ĉ max (list (confidence + d) 0) ; applies change in confidence to current confidence, though this value cannot fall below 0
  set confidence ((2 * ((1 + (exp(-1 * ĉ))) ^ -1)) - 1) ; calulates new confidence
  if hater? = true [set confidence (confidence + hater-confidence-boost)] ; adds specified boost to confidence of the turtle if it is a hater
  if paragon? = true [set confidence (confidence + paragon-confidence-boost)] ; adds specified boost to confidence of the turtle if it is a paragon
end

to-report delta ; procedure for the calculation of the confidence change based on a turtles neighbors and their opinions
  let ns 0
  let no 0
  let hater-influence (count link-neighbors with [silent? = false and hater? = true] * hater-influence-boost)
  if hater-influence > 0 [set hate-speech-seen? true]
  ifelse opinion = 1 ; since the relative opinion of neighbors (same vs. opposite) is relevant, the opinion of the currently selected turtle determines which opinion (positive vs. negative) is which
  [
    if ban-request-chance > 0 [request-bans] ; if ban requests are enabled, the turtle will try to request bans of any hater it is in contact with, though those will only come into effect after the calculation of its new confidence
    set ns count link-neighbors with [opinion = 1 and silent? = false] ; counts number of neighbors with the same opinion
    set no (count link-neighbors with [opinion = -1 and silent? = false] + hater-influence) ; same but for opposite opinion. Haters may count as multiple turtles based on their influence boost
  ]
  [
    ; neither blocking nor banning are available for turtles with negative opinion, as in the model, no haters with positive opinion exist which could be banned/blocked
    set ns (count link-neighbors with [opinion = -1 and silent? = false] + hater-influence) ; number of neighbors with same opinion. Once again, haters may count as multiple turtles
    set no count link-neighbors with [opinion = 1 and silent? = false] ; number of neighbors with opposite opinion
  ]
  ifelse ns + no = 0 [report 0] [report (ns - no) / (ns + no)] ; returns the calculated change based on the numbers calculated above. If a turtle has no neighbors, 0 is returned before calcualtion to prevent division by zero.
end

to-report stop-check ; procedure that checks if termination criteria are fulfilled; used to check for more complex criteria but those are no longer valid after the addition of hater link growth
  if ticks = 100 [report true] ; simulation ends after 100 time steps at the latest, as it is possible for a stable loop of values to emerge preventing the other termination criterion from being fulfilled
  report false
end
@#$#@#$#@
GRAPHICS-WINDOW
265
10
724
470
-1
-1
11.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
28
483
123
523
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
140
484
235
524
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
762
527
1017
789
Network Status
time
% of nodes
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"positive" 1.0 0 -13345367 true "" "plot (count turtles with [not silent? and opinion = 1]) / (count turtles) * 100"
"negative" 1.0 0 -2674135 true "" "plot (count turtles with [not silent? and opinion = -1]) / (count turtles) * 100"
"silent" 1.0 0 -7500403 true "" "plot (count turtles with [silent?]) / (count turtles) * 100"

SLIDER
25
15
230
48
number-of-nodes
number-of-nodes
50
300
300.0
50
1
NIL
HORIZONTAL

SLIDER
25
85
230
118
negative-opinion-ratio
negative-opinion-ratio
0.2
0.5
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
25
50
230
83
average-node-degree
average-node-degree
5
15
5.0
5
1
NIL
HORIZONTAL

PLOT
9
527
372
789
Visible Opinion Ratio
time
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Opinion = +1" 1.0 0 -13345367 true "" "plot count turtles with [not silent? and opinion = 1] / count turtles with [not silent?] * 100"
"Opinion = -1" 1.0 0 -2674135 true "" "plot count turtles with [not silent? and opinion = -1] / count turtles with [not silent?] * 100"

PLOT
376
527
759
789
Silent Ratio
time
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Opinion = +1" 1.0 0 -13345367 true "" "plot count turtles with [silent? and opinion = 1] / count turtles with [opinion = 1] * 100"
"Opinion = -1" 1.0 0 -2674135 true "" "plot count turtles with [silent? and opinion = -1] / count turtles with [opinion = -1] * 100"
"Overall" 1.0 0 -7500403 true "" "plot count turtles with [silent?] / number-of-nodes * 100"

SLIDER
25
120
231
153
hater-count
hater-count
11
13
12.0
1
1
NIL
HORIZONTAL

SLIDER
26
229
232
262
paragon-count
paragon-count
0
hater-count
0.0
1
1
NIL
HORIZONTAL

SLIDER
26
265
233
298
paragon-confidence-boost
paragon-confidence-boost
0.1
0.7
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
26
301
233
334
paragon-link-chance
paragon-link-chance
0
1
0.0
0.2
1
NIL
HORIZONTAL

SLIDER
27
374
234
407
block-chance
block-chance
0
0.4
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
27
410
235
443
ban-request-chance
ban-request-chance
0
0.2
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
27
446
235
479
ban-success-rate
ban-success-rate
0.3
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
25
156
230
189
hater-confidence-boost
hater-confidence-boost
0.1
0.7
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
26
338
234
371
paragon-link-count
paragon-link-count
1
5
1.0
1
1
NIL
HORIZONTAL

SLIDER
26
192
230
225
hater-influence-boost
hater-influence-boost
0.5
2
1.0
0.5
1
NIL
HORIZONTAL

PLOT
739
215
940
469
Hate Speech Prevalence
time
% of nodes
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"nodes" 1.0 0 -16777216 true "" "plot (count turtles with [hate-speech-seen? = true] / number-of-nodes) * 100"

SLIDER
748
12
920
45
hater-link-chance
hater-link-chance
0.06
0.21
0.21
0.05
1
NIL
HORIZONTAL

SLIDER
748
50
920
83
hater-link-count
hater-link-count
1
3
1.0
1
1
NIL
HORIZONTAL

INPUTBOX
749
128
921
188
seed
1.2031998E7
1
0
Number

SWITCH
749
88
921
121
user-defined-seed?
user-defined-seed?
1
1
-1000

MONITOR
947
216
1099
261
visible-opinion-ratio
count turtles with [not silent? and opinion = -1] / count turtles with [not silent?]
17
1
11

MONITOR
948
265
1099
310
positive-silent-ratio
count turtles with [silent? and opinion = 1] / count turtles with [opinion = 1]
17
1
11

MONITOR
948
314
1099
359
negative-silent-ratio
count turtles with [silent? and opinion = -1] / count turtles with [opinion = -1]
17
1
11

@#$#@#$#@
## WHAT IS IT?

## HOW IT WORKS

## HOW TO USE IT

## THINGS TO NOTICE

## THINGS TO TRY

## EXTENDING THE MODEL

## RELATED MODELS

## NETLOGO FEATURES

## HOW TO CITE
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
