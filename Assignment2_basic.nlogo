breed [ infrastructures infrastructure  ]      ; Define two types of agents: infrastructure and aircraft agents
breed [ aircrafts aircraft ]

undirected-link-breed [local-roads local-road] ; Define two tyes of links: undirected (bidirectional) local roads
directed-link-breed [highways highway]         ; and directed (unidirectional) highways


patches-own[
  patch-type                                   ; Patches can be "road" (white), "gate" (red) or "runway" (blue)
]

aircrafts-own [
  goal                                         ; The goal of an aircraft is the next infrastructure agent that he is sent to
  infrastructure-mate                          ; The closest infrastructure agent to the aircraft
  other-aircraft                               ; All other aircraft that aircraft A detects within a certain radius
  nearest-aircraft                             ; The aircraft to which the distance from aircraft A is the smallest, used for collision check
  other-aircraft-1                             ; Other aircraft that is close to aircraft A and should therefore be checked for potential collision
  other-aircraft-2                             ; Other aircraft that is close to aircraft A and should therefore be checked for potential collision
  other-aircraft-3                             ; Other aircraft that is close to aircraft A and should therefore be checked for potential collision
  collision?                                   ; Reports true if there is a collision
  patch-x                                      ; Xcor of the patch that aircraft is currently on
  patch-y                                      ; Ycor of the patch that aircraft is currently on
  following-patch-x                            ; Xcor of the patch that aircraft is on when it makes one step forward with the same heading
  following-patch-y                            ; Ycor of the patch that aircraft is on when it makes one step forward with the same heading
  free                                         ; If this value reports false, the aircraft should not move in order to prevent collision
  on-infra                                     ; Reports if aircraft is on same patch as an infrastructure agent or not
  travel-time                                  ; Describes how long an aircraft is on the road
  waiting-time                                 ; Amount of time that aircraft has waited in total when travelling from gate to runway
  last-infra                                   ; Last infrastructure agent that aircraft has passed
  bid                                          ; The quantatity bid by an aircraft in an auction
  total-bid                                    ; The total quantity of the bids performed in auctions
  budget                                       ; The remaining budget to be used by an aircraft to bid, in order to potentially be granted priority
  travel-distance                              ; Total distance travelled by an aircraft
  hub                                          ; Defines whether the aircraft has a hub at the airport or not

]

infrastructures-own [
  path                                         ; Instructed path from the current infrastructure agent to the goal infrastructure agent with the lowest weight at that moment
  patch-x                                      ; Xcor of the patch that infrastructure agent is on
  patch-y                                      ; Ycor of the patch that infrastructure agent is on
  interarrival-time                            ; Time between two aircraft arriving at runway
  activated                                    ; Makes sure interarrival-time starts counting from first arriving aircraft at runway
  empty                                        ; If this value reports false, the infrastructure is currently occupied by an aircraft
  neighbor-north                               ; The neighboring infrastructure directly to the north of infrastructure A (assuming map pointing north)
  neighbor-east                                ; The neighboring infrastructure directly to the east of infrastructure A (assuming map pointing north)
  neighbor-south                               ; The neighboring infrastructure directly to the south of infrastructure A (assuming map pointing north)
  neighbor-west                                ; The neighboring infrastructure directly to the west of infrastructure A (assuming map pointing north)
  neighbor-cardinal                            ; Neighboring infrastructure in a given cardinal direction from infrastructure A
  aircrafts-cardinal                           ; Agenset of aircraft present on the adjacent link in a cardinal direction from infrastructure A
  key-waypoint                                 ; If this value reports true, the infrastructure is asked to change the weight of its adjacent links for the local observation-based planning
  nearby-aircraft                              ; Used for coordination by negotiation auctions, defines closeby aircraft
]

globals [
  counter-collisions                           ; Counts the total amount of collisions
  random-generator-1                           ; Generates random tick at which new aircraft is generated at gate 1 (most left)
  random-generator-2                           ; Generates random tick at which new aircraft is generated at gate 2 (center)
  random-generator-3                           ; Generates random tick at which new aircraft is generated at gate 3 (most right)
  integer-1                                    ; Reports "true" if new aircraft must be generated at gate 1
  integer-2                                    ; Reports "true" if new aircraft must be generated at gate 2
  integer-3                                    ; Reports "true" if new aircraft must be generated at gate 3
  arrived-left                                 ; Amount of aircraft arrived at left runway
  arrived-right                                ; Amount of aircraft arrived at right runway
  ac-generated
  interarrival-time-list                       ; List of all interarrival-times
  travel-time-list                             ; List of all travel times of aircraft
  travel-time-prio-list                        ; List of all travel times of aircraft with priority
  travel-time-nonprio-list                     ; List of all travel times of aircraft without priority
  waiting-time-list                            ; List of all waiting times of aircraft
  link-list                                    ; List of list with all links and the number of aircraft on them
  ticks-generator-left                         ; Number of ticks between the generation of aircraft at the left gate
  ticks-generator-centre                       ; Number of ticks between the generation of aircraft at the central gate
  ticks-generator-right                        ; Number of ticks between the generation of aircraft at the right gate
  used-capacity-list                           ; List of all 'used capacity' values
  aircraft-waiting-list                        ; List of all 'share of aircraft waiting' at every tick
  travel-distance-list                         ; List of all travel distance to runway
  occupied-links-list                          ; List of all 'share of occupied links' at every tick
  occupied-links-count                         ; Value for share of occupied links at a given tick
  travel-distance-to-runway                    ; Value for travel distance to runway at a given tick
  travel-time-to-runway                        ; Value for travel distance to runway at a given tick
  reds                                         ; Amount of waiting (aka red) aircraft
  traffic-left-approach                        ; Amount of traffic present on taxiway links leading to left runway
  traffic-right-approach                       ; Amount of traffic present on taxiway links leading to right runway
  total-bid-list                               ; List of total-bid (budget) done by aircraft during coordination by negotiation
]


links-own [
  weight                                       ; Each link is assigned its own weight
  ]

extensions [
  nw                                           ; Network extension, used for determining the shortest weighted path
  ]

;--------------------------------------------------------------------------------------
; SETUP: having determined all agents and their local variables, global vairables, link variables

to setup
  clear-all

  ask-input-for-analysis                                                                ; If using the automatic demand mode selector, change demand conditions
  ask patches [ set pcolor green + 1 ]                                                  ; Make all patches green, except:
  setup-roads                                                                           ; patches with special patch-types: roads, gates, and runways
  infrastructure-placing                                                                ; Place infrastructure agents on every intersection
  creating-links                                                                        ; Create links between infrastructre agents
  ask infrastructures [find-neigboring-infrastructure]                                  ; Helper procedure: make each infrastructure agent find its neighboring infrastructure agents
  set-default-shape aircrafts "airplane"
  set-default-shape infrastructures "circle"
  set interarrival-time-list []                                                         ; Initialize interarrival-time-list
  set travel-time-list []                                                               ; Initialize travel-time-list
  set travel-time-nonprio-list []                                                       ; Initialize travel-time-nonprio-list
  set travel-time-prio-list []                                                          ; Initialize travel-time-prio-list
  set waiting-time-list []                                                              ; Initialize waiting-time-list
  set aircraft-waiting-list []                                                          ; Initialize aircraft-waiting-list
  set occupied-links-list []                                                            ; Initialize occupied-links-list
  set link-list []                                                                      ; Initialize link-list
  set travel-distance-list []                                                           ; Initialize travel-distance-list
  set used-capacity-list []                                                             ; Initialize used-capacity-list
  ask infrastructures [find-patches]                                                    ; Helper procedure that finds Xcor and Ycor of infrastructures
  ask infrastructures with [patch-type = "waypoint"] [determine-if-key]                 ; Helper procedure that determines if the waypoint infrastructure shoudl update its weights for the local observation-based planning                                                               ; Helper procedure that determines in how many ticks one new aircraft is generated
  reset-ticks
