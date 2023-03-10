globals [season worldTemperature hungerFactor sicknessFactor  thirstFactor  coldnessFactor storageCounter idCounter humansPlaced weekLength workEnergy initialJobAmount healthThreshold killed stolen waterConsumed woodConsumed foodConsumed herbsConsumed timesRation timesWorked timesBackpack avgCouncilWater avgCouncilWood avgCouncilFood avgCouncilHerbs
  avgCouncilWaterJobs avgCouncilWoodJobs avgCouncilFoodJobs avgCouncilHerbsJobs startingMorals startingImmorals]  ;the factors will be used to manipulate the need for each resource that a human has
breed [humans human]
breed [campCouncils campCouncil]


humans-own
[
  id                                                              ;the id of the human agent
  morality                                                        ;if the human is naturally immoral or not
  age                                                             ;how old the human is and will affect energy and health
  energy                                                          ;how much stamina a human has, energy will be needed to perform any action like farming
  hunger                                                          ;the need for food a human has, and affects energy and health
  coldness                                                        ;the need for wood of a human, affects health
  thirst                                                          ;the need for water of a human, affects health
  sickness                                                        ;the physical wellbeing of the human in terms of diseases, affects need for herbs and health
  moralLevel                                                      ;how "good or bad" a human is, affects the probabilities of choosing survival actions
  health                                                          ;the overall health of the human, affects moral level value
  backpack                                                        ;the personal storage of a human for resources
  bussy?                                                          ;if the human is currently performing an action, this will help avoid the agent trying to do multiple actions at the same time and getting stuck (i hope xd)
  alive?                                                          ;if the human is alive or ded
  survivalCamp                                                    ;the survival camp the human is part of
]

;adding variables to patches in order for them to be able to act as survival camps too
patches-own
[
  subPatches                                                      ;divides each patch into subpatches for precise human placement
  camp?                                                           ;is the patch a survival camp
  workplace?                                                      ;is the patch a workplace
  campId                                                          ;identifies each camp
  storageId                                                       ;which storage belongs to the camp
]

campCouncils-own                                                  ;councils represent a mini-government that manages the camps respurces, jobs and rations of resources for humans that inhabit them
[
  id                                                              ;the id of the storage to keep track which storage belongs to which camp
  commonWater                                                     ;current amount of water in the camps common storage
  commonWood                                                      ;current amount of wood in the camps common storage
  commonFood                                                      ;current amount of food in the camps common storage
  commonHerbs                                                     ;current amount of herbs in the camps common storage
  waterRation                                                     ;max amount humans can get per day of water without stealing, dependant on common water
  woodRation                                                      ;max amount humans can get per day of wood without stealing, dependant on common wood
  foodRation                                                      ;max amount humans can get per day of food without stealing, dependant on common food
  herbsRation                                                     ;max amount humans can get per day of herbs without stealing, dependant on common herbs
  numberOfHabitants                                               ;the current number of habitants of the camp
  waterJobs                                                       ;current amount of available jobs that produce water
  woodJobs                                                        ;current amount of available jobs that produce wood
  foodJobs                                                        ;current amount of available jobs that produce food
  herbsJobs                                                       ;current amount of available jobs that produce herbs
  waterProduction                                                 ;production rate of water for any water job
  woodProduction                                                  ;production rate of wood for any wood job
  foodProduction                                                  ;production rate of food for any water job
  herbsProduction                                                 ;production rate of herbs for any herbs job
  waterRationList                                                 ;list of ids of agents that have received their weekly water ration
  woodRationList                                                  ;list of ids of agents that have received their weekly wood ration
  foodRationList                                                  ;list of ids of agents that have received their weekly food ration
  herbsRationList                                                 ;list of ids of agents that have received their weekly herbs ration
]


;-------------------------------------------------------------------------Model Setup Functions----------------------------------------------------------------------------
to setup
  clear-all
  reset-ticks
  set season "spring"
  set storageCounter 0
  set idCounter 1
  set humansPlaced 0
  set workEnergy 2
  set healthThreshold 70
  set killed 0
  set stolen 0
  set waterConsumed 0
  set woodConsumed 0
  set foodConsumed 0
  set herbsConsumed 0
  set timesBackpack 0
  set timesWorked 0
  set timesRation 0
  set avgCouncilWater 0
  set avgCouncilWood 0
  set avgCouncilFood 0
  set avgCouncilHerbs 0
  set avgCouncilWaterJobs 0
  set avgCouncilWoodJobs 0
  set avgCouncilFoodJobs 0
  set avgCouncilHerbsJobs 0
  set initialJobAmount (population / 4) / 4
  set weekLength (seasonduration / 3) / 4
  setupWorld
  setupHumans
  setupCouncils
  set startingMorals (count humans with [morality = "moral"])
  set startingImmorals (count humans with [morality = "immoral"])
