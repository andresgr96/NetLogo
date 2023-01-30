globals [lightCounter pedestrianWaitingTime carWaitingTime]
breed [sceneObjects sceneObject]
breed [cars car]
breed [pedestrians pedestrian]
breed [traffickLights light]

cars-own
[
  preference                       ;indicates whether a car wants to turn left (-1), right (1) or go straight (0)
  alreadyTurned?                   ;keeps track of whether a car has already made a turn on the intersection
  moving?                          ;keeps track if the car is moving
]

pedestrians-own
[
  subPatch                         ;keeps track of the subpatch currently occupied by the pedestrian
  class
  moving?                          ;keeps track if the pedestrian is moving
]

patches-own
[
  road?                            ;is this patch part of the road?
  sidewalk?                        ;is it part of the sidewalk?
  intersection?                    ;is it an intersection?
  turningPoint?                    ;is it a place where agents can turn?
  headingTurnLeft                  ;indicates which heading a turtle should have to turn left on this patch
  headingTurnRight                 ;same for right turn
  subPatches                       ;each patch is divided in 4 subpatches that can hold a pedestrian
  assignedLight                    ;the light cars have to check before driving forward in this patch
  horizontalPedestrianLight        ;specific pedestrian light for horizontal walking humans, necessary to distinct when pedestrians walk in the same patch but in diff directions
  verticalPedestrianLight          ;same as bove but vertical
]

traffickLights-own
[
  lightColor                       ;keeps track of the current color displayed by the lights: red(-1), yellow(0), green(1)
  id                               ;where

]


to setup
  clear-all
  reset-ticks
  setupWorld
  setupPedestrians
  setupCars
  setupTraffickLights
  set lightCounter 0
  set pedestrianWaitingTime 0
  set carWaitingTime 0
end

to setupWorld
  ask patches                      ;setup buildings
  [
    set pcolor 7
    set subPatches [nobody nobody nobody nobody]
  ]
                                   ;setup field
  ask patches with [pxcor < -1 and pycor < -1]
  [
    set pcolor 64
  ]
                                   ;setup sidewalks
  ask patches with [pxcor = 1 or pycor = 1]
  [
    set pcolor 3
    set sidewalk? true
    set intersection? false
    set turningPoint? false
  ]
                                   ;setup the road
  ask patches with [(pxcor >= -1 and pxcor <= 0) or (pycor >= -1 and pycor <= 0)]
  [
    set pcolor black
    set road? true
    set intersection? false
    set turningPoint? false
  ]
                                   ;setup intersection
  ask patches with [(pxcor >= -1 and pxcor <= 1) and (pycor >= -1 and pycor <= 1) and not (pxcor = 1 and pycor = 1)]
  [
    set pcolor 1
    set intersection? true
    if pxcor = 0 and pycor = 0
    [
      set turningPoint? true
      set headingTurnLeft 0
      set headingTurnRight 270
    ]
    if pxcor = 0 and pycor = -1
    [
      set turningPoint? true
      set headingTurnLeft 90
      set headingTurnRight 0
    ]
    if pxcor = -1 and pycor = -1
    [
      set turningPoint? true
      set headingTurnLeft 180
      set headingTurnRight 90
    ]
    if pxcor = -1 and pycor = 0
    [
      set turningPoint? true
      set headingTurnLeft 270
      set headingTurnRight 180
    ]
  ]

  ;add light assignment to patches that need it.
  ;light for cars at (-1,2): 3
  ;light for cars at (2,0): 1
  ;light for cars at (0,-2): 2
  ;light for cars at (-2,-1): 4
  ;0 for patches with no light assignment needed, mainly for conditional checks
  ask patches
  [
    set assignedLight 0
    if pxcor = 2 and pycor = 0
    [
      set assignedLight 1
    ]
    if pxcor = 0 and pycor = -2
    [
      set assignedLight 2
    ]
    if pxcor = -1 and pycor = 2
    [
      set assignedLight 3
    ]
    if pxcor = -2 and pycor = -1
    [
      set assignedLight 4
    ]
    ;traffick Light for pedestrians walking horizontally
    if (pxcor = 1 or pxcor = -2) and (pycor >= 0.75 and pycor <= 1.25)
    [
      set horizontalPedestrianLight 5
    ]
    ;traffick light for pedestrians walking vertically
    if (pycor = 1 or pycor = -2) and (pxcor >= 0.75 and pxcor <= 1.25)
    [
      set verticalPedestrianLight 6
    ]
  ]
                                   ;setup crosswalks
  let direction (list "crosswalkVertical" "crosswalkVertical" "crosswalkHorizontal" "crosswalkHorizontal")
  let places (list patch 1 0 patch 1 -1 patch 0 1 patch -1 1)
  let index 0

  create-sceneObjects 4
  [
    set shape item index direction
    move-to item index places
    set color 8
    set index index + 1
  ]