end

;-------------------------------------------------------------------------------------
; ALL SETUP COMMANDS: setup-roads, infrastructure-placing and creating-links

; SETUP-ROADS: Make roads, gates, and runways (left and right)

to setup-roads

  ; graphics for the runway asphalt
  let runway patches with [
    ((pxcor <= 10) and (pxcor >= -10) and (pycor >= 8))
  ]
  ask runway [
    set pcolor black
    set patch-type "runway"
     ]

  ; graphics for the runway white lines
  let lines patches with [
    ((pxcor >= -9) and (pxcor mod 2 = 0) and (pxcor <= 9) and (pycor >= 9) and (pycor <= 13)) or
    ((pxcor <= 1) and (pxcor >= -1) and (pycor = 15)) or
    ((pxcor = -1) and (pycor = 16))
  ]
  ask lines [
    set pcolor white
    set patch-type "lines"
     ]

  ; graphics for the airport
  let airport patches with [
    ((pxcor <= 10) and (pxcor >= -10) and (pycor <= -14)) or
    ((pxcor = -5) and  (pycor <= -12)) or
    ((pxcor = 0) and  (pycor <= -12)) or
    ((pxcor = 5) and  (pycor <= -12))
  ]
  ask airport [
    set pcolor 8
    set patch-type "airport"
     ]

  let roads patches with [
    ((pxcor <= 15) and (pxcor >= -15) and (pycor = 0)) or
    ((pxcor <= 15) and (pxcor >= -15) and (pycor = -5)) or
    ((pxcor <= 15) and (pxcor >= -15) and (pycor = 5)) or
    (((pxcor mod 5 = 0) or (pxcor = 0)) and (pycor >= -5) and (pycor <= 5)) or
    (((pxcor = -15) or (pxcor = 15)) and (pycor >= 0) and (pycor <= 10)) or
    (((pxcor = -5) or (pxcor = 0) or (pxcor = 5)) and (pycor >= -10) and (pycor <= -5))
  ]
  ask roads [
    set pcolor white
    set patch-type "road"
     ]

  let gates patches with [
    ((pxcor = -5) and (pycor = -10)) or
    ((pxcor = 0) and (pycor = -10)) or
    ((pxcor = 5) and (pycor = -10))
  ]
  ask gates [
    set pcolor 13
    set patch-type "gates"
    ]

  let runwayleft patches with [
    ((pxcor = -15) and (pycor = 10))
  ]
  ask runwayleft [
    set pcolor 105
    set patch-type "runwayleft"]

    let runwayright patches with [
    ((pxcor = 15) and (pycor = 10))
  ]
  ask runwayright [
    set pcolor 105
    set patch-type "runwayright"]

end


;-------------------------------------------------------------------------------------
; INFRASTRUCTURE-PLACING: Place infrastructure agents and give them a number that is to be recognized

to infrastructure-placing
;; infrastructure 0 & 1 are on runway and keep patch-type runway
  ask patches at-points [ [15 10] [-15 10] ]
[sprout-infrastructures 1
[  set size 0.5
  set color grey]]
;; infrastructure 2 and 3 are connecting the roads to the runway. They are located at the top left and top right white intersections
  ask patches at-points [[15 5] [-15 5] ]
[sprout-infrastructures 1
[  set size 0.5
  set color grey
set patch-type "runwayconnection"
set heading 0]]
;; infrastructure 4 - 22 are on intersections of roads and get patch-type waypoint
  ask patches at-points [[10 5] [5 5] [0 5] [-5 5] [-10 5] [15 0] [10 0] [5 0] [0 0] [-5 0] [-10 0] [-15 0] [15 -5] [10 -5] [5 -5][0 -5] [-5 -5] [-10 -5] [-15 -5] ]
[sprout-infrastructures 1
[  set size 0.5
  set color grey
set patch-type "waypoint"
set heading 0]]
;; infrastructure 23 - 25 are at gates
  ask patches at-points [[5 -10][0 -10] [-5 -10] ]
[sprout-infrastructures 1
[  set size 0.5
  set color grey
  set heading 0]]
;; final agent goal: infrastructure 26. All infrastructure agents are instructed to go to this fictional end point. It could be regarded as: take-off to flight
  ask patches with [((pxcor = 0) and (pycor = 15))]
[sprout-infrastructures 1
[  set size 0.5
  set color grey]]
end

;-------------------------------------------------------------------------------------
; LINKS CREATION

; CREATING-LINKS: Create links between infrastructure agents of the required type

to creating-links
  ifelse structural-coordination                                                                                                ; Initiate if structural modifications are desired
  [creating-directional-and-bidirectional-links]                                                                                ; Create bidirectional and directional links between infrastructre agents
  [creating-bidirectional-links]                                                                                                ; Otherwise, only create bidirectional links between all infrastructre agents
end


; CREATING-BIDIRECTIONAL-LINKS: Create bidirectional links between all infrastructure agents, defined as local roals

to creating-bidirectional-links
ask infrastructures at-points [[15 5] [10 5] [5 5][0 5] [-5 5] [-10 5] [-15 5]
    [15 0] [10 0] [5 0][0 0] [-5 0] [-10 0] [-15 0] [15 -5] [10 -5] [5 -5][0 -5]
    [-5 -5] [-10 -5] [-15 -5] ]                                                                                                 ;Create the links.
   [create-local-roads-with other infrastructures in-radius 5 [set weight 1]]                                                   ;Bidirectional links are defined as local roads. The standard weight of a link is 1
ask infrastructure 26                                                                                                           ;The final goal infrastructure 26 has specific links
   [create-local-road-with infrastructure 0 [set weight 1]
    create-local-road-with infrastructure 1 [set weight 1]]
end


; CREATING-BI/DIRECTIONAL-LINKS: Create bidirectional and directional links between infrastructure agents, defined as local roals and highways respectively

to creating-directional-and-bidirectional-links

  let main-infra infrastructures with [abs(xcor) = 15 or ycor = -10 or (ycor = -5 and abs(xcor) >= 0)                           ; Identifies the main infrastrucutre agents to be connected by highways
    or (ycor = 0 and abs(xcor) >= 5) or (ycor = 5 and abs(xcor) >= 10)]
  let secondary-infra infrastructures with [not member? self highways and ycor != 15 and ycor != -10]                           ; Identifies the secondary infrastrucutre agents to be connected by local roads (the ones which are not highways)

  ask secondary-infra                                                                                                           ; Creates bidirectional local roads between secondary infrastrucutre agents and all their neighboring agents
  [create-local-roads-with other infrastructures in-radius 5 [ set weight 1 ]]                                                  ; The standard weight of a link is 1

  ask main-infra                                                                                                                ; Creates undirectional highways between main infrastrucutre agents
  [let py ycor                                                                                                                  ; Stores the coordinates of the main infrastrucutre agent A
   let px xcor

   if any? main-infra with [xcor = px and ycor = py + 5 ]                                                                       ; Checks the presence of a neighboring main infrastrucutre agent north of agent A to create a link with
   [create-highway-to one-of main-infra with [xcor = px and ycor = py + 5][ set weight 1]]                                      ; The standard weight of a link is 1

   if any? main-infra with [abs(xcor) = abs(px) + 5 and ycor = py and xcor * px > 0 and ycor != -10]                            ; Checks the presence of a neighboring main infrastrucutre agent west (east) of agent A if agent A is on the left (right) half plane
   [create-highway-to one-of main-infra with [abs(xcor) = abs(px) + 5 and ycor = py and xcor * px > 0 and ycor != -10]
      [set weight 1]]                                                                                                           ; The standard weight of a link is 1

   if any? main-infra with [abs(xcor) = 5 and ycor = py  and py = -5 and px = 0]                                                ; Create links connecting the path from the central gate
   [create-highways-to main-infra with [abs(xcor) = 5 and ycor = -5][ set weight 1]]                                            ; The standard weight of a link is 1

   set color 3                                                                                                                  ; Set a darker grey color for highway links and theiur infrastructure agents
   ask highways [set color 3]
  ]

  ask infrastructure 26                                                                                                         ; The final goal infrastructure 26 has specific highway links
  [create-highway-from infrastructure 0 [set weight 1]
   create-highway-from infrastructure 1 [set weight 1] ]