end

to setupWorld
  ask patches                                                                       ;setup areas outside of camps
  [
    set pcolor 52
    set camp? false
    set workplace? false
    set subPatches [nobody nobody nobody nobody]
  ]


  ask patches with [pxcor < -10 and pxcor > -40 and pycor < 40 and pycor > 10]     ;set up survival camp 1
  [
    set pcolor 69
    set camp? true
    set campId 1
    set storageId 1
  ]

  ask patches with [pxcor < 40 and pxcor > 10 and pycor < 40 and pycor > 10]     ;set up survival camp 2
  [
    set pcolor 69
    set camp? true
    set campId 2
    set storageId 2
  ]

  ask patches with [pxcor < -10 and pxcor > -40 and pycor < -10 and pycor > -40]    ;set up survival camp 3
  [
    set pcolor 69
    set camp? true
    set campId 3
    set storageId 3
  ]


  ask patches with [pxcor < 40 and pxcor > 10 and pycor < -10 and pycor > -40]    ;set up survival camp 4
  [
    set pcolor 69
    set camp? true
    set campId 4
    set storageId 4
  ]

  ask patches with [pxcor < -10 and pxcor > -40 and pycor < 40 and pycor > 35]     ;set up workplace 1
  [
    set pcolor gray
    set workplace? true
  ]

  ask patches with [pxcor < 40 and pxcor > 10 and pycor < 40 and pycor > 35]     ;set up workplace 2
  [
    set pcolor gray
    set workplace? true
  ]

  ask patches with [pxcor < -10 and pxcor > -40 and pycor < -35 and pycor > -40]    ;set up workplace 3
  [
    set pcolor gray
    set workplace? true
  ]


  ask patches with [pxcor < 40 and pxcor > 10 and pycor < -35 and pycor > -40]    ;set up workplace 4
  [
    set pcolor gray
    set workplace? true
  ]
end


to setupHumans
  let randomN random 101
  let maxImmorals (population * (percOfImmoral / 100))

  create-humans population
  [
    let immorals count turtles with [breed = humans] with [morality = "immoral"]
    ifelse immorals < maxImmorals
    [
      let randomI random 2
      ifelse randomI = 0
      [
        set morality "immoral"
      ]
      [
        set morality "moral"
      ]
    ]
    [
      set morality "moral"
    ]
    set shape "person"
    set alive? true
    set bussy? false
    set id idCounter
    set age getAge
    set energy 10
    set hunger 0
    set thirst 0
    set coldness 0
    set sickness 0
    ifelse morality = "immoral"
    [
      set moralLevel 10 + (random (51 - 10))
      set color red
    ]
    [
      set moralLevel 70 + (random (101 - 70))
      set color green
    ]
    set health 80 + energy - hunger  - coldness - thirst - sickness
    set backpack (list 0 0 0 0 0)
    findSurvivalCamp
    set idCounter idCounter + 1
  ]

end

to setupCouncils
  create-campCouncils 4
  [
    let idList (list 1 2 3 4)
    let xcorList (list -25 25 -25 25 )
    let ycorList (list 25 25 -25 -25)
    let waterList (list 7 7 10 7)
    let woodList (list 10 7 7 7)
    let herbsList (list 7 7 7 10)
    let foodList (list 7 10 7 7)
    set shape "square"
    set color gray
    set size 5
    set waterProduction item storageCounter waterList
    set woodProduction item storageCounter woodList
    set herbsProduction item storageCounter herbsList
    set foodProduction item storageCounter foodList
    set id item storageCounter idList
    set xcor item storageCounter xcorList
    set ycor item storageCounter ycorList
    set numberOfHabitants population / 4
    set commonWater 0
    set commonWood 0
    set commonFood 0
    set commonHerbs 0
    set waterJobs numberOfHabitants
    set woodJobs numberOfHabitants
    set foodJobs numberOfHabitants
    set herbsJobs numberOfHabitants
    set waterRationList (list )
    set woodRationList (list )
    set herbsRationList (list )
    set foodRationList (list )
    set storageCounter storageCounter + 1
  ]
