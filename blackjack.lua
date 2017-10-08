
-- Let the program stops temporarily to create basic animation
function sleep (a)
  local sec = tonumber(os.clock() + a);
  while (os.clock() < sec) do
  end
end

-- Setting the randomness seed
math.randomseed(os.time())

-- Function to copy Tables (keeping a table of a new deck)
function table.clone(org)
  return {table.unpack(org)}
end

-- Clears the Terminal screen (When redrawing the play area)
function clear()
  os.execute("clear")
end

-- Initializing the Player class for user and dealer
Player = {}
Player.__index = Player

function Player:new (o)
     o = o or {}   -- create object if user does not provide one
     setmetatable(o, self)
     self.__index = self
     self.name = ""
     self.choice = 0
     self.total = 0
     self.money = 0
     self.bet = 0
     return o
end

function Player:set_name(name)
  self.name = name
end

function Player:hit(deck)
   table.insert(self.hand, draw(deck))
end

function Player:win(amount)
  self.money = self.money + (self.bet * amount)
  self.bet = 0
end

-- Empties the hand and gets ready for a new deal
function Player:empty_hand()
 for i in pairs (self.hand) do
   self.hand[i] = nil
 end
end

-- Draws a random card from the deck "drawFrom" and removes the
-- card each time to make sure it is not drawn twice.
-- Returns the drawn card value as output
function draw(deck)
    local n = #deck
    local pos = math.random(n)
    local cardDrew = deck[pos]
    table.remove(deck, pos)
    return cardDrew
end

-- Draws/Updates the play area on the table
function redrawTable()
  clear()

  io.write("You: ")
  for i = 1, #user.hand do
    io.write(user.hand[i] .. " ")
  end
  io.write("(" .. user:count_hand() .. ")")

  io.write("\nDealer: ")
  for i = 1, #dealer.hand do
    io.write(dealer.hand[i] .. " ")
  end
  io.write("(" .. dealer:count_hand() .. ")")
  io.write("\n\n")
  io.write("Your bet:" .. user.bet .. "\n")
end

-- Calculates the hand total after every hit
function Player:count_hand()
    local total = 0
    local softHand = false
    local softHandCount = 0

    for i = 1, #self.hand do
      local value = self.hand[i]

      if value == 'J' or value == 'Q' or value == 'K' then
        value = 10
      elseif value == 'A' then
        value = 11
        softHand = true
        softHandCount = softHandCount + 1
      end

      total = total + value
    end

    if total > 21 and softHand == true then
      total = total - (softHandCount * 10)
    end

    return total
end

-- main loop of the game
function game ()
  while true do

    bet()

    newDeal()

    playerTurn()

    dealerTurn()

    compare()

    -- pay()

  end
end

-- Asks the user to place a bet
-- TODO: Limit to integers, and prevent alphabetic entries (Causes an infinite loop)
function bet()

  if user.money < 1 then -- If user has 0.50 left, he cannot play it, so the game ends
    clear()
    io.write("You are out of money. Thank you for playing. You may now leave the casino...\n")
    sleep(5)
    os.exit()
  end

  repeat
    user.bet = 0
    io.write("You have " .. user.money .. "\n" .. "How much do you want to bet: ")
    user.bet = math.floor(io.read("*numbers"))
  until user.bet > 0 and user.bet <= user.money

  user.money = user.money - user.bet
end


-- Deals the first two cards to dealer and player
-- TODO: Check for Blackjack and insurance
function newDeal()
-- Clears the screen and instantiate a new deck to draw from
  skipDealerTurn = 0
  user:empty_hand()
  dealer:empty_hand()

  drawFrom = table.clone(newDeck)

  for i = 1, 2 do
    user:hit(drawFrom)
  end
  dealer:hit(drawFrom)

  redrawTable()
end