end

;-------------------------------------------------------------------------------------
; UPDATING WEIGHTS

; UPDATE-WEIGHTS: To choose observation strategy to update weights of links

to update-weights
  (ifelse planning = "Global"                                                                              ; Enforces planning based on global observations if activated
    [ask infrastructures with [patch-type = "waypoint"] [update-weights-global-obs]]                       ; Only waypoint agents are asked to change weights
   planning = "Local"                                                                                      ; Enforces planning based on local observations if activated
    [ask infrastructures with [key-waypoint = true] [update-weights-local-obs]]                            ; Only key waypoint agents are asked to change weights
   planning = "None" [])                                                                                   ; Enforces no planning if no planning is activated
end


; UPDATE-WEIGHTS-LOCAL-OBS: To change weights of links based on local observations

to update-weights-local-obs
let px xcor                                                                                                ; Stores the coordinates of the infrastrucutre agent A
let py ycor

let aircrafts-north aircrafts with [xcor = px and ycor > py and ycor < 5 + py]                             ; Find aircraft present on the northern adjacent link to infrastrucutre agent A
let aircrafts-east aircrafts with [xcor > px and xcor < 5 + px and ycor = py]                              ; Find aircraft present on the eastern adjacent link to infrastrucutre agent A
let aircrafts-south aircrafts with [xcor = px and ycor < py and ycor > py - 5]                             ; Find aircraft present on the southern adjacent link to infrastrucutre agent A
let aircrafts-west aircrafts with [xcor < px and xcor > px - 5 and ycor = py]                              ; Find aircraft present on the western adjacent link to infrastrucutre agent A

set aircrafts-cardinal  aircrafts-north                                                                    ; Helper procedure for weight update function
set neighbor-cardinal   neighbor-north                                                                     ; Helper procedure for wieght update function
update-link-weight-in-cardinal-direction                                                                   ; Update weights of northern adjacent link

set aircrafts-cardinal  aircrafts-east                                                                     ; Helper procedure for weight update function
set neighbor-cardinal   neighbor-east                                                                      ; Helper procedure for weight update function
update-link-weight-in-cardinal-direction                                                                   ; Update weights of eastern adjacent link

set aircrafts-cardinal  aircrafts-south                                                                    ; Helper procedure for weight update function
set neighbor-cardinal   neighbor-south                                                                     ; Helper procedure for weight update function
update-link-weight-in-cardinal-direction                                                                   ; Update weights of southern adjacent link

set aircrafts-cardinal  aircrafts-west                                                                     ; Helper procedure for weight update function
set neighbor-cardinal   neighbor-west                                                                      ; Helper procedure for weight update function
update-link-weight-in-cardinal-direction                                                                   ; Update weights of western adjacent link
end


; UPDATE-LINK-WEIGHT-IN-CARDINAL-DIRECTON: Change weights ofadjacent link in a given cardinal direction

to update-link-weight-in-cardinal-direction
  if any? aircrafts-cardinal                                                                               ; Checks if any aicraft is present on the adjacent link in question. If at least one is present, initiate procedure
  [let aircrafts-cardinal-free count aircrafts-cardinal with [free = true]                                 ; Counts how many non-waiting aicraft are present on that link
   let aircrafts-cardinal-waiting count aircrafts-cardinal with [free = false]                             ; Counts how many waiting aicraft are present on that link
   let weight-factor (aircrafts-cardinal-free + 1.5 * aircrafts-cardinal-waiting) / 4                      ; Computes weight increase factor based on local observations
   ifelse local-road  [who] of self [who] of neighbor-cardinal != nobody                                   ; Checks if the link between infrastrucutre agent A and neighboring infrastructure is a local road
      [ask local-road [who] of self [who] of neighbor-cardinal [set weight weight-factor + 1]]             ; Increases that link's weight based on the number of aircraft present on that link
      [ask highway    [who] of self [who] of neighbor-cardinal [set weight weight-factor + 1]]             ; If that link is a highway, increases that link's weight based on the number of aircraft present on that link
  ]
  end


; UPDATE-WEIGHTS-GLOBAL-OBS: To change weights of links based on global observations

to update-weights-global-obs
let waiting-aircrafts aircrafts in-radius 30 with [free = false and last-infra != nobody]                 ; Counts how many aircraft are currently waiting on the field, excluding the ones who have not reached a waypoint yet
ifelse any? waiting-aircrafts                                                                             ; If aircraft with such conditions are present, initiate procedure
   [foreach sort-on [waiting-time] waiting-aircrafts [the-waiting-aircraft ->                             ; Sorts aircraft on witing time and for each waiting aircraft, do
    let path-to-congestion nw:path-to [last-infra] of the-waiting-aircraft                                ; Computes the path from infrastructure agent A to that waiting aircraft
    if not empty? path-to-congestion                                                                      ; If a path exists,
       [let weight-factor 1 / ( [distance myself] of the-waiting-aircraft + 1)                            ; Computes the weight increase factor based on the waiting time of this aircraft and its distance to infrastructure agent A
          * [waiting-time] of the-waiting-aircraft / max [waiting-time] of waiting-aircrafts              ;
        ask first path-to-congestion [set weight 1 + weight-factor]]                                      ; Infrastructure agent A changes the weight of one of its adjacent link only
        ]
  ]
   [let px xcor                                                                                           ; Stores the coordinates of the infrastrucutre agent A
    let py ycor

    if aircrafts != nobody and abs(px) != 15                                                              ; Initiates weight update procedure if aircraft are present and not on the western and eastern borders
    [let aircraft-density-east count aircrafts with [xcor > px] / count infrastructures with [xcor > px]  ; Computes the density of aircraft on to the east of infrastrucutre agent A
    let aircraft-density-west count aircrafts with [xcor <= px] / count infrastructures with [xcor <= px] ; Computes the density of aircraft on to the west of infrastrucutre agent A

    (ifelse aircraft-density-east > aircraft-density-west                                                 ; Identifies the side with higher aircraft density
    [ifelse local-road [who] of self [who] of neighbor-east != nobody                                     ; If link is a local road, makes link increase their weight
      [ask local-road [who] of self [who] of neighbor-east [set weight 1.2]]                              ;
      [ask highway [who] of self [who] of neighbor-east [set weight 1.2]]                                 ; If link is a highway, makes link increase their weight
    ]
    aircraft-density-east < aircraft-density-west                                                         ; Identifies the side with higher aircraft density
     [ifelse local-road [who] of self [who] of neighbor-west != nobody                                    ; If link is a local road, makes link increase their weigh
      [ask local-road [who] of self [who] of neighbor-west [set weight 1.2]]                              ;
      [ask highway [who] of self [who] of neighbor-west [set weight 1.2]]                                 ; If link is a highway, makes link increase their weight
    ]
      [])                                                                                                 ; If the densities are equal, no weight change
    ]
  ]


end


;-------------------------------------------------------------------------------------
; EXECUTE AUCTION

