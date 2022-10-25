var express = require('express');

// VVV Where I store data VVV **************************************************************************************************************

var deck = [];

var publicInfo = {};

var privateInfo = {};

var values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "0", "J", "Q", "K"];
var points = ["x", 2, 3, 4, 5, 6, 7, 8, 9, 10, 10 , 10, 10];
var suits  = [ "Spades", "Hearts", "Clubs", "Diamonds"];

function newPublicInfo() {
     var publicInfo = {
          "state": "notStarted",
          "status" : "",
          "dealersCards": [
               {}
          ],
          "player": {
               "cards": [
                    {}
               ],
               "score": "0"
          },
          "availableMoves": [
               "newGame"
          ],
          "success":false
     }
     return publicInfo;
}

function newPrivateInfo() {
     var privateInfo = {
          "state": "notStarted",
          "dealer": {
               "cards": [{
                    "value":"",
                    "suit":"",
                    "image":"",
                    "point":0,
                    "visible":false
               }],
               "score": {}
          },
          "player": {
               "cards": [{}],
               "score": {}
          },
     }
     return privateInfo;
}

// VVV These deal with data manipulation VVV **************************************************************************************************************

function shuffle() {
     var cards = [];
     for(var s=0;s<suits.length;++s) {
          for(var v=0;v<values.length;++v) {
               cards.push({value:values[v],point:points[v],suit:suits[s]});
          }
     }
     return cards;
}

function drawCard() {
     if(deck.length === 0) {
          deck = shuffle();
     }
     var randomNumber = Math.random();
     var randomIndex  = Math.floor(randomNumber * deck.length);
     var card = deck[randomIndex];
     deck.splice(randomIndex,1);
     card.image = "https://deckofcardsapi.com/static/img/" + card.value + card.suit[0] + ".png"
     card.visible = true;  //this is assumed and the code that called it will change it if necessary
     card.animate = true; //This will be set true, but after the called function sends the data, it will need to call unsetAnimate()

     return card;
}

function unsetAnimate() {
     for(var i=0;i<privateInfo.dealer.cards.length;++i) {
          privateInfo.dealer.cards[i].animate = false;
          publicInfo.dealersCards[i].animate = false;
     }

     for(var i=0;i<privateInfo.player.cards.length;++i) {
          privateInfo.player.cards[i].animate = false;
          publicInfo.player.cards[i].animate = false;
     }
}

function deal() {
     deck = shuffle();
     publicInfo = newPublicInfo();
     privateInfo = newPrivateInfo();

     for(var i=0;i<2;++i) {
          privateInfo.dealer.cards[i] = drawCard();
          privateInfo.player.cards[i] = drawCard();
     }
     publicInfo.player = privateInfo.player;

     privateInfo.dealer.cards[0].visible = false;
     privateInfo.dealer.cards[0].image = "cardback.png"

     publicInfo.dealersCards[0].visible = privateInfo.dealer.cards[0].visible;
     publicInfo.dealersCards[0].image = privateInfo.dealer.cards[0].image;
     publicInfo.dealersCards[0].animate = privateInfo.dealer.cards[0].animate;
     publicInfo.dealersCards[1] = privateInfo.dealersCards[1];
}

function calculateScores() {
     var playerScore = sumOfPlayer();
     privateInfo.player.score = playerScore;
     publicInfo.player.score = playerScore;

     privateInfo.dealer.score = sumOfDealer();
}

// VVV These deal with reading from data VVV **************************************************************************************************************

function sumOfPlayer() {
     var score = {'value': 0, 'isSoft': false};

     for(var i=0;i<privateInfo.player.cards.length;++i) {
          var card = privateInfo.player.cards[i];

          if(card.point === 'x') {
               if(score.value >= 11) {
                    score.value += 1;
               } else {
                    score.value += 11;
                    score.isSoft = true;
               }
          } else {
               if(score.value + card.point > 21 && score.isSoft) {
                    score.value += (card.point - 10);
                    score.isSoft = false
               } else {
                    score.value += card.point;
               }
          }
     }
     return score;
}

function sumOfDealer() {
     var score = {'value': 0, 'isSoft': false};

     for(var i=0;i<privateInfo.dealer.cards.length;++i) {
          var card = privateInfo.dealer.cards[i];

          if(card.point === 'x') {
               if(score.value >= 11) {
                    score.value += 1;
               } else {
                    score.value += 11;
                    score.isSoft = true;
               }
          } else {
               if((score.value + card.point) > 21 && score.isSoft) {
                    score.value += (card.point - 10);
                    score.isSoft = false
               } else {
                    score.value += card.point;
               }
          }
     }
     return score;
}



// VVV These handle all the URL calls VVV **************************************************************************************************************

var app = express();

app.get('/startgame', function(req,res) {
     deal();
     /*
     check for insurance
		y: request if player wants insurance **
		break;
	check for [natural] blackjacks
		deal && play: It's a push, nobody wins (also bet stays static)
		deal: Player looses (also bet goes to house)
		play: Player wins (also calculate winnings)
		break;
	check for split
		y: offer double, split, surrender, hit, stand
		n: offer double, surrender, hit, stand
		break;
     */
     res.send(publicInfo);
     unsetAnimate();
     console.log(publicInfo);
});

app.get('/debug',function(req,res) {
     res.send(publicInfo);
});

app.get('/hit', function(req,res) {
     var index = privateInfo.player.cards.length; //get the index number to the next slot
     privateInfo.player.cards[index] = drawCard(); //draw card
     publicInfo.player.cards[index] = privateInfo.player.cards[index];

     publicInfo.state = "waitingOnPlayer";
     publicInfo.status = "hit";

     res.send(publicInfo);
     unsetAnimate();
});

app.use(express.static('public'));

// VVV Just the initialize of app VVV **************************************************************************************************************

var server = app.listen(8081, function () {
     var host = server.address().address;
     var port = server.address().port;
     console.log("Example app listening at http://%s:%s", host, port);
});
