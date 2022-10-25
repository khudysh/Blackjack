var URL = "http://localhost:8081/";

// VVV This is where I store info VVV **************************************************************************************************************

var info = {};

// VVV These are my functions for client to server operations VVV **************************************************************************************************************

var firstDraw = function() {
     $.getJSON(URL + 'startgame',function(dat,stat){
          info = dat;
          drawCards();
     });
}

var hit = function() {
     $.getJSON(URL+ 'hit', function(dat,stat) {
          info=dat;
          drawCards();
     });
}

var stand = function() {

}

var shuffle = function() {
     $.getJSON(beginURL + shuffleURL,function(dat,stat){

     });
}

// VVV Thse are my functions for client only operations (the GUI) VVV **************************************************************************************************************

function clearCards() {
     $("div.cardSlot").remove();
}

function drawCards() {
     //deal the dealers cards
     if(!info.dealersCards[0].visible && info.dealersCards[0].animate) {
          $("div#DealersTable").append('<div class="cardSlot"><img class="cardBack" src="cardBack.png"></img></div>');
          $("img.cardBack:first").css("-webkit-animation-play-state", "paused");
     }
     for(var i=1;i<info.dealersCards.length;++i) {
          if(info.dealersCards[i].animate) {
               $("div#DealersTable").append('<div class="cardSlot"><img class="cardFront" src="' + info.dealersCards[i].image + '"></img><img class="cardBack" src="cardBack.png"></img></div>');
          }
     }

     //deal the players cards
     for(var i=0;i<info.player.cards.length;++i) {
          if(info.player.cards[i].animate) {
               $("div#PlayersTable").append('<div class="cardSlot"><img class="cardFront" src="' + info.player.cards[i].image + '"/><img class="cardBack" src="cardBack.png"/></div>');
          }
     }
}

//initialize
firstDraw();