to auction
  let x-patch pxcor
  let y-patch pycor

  let patch-infra patch-ahead 0                        ; Infrastructure's own patch
  let patch-top patch-ahead 1                          ; Patch north of infrastructure
  let patch-below patch-ahead -1                       ; Patch south of infrastructure
  let patch-left patch-left-and-ahead 90 1             ; Patch east of infrastructure
  let patch-right patch-left-and-ahead 270 1           ; Patch west of infrastructure

  ; If aircraft on any of above patches and patch-ahead is infrastructure's patch, start coordination by negotiation process
  if any? aircrafts with [(patch-ahead 0 = patch-top and patch-ahead 1 = patch-infra) or (patch-ahead 0 = patch-below and patch-ahead 1 = patch-infra) or (patch-ahead 0 = patch-left and patch-ahead 1 = patch-infra)  or (patch-ahead 0 = patch-right and patch-ahead 1 = patch-infra)]
  [set nearby-aircraft aircrafts with [(patch-ahead 0 = patch-top and patch-ahead 1 = patch-infra) or (patch-ahead 0 = patch-below and patch-ahead 1 = patch-infra) or (patch-ahead 0 = patch-left and patch-ahead 1 = patch-infra)  or (patch-ahead 0 = patch-right and patch-ahead 1 = patch-infra)]
    ifelse any? aircrafts with [xcor = x-patch and ycor = y-patch]
    [ask nearby-aircraft [set free false]]            ; If there are any aicraft on the infrastructure's patch, the nearby aircraft are set free to false until crossing is cleared
    [let mean-travel-nearby-aircraft mean [travel-time] of nearby-aircraft
    ask nearby-aircraft [
      ifelse hub                                      ; Aircraft that have a hub at this airport receive a higher budget, also the randomly added value when budget is depleted can take a higher value
      [
      set free false
      ;print total-bid
      ifelse total-bid > 8                            ; If true => Resources depleted as reached maximum budget, bid is now small and random is as to prevent bid from being 0
        [set bid random-float 0.02
         set total-bid total-bid                      ; Total-bid remains the same value as maximum budget reached
        ]
      [set bid travel-time / mean-travel-nearby-aircraft + random-float 0.05
      set total-bid total-bid + bid
          ]
      ]
      [
      set free false
      ifelse total-bid > 4                            ; If true => Resources depleted as reached maximum budget, bid is now small and random is as to prevent bid from being 0
        [set bid random-float 0.01
         set total-bid total-bid                      ; Total-bid remains the same value as maximum budget reached
        ]
      [set bid travel-time / mean-travel-nearby-aircraft + random-float 0.05
      set total-bid total-bid + bid                   ; Bid initially 0, added is the proportion of travel-time of aircraft and average travel time of the nearby aircraft

          ]
      ]
      ]
    let winner nearby-aircraft with-max [bid]         ; Winner is nearby aircraft with highest bid
      ask winner [set free true]                      ; Winner is subsequently set free
  ]
  ]
end

;-------------------------------------------------------------------------------------
; GO: Once everything has been set up correctly, a go command is used to start and continue the simulation

to go
  creating-aircraft                         ; Creates aircraft every certain amount of ticks

  ask local-roads [set weight 1]            ; Reset link weights to standard weight
  ask highways [set weight 1]               ; if highway-type links are used, their weights are also reset to standard weight

  ask infrastructures [check-empty]         ; Checks if any aircraft is currently present on the infrastructure agent
  update-weights                            ; Updates link weights

  ask infrastructures [find-path]           ; Helper procedure: asks infrastructures to find the lowest weighted path over the weighted links
  ask aircrafts [find-other-aircraft]       ; Helper procedure: finds other aircraft close to aircraft to anticipate on these
  ask aircrafts [find-infrastructure-mate]  ; Helper procedure: if aircraft is on same patch as an infrastructure agent is, it becomes its "mate"
  ask aircrafts [find-following-patch]      ; Finds its next patch if aircraft goes one patch forward
  ask aircrafts [check-free]                ; Checks if the road is free and no other aircraft is currently on it or will be on it in the next tick

  if coordination-negotiation
  [ask infrastructures [auction]]           ; Perform auction at intersection between agentss

  ask aircrafts [runway-usage]

  ask aircrafts [normal-taxi-runway]        ; Asks aircraft to taxi, if the road is free to go
  ask aircrafts [check-collision]           ; Checks if a collision is currently happening with another aircraft

; Ask infrastructures to calculate and report the interarrival time when aircraft arrive on one of the runways
  ask infrastructures with [patch-type = "runwayleft" or patch-type = "runwayright"] [calculate-interarrival]

  count-aircraft                            ; For analysis, count aircraft and waiting aircraft
  link-traffic                              ; Used for analysis
  update-bid-list                           ; Used for analysis

  tick                                      ; Adds one tick everytime the go procedure is performed

end


;-------------------------------------------------------------------------------------
; ALL GO COMMANDS
; CREATING-AIRCRAFT: Generate new aircraft after certain amount of ticks

to creating-aircraft
  make-ticks-generator
  find-integer                                         ; Helper procedure: chooses a random tick to generate an aircraft in, within the number of ticks as determined by ticks-generator
 if integer-1 = "true" and not any? aircrafts-on patch -5 -10 and (ac-generated - arrived-left - arrived-right) <= taxiway-capacity
  [ask patches with [((pxcor = -5) and (pycor = -10))] ; Integer-1 is the (random) tick in which an aircraft is created on the most left gate
  [create-aircraft-now]]                                 ; Creates aircraft (see next command)
if integer-3 = "true" and not any? aircrafts-on patch 5 -10 and (ac-generated - arrived-left - arrived-right) <= taxiway-capacity
  [ask patches with [((pxcor = 5) and (pycor = -10))]  ; Integer-3 is the (random) tick in which an aircraft is created on the most right gate
  [create-aircraft-now]]
if integer-2 = "true" and not any? aircrafts-on patch 0 -10 and (ac-generated - arrived-left - arrived-right) <= taxiway-capacity
  [ask patches with [((pxcor = 0) and (pycor = -10))]  ; Integer-2 is the (random) tick in which an aircraft is created on the center gate
  [create-aircraft-now]]
end