end

to go
  seasonManagement
  basicHumanAttributeManagement
  humanBehaviourManagement
  councilManagement
  let totalPopulation count humans
  if totalPopulation < 45
  [stop]
  tick
end

;----------------------------------------------------------------------------------------------Management Systems----------------------------------------------------------------------------

to seasonManagement
  let seasonflow (list "spring" "summer" "fall" "winter")
  if ticks mod seasonDuration = 0
  [
    (ifelse season = "spring"
      [
        set season "summer"
        set thirstFactor 2
        set sicknessFactor 1
        set coldnessFactor 1
        set hungerFactor 1
      ]
      season = "summer"
      [
        set season "fall"
        set thirstFactor 1
        set sicknessFactor 2
        set coldnessFactor 1
        set hungerFactor 1
      ]
      season = "fall"
      [
        set season "winter"
        set thirstFactor 1
        set sicknessFactor 1
        set coldnessFactor 2
        set hungerFactor 1
      ]
      season = "winter"
      [
        set season "spring"
        set thirstFactor 1
        set sicknessFactor 1
        set coldnessFactor 1
        set hungerFactor 2
      ]
    )
  ]
end

to councilManagement
  ;every week the camp has new jobs and clears the list of humans that received their rations
  if ticks mod weekLength = 0
  [
    ask campCouncils
    [
      let inhabitants count humans with [survivalCamp = [id] of myself]
      set waterJobs initialJobAmount
      set woodJobs initialJobAmount
      set foodJobs initialJobAmount
      set herbsJobs initialJobAmount
      set waterRationList (list )
      set woodRationList (list )
      set herbsRationList (list )
      set foodRationList (list )
      set waterProduction 150 / inhabitants
      set woodProduction 150 / inhabitants
      set herbsProduction 150 / inhabitants
      set foodProduction 150 / inhabitants
    ]
  ]

  ;manage rations depending on current common resource and amount of people on the camp
  ask campCouncils
  [
    let inhabitants count humans with [survivalCamp = [id] of myself]
    (ifelse inhabitants > 0
      [
        set waterRation (commonWater / inhabitants) / 4
        set woodRation (commonWood / inhabitants) / 4
        set foodRation (commonFood / inhabitants) / 4
        set herbsRation (commonHerbs / inhabitants) / 4
      ]
      inhabitants <= 0
      [
        set waterRation 0
        set woodRation 0
        set foodRation 0
        set herbsRation 0
      ]
    )
  ]
end