end

to setupPedestrians
  create-pedestrians numberOfPedestrians
  [
    set shape "person"
    set size 0.5
    set color 127
    findPlacePedestrian
  ]
end

to setupCars
  create-cars numberOfCars
  [
    set shape "cars"               ;default car shape was adjusted to enable rotate and adjust direction
    set color 98
    set preference (random 3) - 1  ;turn preference (-1 = left, 0 = straight ahead, 1 = right)
    findPlaceCar                   ;note: make sure always #cars < #places
  ]
end

to setupTraffickLights
  create-traffickLights 6
  [
    ;using list to declare variable values to avoid a bunch of ifs that would make the traffick lights setup function very ugly
    let shapeList (list "carTraffickLight" "carTraffickLight" "carTraffickLight" "carTraffickLight" "circle" "circle")
    let xcorList (list 2 2 -2 -2 -1.75 0.75)
    let ycorList (list 2 -2 2 -2 1.25 -2)
    let idList (list 1 2 3 4 5 6)
    let colorList (list 73 red red 73 72 red)
    let lightColorList(list 1 -1 -1 1 1 -1)
    let sizeList(list 1.25 1.25 1.25 1.25 0.5 0.5)

    ;now the variables are instaniated using the index built-in function + a counter to keep track of which lights have already been created
    set shape item lightCounter shapeList
    set size item lightCounter sizeList
    set xcor item lightCounter xcorList
    set ycor item lightCounter ycorList
    set id item lightCounter idList
    set lightColor item lightCounter lightColorList
    set color item lightCounter colorList
    set lightCounter lightCounter + 1
  ]
end


to findPlacePedestrian

  let success false
  while [success = false]
  [
    let place one-of patches with [sidewalk? = true and count turtles-here < 4]
    let subPlace random 4
    if [item subPlace subPatches] of place = nobody
    [
      ask place                    ;adds agent to one of the subpatches of a patch
      [                            ;note that myself here refers to the agent that askes the patch to do something
        set subPatches replace-item subPlace subPatches myself
      ]
      set subPatch subPlace        ;also keep track of occupied subpatch per agent
                                   ;the following lines give the agents the xy-coordinates matching the subpatch
      set xcor [pxcor] of place - 0.25 + 0.5 * (subplace mod 2)
      ifelse subPlace < 2
      [ set ycor [pycor] of place + 0.25]
      [ set ycor [pycor] of place - 0.25]
      set success true
    ]
  ]
  if ycor = 0.75                   ;set the direction the pedestrian is walking
  [
    set heading 270
    set class "horizontal"
  ]
  if ycor = 1.25
  [
    set heading 90
    set class "horizontal"
  ]
  if xcor = 0.75
  [
    set heading 180
    set class "vertical"
  ]
  if xcor = 1.25
  [
    set heading 0
    set class "vertical"
  ]
end

to findPlaceCar
                                   ;find a free piece of road and place the car on it
  let place one-of patches with [road? = true and not any? turtles-here]
  set xcor [pxcor] of place
  set ycor [pycor] of place

  if xcor = 0                      ;set the direction the car is driving
  [ set heading 0 ]
  if xcor = -1
  [ set heading 180 ]
  if ycor = 0
  [ set heading 270 ]
  if ycor = -1
  [ set heading 90 ]
end


to go
  movePedestrians
  moveCars

  if turnLights?
  [
    lightsBehaviour
  ]
end

to lightsBehaviour
  let n lightDuration
  if ticks mod n = 0
  [
  ask traffickLights
    [
      (ifelse lightcolor = -1
      [
        set lightColor 1
        set color 73
      ]
      lightcolor = 1
      [
        set lightColor -1
        set color red
      ])
    ]
  ]