to create-aircraft-now                                 ; Makes sure an aircraft is created when needed, in black color, size 1, and pointing up
  sprout-aircrafts 1
  [
  set ac-generated (ac-generated + 1)
  ;set color black
  set size 1
  set heading 0
  set last-infra nobody
  ifelse airport-hub
    [set hub (random-float 1 < 0.6)]                 ; Reports true or false, with 60% probability of reporting true (6/10 aircraft have hub at this airport
    [set hub false]
  ifelse hub
    [set color blue]
    [set color black]



  ]
end

;-------------------------------------------------------------------------------------
; AIRCRAFT PROCEDURES

; CHECK-FREE: Check if the coming patches are free to travel to and if seperation must be maintained

to check-free
  find-other-aircraft-1-2-3                         ; Helper procedure that finds and identifies other aircraft that are within radius of 1.5 patches

  set free true                                     ; In principle aircraft is free to go further.

  runway-usage                                                                                                   ; Prevents two aircraft using entering the runway simultaneously

  (ifelse coordination-rule = "Original rule"                                                                    ; Enforces coordination based on priority from the right if activated
    [coordination-rules-original]
   coordination-rule = "Travel-time rule"                                                                        ; Enforces coordination based on agent's total waiting time if activated
    [coordination-rules-traveltime])
end

;-------------------------------------------------------------------------------------
; COORDINATION BY RULES

to coordination-rules-original                    ; Enforces the default coordination strategy (priority from the right)

  ifelse hub                                      ; first case if aircraft has hub at airport, second case if aircraft does not have hub at airport
  [
   if other-aircraft-1 != nobody
    [

            if [following-patch-x] of other-aircraft-1 = following-patch-x and [following-patch-y] of other-aircraft-1 = following-patch-y  and (([heading] of other-aircraft-1 - heading = 270 or [heading] of other-aircraft-1 - heading = -90) and [hub] of other-aircraft-1)
          [set free false]

            if [patch-x] of other-aircraft-1 = following-patch-x and [patch-y] of other-aircraft-1 = following-patch-y ;and ([free] of other-aircraft-1) = false
                [set free false]


      if other-aircraft-2 != nobody
        [
          if [following-patch-x] of other-aircraft-2 = following-patch-x and [following-patch-y] of other-aircraft-2 = following-patch-y and (([heading] of other-aircraft-2 - heading = 270 or [heading] of other-aircraft-2 - heading = -90) and [hub] of other-aircraft-2)
                      [set free false]
                  if [patch-x] of other-aircraft-2 = following-patch-x and [patch-y] of other-aircraft-2 = following-patch-y ;and ([free] of other-aircraft-2) = false
                      [set free false]


           if other-aircraft-3 != nobody
             [
              if [following-patch-x] of other-aircraft-3 = following-patch-x and [following-patch-y] of other-aircraft-3 = following-patch-y and (([heading] of other-aircraft-3 - heading = 270 or [heading] of other-aircraft-3 - heading = -90) and [hub] of other-aircraft-3)
                        [set free false]
                      if [patch-x] of other-aircraft-3 = following-patch-x and [patch-y] of other-aircraft-3 = following-patch-y
                        [set free false]
             ]
        ]
    ]
  ]
  [
    if other-aircraft-1 != nobody
    [

            if [following-patch-x] of other-aircraft-1 = following-patch-x and [following-patch-y] of other-aircraft-1 = following-patch-y  and (([heading] of other-aircraft-1 - heading = 270 or [heading] of other-aircraft-1 - heading = -90) or ([hub] of other-aircraft-1 and not hub))
          [set free false]

            if [patch-x] of other-aircraft-1 = following-patch-x and [patch-y] of other-aircraft-1 = following-patch-y ;and ([free] of other-aircraft-1) = false
                [set free false]


      if other-aircraft-2 != nobody
        [
          if [following-patch-x] of other-aircraft-2 = following-patch-x and [following-patch-y] of other-aircraft-2 = following-patch-y and (([heading] of other-aircraft-2 - heading = 270 or [heading] of other-aircraft-2 - heading = -90) or ([hub] of other-aircraft-2 and not hub))
                      [set free false]
                  if [patch-x] of other-aircraft-2 = following-patch-x and [patch-y] of other-aircraft-2 = following-patch-y ;and ([free] of other-aircraft-2) = false
                      [set free false]


           if other-aircraft-3 != nobody
             [
              if [following-patch-x] of other-aircraft-3 = following-patch-x and [following-patch-y] of other-aircraft-3 = following-patch-y and (([heading] of other-aircraft-3 - heading = 270 or [heading] of other-aircraft-3 - heading = -90) or ([hub] of other-aircraft-3 and not hub))
                        [set free false]
                      if [patch-x] of other-aircraft-3 = following-patch-x and [patch-y] of other-aircraft-3 = following-patch-y
                        [set free false]
             ]
        ]
    ]
  ]



end


to coordination-rules-traveltime                    ; Enforces the adjusted and optimised strategy: priority at infrastructer agent is given to agent's with the largest waiting time

  ifelse hub                                        ; first case if aircraft has hub at airport, second case if aircraft does not have hub at airport
  [
    if other-aircraft-1 != nobody
    [

      if [following-patch-x] of other-aircraft-1 = following-patch-x and [following-patch-y] of other-aircraft-1 = following-patch-y  and ([travel-time] of other-aircraft-1 > travel-time and [hub] of other-aircraft-1)
          [set free false]

            if [patch-x] of other-aircraft-1 = following-patch-x and [patch-y] of other-aircraft-1 = following-patch-y ;and ([free] of other-aircraft-1) = false
                [set free false]


      if other-aircraft-2 != nobody
        [
          if [following-patch-x] of other-aircraft-2 = following-patch-x and [following-patch-y] of other-aircraft-2 = following-patch-y and ([travel-time] of other-aircraft-2 > travel-time and [hub] of other-aircraft-2)
                      [set free false]
                  if [patch-x] of other-aircraft-2 = following-patch-x and [patch-y] of other-aircraft-2 = following-patch-y ;and ([free] of other-aircraft-2) = false
                      [set free false]


           if other-aircraft-3 != nobody
             [
              if [following-patch-x] of other-aircraft-3 = following-patch-x and [following-patch-y] of other-aircraft-3 = following-patch-y and ([travel-time] of other-aircraft-3 > travel-time and [hub] of other-aircraft-3)
                        [set free false]
                      if [patch-x] of other-aircraft-3 = following-patch-x and [patch-y] of other-aircraft-3 = following-patch-y
                        [set free false]
             ]
        ]
    ]
  ]


  [if other-aircraft-1 != nobody
    [

      if [following-patch-x] of other-aircraft-1 = following-patch-x and [following-patch-y] of other-aircraft-1 = following-patch-y  and ([travel-time] of other-aircraft-1 > travel-time or ([hub] of other-aircraft-1 and not hub))
          [set free false]

            if [patch-x] of other-aircraft-1 = following-patch-x and [patch-y] of other-aircraft-1 = following-patch-y ;and ([free] of other-aircraft-1) = false
                [set free false]


      if other-aircraft-2 != nobody
        [
          if [following-patch-x] of other-aircraft-2 = following-patch-x and [following-patch-y] of other-aircraft-2 = following-patch-y and ([travel-time] of other-aircraft-2 > travel-time or ([hub] of other-aircraft-2 and not hub))
                      [set free false]
                  if [patch-x] of other-aircraft-2 = following-patch-x and [patch-y] of other-aircraft-2 = following-patch-y ;and ([free] of other-aircraft-2) = false
                      [set free false]


           if other-aircraft-3 != nobody
             [
              if [following-patch-x] of other-aircraft-3 = following-patch-x and [following-patch-y] of other-aircraft-3 = following-patch-y and ([travel-time] of other-aircraft-3 > travel-time or ([hub] of other-aircraft-3 and not hub))
                        [set free false]
                      if [patch-x] of other-aircraft-3 = following-patch-x and [patch-y] of other-aircraft-3 = following-patch-y
                        [set free false]
             ]
        ]
    ]
  ]




end

; NORMAL-TAXI-RUNWAY: Procedure to either move forward or not, using the specified variables

to normal-taxi-runway
set travel-time (travel-time + 1 + random-float 0.00001)    ; Aircraft counts how long it has been travelling, and adds random component, so no travel-times of two a/c are same
ifelse [patch-type] of patch-ahead 0 = "runwayleft" or [patch-type] of patch-ahead 0 = "runwayright"
    [set travel-time-to-runway travel-time
     if ticks > 500
        [set travel-time-list lput travel-time-to-runway travel-time-list]    ; Put the travel time of the arrived aircraft in the list
        ifelse hub
        [set travel-time-prio-list lput travel-time-to-runway travel-time-prio-list]
        [set travel-time-nonprio-list lput travel-time-to-runway travel-time-nonprio-list]
     set waiting-time-list lput waiting-time waiting-time-list ; Put the waiting time of the arrived aircraft in the list
     die ]                                                     ; If runway has been reached: die.
  [ifelse free = false
    [move-to patch-ahead 0                                  ; Don't move ahead if it is specified that the way is not free,
      set waiting-time (waiting-time + 1)                   ; set waiting time plus one, because he waits one unit of time,
      set color red]                                        ; and set color to red, to see clearly that an aircraft is waiting
    [move-to patch-ahead 1                                  ; If free is not false, then one aircraft can move ahead,
      ifelse hub
      [set color blue]                                      ; and color can be (re)set to black
      [set color black]
      set travel-distance (travel-distance + 1)
      if on-infra = 1                                       ; If a/c is on infrastructure agent,
      [
       set last-infra infrastructure-mate                   ; Set last-infra to keep track of which was previous link
      ]
    ]
  ]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; HELPER PROCEDURES
; Procedures called upon in the above procedures.
to link-traffic
  ; Numbering done bottom to top, left to right
  ; Gather data on taxiway traffic, useful for analysis o.a.
  let traffic-link-1 count aircrafts with [pycor >= -10 and pycor < -5 and pxcor = -5]
  let traffic-link-2 count aircrafts with [pycor >= -10 and pycor < -5 and pxcor = 0]
  let traffic-link-3 count aircrafts with [pycor >= -10 and pycor < -5 and pxcor = 5]

  let traffic-link-4 count aircrafts with [pycor = -5 and pxcor >= -15 and pxcor < -10]
  let traffic-link-5 count aircrafts with [pycor = -5 and pxcor >= -10 and pxcor < -5]
  let traffic-link-6 count aircrafts with [pycor = -5 and pxcor >= -5 and pxcor < 0]
  let traffic-link-7 count aircrafts with [pycor = -5 and pxcor >= 0 and pxcor < 5]
  let traffic-link-8 count aircrafts with [pycor = -5 and pxcor >= 5 and pxcor < 10]
  let traffic-link-9 count aircrafts with [pycor = -5 and pxcor >= 10 and pxcor <= 15]

  let traffic-link-10 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = -15]
  let traffic-link-11 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = -10]
  let traffic-link-12 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = -5]
  let traffic-link-13 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = 0]
  let traffic-link-14 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = 5]
  let traffic-link-15 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = 10]
  let traffic-link-16 count aircrafts with [pycor >= -5 and pycor < 0 and pxcor = 15]

  let traffic-link-17 count aircrafts with [pycor = 0 and pxcor >= -15 and pxcor < -10]
  let traffic-link-18 count aircrafts with [pycor = 0 and pxcor >= -10 and pxcor < -5]
  let traffic-link-19 count aircrafts with [pycor = 0 and pxcor >= -5 and pxcor < 0]
  let traffic-link-20 count aircrafts with [pycor = 0 and pxcor >= 0 and pxcor < 5]
  let traffic-link-21 count aircrafts with [pycor = 0 and pxcor >= 5 and pxcor < 10]
  let traffic-link-22 count aircrafts with [pycor = 0 and pxcor >= 10 and pxcor <= 15]

  let traffic-link-23 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = -15]
  let traffic-link-24 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = -10]
  let traffic-link-25 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = -5]
  let traffic-link-26 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = 0]
  let traffic-link-27 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = 5]
  let traffic-link-28 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = 10]
  let traffic-link-29 count aircrafts with [pycor >= 0 and pycor < 5 and pxcor = 15]

  let traffic-link-30 count aircrafts with [pycor = 5 and pxcor >= -15 and pxcor < -10]
  let traffic-link-31 count aircrafts with [pycor = 5 and pxcor >= -10 and pxcor < -5]
  let traffic-link-32 count aircrafts with [pycor = 5 and pxcor >= -5 and pxcor < 0]
  let traffic-link-33 count aircrafts with [pycor = 5 and pxcor >= 0 and pxcor < 5]
  let traffic-link-34 count aircrafts with [pycor = 5 and pxcor >= 5 and pxcor < 10]
  let traffic-link-35 count aircrafts with [pycor = 5 and pxcor >= 10 and pxcor <= 15]

  let traffic-link-36 count aircrafts with [pycor >= 5 and pycor <= 10 and pxcor = -15]
  let traffic-link-37 count aircrafts with [pycor >= 5 and pycor <= 10 and pxcor = 15]

  set link-list [];

  set link-list lput traffic-link-1 link-list                                 ; Add number of aircraft on respective links to the link-list
  set link-list lput traffic-link-2 link-list
  set link-list lput traffic-link-3 link-list

  set link-list lput traffic-link-4 link-list
  set link-list lput traffic-link-5 link-list
  set link-list lput traffic-link-6 link-list
  set link-list lput traffic-link-7 link-list
  set link-list lput traffic-link-8 link-list
  set link-list lput traffic-link-9 link-list

  set link-list lput traffic-link-10 link-list
  set link-list lput traffic-link-11 link-list
  set link-list lput traffic-link-12 link-list
  set link-list lput traffic-link-13 link-list
  set link-list lput traffic-link-14 link-list
  set link-list lput traffic-link-15 link-list
  set link-list lput traffic-link-16 link-list

  set link-list lput traffic-link-17 link-list
  set link-list lput traffic-link-18 link-list
  set link-list lput traffic-link-19 link-list
  set link-list lput traffic-link-20 link-list
  set link-list lput traffic-link-21 link-list
  set link-list lput traffic-link-22 link-list

  set link-list lput traffic-link-23 link-list
  set link-list lput traffic-link-24 link-list
  set link-list lput traffic-link-25 link-list
  set link-list lput traffic-link-26 link-list
  set link-list lput traffic-link-27 link-list
  set link-list lput traffic-link-28 link-list
  set link-list lput traffic-link-29 link-list

  set link-list lput traffic-link-30 link-list
  set link-list lput traffic-link-31 link-list
  set link-list lput traffic-link-32 link-list
  set link-list lput traffic-link-33 link-list
  set link-list lput traffic-link-34 link-list
  set link-list lput traffic-link-35 link-list

  set link-list lput traffic-link-36 link-list
  set link-list lput traffic-link-37 link-list

  let max-list max(link-list)
  let max-list-index position max-list link-list + 1

  set occupied-links-count length remove 0 link-list / 37 * 100                                    ; Computes the share of links which have an aircraft or more present on them (37 links in total)
  if ticks > 500                                                                                   ; When the metric has converged close to a steady state average,
  [set occupied-links-list lput occupied-links-count occupied-links-list]                          ; adds its value to a list to later compute the value of the steady state average

  set traffic-left-approach (traffic-link-23 + traffic-link-30 + traffic-link-36)                  ; The amount of traffic on left approach (three links leading to the left runway), used in runway-usage procedure
  set traffic-right-approach (traffic-link-29 + traffic-link-35 + traffic-link-37)                 ; The amount of traffic on right approach (three links leading to the right runway), used in runway-usage procedure
