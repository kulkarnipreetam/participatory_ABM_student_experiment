extensions [rnd csv]

breed [shippers shipper]
breed [carriers carrier]
breed [vehicles vehicle]
breed [shops shop]
breed [customers customer]
breed [student_shops student_shop]

shippers-own [
  Price_per_unit
  capacity_issues_flag
  delay_issues_flag
  issue
  number_of_shops_who_order
  shops_list
  distance_from_shops
  daily_demand_estimate_from_shops
  carrier_selection
  selected_carrier_bid
  carrier_bids
  orders_from_shops
  delayed_orders
  order_fulfillment_price
]

carriers-own [
  vehicle_IDs
  Shipper_IDs
  fixed_cost
  profit_percentage
  bids_placed
  filled_capacity
  orders_from_shippers
  unfulfilled_orders
]

vehicles-own [
  carrier_ID
  units_loaded_from_shipper
  orders_on_vehicle_for_delivery
]

shops-own [
  shipper_selection
  order_placed_with_shipper
  vehicles_visiting
  undelivered_inventory
  shortage
  shop_area
  max_stock_level
  daily_demand_of_shop
  customers_at_shop
  customers_demand
  safety_stock
  reorder_point
  ordering_cost
  profit_per_unit
  selling_price
  cost_price
  economic_order_quantity
  onshelf_inventory
  inventory_tracker
  order_counter
  order_tracker
  customer_demand_tracker
  Order_delayed
  delayed_order_tracker
]

student_shops-own [
  user-id
  setup_status
  placing_order_decision
  shipper_selection
  fill_rate
  order_placed_with_shipper
  vehicles_visiting
  undelivered_inventory
  shortage
  shop_area
  max_stock_level
  daily_demand_of_shop
  customers_at_shop
  customers_demand
  safety_stock
  reorder_point
  ordering_cost
  profit_per_unit
  selling_price
  cost_price
  economic_order_quantity
  onshelf_inventory
  shipper-item
  inventory_tracker
  order_counter
  order_tracker
  customer_demand_tracker
  Order_delayed
  delayed_order_tracker
]


customers-own [
  shop_today
  Shoping_quantity
  utility
  exp_utility_sum
  probability_of_choosing_a_shop
  shop_selected
  home_xcor
  home_ycor
]

globals [
  Cor
  Shop_Cor
  Ship_Cor
  Carr_Cor
  Day_counter
  carriers_list
  all_shops
  agent_shops_list
  student_shops_list
  student_shops_counter
  actual_customer_demand_at_shops
  actual_averag_customer_demand
  total_orders_placed_by_shops
  total_shortage_at_shops
  total_undelivered_inventory_to_shops
  vehicles_delivering_orders
  max_shop_area
  max_shop_onshelf_inventory
  max_selling_price_per_unit
  Shippers-info
  history
  dummy
  dummy_1
]

to startup
  hubnet-reset
  listen-clients
end

