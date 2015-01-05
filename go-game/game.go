package main

import (
	"math/rand"
)

const (
	maxCard = 12
)

// last is the last thing played, which needs to get sent to clients
// might not need/want it as part of state.
type gameState struct {
	hands []map[int]int
	last []int
	numPlayers int
	started bool
}

var globalState = gameState{
	hands: make([]map[int]int, 10), // TODO: fix this 10
	last: make([]int,0),
	numPlayers: 0,
	started: false,

}

func makeDeck() []int {
	deck := make([]int, 0)
	// Put cards into deck to be shuffled.
	for i := 0; i <= maxCard; i++ {
		if (i == 0) { 
			// TODO: wildcards.
		} else {
			// Deal out i cards of value i
			for j := 0; j < i; j++ {
				deck = append(deck, i);
			}
		}
		
	}
	return deck
}

func shuffleDeck(deck []int) []int {
	shuffledDeck := make([]int, len(deck))
	perm := rand.Perm(len(deck))
	for i, v := range perm { shuffledDeck[v] = deck[i] }
	return shuffledDeck
}

func dealDeck(state *gameState, deck[]int, numPlayers int) {
	for i, card := range deck {
		_, ok := state.hands[i % numPlayers][card] 
		if !ok {
			state.hands[i % numPlayers][card] = 0
		}
		state.hands[i % numPlayers][card] += 1
	}	
}

func (all *hub) run() {
	numPlayers := 0
	for {
		select {
		case c := <-all.register:
			all.connections[c] = true
			numPlayers++
			if numPlayers == 2 {
				go func() {all.ready <- true;}() // This seems bad.
			}
		case c := <-all.unregister:
			if _, ok := all.connections[c]; ok {
				delete(all.connections, c)
				close(c.send)
			}
		case b := <-all.ready:
			deck := makeDeck()
			shuffledDeck := shuffleDeck(deck)
			dealDeck(&globalState, shuffledDeck, numPlayers)
			
			if b {
				message := GameMessage{"start_game",0,[]string{}}
				sendToAll(*all, message)
			}
		case <-all.broadcast:
			m := GameMessage{"echo",0,[]string{}}
			sendToAll(*all, m)
		}
		
	}
}