end

to runway-usage                                                                                    ; Prevent two aircraft of using the runway at the same time
  link-traffic                                                                                     ; Call link-traffic to obtain link traffic data

  let right-runway count other aircrafts with [[patch-type] of patch-ahead 1 = "runwayright"]      ; Counts the amount of aircraft on the right runway
  let left-runway count other aircrafts with [[patch-type] of patch-ahead 1 = "runwayleft"]        ; Counts the amount of aircraft on the left runway

 ifelse traffic-left-approach <= traffic-right-approach                                            ; If traffic on left approach is less than right, in case of potential simultaneous runway usage
 [if [patch-type] of patch-ahead 1 = "runwayleft" and right-runway != 0                            ; The aircraft on the left approach should give priority to the aircraft on right approach, and vice-versa
    [set free false]]
 [if [patch-type] of patch-ahead 1 = "runwayright" and left-runway != 0
    [set free false]]
end

to find-path
  set path nw:turtles-on-weighted-path-to infrastructure 26 "weight"                               ; Asks infrastructures to find the lowest weighted path over the weighted links
end

to make-ticks-generator                                                                            ; Specifies how often new aircraft are generated

  set ticks-generator-left ticks-generator                                                         ; Aircraft are generated at gates every 3 ticks
  set ticks-generator-centre ticks-generator                                                       ; Aircraft are generated at gates every 3 ticks
  set ticks-generator-right ticks-generator                                                        ; Aircraft are generated at gates every 3 ticks

  if asymmetric-demand = "left"                                                                    ; In case of left asymmetric demand,
  [set ticks-generator-left ticks-generator - 1                                                    ; Decrease the ticks-generator at the left gate
   set ticks-generator-centre ticks-generator + 1                                                  ; Increase the ticks-generator at the central gate
   set ticks-generator-right ticks-generator + 1]                                                  ; Increase the ticks-generator at the right gate
  if asymmetric-demand = "right"                                                                   ; In case of left asymmetric demand,
  [set ticks-generator-left ticks-generator + 1                                                    ; Increase the ticks-generator at the left gate
   set ticks-generator-centre ticks-generator + 1                                                  ; Increase the ticks-generator at the central gate
   set ticks-generator-right ticks-generator - 1]                                                  ; Decrease the ticks-generator at the right gate