to setup

  clear-patches
  clear-drawing
  clear-output
  clear-all-plots

  set Day_counter 0

  file-open "Coordinates.txt"

  set Cor []

  while [not file-at-end?] ; read data from text file
  [
    let x []
    set x lput file-read x
    set x lput file-read x
    set Cor lput x Cor
  ]
  file-close

  set Shop_Cor sublist Cor 0 100
  set Ship_Cor sublist Cor 100 130
  set Carr_Cor sublist Cor 130 150

  ask shippers [die]
  ask carriers [die]
  ask vehicles [die]
  ask shops [die]
  ask customers [die]

  listen-clients

  set carriers_list []
  set agent_shops_list []
  set student_shops_list []
  set actual_customer_demand_at_shops []
  set vehicles_delivering_orders []
  set total_orders_placed_by_shops []
  set total_shortage_at_shops []
  set total_undelivered_inventory_to_shops []
  set Shippers-info []

  create-shippers 4 [
    set shape "house"
    set color green
    set size 2
    set shops_list []
    set distance_from_shops []
    set carrier_bids []
    set orders_from_shops []
    set delayed_orders []
  ]

  create-carriers No_of_carriers [
    set shape "triangle"
    set color white
    set size 2
    set fixed_cost (precision (random-normal Average_carrier_fixed_cost 3) 2)
    if  (fixed_cost <= 0) [set fixed_cost Average_carrier_fixed_cost / 4]
    set profit_percentage (precision (random-normal Carrier_profit_percentage 3) 2)
    if  (profit_percentage <= 1.8) [set profit_percentage 2]
    set bids_placed []
    set filled_capacity []
    set Shipper_IDs []
    set orders_from_shippers []
    set unfulfilled_orders []
  ]

  create-vehicles No_of_vehicles * No_of_carriers [
    set shape "truck"
    set orders_on_vehicle_for_delivery []
  ]

  create-shops No_of_shops [
    set shape "house"
    set color red
    set shipper_selection [who] of min-one-of other shippers [distance myself]
    set shop_area precision (random-normal Average_shop_area 500) 2
    if (shop_area <= 0) [set shop_area Average_shop_area / 3]
    set profit_per_unit (precision (random-normal Shops_avg_profit_per_unit 1.5) 2)
    if  (profit_per_unit < 1) [set profit_per_unit 1]
    set daily_demand_of_shop round (random-normal Average_daily_demand_for_shops Std_dev_daily_demand_for_shops)
    if  (daily_demand_of_shop <= 100) [set daily_demand_of_shop 150]
    set safety_stock round (daily_demand_of_shop)
    set reorder_point round ((daily_demand_of_shop) + safety_stock)
    set max_stock_level round (shop_area / Floor_area_occupied_by_a_unit)
    set onshelf_inventory round (shop_area / Floor_area_occupied_by_a_unit)
    set customers_at_shop []
    set customers_demand []
    set vehicles_visiting []
    set undelivered_inventory []
    set shortage []
    set inventory_tracker []
    set delayed_order_tracker []
  ]

  create-customers No_of_customers [
    set shape "person"
    setxy random-xcor random-ycor
    set home_xcor xcor
    set home_ycor ycor
    set utility []
    set probability_of_choosing_a_shop []
  ]

  ;Assigning fixed locations to shops, shippers and carriers

  let j 0
  while [j < No_of_shops]
  [
    ask one-of shops with [xcor = 0 and ycor = 0]
    [
      set xcor item 0 item j Shop_Cor
      set ycor item 1 item j Shop_Cor
    ]
    set j j + 1
  ]

   let k 0
  while [k < 4]
  [
    ask one-of shippers with [xcor = 0 and ycor = 0]
    [
      set xcor item 0 item k Ship_Cor
      set ycor item 1 item k Ship_Cor
    ]
    set k k + 1
  ]

   let m 0
  while [m < No_of_carriers]
  [
    ask one-of carriers with [xcor = 0 and ycor = 0]
    [
      set xcor item 0 item m Carr_Cor
      set ycor item 1 item m Carr_Cor
    ]
    set m m + 1
  ]

  shipper_issues_designation

  ask student_shops [
    let x user-id
    let s_who item 0 item shipper-item Shippers-info
    let o_cost [order_fulfillment_price] of one-of shippers with [who = s_who]
    ask patch-here [set plabel x set plabel-color white]
    hubnet-send user-id "Shipper-info" (word "Shipper: " (item 0 item shipper-item Shippers-info) ";   Price/unit: $ " (item 1 item shipper-item Shippers-info) ";   Issues:" (item 2 item shipper-item Shippers-info) ";   Ordering cost: $ " precision (distance one-of shippers with [who = s_who] * o_cost) 2 )
  ]

  while [count student_shops with [setup_status != true] != 0]
  [
    listen-clients
    print(word "Following users have not completed setup: " [user-id] of student_shops with [setup_status != true])
  ]

  set all_shops (turtle-set student_shops shops)
  set agent_shops_list [who] of shops
  set student_shops_list [who] of student_shops

  ask all_shops ;all shops calculate selling price
  [
    let shipper_who shipper_selection
    set cost_price [Price_per_unit] of one-of shippers with [who = shipper_who]
    set selling_price precision ((cost_price * (1 + (interest_rate / 100))) + profit_per_unit) 2
    set order_tracker []
    set customer_demand_tracker []
    set Order_delayed false
  ]

  ask student_shops [hubnet-send user-id "Selling-price" (word "$ " selling_price)]

  set max_shop_area max [shop_area] of all_shops
  set max_shop_onshelf_inventory max [max_stock_level] of all_shops
  set max_selling_price_per_unit max [selling_price] of all_shops

  ask carriers [
    let x who
    ask n-of No_of_vehicles vehicles with [carrier_ID = 0][
      set carrier_ID x
    ]
  ]

  ask vehicles [
    let x carrier_ID
    move-to one-of carriers with [who = x]
  ]

  ask carriers[
    set vehicle_IDs [who] of vehicles-here
    set carriers_list lput who carriers_list
  ]

  auction_for_carrier_selection_by_shipper

  ask shippers
  [
    let i 0
    let l length shops_list
    let c order_fulfillment_price
    let s_w who
    while [i < l]
    [
      let s item i shops_list
      ask one-of all_shops with [who = s] [set ordering_cost precision ((distance one-of shippers with [who = s_w]) * c) 2 ]
      ask student_shops with [setup_status = true] [hubnet-send user-id "Ordering-cost" (word "$ " ordering_cost)]
      set i i + 1
    ]
  ]

  customers_calculate_probabilities_to_buy_from_specific_shop

  set history []

  reset-ticks
end