end

to movePedestrians
  ask pedestrians
  [
                                   ;calculate the new xy-coordinates the pedestrian would like to move to
    let newX precision (xcor + sin heading * 0.5) 2
    let newY precision (ycor + cos heading * 0.5) 2
                                   ;check if the pedestrian is allowed to move there, if so move the agen
    let verticalLightCheck [verticalPedestrianLight] of patch-here
    let horizontalLightCheck [horizontalPedestrianLight] of patch-here
    let vLight traffickLights with [id = verticalLightCheck]    ;retireve the actual light agent
    let hLight traffickLights with [id = horizontalLightCheck]
    let freeToCrossVertically true
    let freeToCrossHorizontally true

    if turnLights?
    [
      ask vLight
      [
        if lightcolor = -1                                ;if the light ahead is red, then the car is no longer free to cross. No need to set back to true since this function is in go and the variable gets set back to true each time its called.
        [
          set freeToCrossVertically false
        ]
      ]

      ask hLight
      [
        if lightcolor = -1                                ;if the light ahead is red, then the car is no longer free to cross. No need to set back to true since this function is in go and the variable gets set back to true each time its called.
        [
          set freeToCrossHorizontally false
        ]
      ]
    ]
     ;if walking vertically then check the vertical permission to cross


    (ifelse any? other pedestrians with [xcor = newX and ycor = newY] or (any? cars-on patch-ahead 1 or any? cars-on patch-ahead 2) or ((class = "vertical" and freeToCrossVertically = false) or (class = "horizontal" and freeToCrossHorizontally = false))
      [
        set moving? false
      ]
      [
        (ifelse class = "vertical"
          [
            if not any? other pedestrians with [xcor = newX and ycor = newY] and ([pcolor = 3] of patch-ahead 1 or (not any? cars-on patch-ahead 1 and not any? cars-on patch-ahead 2)) and freeToCrossVertically = true
            [
              set xcor newX
              set ycor newY
              set moving? true
            ]
          ]

          ;if walking horizontally then check the horizontal permission to cross
          class = "horizontal"
          [
            if not any? other pedestrians with [xcor = newX and ycor = newY] and ([pcolor = 3] of patch-ahead 1 or (not any? cars-on patch-ahead 1 and not any? cars-on patch-ahead 2)) and freeToCrossHorizontally = true
            [
              set xcor newX
              set ycor newY
              set moving? true
            ]
          ]
        )
      ]
    )

    if not moving?
    [
     set pedestrianWaitingTime pedestrianWaitingTime + 1
    ]

  ]
end


to moveCars
  ask cars
  [                                ;first check whether the current patch is a turning point and the agent has not turned already. Note that this is necessary
    let intendedTurn 0             ;because otherwise agents may drive on the wrong side of the road

    ifelse [turningPoint?] of patch-here and alreadyTurned? = false
    [
                                   ;if agent wants to go to the left and it is at the correct patch to do so (its heading matches headingTurnLeft of patch)
      if heading = headingTurnLeft and preference = -1
      [
        set intendedTurn -90
        set alreadyTurned? true    ;this makes sure that a car only turns once on the intersection (no u-turns)
      ]
                                   ;same check but to the right
      if heading = headingTurnRight and preference = 1
      [
        set intendedTurn 90
        set alreadyTurned? true
      ]
    ]
    [                              ;if patch is not part of the intersection
      if not [intersection?] of patch-here
      [
        set alreadyTurned? false   ;reset parameter that keeps track of whether the agent has turned if not on the intersection
      ]
    ]
    rt intendedTurn                ;now that the prefered heading is chosen, check if the preferred new location is occupied
                                   ;if another car or pedestrian is in the way or a car is on the intersection, stay in place
                                   ;else the car can move forward

    let lightCheck [assignedLight] of patch-here        ;check wether the current patch is a patch where the car should check the traffick light before continuing, and retireve the id if so
    let tLight traffickLights with [id = lightCheck]    ;retireve the actual light agent
    let freeToCross true                                ;initially all cars are free to cross
    ask tLight
    [
      if lightcolor = -1                                ;if the light ahead is red, then the car is no longer free to cross. No need to set back to true since this function is in go and the variable gets set back to true each time its called.
      [
        set freeToCross false
      ]
    ]
     ifelse [pcolor = red] of patch-ahead 1 or any? cars-on patch-ahead 1 or any? pedestrians-on patch-ahead 1 or ([intersection? = false] of patch-here and [intersection? = true] of patch-ahead 1 and any? other cars-on patches with [intersection? = true]) or (freeToCross = false and turnLights?)
     [
       set moving? false
       if abs(intendedTurn) > 0     ;if the car turned already, undo the turn
       [
         lt intendedTurn
         set alreadyTurned? false
       ]
     ]
     [
      set moving? true
      forward 1
     ]
    if not moving?
    [
     set carWaitingTime carWaitingTime + 1
    ]
  ]