end

to find-integer
; Generation of aircraft, every 5 ticks, either stochastically or not

    if int (ticks / ticks-generator-left) = (ticks / ticks-generator-left)                         ; Every time that the amount of ticks that have passed is ticks-generator-left,
    [
      ifelse stochastic-departure = true                                                           ; If stochastic-departure is on,
      [set random-generator-1 ticks + one-of [0 1 2]]                                              ; for every gate, choose random number between 0 and 4, and add this to the current amount of ticks.
      [set random-generator-1 ticks]                                                               ; If stochastic-departure is off, generate all new aircraft at same time, every 5 ticks
       ]

    if int (ticks / ticks-generator-centre) = (ticks / ticks-generator-centre)                     ; Every time that the amount of ticks that have passed is ticks-generator-centre,
    [
      ifelse stochastic-departure = true                                                           ; If stochastic-departure is on,
      [set random-generator-2 ticks + one-of [0 1 2]]                                              ; for every gate, choose random number between 0 and 4, and add this to the current amount of ticks.
      [set random-generator-2 ticks]                                                               ; If stochastic-departure is off, generate all new aircraft at same time, every 5 ticks
       ]

    if int (ticks / ticks-generator-right) = (ticks / ticks-generator-right)                       ; Every time that the amount of ticks that have passed is ticks-generator-right,
    [
      ifelse stochastic-departure = true                                                           ; If stochastic-departure is on,
      [set random-generator-3 ticks + one-of [0 1 2]]                                              ; for every gate, choose random number between 0 and 4, and add this to the current amount of ticks.
      [set random-generator-3 ticks]                                                               ; If stochastic-departure is off, generate all new aircraft at same time, every 5 ticks
       ]

    ifelse random-generator-1 = ticks                                                              ; If the random-generator equals current amount of ticks,
    [set integer-1 "true"]                                                                         ; a new aircraft can be generated on gate 1
    [set integer-1 "false"]
    ifelse random-generator-2 = ticks                                                              ; idem
    [set integer-2 "true"]
    [set integer-2 "false"]
    ifelse random-generator-3 = ticks                                                              ; idem
    [set integer-3 "true"]
    [set integer-3 "false"]

end

to find-patches                                                                        ; Used by both infrastructure & aircraft agents: find current patch that they are on
  set patch-x [pxcor] of patch-ahead 0                                                 ; For that Xcor,
  set patch-y [pycor] of patch-ahead 0                                                 ; and Ycor must be known
end

to find-other-aircraft                                                                 ; Finds other aircraft nearby,
  set other-aircraft other aircrafts in-cone 1.5 180                                   ; that are ahead of aircraft and within radius of 1.5 patches
end

to find-neigboring-infrastructure                                                      ; Identitfies the neighboring infrastructure agents of infrastructure agent A
  let px xcor                                                                          ; Stores the coordinates of the main infrastrucutre agent A
  let py ycor

  set neighbor-north one-of infrastructures with [xcor = px     and ycor = py + 5]     ; Sets northern neighbor to be 5 patches above agent A
  set neighbor-east  one-of infrastructures with [xcor = px + 5 and ycor = py]         ; Sets eastern neighbor to be 5 patches to the right of agent A
  set neighbor-south one-of infrastructures with [xcor = px     and ycor = py - 5]     ; Sets northern neighbor to be 5 patches below agent A
  set neighbor-west  one-of infrastructures with [xcor = px - 5 and ycor = py]         ; Sets eastern neighbor to be 5 patches to the left of agent A
end

to find-nearest-aircraft                                                               ; Finds nearest aircraft to check for collision
  find-other-aircraft                                                                  ; Finds other aircraft surrounding the agent
  ifelse other-aircraft = 0                                                            ; If no other aircraft are found, there is no nearest aircraft
  [set nearest-aircraft  nobody]
  [set nearest-aircraft min-one-of other-aircraft [distance myself]] ; Set nearest aircraft to be the closest other aircraft
end

to find-other-aircraft-1-2-3                                                           ; Find and identify other aircraft that are nearby
  find-other-aircraft                                                                  ; Helper procedure that finds other aircraft nearby
  ifelse length sort other-aircraft > 0                                                ; If there is at least  one other aircraft
   [set other-aircraft-1 item 0 sort other-aircraft                                    ; Set other-aircraft-1 to be the aircraft with lowest agent no.
    ifelse length sort other-aircraft > 1                                              ; If there are at least two other aircraft
     [set other-aircraft-2 item 1 sort other-aircraft                                  ; Set other-aircraft-2 to be the aircraft with second lowest agent no.
       ifelse length sort other-aircraft > 2                                           ; If there are three other aircraft
        [set other-aircraft-3 item 2 sort other-aircraft]                              ; Set other-aircraft-3 to be the aircraft with third lowest agent no.
        [set other-aircraft-3 nobody]                                                  ; If there are only two other aircraft, other-aircraft-3 = nobody
     ]
     [set other-aircraft-2 nobody                                                      ; If there is only one other aircraft, other-aircraft-2 and -3 = nobody
      set other-aircraft-3 nobody ]
   ]
   [set other-aircraft-1 nobody                                                        ; If there are no other aircraft, set other-aircraft-1, -2 and -3 = nobody
    set other-aircraft-2 nobody
    set other-aircraft-3 nobody]
end

to find-infrastructure-mate                                                            ; If aircraft is on the same patch as an infrastructure agent, it becomes its "mate".
ifelse [patch-type] of patch-ahead 0 = "gates" or [patch-type] of patch-ahead 0 = "waypoint" or [patch-type] of patch-ahead 0 = "runwayconnection" or [patch-type] of patch-ahead 0 = "runwayleft" or [patch-type] of patch-ahead 0 = "runwayright"
   [set infrastructure-mate min-one-of infrastructures [distance myself]               ; Only if on gate, runwayconnection or waypoint,
    find-facing                                                                        ; aircraft is faced in new directsion using find-facing
    set on-infra 1]                                                                    ; Furthermore, on-infra is set to 1 of the aircraft is on the same patch as
   [set on-infra 0]                                                                    ; an infrastructure agent
end

to find-facing                                                                         ; Helps aircraft face in right direction, as determined by the goal
  find-goal                                                                            ; Find the goal of the aircraft: the path that he will travel
  face goal                                                                            ; and face the correct direction for it
end

to find-goal                                                                           ; Finds the goal of the aircraft, which is
  set goal item 1 [path] of infrastructure-mate                                        ; the item 1 in the path that the infrasturcture agent specifies for the aircraft
end

to find-following-patch                                                                ; Finds patches (x,y) that aircraft is on when he moves 1 patch forward
  find-patches                                                                         ; Calls helper procedure above that finds current Xcor and Ycor
  set following-patch-x [pxcor] of patch-ahead 1
  set following-patch-y [pycor] of patch-ahead 1
end

to check-empty                                                                         ; Checks if any aircraft is currently present on the infrastructure agent
  let px xcor                                                                          ; Stores the coordinates of the main infrastrucutre agent A
  let py ycor
  ifelse any? aircrafts with [xcor = px and ycor = py]                                 ; If any aicraft currently has the same coordinates as agent, agent A is not empty
  [set empty false]
  [set empty true]                                                                     ; Otherwise agent A is empty
end

to determine-if-key                                                                    ; Determines if infrastructure agent is a key waypoint
  ifelse (ycor = -5 and xcor mod 10 = 0) or (ycor = 0 and xcor mod 10 = 5)             ; Uses coordinates to determine that
           or (ycor = 5 and xcor mod 10 = 0)
     [set key-waypoint true]
     [set key-waypoint false]
end