to go
  if (Day_counter = Iterations)
  [
    write_history
    ask student_shops [hubnet-send user-id "System-Message" "End of simulation! Thank you for participating :)"]
    stop
  ]

  if (ticks = 0) [agents_record_history]

  listen-clients

  if (count student_shops with [placing_order_decision != true] = 0)
  [

    set actual_customer_demand_at_shops []
    set total_orders_placed_by_shops []
    set total_shortage_at_shops []
    set total_undelivered_inventory_to_shops []
    set vehicles_delivering_orders []

    ask all_shops
    [
      set customers_at_shop []
      set customers_demand []
      set vehicles_visiting []
    ]

    ask shippers with [orders_from_shops != []] ;orders from shippers is passed on to the selected carrier
    [
      let i 0
      let w who
      while [i < length orders_from_shops]
      [
        let o item i orders_from_shops
        set o insert-item 0 o w
        let c carrier_selection
        ask one-of carriers with [who = c]
        [
          set orders_from_shippers lput o orders_from_shippers
        ]
        set i i + 1
      ]
    ]

    ask shippers with [delayed_orders != []] ;delayed orders from shippers is passed on to the selected carrier
    [
      let j 0
      let w who
      while [j < length delayed_orders]
      [
        if ((item 2 item j delayed_orders) = (Day_counter - 2))
        [
          let copy_to_remove item j delayed_orders
          let o sublist item j delayed_orders 0 2
          set o insert-item 0 o w
          let c carrier_selection
          let shop_who item 0 item j delayed_orders
          let shop_order_size item 1 item j delayed_orders
          ask one-of carriers with [who = c]
          [
            set orders_from_shippers lput o orders_from_shippers
          ]
          ask one-of all_shops with [who = shop_who] [set delayed_order_tracker remove shop_order_size delayed_order_tracker]
          set delayed_orders remove copy_to_remove delayed_orders
        ]
        set j j + 1
      ]
    ]

    carriers_process_deliveries

    ask all_shops [set vehicles_delivering_orders lput length vehicles_visiting vehicles_delivering_orders]

    ask shippers with [orders_from_shops != []] [set orders_from_shops []] ; reset orders
    ask carriers with [orders_from_shippers != []] [set orders_from_shippers [] set unfulfilled_orders []] ;reset orders

    customers_go_shopping

    ask student_shops [set placing_order_decision false]

    shops_place_orders

    ask all_shops [
      set actual_customer_demand_at_shops lput sum customers_demand actual_customer_demand_at_shops
      set customer_demand_tracker lput sum customers_demand customer_demand_tracker
      set total_shortage_at_shops lput sum shortage total_shortage_at_shops
      set total_undelivered_inventory_to_shops lput sum undelivered_inventory total_undelivered_inventory_to_shops
      set inventory_tracker lput onshelf_inventory inventory_tracker
    ]

    ask shippers [set total_orders_placed_by_shops lput length orders_from_shops total_orders_placed_by_shops]

    ifelse (actual_customer_demand_at_shops = [])[set actual_averag_customer_demand 0] [set actual_averag_customer_demand mean actual_customer_demand_at_shops]

    agents_record_history

    set Day_counter Day_counter + 1

    ask all_shops [set order_placed_with_shipper 0 set Order_delayed false]

    ask shops [set economic_order_quantity 0]

    ask student_shops [hubnet-send user-id "System-Message" ""]
  ]

  ask student_shops [send-student-info]

  tick

end

to shipper_issues_designation
  ask n-of 1 shippers with [capacity_issues_flag = 0 and delay_issues_flag = 0]
  [
    let x []
    set x lput who x
    set Price_per_unit (Avg.Price_per_unit - 0.5)
    set capacity_issues_flag true
    set delay_issues_flag false
    set issue " Capacity"
    set x lput Price_per_unit x
    set x lput issue x
    set Shippers-info lput x Shippers-info
    set order_fulfillment_price 1
  ]

  ask n-of 1 shippers with [capacity_issues_flag = 0 and delay_issues_flag = 0]
  [
    let x []
    set x lput who x
    set Price_per_unit (Avg.Price_per_unit - 1)
    set capacity_issues_flag false
    set delay_issues_flag true
    set issue " Delay"
    set x lput Price_per_unit x
    set x lput issue x
    set Shippers-info lput x Shippers-info
    set order_fulfillment_price 0.85
  ]

  ask n-of 1 shippers with [capacity_issues_flag = 0 and delay_issues_flag = 0]
  [
    let x []
    set x lput who x
    set Price_per_unit (Avg.Price_per_unit - 1.5)
    set capacity_issues_flag true
    set delay_issues_flag true
    set issue " Capacity & Delay"
    set x lput Price_per_unit x
    set x lput issue x
    set Shippers-info lput x Shippers-info
    set order_fulfillment_price 0.7
  ]

  ask n-of 1 shippers with [capacity_issues_flag = 0 and delay_issues_flag = 0]
  [
    let x []
    set x lput who x
    set Price_per_unit Avg.Price_per_unit
    set capacity_issues_flag false
    set delay_issues_flag false
    set issue " None"
    set x lput Price_per_unit x
    set x lput issue x
    set Shippers-info lput x Shippers-info
    set order_fulfillment_price 1.5
  ]
end

to auction_for_carrier_selection_by_shipper
  ;shippers identify shops who want to purchase from them and calculate their distance from shops
  ask shippers[
    let x who
    set number_of_shops_who_order count all_shops with [shipper_selection = x]
    set daily_demand_estimate_from_shops (Average_daily_demand_for_shops * number_of_shops_who_order)
    set shops_list [who] of all_shops with [shipper_selection = x]
    let h 0
    while [h < length shops_list]
    [
      set dummy item h shops_list
      set distance_from_shops lput precision (distance one-of all_shops with [who = dummy]) 2 distance_from_shops
      set h h + 1
    ]
  ]

  ;carriers place bids
  let i 0
  let y 0
  while [i < length carriers_list]
  [
    set dummy []
    ask shippers [
      let x []
      ifelse (empty? distance_from_shops) [set y 2 * distance one-of carriers with [who = item i carriers_list]]
      [set y (2 * distance one-of carriers with [who = item i carriers_list]) + mean distance_from_shops]
      let c (y + [fixed_cost] of one-of carriers with [who = item i carriers_list]) * (1 + (([profit_percentage] of one-of carriers with [who = item i carriers_list]) / 100))
      set x lput who x
      set x lput (precision c 2) x
      set dummy lput x dummy
    ]
    ask one-of carriers with [who = item i carriers_list] [set bids_placed dummy]
    set i i + 1
  ]

  ;shippers collect bids placed by carriers
  ask shippers [
    let j 0
    while [j < length carriers_list]
    [
      let k 0
      while [k < length [bids_placed] of one-of carriers with [who = item j carriers_list]]
      [
        if (item 0 item k [bids_placed] of one-of carriers with [who = item j carriers_list] = who)
        [
          set dummy []
          set dummy lput item j carriers_list dummy
          set dummy lput item 1 item k [bids_placed] of one-of carriers with [who = item j carriers_list] dummy
          set k length [bids_placed] of one-of carriers with [who = item j carriers_list]
        ]
        set k k + 1
      ]
      set carrier_bids lput dummy carrier_bids
      let sorted_list sort-by [[a b] -> item 1 a < item 1 b] carrier_bids
      set carrier_bids sorted_list
      set j j + 1
    ]
  ]

  ;shippers select a carrier with lowest bid
  ask shippers with [carrier_selection = 0]
  [
    let l 0
    while [l < length carrier_bids]
    [
      set dummy item 0 item l carrier_bids
      if (sum item 0 [filled_capacity] of carriers with [who = dummy] + (daily_demand_estimate_from_shops) <= (No_of_vehicles * Capacity_per_vehicle))
      [
        set carrier_selection dummy
        set selected_carrier_bid item 1 item l carrier_bids
        set dummy_1 who
        ask one-of carriers with [who = dummy]
        [
          set filled_capacity lput round (item 0 [daily_demand_estimate_from_shops] of shippers with [who = dummy_1]) filled_capacity
          set Shipper_IDs lput dummy_1 Shipper_IDs
        ]
        set l length carrier_bids
      ]
      set l l + 1
    ]
  ]