to humanBehaviourManagement
  ask humans
  [
    let humanId id
    let myWater item 0 backpack
    let myWood item 1 backpack
    let myFood item 2 backpack
    let myHerbs item 3 backpack
    let waterRationTaken? false
    let woodRationTaken? false
    let foodRationTaken? false
    let herbsRationTaken? false
    let councilWaterJobs 0
    let councilWoodJobs 0
    let councilFoodJobs 0
    let councilHerbsJobs 0

    let council campCouncils with [id = [survivalCamp] of myself]
    ask council                                                                                                ;check which lists the human is part of
    [
      set councilWaterJobs waterJobs
      set councilWoodJobs woodJobs
      set councilFoodJobs foodJobs
      set councilHerbsJobs herbsJobs
      if member? humanId waterRationList
      [
        set waterRationTaken? true
      ]
      if member? humanId woodRationList
      [
        set woodRationTaken? true
      ]
      if member? humanId foodRationList
      [
        set foodRationTaken? true
      ]
      if member? humanId herbsRationList
      [
        set herbsRationTaken? true
      ]
    ]


    ifelse health < healthThreshold                                                                               ;if health level is below the threshold try to satisfy yout most urgent need
    [
      ifelse thirst > coldness and thirst > hunger and thirst > sickness and thirst > 2
      [
        ifelse energy > workEnergy and councilWaterJobs > 0
        [
          workForResource 0
        ]
        [
          ifelse waterRationTaken? = false
          [
            getResourceRation 0
          ]
          [
            ifelse myWater > 0
            [
              getResourceBackpack 0
            ]
            [
              let caughtProbability caughtChance
              let actionProbability random-float 101
              let actionScore (moralLevel * 0.8) + (health * 0.2) + caughtProbability
              let difference actionProbability - actionScore
              ifelse actionScore < actionProbability
              [
                ifelse difference < 30
                [
                  getResourceRation 0
                  set stolen stolen + 1
                ]
                [
                  killForResources
                ]
              ]
              [
                askHelp 0
              ]
            ]
          ]
        ]
      ]

      [
        ifelse coldness > thirst and coldness > hunger and coldness > sickness and coldness > 2
        [
          ifelse energy > workEnergy and councilWoodJobs > 0
          [
            workForResource 1
          ]
          [
            ifelse woodRationTaken? = false
            [
              getResourceRation 1
            ]
            [
              ifelse myWood > 0
              [
                getResourceBackpack 1
              ]
              [
                let caughtProbability caughtChance
                let actionProbability random-float 100
                let actionScore (moralLevel * 0.8) + (health * 0.2) + caughtProbability
                let difference actionProbability - actionScore
                ifelse actionScore < actionProbability
                [
                  ifelse difference < 30
                  [
                    getResourceRation 1
                    set stolen stolen + 1
                  ]
                  [
                    killForResources
                  ]
                ]
                [
                  askHelp 1
                ]
              ]
            ]
          ]
        ]
        [
          ifelse hunger > thirst and hunger > coldness and hunger > sickness and hunger > 2
          [
            ifelse energy > workEnergy and councilFoodJobs > 0
            [
              workForResource 2
            ]
            [
              ifelse foodRationTaken? = false
              [
                getResourceRation 2
              ]
              [
                ifelse myFood > 0
                [
                  getResourceBackpack 2
                ]
                [
                  let caughtProbability caughtChance
                  let actionProbability random-float 100
                  let actionScore (moralLevel * 0.8) + (health * 0.2) + caughtProbability
                  let difference actionProbability - actionScore
                  ifelse actionScore < actionProbability
                  [
                    ifelse difference < 30
                    [
                      getResourceRation 2
                      set stolen stolen + 1
                    ]
                    [
                      killForResources
                    ]
                  ]
                  [
                    askHelp 2
                  ]
                ]
              ]
            ]
          ]
          [
            if sickness > thirst and sickness > coldness and sickness > hunger and sickness > 2
            [
              ifelse energy > workEnergy and councilHerbsJobs > 0
              [
                workForResource 3
              ]
              [
                ifelse herbsRationTaken? = false
                [
                  getResourceRation 3
                ]
                [
                  ifelse myherbs > 0
                  [
                    getResourceBackpack 3
                  ]
                  [
                    let caughtProbability caughtChance
                    let actionProbability random-float 100
                    let actionScore (moralLevel * 0.8) + (health * 0.2) + caughtProbability
                    let difference actionProbability - actionScore
                    ifelse actionScore < actionProbability
                    [
                      ifelse difference < 30
                      [
                        getResourceRation 3
                        set stolen stolen + 1
                      ]
                      [
                        killForResources
                      ]
                    ]
                    [
                      askHelp 3
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
    ;if satiesfied then walk around peacefully
    [
      idleWalk
    ]
  ]
end

to basicHumanAttributeManagement
  if ticks mod weekLength = 0
  [
    ask humans
    [
      if energy > 0
      [
        set energy energy - 0.5
      ]
      if hunger < 10
      [
        set hunger hunger + (random-float 1 * hungerFactor)
      ]
      if thirst < 10
      [
        set thirst thirst + ( random-float 1 * thirstFactor)
      ]
      if coldness < 10
      [
        set coldness coldness + (random-float 1 * coldnessFactor)
      ]
      if sickness < 10
      [
        set sickness sickness + (random-float 1 * sicknessFactor)
      ]

      set health 90 + energy - hunger - coldness - thirst - sickness


      if health < healthThreshold                                                   ;if the humans health is lower than the healthy treshold, the moral level starts lowering
      [
        set moralLevel moralLevel - (1 - (health * 0.01))              ;how much the moral level lowers depends on the helth of the human
      ]
      if health < 30
      [
        die
      ]
    ]
  ]
end

;---------------------------------------------------------------------------------------------Human Actions--------------------------------------------------------------------------------

to workForResource[resource]                                                                                     ;implements the ability of humans to work for resources
  set bussy? true
  let council one-of campCouncils with [id = [survivalCamp] of myself]
  let workplaceArea patches with [campId = [survivalCamp] of myself and workplace? = true]
  let randomStation one-of workplaceArea
  face randomStation
  let toReceive 0
  let atWorkPlace? false
  let counter 0
  let water item 0 backpack
  let wood item 1 backpack
  let food item 2 backpack
  let herbs item 3 backpack

  while [counter < 5 and [workPlace? = false] of patch-here]
  [
    let newX precision (xcor + sin heading * 0.5) 2
    let newY precision (ycor + cos heading * 0.5) 2
    if not [workPlace?] of patch-ahead 5
    [
      set xcor newX
      set ycor newY
    ]
    set counter counter + 1
  ]
  ask council
  [
    (ifelse resource = 0
      [
        set commonWater commonWater + waterProduction * 0.99
        set toReceive waterProduction * 0.01
        set waterJobs waterJobs - 1
        set water water + toReceive
      ]
      resource = 1
      [
        set commonWood commonWood + woodProduction * 0.99
        set toReceive woodProduction * 0.01
        set woodJobs woodJobs - 1
        set wood wood + toReceive
      ]
      resource = 2
      [
        set commonFood commonFood + foodProduction * 0.99
        set toReceive foodProduction * 0.01
        set foodJobs foodJobs - 1
        set food food + toReceive
      ]
      resource = 3
      [
        set commonHerbs commonHerbs + herbsProduction * 0.99
        set toReceive herbsProduction * 0.01
        set herbsJobs herbsJobs - 1
        set herbs herbs + toReceive
    ])
  ]
  let res item resource backpack
  set backpack (list water wood food herbs)
  ;set backpack replace-item resource backpack (res + toReceive)
  set energy energy - 0.5
  set bussy? false
  set timesWorked timesWorked + 1
end


to getResourceRation[resource]                                                     ;implements the ability of humans to get resources from councils resource storage
  set bussy? true
  let council one-of campCouncils with [id = [survivalCamp] of myself]
  face council
  let ration 0
  let atCouncil? false
  let myId id

  while [atCouncil? = false]
  [
    let newX precision (xcor + sin heading * 0.5) 2
    let newY precision (ycor + cos heading * 0.5) 2
    (ifelse not any? campCouncils-on patch-ahead 5
      [
        set xcor newX
        set ycor newY
      ]
      any? campCouncils-on patch-ahead 5
      [
        set atCouncil? true
      ]
    )
  ]
  ask council
  [
    (ifelse resource = 0
      [
        set ration waterRation
        set commonWater commonWater - ration
        set waterRationList lput myId waterRationList
      ]
      resource = 1
      [
        set ration woodRation
        set commonWood commonWood - ration
        set woodRationList lput myId woodRationList
      ]
      resource = 2
      [
        set ration foodRation
        set commonFood commonFood - ration
        set foodRationList lput myId foodRationList
      ]
      resource = 3
      [
        set ration herbsRation
        set commonHerbs commonHerbs - ration
        set herbsRationList lput myId herbsRationList
    ])

  ]
  let res item resource backpack
  set backpack replace-item resource backpack (res + ration)

  set bussy? false
  set timesRation timesRation + 1
end

to getResourceBackpack[resource]                                                     ;implements the ability of humans to get resources backpack
  set bussy? true
  let water item 0 backpack
  let wood item 1 backpack
  let food item 2 backpack
  let herbs item 3 backpack
  if resource = 0
  [
    set thirst thirst - water
    set water 0
    set waterConsumed waterConsumed + 1
  ]
  if resource = 1
  [
    set coldness coldness - wood
    set wood 0
    set woodConsumed woodConsumed + 1
  ]
  if resource = 2
  [
    set hunger hunger - food
    set energy energy + food
    set food 0
    set foodConsumed foodConsumed + 1
  ]
  if resource = 3
  [
    set sickness sickness - herbs
    set herbs 0
    set herbsConsumed herbsConsumed + 1
  ]
  set backpack (list water wood food herbs)
  set bussy? false
  set timesBackpack timesBackpack + 1
end


to askHelp[resIndex]                                                          ;as another form of cooperation agents cna ultimatly ask for help from the camp mates
  set bussy? true
  let campMates other humans with [survivalCamp = [survivalCamp] of myself]
  let success? false
  let toShare 0

  ask campMates
  [
    let chance random 101
    let resource item resIndex backpack
    let healthAdd ((health / 2) - 20)
    let moralAdd (moralLevel / 2)
    let resourceAdd (resource * 20)
    let probSharing (healthAdd + moralAdd + resourceAdd)

    if probSharing > chance and success? = false
    [
      set backpack replace-item resIndex backpack (resource / 2)
      set toShare (resource / 2)
      set success? true
    ]
  ]
  if success? = true
  [
    let resource item resIndex backpack
    set backpack replace-item resIndex backpack (resource + toShare)
  ]
  set bussy? false
end

to killForResources                                                                        ;as another form of competition agents can kill another agent for the resources in their backpack

  set bussy? true
  let closeMates other humans with [survivalCamp = [survivalCamp] of myself] in-radius 5
  let myWater item 0 backpack
  let myWood item 1 backpack
  let myFood item 2 backpack
  let myHerbs item 3 backpack
  let water 0
  let wood 0
  let food 0
  let herbs 0

  if any? closeMates
  [
    let target min-one-of closeMates [distance myself]
    ask target
    [
      set water item 0 backpack
      set wood item 1 backpack
      set food item 2 backpack
      set herbs item 3 backpack
      set killed killed + 1
      die
    ]
  ]
  set backpack replace-item 0 backpack (myWater + water)
  set backpack replace-item 1 backpack (myWood + wood)
  set backpack replace-item 2 backpack (myFood + food)
  set backpack replace-item 3 backpack (myHerbs + herbs)
  set bussy? false
end

to idleWalk
  if not bussy?
  [
    ifelse not [camp?] of patch-ahead 1
    [
      rt 180
    ]
    [
      forward 1
    ]
  ]
end


;--------------------------------------------------------------------------------------Reporters and Helper Functions--------------------------------------------------------------------------------


to getPunished[crime]                                                                        ;agens can get punsihed for their crimes if they get caught, punishment depends on the crime
  let council campCouncils with [id = [survivalCamp] of myself]
  let myWater item 0 backpack
  let myWood item 1 backpack
  let myFood item 2 backpack
  let myHerbs item 3 backpack

  (ifelse crime = "stealing"                                                               ;if they are caught stealing, they loose all their resources
    [
      ask council
      [
        set commonWater commonWater + myWater
        set commonWood commonWood + myWood
        set commonFood commonFood + myFood
        set commonHerbs commonHerbs + myHerbs
      ]
      set backpack replace-item 0 backpack 0
      set backpack replace-item 1 backpack 0
      set backpack replace-item 2 backpack 0
      set backpack replace-item 3 backpack 0
    ]
    crime = "kiling"                                                                         ;if they are caught killing, they are executed and their resources go to the council
    [
      ask council
      [
        set commonWater commonWater + myWater
        set commonWood commonWood + myWood
        set commonFood commonFood + myFood
        set commonHerbs commonHerbs + myHerbs
      ]
      die
    ]
  )

end


to-report getAge                                                   ;reports age from real life age distribution
  let n random 101
  let under20 33
  let under40 65
  let under60 78
  let under80 100
  let ageI 0


  (ifelse n < under20
    [
      set ageI random 20
    ]
    under40 > n and n > under20
    [
      set ageI 20 + (random (39 - 20))
    ]
    under60 > n  and n > under40
    [
      set ageI 40 + (random (59 - 40))
    ]
    under80 > n and n > under60
    [
      set ageI 60 + (random (79 - 60))
  ])
  report ageI
end


to-report caughtChance                                               ;adds a negative influence on immoral decisions by getting caught depending on the humans around the agent
  let witnesses other humans in-radius 5
  let prob 0
  ask witnesses
  [
    ifelse prob < 25                                                 ;keep stacking the probability to a max of 25
    [
      set prob prob + 5
    ]
    [
      set prob prob
    ]
  ]
  report prob
end



to-report avgHealth
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + health
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end


to-report avgEnergy
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + energy
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end


to-report avgHunger
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + hunger
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgColdness
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + coldness
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end


to-report avgSickness
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + sickness
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end


to-report avgThirst
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + thirst
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgWater
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + item 0 backpack
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgFood
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + item 2 backpack
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgWood
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + item 1 backpack
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgHerbs
  let healthSum 0
  let humansAlive 0
  ask humans
  [
    set healthSum healthSum + item 3 backpack
    set humansAlive humansAlive + 1
  ]
  report healthSum / humansAlive
end

to-report avgCouncilWaterReporter
  let waterSum 0
  let councils count campCouncils
  ask campCouncils
  [
    set waterSum waterSum + commonWater
  ]
  report waterSum / councils
end

to-report avgCouncilWaterJobsReporter
  let jobSum 0
  let councils count campCouncils
  ask campCouncils
  [
    set jobSum jobSum + waterJobs
  ]
  report jobSum / councils
end

to-report moralsurvivalRate
  let morals count humans with [morality = "moral"]
  report (morals / startingMorals ) * 100
end

to-report immoralSurvivalRate
  let morals count humans with [morality = "immoral"]
  report (morals / startingImmorals ) * 100
end

to-report seasonReporter
  report season
end

to-report humansKilled
  report killed
end

to-report timesStolen
  report stolen
end

to-report timesWaterConsumed
  report waterConsumed
end

to-report timesWoodConsumed
  report woodConsumed
end

to-report timesFoodConsumed
  report foodConsumed
end

to-report timesHerbsConsumed
  report herbsConsumed
end

to-report totalTimesWorked
  report timesWorked
end

to-report totalTimesBackpack
  report timesBackpack
end

to-report totalTimesRation
  report timesRation
end



to findSurvivalCamp   ;code mostly taken from assignment 2
  let maxCapacity (population / 4)                                      ;we keep the population of each camp equal to avoid unnecesary randomness in the experiment
  (ifelse humansPlaced < maxCapacity                                    ;populate camp 1
    [
      let success false
      while [success = false]
      [
        let place one-of patches with [camp? = true and count turtles-here < 4 and campId = 1]
        let subPlace random 4
        if [item subPlace subPatches] of place = nobody
        [
          ask place                    ;adds agent to one of the subpatches of a patch
          [                            ;note that myself here refers to the agent that askes the patch to do something
            set subPatches replace-item subPlace subPatches myself
          ]
          set survivalCamp [campId] of place
          set xcor [pxcor] of place - 0.25 + 0.5 * (subplace mod 2)
          ifelse subPlace < 2
          [ set ycor [pycor] of place + 0.25]
          [ set ycor [pycor] of place - 0.25]
          set success true
          set humansPlaced humansPlaced + 1
        ]
      ]
    ]

    humansPlaced >= maxCapacity and humansPlaced < (maxCapacity * 2)   ;populate camp 2
    [
      let success false
      while [success = false]
      [
        let place one-of patches with [camp? = true and count turtles-here < 4 and campId = 2]
        let subPlace random 4
        if [item subPlace subPatches] of place = nobody
        [
          ask place                    ;adds agent to one of the subpatches of a patch
          [                            ;note that myself here refers to the agent that askes the patch to do something
            set subPatches replace-item subPlace subPatches myself
          ]
          set survivalCamp [campId] of place
          set xcor [pxcor] of place - 0.25 + 0.5 * (subplace mod 2)
          ifelse subPlace < 2
          [ set ycor [pycor] of place + 0.25]
          [ set ycor [pycor] of place - 0.25]
          set success true
          set humansPlaced humansPlaced + 1
        ]
      ]
    ]

    humansPlaced >= (maxCapacity * 2) and humansPlaced < (maxCapacity * 3)   ;populate camp 2
    [
      let success false
      while [success = false]
      [
        let place one-of patches with [camp? = true and count turtles-here < 4 and campId = 3]
        let subPlace random 4
        if [item subPlace subPatches] of place = nobody
        [
          ask place                    ;adds agent to one of the subpatches of a patch
          [                            ;note that myself here refers to the agent that askes the patch to do something
            set subPatches replace-item subPlace subPatches myself
          ]
          set survivalCamp [campId] of place
          set xcor [pxcor] of place - 0.25 + 0.5 * (subplace mod 2)
          ifelse subPlace < 2
          [ set ycor [pycor] of place + 0.25]
          [ set ycor [pycor] of place - 0.25]
          set success true
          set humansPlaced humansPlaced + 1
        ]
      ]
    ]

    humansPlaced >= (maxCapacity * 3) and humansPlaced < population       ;populate camp 2
    [
      let success false
      while [success = false]
      [
        let place one-of patches with [camp? = true and count turtles-here < 4 and campId = 4]
        let subPlace random 4
        if [item subPlace subPatches] of place = nobody
        [
          ask place                    ;adds agent to one of the subpatches of a patch
          [                            ;note that myself here refers to the agent that askes the patch to do something
            set subPatches replace-item subPlace subPatches myself
          ]
          set survivalCamp [campId] of place
          set xcor [pxcor] of place - 0.25 + 0.5 * (subplace mod 2)
          ifelse subPlace < 2
          [ set ycor [pycor] of place + 0.25]
          [ set ycor [pycor] of place - 0.25]
          set success true
          set humansPlaced humansPlaced + 1
        ]
      ]
    ]
  )
end
@#$#@#$#@
GRAPHICS-WINDOW
207
10
720
524
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
39
151
103
184
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

SLIDER
19
22
191
55
percOfImmoral
percOfImmoral
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
19
68
191
101
population
population
1
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
111
151
174
184
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
20
110
192
143
seasonDuration
seasonDuration
10
1200
120.0
10
1
NIL
HORIZONTAL

MONITOR
734
13
791
58
Season
seasonReporter
17
1
11

MONITOR
806
12
934
57
Population Camp 1
count turtles with [breed = humans] with [survivalCamp = 1]
17
1
11

MONITOR
806
68
932
113
Population Camp 2
count turtles with [breed = humans] with [survivalCamp = 2]
17
1
11

MONITOR
806
118
932
163
Population Camp 3
count turtles with [breed = humans] with [survivalCamp = 3]
17
1
11

MONITOR
806
170
933
215
Population Camp 4
count turtles with [breed = humans] with [survivalCamp = 4]
17
1
11

MONITOR
960
12
1060
57
Average Health
avgHealth
2
1
11

MONITOR
960
67
1063
112
Average Energy
avgEnergy
1
1
11

MONITOR
962
119
1065
164
Average Thirst
avgThirst
2
1
11

MONITOR
963
170
1067
215
Average Hunger
avgHunger
2
1
11

MONITOR
1077
11
1190
56
Average Coldness
avgColdness
2
1
11

MONITOR
1079
69
1189
114
Average Sickness
avgSickness
2
1
11

MONITOR
735
70
792
115
Killed
humansKilled
1
1
11

MONITOR
737
127
794
172
Stolen
timesStolen
1
1
11

MONITOR
738
279
836
324
Average Water
avgWater
1
1
11

MONITOR
739
332
837
377
Average Food
avgFood
2
1
11

MONITOR
740
387
836
432
Average Wood
avgWood
1
1
11

MONITOR
741
442
837
487
Average Hebrs
avgHerbs
11
1
11

MONITOR
861
280
1004
325
Times Water Consumed
timesWaterConsumed
1
1
11

MONITOR
864
337
1005
382
Times Wood Consumed
timesWoodConsumed
17
1
11

MONITOR
863
391
999
436
Times Food Consumed
timesFoodConsumed
1
1
11

MONITOR
864
448
999
493
Times Herb Consumed
timesHerbsConsumed
1
1
11

MONITOR
1033
284
1181
329
Times Backpack Accesed
totalTimesBackpack
1
1
11

MONITOR
1035
342
1177
387
Times a Human Worked
totalTimesWorked
17
1
11

MONITOR
1036
398
1178
443
Times Ration Served
totalTimesRation
1
1
11

TEXTBOX
1028
260
1178
278
NIL
11
0.0
1

MONITOR
1224
287
1340
332
Avg Council Water
avgCouncilWaterReporter
2
1
11

MONITOR
1353
290
1501
335
Avg Council Water Jobs 
avgCouncilWaterJobs
1
1
11

MONITOR
1203
10
1285
55
Immoral Left
count humans with [morality = \"immoral\"]
17
1
11

MONITOR
1208
65
1285
110
Normal Left
count humans with [morality = \"moral\"]
17
1
11

MONITOR
1294
66
1414
111
Moral Survival Rate
moralsurvivalRate
1
1
11

MONITOR
1293
10
1420
55
ImmoralSurvivalRate
immoralsurvivalRate
1
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