-- Start of the Player's turn
function playerTurn()
  while true do

    if user:count_hand() == 21 and #user.hand == 2 then
      io.write("BLACKJACK!! Your turn is done and you WIN!\n")
      skipDealerTurn = 1
      user:win(2.5)
      sleep(5)
      break
    end

    io.write("What will you do?\n")
    io.write("(1) Hit\n")
    io.write("(2) Stay\n")
    if #user.hand == 2 then
      io.write("(3) Double\n")
    end
    if user.hand[1] == user.hand[2] then
      io.write("(4) Split\n")
    end
    io.write("(5) Quit\n")

      repeat
        user.choice = 0
        io.write("Command: ")
        user.choice = math.floor(io.read("*numbers"))
      until user.choice > 0 and user.choice <= 5 and user.choice ~= nil

      if user.choice == 1 then
        user:hit(drawFrom)
        redrawTable()


        if user:count_hand() > 21 then
          io.write("\nYou went over 21. Try again.\n")
          skipDealerTurn = 1
          sleep(5)
          clear()
          break
        elseif user:count_hand() == 21 then
          io.write("\nTWENTY ONE!! Your turn is done!\n")
          sleep(5)
          break
        end

      elseif user.choice == 2 then
        clear()
        break

      elseif user.choice == 3 then
        if user.money > user.bet * 2 then
          user.money = user.money - user.bet
          user.bet = user.bet * 2
          clear()
          redrawTable()
          io.write("Double down for one card! Good luck! Your turn is done!\n")
          sleep(3)
          user:hit(drawFrom)

          if user:count_hand() > 21 then
            io.write("\nYou went over 21. Try again.\n")
            skipDealerTurn = 1
            sleep(5)
            clear()
            break
          elseif user:count_hand() == 21 then
            io.write("\nTWENTY ONE!! Your turn is done!\n")
            sleep(5)
            break
          end

          redrawTable()
          break
        else
          io.write("You don't have enough credit to double your bet.\n")
          redrawTable()
        end


      elseif user.choice == 4 then
        -- TODO: Split()
        os.exit()
      elseif user.choice == 5 then
        os.exit()
      end --End the choices "if"s
  end
end

function dealerTurn()

  while dealer:count_hand() < 17 do
    if skipDealerTurn == 1 then
      break
    end
    dealer:hit(drawFrom)
    clear()
    redrawTable()
    io.write("Dealer's turn...\n")
    sleep(3)
    if dealer:count_hand() > 21 then
      io.write("Dealer busts! You win " .. user.bet .. " credits!\n")
      user:win(2)
      sleep(4)
      break
    end
  end
end

-- Evaluates the player's and dealer's cards, Returns a numeric value and a winner
function compare()
  if user:count_hand() > dealer:count_hand() then
    io.write("You win! You receive " .. user.bet .. " credits!\n")
    user:win(2)
  else
    io.write("Dealer wins. Please try again.\n")
  end
end


-- First logic of the program: Setting up basic variables.

borrow = 0

newDeck = {"A", 2, 3, 4, 5, 6, 7, 8, 9 , 10, "J", "Q", "K",
 "A", 2, 3, 4, 5, 6, 7, 8, 9 , 10, "J", "Q", "K",
 "A", 2, 3, 4, 5, 6, 7, 8, 9 , 10, "J", "Q", "K",
 "A", 2, 3, 4, 5, 6, 7, 8, 9 , 10, "J", "Q", "K"}

user = Player:new({hand = {}}) -- Instantiates the user and dealer objects
dealer = Player:new({hand = {}})

user.name = "Player"
dealer.name = "Dealer"

user.money = 1000 -- Sets the player starting money

---------------------------------------------------
-- Start of main program, and displays main menu --
---------------------------------------------------

clear()

io.write("\n" .. [[Welcome to Blackjack]] .. "\n")

sleep(1)

io.write("\n" .. [[By TuxMan20]] .. "\n\n")

sleep(1)

io.write("Current credit: " .. user.money .. "\n\n")

sleep(1)

io.write("\n" .. [[Please choose an option:
(1) New Game
(2) Add Credits
(3) Quit]] .. "\n\n")

repeat
  io.write("Command: ")
  user.choice = math.floor(io.read("*numbers"))
until user.choice > 0 and user.choice <= 3

if user.choice == 1 then
  game()
elseif user.choice == 2 then
  -- TODO: addCredit()
  io.write("Choice 2\n")
elseif user.choice == 3 then
  os.exit()
end