end

to customers_calculate_probabilities_to_buy_from_specific_shop
  ask customers [
    set shop_today one-of [true false]
    set Shoping_quantity round random-poisson Average_customer_orders
    let i 0
    let s [who] of all_shops
    while [i < length s]
    [
      let x []
      let w item i s
      set x lput w x
      set x lput precision ((0.25 * ([shop_area] of one-of all_shops with [who = w] / max_shop_area)) + (0.75 * (1 - ([selling_price] of one-of all_shops with [who = w] / max_selling_price_per_unit)))) 4 x
      set utility lput x utility
      set i i + 1
    ]

    let j 0
    let sum_exp_utility []
    while [j < length utility]
    [
      set sum_exp_utility lput exp item 1 item j utility sum_exp_utility
      set j j + 1
    ]

    set exp_utility_sum precision (sum sum_exp_utility) 4

    let k 0
    while [k < length utility]
    [
      let x []
      let w item 0 item k utility
      set x lput w x
      set x lput precision ((exp item 1 item k utility) / exp_utility_sum) 4 x
      set probability_of_choosing_a_shop lput x probability_of_choosing_a_shop
      set k k + 1
    ]
  ]
end

to carriers_process_deliveries
  ask carriers with [orders_from_shippers != []] ;Carriers assign vehicles for delivery and raise exception if they do not have enough capacity
  [
    set unfulfilled_orders orders_from_shippers
    let carrier_who who
    let i 0
    while [i < length orders_from_shippers]
    [
      ;print(word "Carrier " who " " orders_from_shippers)
      let o item i orders_from_shippers
      let oq item 2 item i orders_from_shippers
      let vID vehicle_IDs
      let j 0
      while [j < length vID]
      [
        set dummy item j vID
        ask one-of vehicles with [who = dummy]
        [
          ifelse (units_loaded_from_shipper + oq < Capacity_per_vehicle)
          [
            set orders_on_vehicle_for_delivery lput o orders_on_vehicle_for_delivery
            set units_loaded_from_shipper units_loaded_from_shipper + oq
            ask one-of carriers with [who = carrier_who] [set unfulfilled_orders remove o unfulfilled_orders]
            set i i + 1
            set j length vID
            ;print(word "Vechicle " who " " orders_on_vehicle_for_delivery)
          ]
          [
            ifelse (units_loaded_from_shipper = Capacity_per_vehicle) [set j j + 1]
            [
              let y []
              set y lput item 0 o y
              set y lput item 1 o y
              set y lput (Capacity_per_vehicle - units_loaded_from_shipper) y
              ask one-of carriers with [who = carrier_who]
              [
                set orders_from_shippers replace-item i orders_from_shippers y
                set unfulfilled_orders remove o unfulfilled_orders
              ]
              set orders_on_vehicle_for_delivery lput y orders_on_vehicle_for_delivery
              set units_loaded_from_shipper units_loaded_from_shipper + item 2 y
              ;print(word "Vechicle " who " " orders_on_vehicle_for_delivery)
              let z []
              set z lput item 0 o z
              set z lput item 1 o z
              set z lput (oq - item 2 y) z
              ask one-of carriers with [who = carrier_who]
              [
                set orders_from_shippers lput z orders_from_shippers
                set unfulfilled_orders lput z unfulfilled_orders
                ;print(word "Carrier " who " " orders_from_shippers)
              ]
              if ((j + 1) = length vID)
              [
                ask one-of carriers with [who = carrier_who]
                [
                  print(word "Carrier " who " does not have enough capacity to fullfill orders " unfulfilled_orders)
                  set dummy_1 length orders_from_shippers
                ]
                set i dummy_1
                set j length vID
              ]
              set i i + 1
              set j length vID
            ]
          ]
        ]
      ]
    ]
    let k 0
    while [k < length unfulfilled_orders]
    [
      let u_ord item k unfulfilled_orders
      ask one-of all_shops with [who = item 1 u_ord] [set undelivered_inventory lput item 2 u_ord undelivered_inventory]
      set k k + 1
    ]
  ]

  ask vehicles with [orders_on_vehicle_for_delivery != []]
  [
    let j 0
    let c carrier_ID
    let vehicle_who who
    while [j < length orders_on_vehicle_for_delivery]
    [
      let who_shipper item 0 item j orders_on_vehicle_for_delivery
      let q item 2 item j orders_on_vehicle_for_delivery
      let who_shop item 1 item j orders_on_vehicle_for_delivery
      move-to one-of shippers with [who = who_shipper]
      move-to one-of all_shops with [who = who_shop]
      ask one-of all_shops with [who = who_shop]
      [
        set onshelf_inventory onshelf_inventory + q
        set vehicles_visiting lput vehicle_who vehicles_visiting
      ]
      set j j + 1
    ]
    move-to one-of carriers with [who = c]
    set orders_on_vehicle_for_delivery []
    set units_loaded_from_shipper 0
  ]