;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
; ANALYSIS

; CHECK-COLLISION: Check and count total amount of collisions

to check-collision                                                   ; Checks for collisions with other aircraft
  find-nearest-aircraft                                              ; Finds aircraft that is closest by
  ifelse nearest-aircraft = nobody                                   ; If there is no nearby aircraft, there is no collision
  [set collision? false]
  [
  ifelse distance nearest-aircraft < 0.1                             ; If the distance is smaller than 0.1 patch, there is a collision, which is summed
    [ set collision? true set counter-collisions (counter-collisions + 1) wait 2
    print "collision"]
    [ set collision? false ]
  ]
end

;  CALCULATE-INTERARRIVAL: Calculate and report interarrival time when aircraft have arrived at the runways

to calculate-interarrival
  find-patches                                                                 ; Helper procedure that finds current Xcor and Ycor for infrastruc.
  if activated = 1                                                             ; Only calculate interarrival-time after activation
  [set interarrival-time (interarrival-time + 1)]                              ; Interarrival time is counted every tick
  if any? aircrafts-on patch patch-x patch-y                                   ; If an aircraft has arrived
      [set travel-distance-to-runway [travel-distance] of one-of aircrafts-on patch patch-x patch-y
       if ticks > 500
        [set travel-distance-list lput travel-distance-to-runway travel-distance-list]
       if interarrival-time > 0
        [set interarrival-time-list lput interarrival-time interarrival-time-list]  ; Put the interarrival time between the arrived aircraft in the list
       set interarrival-time 0                                                  ; Reset interarrival time
       set activated 1                                                          ; Activate calculation after first aircraft has arrived

      ifelse patch-type = "runwayleft"                                          ; If the arrival is at left runway,
      [set arrived-left (arrived-left + 1)]                                     ; count one extra at left runway
      [set arrived-right (arrived-right + 1)]                                   ; if at right runway, count one at right runway

     ]
end

; UPDATE-BID-LIST:

to update-bid-list
  ask aircrafts[
  if patch-type = "runway-right" or patch-type = "runway-left" and total-bid != 0
        [set total-bid-list lput total-bid total-bid-list]]
end

; COUNT-AIRCRAFT: Count aircraft

to count-aircraft
  if any? aircrafts and ticks > 500                                                     ; Counts only if aircraft are present and after the metric has converged close to a steady state average
  [set used-capacity-list lput
    (count aircrafts / taxiway-capacity * 100) used-capacity-list                       ; Append to list the used capacity share
   set aircraft-waiting-list lput
    (count aircrafts with [free = false] / count aircrafts * 100) aircraft-waiting-list ; Append to list the waiting aircraft proportion
  ]
end

; ASK-INPUT-FOR-ANALYSIS: If the automatic demand condition selector is chosen, change demand conditions

to ask-input-for-analysis
  if conditions-mode = "normal"
  [set ticks-generator 4
   set asymmetric-demand "none"
   set stochastic-departure false
   set taxiway-capacity 100
  ]

  if conditions-mode = "high"
  [set ticks-generator 2
   set asymmetric-demand "none"
   set stochastic-departure false
   set taxiway-capacity 100
  ]

  if conditions-mode = "asymmetric"
  [set ticks-generator 3
   set asymmetric-demand "left"
   set stochastic-departure false
   set taxiway-capacity 100
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
223
10
712
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-18
18
-16
16
0
0
1
ticks
30.0

BUTTON
111
35
174
68
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
25
35
88
68
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
1

PLOT
728
11
928
161
Number of collisions
Time
Collisions
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Collisions" 1.0 0 -16777216 true "" "plot count aircrafts with [collision? = true]"

PLOT
727
177
927
327
Travel time histogram
Time
Aircraft
25.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram travel-time-list"

PLOT
727
342
927
492
Histogram waiting time
Time
Aircraft
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram (waiting-time-list)"

SWITCH
0
447
188
480
stochastic-departure
stochastic-departure
1
1
-1000

MONITOR
233
42
290
87
Ac left
arrived-left
0
1
11

MONITOR
620
40
683
85
Ac right
arrived-right
0
1
11

SLIDER
0
481
188
514
taxiway-capacity
taxiway-capacity
10
100
100.0
1
1
NIL
HORIZONTAL

CHOOSER
0
231
184
276
planning
planning
"Global" "Local" "None"
1

SWITCH
0
356
184
389
structural-coordination
structural-coordination
0
1
-1000

CHOOSER
0
277
184
322
coordination-rule
coordination-rule
"Original rule" "Travel-time rule" "None"
1

CHOOSER
0
549
188
594
asymmetric-demand
asymmetric-demand
"left" "none" "right"
1

PLOT
1268
12
1572
171
Travel distance to runway
Time
Patches
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot travel-distance-to-runway"
"pen-1" 1.0 0 -2674135 true "" "if not empty? travel-distance-list\n[plot mean travel-distance-list]"

SLIDER
0
515
188
548
ticks-generator
ticks-generator
2
7
2.0
1
1
ticks btw a/c
HORIZONTAL

SWITCH
0
322
184
355
coordination-negotiation
coordination-negotiation
0
1
-1000

PLOT
1267
174
1571
338
Waiting aircraft
Time
% All aircraft
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? aircrafts\n[plot (count aircrafts with [free = false] / count aircrafts * 100)]"
"pen-1" 1.0 0 -2674135 true "" "if not empty? aircraft-waiting-list\n;if ticks > 1000\n[plot mean aircraft-waiting-list]"

PLOT
960
174
1264
337
Occupied Links
Time
% All links
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot occupied-links-count"
"pen-1" 1.0 0 -2674135 true "" "if not empty? occupied-links-list\n[plot mean occupied-links-list]\n"

MONITOR
960
349
1087
394
Saturated links [%]
length filter [i -> i = 5] link-list / 37 * 100
0
1
11

TEXTBOX
3
97
153
115
Demand conditions
13
0.0
1

TEXTBOX
3
214
153
232
Model features
13
0.0
1

PLOT
959
398
1262
561
Used capacity
Time
% Total Capacity
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count aircrafts / taxiway-capacity * 100)"
"pen-1" 1.0 0 -2674135 true "" "if not empty? used-capacity-list\n[plot mean used-capacity-list]"

PLOT
960
12
1264
171
Travel time to runway
Time
Travel time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot travel-time-to-runway"
"pen-1" 1.0 0 -2674135 true "" "if not empty? travel-time-list\n[plot mean travel-time-list]"

SWITCH
0
160
189
193
airport-hub
airport-hub
0
1
-1000

CHOOSER
0
114
188
159
conditions-mode
conditions-mode
"normal" "high" "asymmetric" "manual selection"
1

TEXTBOX
5
412
234
444
Manual selection for\ndemand conditions
13
0.0
1

PLOT
1267
342
1570
560
Hub / Non-hub mean travel time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10146808 true "" "if not empty? travel-time-nonprio-list\n[plot mean travel-time-nonprio-list]"
"pen-1" 1.0 0 -11783835 true "" "if not empty? travel-time-prio-list\n[plot mean travel-time-prio-list]"

@#$#@#$#@
## WHAT IS IT?

To Do:
Soms violaten ze de regel dat ze niet door mogen gaan en gaan ze toch door
De counter lijkt niet helemaal te kloppen

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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Model Evalutation" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="800"/>
    <metric>arrived-left</metric>
    <metric>arrived-right</metric>
    <metric>counter-collisions</metric>
    <metric>mean occupied-links-list</metric>
    <metric>mean used-capacity-list</metric>
    <metric>mean travel-distance-list</metric>
    <metric>mean travel-time-list</metric>
    <enumeratedValueSet variable="conditions-mode">
      <value value="&quot;normal&quot;"/>
      <value value="&quot;high&quot;"/>
      <value value="&quot;asymmetric&quot;"/>
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
0
@#$#@#$#@