end

to-report avgCarWaitingTime
    let allCars count turtles with [breed = cars]
    report (carWaitingTime / allCars)
end

to-report avgPedestrianWaitingTime
    let allPeds count turtles with [breed = pedestrians]
    report (pedestrianWaitingTime / allPeds)
end
@#$#@#$#@
GRAPHICS-WINDOW
300
30
923
654
-1
-1
15.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
15
195
95
228
Setup
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
100
195
180
228
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
70
265
103
numberOfCars
numberOfCars
0
50
50.0
1
1
NIL
HORIZONTAL

BUTTON
185
195
265
228
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
30
265
63
numberOfPedestrians
numberOfPedestrians
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
15
110
265
143
lightDuration
lightDuration
0
500
500.0
1
1
NIL
HORIZONTAL

SWITCH
75
150
202
183
turnLights?
turnLights?
1
1
-1000

MONITOR
950
35
1065
80
Pedestrians Moving
count turtles with [breed = pedestrians and moving? = true]
17
1
11

MONITOR
950
95
1027
140
Cars Moving
count turtles with [breed = cars and moving? = true]
17
1
11

MONITOR
950
155
1107
200
Average Car Waiting Time
avgCarWaitingTime
17
1
11

MONITOR
950
215
1142
260
Average Pedestrian Waiting Time
avgPedestrianWaitingTime
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
true
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

cars
true
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58
Circle -16777216 true false 203 55 42
Circle -16777216 true false 202 202 44

cartrafficklight
false
0
Rectangle -16777216 true false -15 75 300 225
Circle -7500403 true true 0 90 120
Rectangle -1 true false 150 90 210 210
Line -1 false 210 90 255 120
Line -1 false 255 120 255 210
Line -1 false 210 210 255 210
Line -1 false 255 150 210 150
Circle -1 true false 129 99 42
Circle -1 true false 129 159 42

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

crosswalkhorizontal
false
15
Rectangle -1 true true 180 0 210 300
Rectangle -1 true true 45 60 45 225
Rectangle -1 true true 120 0 150 300
Rectangle -1 true true 240 0 270 300
Rectangle -1 true true 60 0 90 300
Rectangle -1 true true 0 0 30 300

crosswalkvertical
false
15
Rectangle -1 true true 0 180 300 210
Rectangle -1 true true 75 45 240 45
Rectangle -1 true true 0 120 300 150
Rectangle -1 true true 0 240 300 270
Rectangle -1 true true 0 60 300 90
Rectangle -1 true true 0 0 300 30

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

i beam
false
0
Polygon -7500403 true true 165 15 240 15 240 45 195 75 195 240 240 255 240 285 165 285
Polygon -7500403 true true 135 15 60 15 60 45 105 75 105 240 60 255 60 285 135 285

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

traffick light
false
0
Rectangle -16777216 true false 135 90 165 240
Rectangle -16777216 true false 105 90 195 120
Circle -2674135 true false 105 90 30
Circle -1184463 true false 135 90 30
Circle -13840069 true false 165 90 30

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Traffick Ligts" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>avgCarWaitingTime</metric>
    <metric>avgPedestrianWaitingTime</metric>
    <enumeratedValueSet variable="lightDuration">
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="numberOfCars" first="10" step="20" last="50"/>
    <steppedValueSet variable="numberOfPedestrians" first="25" step="25" last="75"/>
    <enumeratedValueSet variable="turnLights?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