end

to customers_go_shopping
  ask customers ;customers go shopping and shops update their inventories
  [
    set shop_selected item 0 rnd:weighted-one-of-list probability_of_choosing_a_shop [ [p] -> last p ]
    let x shop_selected
    ifelse ([onshelf_inventory] of one-of all_shops with [who = x] >= Shoping_quantity)
    [
      let shop_who shop_selected
      move-to one-of all_shops with [who = shop_who]
      let w who
      let d Shoping_quantity
      ask one-of all_shops with [who = shop_who]
      [
        set onshelf_inventory (onshelf_inventory - d)
        set customers_at_shop lput w customers_at_shop
        set customers_demand lput d customers_demand
      ]
      move-to patch home_xcor home_ycor
    ]
    [
      let d Shoping_quantity
      ask one-of all_shops with [who = x] [set shortage lput (d - onshelf_inventory) shortage]
    ]
  ]
end

to shops_place_orders
  ask shops with [onshelf_inventory + sum delayed_order_tracker < reorder_point] ;shops calculate EOQ
  [
    let shipper_who shipper_selection
    set economic_order_quantity round (sqrt((2 * ordering_cost * daily_demand_of_shop)/([Price_per_unit] of one-of shippers with [who = shipper_who] * interest_rate / 100)))
    if (economic_order_quantity + onshelf_inventory > max_stock_level)
    [set economic_order_quantity (max_stock_level - reorder_point)]
    set order_placed_with_shipper economic_order_quantity
  ]

  ask shops with [order_placed_with_shipper != 0] ;shops place orders with shippers based on EOQs
  [
    let x []
    let s shipper_selection
    set x lput who x

    ifelse ([capacity_issues_flag] of one-of shippers with [who = s])
    [
      ifelse (random 100 < 25)
      [
        set x lput round (0.9 * order_placed_with_shipper) x
        set undelivered_inventory lput (order_placed_with_shipper - round (0.9 * order_placed_with_shipper)) undelivered_inventory
      ] [set x lput order_placed_with_shipper x]
      ifelse ([delay_issues_flag] of one-of shippers with [who = s])
      [
        ifelse (random 100 < 25)
        [
          ask one-of shippers with [who = s]
          [
            set x lput Day_counter x
            set delayed_orders lput x delayed_orders
          ]
          set delayed_order_tracker lput item 1 x delayed_order_tracker
          set order_counter order_counter + 1
          set order_tracker lput item 1 x order_tracker
          set Order_delayed true
        ]
        [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
      ]
      [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
    ]
    [
      set x lput order_placed_with_shipper x
      ifelse ([delay_issues_flag] of one-of shippers with [who = s])
      [
        ifelse (random 100 < 25)
        [
          ask one-of shippers with [who = s]
          [
            set x lput Day_counter x
            set delayed_orders lput x delayed_orders
          ]
          set delayed_order_tracker lput item 1 x delayed_order_tracker
          set order_counter order_counter + 1
          set order_tracker lput item 1 x order_tracker
          set Order_delayed true
        ]
        [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
      ]
      [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
    ]
  ]
end

to agents_record_history
  ask all_shops
  [
    let sh_who shipper_selection
    let scf [capacity_issues_flag] of one-of shippers with [who = sh_who]
    let sdf [delay_issues_flag] of one-of shippers with [who = sh_who]
    let ui sum undelivered_inventory
    let tr precision ((sum customer_demand_tracker - sum shortage) * selling_price) 2
    let tc precision ((Area_purchase_cost * shop_area) + (max_stock_level * cost_price) + (sum order_tracker * cost_price) + (order_counter * ordering_cost) + (sum inventory_tracker * cost_price * (interest_rate / 100)) + (sum shortage * profit_per_unit)) 2
    let tp precision (((sum customer_demand_tracker - sum shortage) * selling_price) - (Area_purchase_cost * shop_area) - (max_stock_level * cost_price) - (sum order_tracker * cost_price) - (order_counter * ordering_cost) - (sum inventory_tracker * cost_price * (interest_rate / 100)) - (sum shortage * profit_per_unit)) 2
    let ic precision (sum inventory_tracker * cost_price * (interest_rate / 100)) 2
    let pc precision (sum order_tracker * cost_price) 2
    let oc precision (order_counter * ordering_cost) 2
    let sc precision (sum shortage * profit_per_unit) 2
    ifelse member? who agent_shops_list [set history lput (list who Day_counter shop_area profit_per_unit selling_price shipper_selection scf sdf sum customers_demand sum shortage onshelf_inventory economic_order_quantity Order_delayed ui tr tc tp ic pc oc sc) history]
    [set history lput (list user-id Day_counter shop_area profit_per_unit selling_price shipper_selection scf sdf sum customers_demand sum shortage onshelf_inventory economic_order_quantity Order_delayed ui tr tc tp ic pc oc sc) history]
  ]
end

to write_history
  set history fput (list "user-id" "Day" "Shop area" "Profit per unit" "Selling price" "Shipper selection" "Capacity issues" "Delay issues" "Customers demand" "Cuml. shortage" "Onshelf inventory" "Order quantity" "Order delayed" "Undelivered inventory" "Total Revenue" "Total cost" "Total Profit" "Inventory cost" "Purchasing cost" "Ordering cost" "Shortage cost") history
  file-open "Participatory_output.csv"
  csv:to-file "Participatory_output.csv" history
  file-close
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;HubNet Procedures;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      create-new-student_shops
    ] [
      ifelse hubnet-exit-message? [
        remove-student_shops
      ] [
        ask student_shops with [ user-id = hubnet-message-source ] [
          execute-command hubnet-message-tag
        ]
      ]
    ]
  ]
end

to create-new-student_shops
  create-student_shops 1 [
    set setup_status false
    set placing_order_decision false
    set user-id hubnet-message-source
    set shape "house"
    set color blue
    set xcor item 0 item (count student_shops + No_of_shops) Ship_Cor
    set ycor item 1 item (count student_shops + No_of_shops) Ship_Cor
    let x user-id
    ask patch-here [set plabel x set plabel-color white]
  ]
end

to remove-student_shops
  ask student_shops with [ user-id = hubnet-message-source ] [ die ]
end

to execute-command [ command ]
  if command = "Shop-area" [set shop_area hubnet-message]
  if command = "Profit-per-unit" [set profit_per_unit hubnet-message]
  if command = "Daily-demand-estimate" [set daily_demand_of_shop hubnet-message]
  if command = "Saftey-stock" [set safety_stock hubnet-message]
  if command = "Reorder-point" [set reorder_point hubnet-message]
  if command = "Fill-rate" [set fill_rate hubnet-message]
  if command = "Complete_setup_of_shop" [command-Complete_setup_of_shop]
  if command = "Order_decision" [command-Place_order]
  if command = "Order-quantity" [set economic_order_quantity hubnet-message]
  if command = "View-next" [view-next]
  if command = "View-previous" [view-prev]
  if command = "Select-shipper" [command-select-shipper]
end

; view the next item in the quickstart monitor
to view-next
  set shipper-item shipper-item + 1
  if shipper-item >= length Shippers-info
  [ set shipper-item length Shippers-info - 1 ]
  let s_who item 0 item shipper-item Shippers-info
  let o_cost [order_fulfillment_price] of one-of shippers with [who = s_who]
  hubnet-send user-id "Shipper-info" (word "Shipper: " (item 0 item shipper-item Shippers-info) ";   Price/unit: $ " (item 1 item shipper-item Shippers-info) ";   Issues:" (item 2 item shipper-item Shippers-info) ";   Ordering cost: $ " precision (distance one-of shippers with [who = s_who] * o_cost) 2 )
end

; view the previous item in the quickstart monitor
to view-prev
  set shipper-item shipper-item - 1
  if shipper-item < 0
  [ set shipper-item 0 ]
  let s_who item 0 item shipper-item Shippers-info
  let o_cost [order_fulfillment_price] of one-of shippers with [who = s_who]
  hubnet-send user-id "Shipper-info" (word "Shipper: " (item 0 item shipper-item Shippers-info) ";   Price/unit: $ " (item 1 item shipper-item Shippers-info) ";   Issues:" (item 2 item shipper-item Shippers-info) ";   Ordering cost: $ " precision (distance one-of shippers with [who = s_who] * o_cost) 2 )
end

to command-select-shipper
  let s_who item 0 item shipper-item Shippers-info
  let o_cost [order_fulfillment_price] of one-of shippers with [who = s_who]
  ifelse (setup_status) [hubnet-send user-id "System-Message" "You can not change the shipper in the middle of a simulation! ."]
  [
    hubnet-send user-id "Selected-shipper" (word "Shipper: " (item 0 item shipper-item Shippers-info) ";   Price/unit: $ " (item 1 item shipper-item Shippers-info) ";   Issues:" (item 2 item shipper-item Shippers-info) ";   Ordering cost: $ " precision (distance one-of shippers with [who = s_who] * o_cost) 2 )
    set shipper_selection item 0 item shipper-item Shippers-info
  ]
end

to command-Complete_setup_of_shop
  set max_stock_level round (shop_area / Floor_area_occupied_by_a_unit)
  hubnet-send user-id "Max-stock-level" max_stock_level
  set onshelf_inventory max_stock_level
  hubnet-send user-id "Current-inventory-level" onshelf_inventory
  set customers_at_shop []
  set customers_demand []
  set vehicles_visiting []
  set undelivered_inventory []
  set shortage []
  set inventory_tracker []
  set delayed_order_tracker []
  set setup_status true
  hubnet-send user-id "System-Message" ""
end


to command-Place_order

  ifelse (placing_order_decision) [hubnet-send user-id "System-Message" "You have already placed an order! Please wait for others to finish."]
  [
    ask student_shops with [user-id = hubnet-message-source and economic_order_quantity = 0 ] [set order_placed_with_shipper 0 set placing_order_decision true]

    ask student_shops with [user-id = hubnet-message-source and economic_order_quantity != 0] ;student shops select an EOQ
    [
      ifelse (economic_order_quantity + onshelf_inventory + sum delayed_order_tracker > max_stock_level)
      [
        hubnet-send user-id "System-Message" "EOQ will result in the onshelf inventory exceeding the maximum allowed stock level. Please try again!"
        set placing_order_decision false
      ]
      [
        set order_placed_with_shipper economic_order_quantity
        hubnet-send user-id "System-Message" "Order placed!"
        set placing_order_decision true
      ]
    ]

    ask student_shops with [user-id = hubnet-message-source and order_placed_with_shipper != 0] ;student shops place orders with shippers based on EOQs
    [
      let x []
      let s shipper_selection
      set x lput who x

      ifelse ([capacity_issues_flag] of one-of shippers with [who = s])
      [
        ifelse (random 100 < 25)
        [
          set x lput round (0.9 * order_placed_with_shipper) x
          set undelivered_inventory lput (order_placed_with_shipper - round (0.9 * order_placed_with_shipper)) undelivered_inventory
        ] [set x lput order_placed_with_shipper x]
        ifelse ([delay_issues_flag] of one-of shippers with [who = s])
        [
          ifelse (random 100 < 25)
          [
            ask one-of shippers with [who = s]
            [
              set x lput Day_counter x
              set delayed_orders lput x delayed_orders
            ]
            set delayed_order_tracker lput item 1 x delayed_order_tracker
            set order_counter order_counter + 1
            set order_tracker lput item 1 x order_tracker
            set Order_delayed true
          ]
          [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
        ]
        [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
      ]
      [
        set x lput order_placed_with_shipper x
        ifelse ([delay_issues_flag] of one-of shippers with [who = s])
        [
          ifelse (random 100 < 25)
          [
            ask one-of shippers with [who = s]
            [
              set x lput Day_counter x
              set delayed_orders lput x delayed_orders
            ]
            set delayed_order_tracker lput item 1 x delayed_order_tracker
            set order_counter order_counter + 1
            set order_tracker lput item 1 x order_tracker
            set Order_delayed true
          ]
          [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
        ]
        [ask one-of shippers with [who = s] [set orders_from_shops lput x orders_from_shops] set order_counter order_counter + 1 set order_tracker lput item 1 x order_tracker]
      ]
    ]
  ]
end

;; sends the appropriate monitor information back to one client
to send-student-info
  hubnet-send user-id "Day" Day_counter
  hubnet-send user-id "Selling-price" (word "$ " selling_price)
  hubnet-send user-id "Current-inventory-level" onshelf_inventory
  hubnet-send user-id "Cumulative-Shortage" sum shortage
  hubnet-send user-id "Undelivered-inventory" sum undelivered_inventory
  hubnet-send user-id "Current-customer-demand" sum customers_demand
  hubnet-send user-id "Total-cost" (word "$ " precision ((Area_purchase_cost * shop_area) + (max_stock_level * cost_price) + (sum order_tracker * cost_price) + (order_counter * ordering_cost) + (sum inventory_tracker * cost_price *(interest_rate / 100)) + (sum shortage * profit_per_unit)) 2)
  hubnet-send user-id "Inventory-cost" (word "$ " precision (sum inventory_tracker * cost_price * (interest_rate / 100)) 2)
  hubnet-send user-id "Purchasing-cost" (word "$ " precision (sum order_tracker * cost_price) 2)
  hubnet-send user-id "Order-cost" (word "$ " precision (order_counter * ordering_cost) 2)
  hubnet-send user-id "Shortage-cost" (word "$ " precision (sum shortage * profit_per_unit) 2)
  hubnet-send user-id "Total-orders-placed" order_counter
  hubnet-send user-id "Total-Revenue" (word "$ " precision ((sum customer_demand_tracker - sum shortage) * selling_price) 2)
  hubnet-send user-id "Total-profit" (word "$ " precision (((sum customer_demand_tracker - sum shortage)* selling_price) - (Area_purchase_cost * shop_area) - (max_stock_level * cost_price) - (sum order_tracker * cost_price) - (order_counter * ordering_cost) - (sum inventory_tracker * cost_price *(interest_rate / 100)) - (sum shortage * profit_per_unit)) 2)
  hubnet-send user-id "Shop-setup-cost" (word "$ " precision (Area_purchase_cost * shop_area) 2)
  hubnet-send user-id "Cumulative-Shortage-cost" (word "$ " precision (sum shortage * profit_per_unit) 2)
end
@#$#@#$#@
GRAPHICS-WINDOW
1022
10
1875
864
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
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
412
244
494
277
Initialize
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
739
524
911
557
No_of_customers
No_of_customers
1
5000
510.0
1
1
NIL
HORIZONTAL

SLIDER
752
68
924
101
No_of_carriers
No_of_carriers
1
20
8.0
1
1
NIL
HORIZONTAL

SLIDER
92
72
264
105
No_of_shops
No_of_shops
1
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
732
114
940
147
No_of_vehicles
No_of_vehicles
2
50
10.0
1
1
per carrier
HORIZONTAL

SLIDER
38
521
280
554
Avg.Price_per_unit
Avg.Price_per_unit
2
100
9.0
1
1
$/unit
HORIZONTAL

SLIDER
440
376
612
409
Iterations
Iterations
1
500
30.0
1
1
NIL
HORIZONTAL

SLIDER
62
124
293
157
Average_shop_area
Average_shop_area
100
100000
31090.0
5
1
m^2
HORIZONTAL

SLIDER
9
220
354
253
Average_daily_demand_for_shops
Average_daily_demand_for_shops
10
30000
2062.0
1
1
units (estimate)
HORIZONTAL

SLIDER
29
272
321
305
Std_dev_daily_demand_for_shops
Std_dev_daily_demand_for_shops
10
500
82.0
1
1
units
HORIZONTAL

SLIDER
733
160
951
193
Capacity_per_vehicle
Capacity_per_vehicle
100
10000
10000.0
1
1
units
HORIZONTAL

SLIDER
679
209
1007
242
Average_carrier_fixed_cost
Average_carrier_fixed_cost
2
150
68.0
1
1
per order delivery
HORIZONTAL

SLIDER
720
256
985
289
Carrier_profit_percentage
Carrier_profit_percentage
2
100
5.0
1
1
percent
HORIZONTAL

SLIDER
23
568
295
601
Floor_area_occupied_by_a_unit
Floor_area_occupied_by_a_unit
2
35
3.0
1
1
m^2
HORIZONTAL

SLIDER
60
173
301
206
Shops_avg_profit_per_unit
Shops_avg_profit_per_unit
1
35
5.0
1
1
$
HORIZONTAL

SLIDER
687
570
964
603
Average_customer_orders
Average_customer_orders
1
100
44.0
1
1
uiits/day
HORIZONTAL

BUTTON
551
246
636
279
Go Once
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

BUTTON
498
298
561
331
Start
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
32
618
275
651
interest_rate
interest_rate
0.5
20
0.5
0.05
1
percentage/day
HORIZONTAL

MONITOR
453
94
597
139
Shops placing orders
sum total_orders_placed_by_shops
17
1
11

MONITOR
439
148
612
193
Vehicles delivering orders
sum vehicles_delivering_orders
17
1
11

MONITOR
495
16
555
77
Day
Day_counter
0
1
15

SLIDER
43
671
269
704
Area_purchase_cost
Area_purchase_cost
0
100
2.0
1
1
$/m^2
HORIZONTAL

TEXTBOX
39
471
302
500
Variables Effecting Costs
20
0.0
1

TEXTBOX
717
472
932
504
Adjust Demand Here
20
0.0
1

TEXTBOX
750
22
937
61
Carrier Attributes
20
0.0
1

TEXTBOX
66
17
293
48
Shop Agent Attributes
20
0.0
1

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
SLIDER
115
67
288
100
Shop-area
Shop-area
1.0
50000.0
0
10.0
1
m^2
HORIZONTAL

SLIDER
296
67
506
100
Profit-per-unit
Profit-per-unit
1.0
15.0
0
1.0
1
$
HORIZONTAL

MONITOR
20
435
177
484
Max-stock-level
NIL
0
1

BUTTON
600
203
760
236
Complete_setup_of_shop
NIL
NIL
1
T
OBSERVER
NIL
NIL

VIEW
781
68
1382
585
0
0
0
1
1
1
1
1
0
1
1
1
-32
32
-32
32

INPUTBOX
204
117
382
177
Reorder-point
0.0
1
0
Number

INPUTBOX
20
117
169
177
Saftey-stock
0.0
1
0
Number

MONITOR
22
503
175
552
Cumulative-Shortage
NIL
3
1

MONITOR
202
504
364
553
Undelivered-inventory
NIL
3
1

MONITOR
619
503
714
552
Ordering-cost
NIL
2
1

MONITOR
202
435
364
484
Current-inventory-level
NIL
0
1

MONITOR
395
464
579
513
Current-customer-demand
NIL
0
1

MONITOR
1053
10
1110
59
Day
NIL
0
1

INPUTBOX
403
118
563
178
Daily-demand-estimate
0.0
1
0
Number

MONITOR
18
764
659
813
System-Message
NIL
0
1

BUTTON
268
642
395
675
Order_decision
NIL
NIL
1
T
OBSERVER
NIL
NIL

SLIDER
23
642
221
675
Order-quantity
Order-quantity
0.0
9000.0
0
1.0
1
units
HORIZONTAL

MONITOR
20
194
545
243
Shipper-info
NIL
0
1

BUTTON
132
254
226
287
View-next
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
22
253
120
286
View-previous
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
284
255
386
288
Select-shipper
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
21
306
544
355
Selected-shipper
NIL
0
1

MONITOR
622
433
714
482
Selling-price
NIL
2
1

MONITOR
1219
692
1382
741
Total-cost
NIL
0
1

MONITOR
1018
838
1123
887
Inventory-cost
NIL
0
1

MONITOR
1144
838
1260
887
Purchasing-cost
NIL
0
1

MONITOR
1281
838
1384
887
Order-cost
NIL
0
1

MONITOR
1241
772
1383
821
Cumulative-Shortage-cost
NIL
0
1

TEXTBOX
928
625
1212
687
Performance Monitors
25
0.0
1

TEXTBOX
19
385
371
447
Inventory & Cost Monitors
25
0.0
1

TEXTBOX
24
589
400
651
Inventory Replenishment
25
0.0
1

TEXTBOX
24
15
174
46
Setup
25
0.0
1

TEXTBOX
20
714
233
776
System Message
25
0.0
1

MONITOR
1092
773
1211
822
Shop-setup-cost
NIL
2
1

INPUTBOX
597
119
746
179
Fill-rate
0.0
1
0
Number

MONITOR
546
633
657
682
Total-orders-placed
NIL
0
1

MONITOR
926
683
1070
732
Total-Revenue
NIL
2
1

MONITOR
782
682
905
731
Total-profit
NIL
2
1

MONITOR
889
839
1001
888
Shortage-cost
NIL
2
1

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
