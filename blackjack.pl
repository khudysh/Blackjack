:- use_module(library(lists), [nth0/3]).
:- use_module(library(random), [random/3]).
:- dynamic card/2, cash/1, cardInHands/3, currentPlayer/1, bet/1, totalBet/1, duplicateGroup/1, groups/2, totalGroup/1, currentGroup/1, firstDealerCard/1, blackjack/0.
:- retractall(cash(_)), assert(cash(1000)).
:- retractall(currentPlayer(_)).
:- retractall(bet(_)).
:- retractall(totalBet(_)).

%Карты в игре. 6 колод
cardsShuffle :-
    retractall(card(_,_)),
    assert(card('A', 24)),
    assert(card(2, 24)),
    assert(card(3, 24)),
    assert(card(4, 24)),
    assert(card(5, 24)),
    assert(card(6, 24)),
    assert(card(7, 24)),
    assert(card(8, 24)),
    assert(card(9, 24)),
    assert(card(10, 24)),
    assert(card('J', 24)),
    assert(card('Q', 24)),
    assert(card('K', 24)).
    
:- retractall(card(_,_)), cardsShuffle.

currentPlayer('I').
bet(0).
    
%************************************************************
%Вспомогательные предикаты

sumLists([], 0).
sumLists([H|T], S) :-
    sumLists(T, S1),
    S is S1 + H.
    
% Суммирует все карты в руках игрока. A превращается в 11, а JQK по 10
cardsSum([], 0).
cardsSum([H|T], Z) :-
    cardsSum(T, Z1),
    (H == 'A' -> Z is Z1 + 11 ;
    (
       ((H == 'J' ; H == 'Q' ; H == 'K') -> Z is Z1 + 10 ;
           Z is Z1 + H
       )
    )).
    
    
numberOfDuplicatedGroups(N) :-
    findall(X, (groups(X,w), duplicateGroup(X)), L),
    length(L, N).

numberOfUnduplicatedGroups(N) :-
    findall(X, (groups(X,w), not(duplicateGroup(X))), L),
    length(L, N).
    
numberOfPushedDuplicatedGroups(N) :-
    findall(X, (groups(X,p), duplicateGroup(X)), L),
    length(L, N).
    
numberOfPushedUnduplicatedGroups(N) :-
    findall(X, (groups(X,p), not(duplicateGroup(X))), L),
    length(L, N).
    
    
hasTwoIdenticalCards :-
    currentGroup(G),
    findall(X, cardInHands('I', X, G), L),
    nth0(0, L, K1), nth0(1, L, K2),
    (K1 == K2; K1 == 'A', K2 == 1; K1 == 1, K2 == 'A').
    
    
svigrupePreko21 :-
    zbrojiKarte(Z1, 'I', 1), zbrojiKarte(Z2, 'I', 2),
    zbrojiKarte(Z3, 'I', 3), zbrojiKarte(Z4, 'I', 4),
    Z1 > 21, Z2 > 21, Z3 > 21, Z4 > 21.
    
    
postaviIshodGrupe(Grupa, Ishod) :-
    retract(groups(Grupa, _)),
    assert(groups(Grupa, Ishod)).
    
%************************************************************

% Смена игрока
promijeniIgracaNaPotezu :-
    retract(currentPlayer(I)),
    (I == 'I' -> assert(currentPlayer('D')); assert(currentPlayer('I'))).
    
% этот предикат инициализирует игру для новой раздачи
gamePrepare :-
    retractall(cardInHands(_,_,_)),  % аргументы: игрок (дилер или другой игрок), карта, группа. Третий аргумент (группа) представляет группу, в которую будет перемещена карта после разделения пары карт.
    retractall(duplicateGroup(_)),
    retractall(groups(_,_)),
    retractall(totalGroup(_)),
    retractall(currentGroup(_)),
    retractall(totalBet(_)),
    retractall(firstDealerCard(_)),
    retractall(blackjack),
    assert(groups(1, u)), %представляет все группы, которые есть у игрока (с соответствующими индексами). Второй аргумент может быть: w (win - победа в этой группе над дилером), l (lose - проигрыш в этой группе над дилером), p (push - ни выигрыша, ни проигрыша в этой группе у дилера, равное количество карты), u (unknown - победа или поражение еще не известно)
    assert(currentGroup(1)),
    assert(totalGroup(1)),
    assert(totalBet(0)).

% дает одну случайную карту из колоды. Учитываются только те карты, которые СУЩЕСТВУЮТ в колоде
randomKarta(Karta) :-
    random(0, 13, Rnd),
    nth0(Rnd, ['A', 2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K'], K),
    card(K, N),
    (N =:= 0 -> (!, randomKarta(Karta)) ; Karta = K).

% берет карту из колоды и уменьшает количество карт этого типа в колоде
izvuciKartu(Karta) :-
    randomKarta(Karta),
    retract(card(Karta, N)),
    N1 is N - 1,
    assert(card(Karta, N1)).


% возвращает общую карту, преобразуя все факты карты в лист и добавляя их
totalCardsNumber(N) :-
    findall(X, card(_, X), L), !,
    sumLists(L, N).
    
    
% возвращает количество карт в руке игрока
brojKartiURukama(I, Broj, Grupa) :-
    findall(K, cardInHands(I, K, Grupa), L),
    length(L, Broj).
    
% возвращает true, если игрок может разделиться. А именно: если у него две одинаковые карты и если он уже сплитил меньше 3-х раз (то есть если всего групп меньше 4-х)
mozesplitati :-
    currentGroup(G),
    brojKartiURukama('I', 2, G),
    hasTwoIdenticalCards,
    totalGroup(U), U < 4.


% берет деньги с игроков
uzmiNovac(X) :-
    retract(cash(Novac)), Novac2 is Novac - X,
    assert(cash(Novac2)),
    retract(totalBet(U)),
    U1 is U + X, assert(totalBet(U1)).
    
% предикат для входа в начальную роль
placeBet :-
    write('Bet: '), read(X),
    cash(Novac), X =< Novac,
    uzmiNovac(X),
    retractall(bet(_)), assert(bet(X)).
    
placeBet :-
    write('Bet: '), read(X),
    cash(Novac), X > Novac,
    write('Too much! You have only: '), write(Novac), write(' $'), nl,
    !, placeBet.
    

    
% I - игрок, D дилер
cardsDealing(D2) :-
    izvuciKartu(I1), izvuciKartu(D1), izvuciKartu(I2), izvuciKartu(D2),
    assert(cardInHands('I', I1, 1)), assert(cardInHands('D', D1, 1)), assert(cardInHands('I', I2, 1)), assert(cardInHands('D', D2, 1)),
    assert(firstDealerCard(D1)),
    writeln('New distribution. Cards:'),
    write('Dealer: '), write(D1), write(' '), write('X'), nl,
    write('Player: '), write(I1), write(' '), write(I2), nl.


% берет карту из колоды и добавляет ее в руку игрока
uzmiKartu(Karta) :-
    currentPlayer(I),
    izvuciKartu(Karta), currentGroup(G),
    assert(cardInHands(I, Karta, G)).
   

% добавляет карты определенного игрока. Сначала он складывает все тузы как одиннадцать, а если общее значение превышает 21, то по одному тузу за раз (меняет столько единиц, сколько необходимо)
zbrojiKarte(Z, I, Grupa) :-
    findall(K, cardInHands(I,K,Grupa), L),
    cardsSum(L, Z1),
    (Z1 > 21 ->
    (
       cardInHands(I, 'A', Grupa) -> (retract(cardInHands(I, 'A', Grupa)), assert(cardInHands(I, 1, Grupa)), !, zbrojiKarte(Z, I, Grupa)); (Z is Z1)
    ); Z is Z1).
    

% если игрок получил блэкджек сразу с первыми двумя картами. В этом случае казино платит в соотношении 3:2.
isplatiIgracaZaBlackjackWin :-
    writeln('WIN!'),
    cash(NovacIgraca), bet(UlogIgraca), NovaVrijednostNovca is NovacIgraca + 1.5 * UlogIgraca,
    retract(cash(_)), assert(cash(NovaVrijednostNovca)), assert(blackjack).
    
% Если и игрок, и дилер получили блэкджек сразу с первыми двумя картами, это push, и деньги возвращаются игроку.
isplatiIgracaZaBlackjackPush :-
    writeln('PUSH'),
    cash(NovacIgraca), bet(UlogIgraca), NovaVrijednostNovca is NovacIgraca + UlogIgraca,
    retract(cash(_)), assert(cash(NovaVrijednostNovca)), assert(blackjack).

% дает игроку деньги, учитывая количество выигранных групп, количество выигранных удвоенных групп и количество пропушенных групп
isplatiIgracuNovac(Dobiveno) :-
    cash(Novac), bet(Ulog),
    numberOfDuplicatedGroups(N1),
    numberOfUnduplicatedGroups(N2),
    numberOfPushedDuplicatedGroups(N3),
    numberOfPushedUnduplicatedGroups(N4),
    Dobiveno is 4 * N1 * Ulog + 2 * (N2 + N3) * Ulog + N4 * Ulog,
    NovaVrijednostNovca is Novac + Dobiveno,
    retract(cash(_)), assert(cash(NovaVrijednostNovca)).



dupliraj(X) :-
    assert(duplicateGroup(X)).

% этот предикат берет другую карту и помещает ее в новую группу. После этого он добавляет в старую группу еще одну карту и записывает, какая это карта.
splitaj :-
    currentGroup(G),
    findall(X, cardInHands('I', X, G), L),
    nth1(2, L, K),
    retract(cardInHands('I', K, G)),
    NovaPozicija is G + 1,
    assert(cardInHands('I', K, NovaPozicija)),
    assert(groups(NovaPozicija, u)),
    uzmiKartu(Karta), write('New card: '), write(Karta), write(', Group: '), write(G), nl.
    
% если это последняя группа игроков, мы останавливаем игру, а дилер продолжает
sljedecaGrupa :-
    currentGroup(G), totalGroup(G).

% если это не последняя группа игроков, мы увеличиваем текущую группу и требуем ввода игроков для следующей группы
sljedecaGrupa :-
    currentGroup(T), totalGroup(U),
    T < U, T1 is T + 1,
    retract(currentGroup(_)), assert(currentGroup(T1)), !,
    (currentPlayer('I') -> ( writeln('Next group'), poteziIgraca('I') ); izvrsiPotezDealera ).


% когда дилер начнет играть, он должен будет сравнить свою руку со всеми своими картами. Поэтому перед этим необходимо установить текущую группу игроков на 1
postaviNaPrvuGrupu :-
    retractall(currentGroup(_)),
    assert(currentGroup(1)).


% Дилер всегда будет использовать hit, если сумма его карт меньше 17.
% если дилер решит "hit" (только если сумма его карт меньше 17)
izvrsiPotezDealera :-
    zbrojiKarte(Z, 'D', 1), Z < 17,
    uzmiKartu(Karta), writeln(Karta), !,
    izvrsiPotezDealera.

% если дилер решает stand, то карты обоих игроков суммируются.
% Если дилер прошел 21
izvrsiPotezDealera :-
    zbrojiKarte(Z, 'D', 1), Z > 21,
    writeln('WIN!'),
    currentGroup(G),
    postaviIshodGrupe(G, w), !,
    sljedecaGrupa.
    
% Если дилер решает stand и если игрок прошел 21
izvrsiPotezDealera :-
    currentGroup(G),
    zbrojiKarte(ZbrojDealera, 'D', 1), ZbrojDealera >= 17, ZbrojDealera =< 21, zbrojiKarte(ZbrojIgraca, 'I', G),
    ZbrojIgraca > 21, !,
    sljedecaGrupa.
    
% Если игрок выиграл
izvrsiPotezDealera :-
    currentGroup(G),
    zbrojiKarte(ZbrojDealera, 'D', 1), ZbrojDealera >= 17, ZbrojDealera =< 21, zbrojiKarte(ZbrojIgraca, 'I', G),
    ZbrojIgraca > ZbrojDealera,
    writeln('WIN!'),
    postaviIshodGrupe(G, w), !,
    sljedecaGrupa.

% Если дилер решает stand и если у дилера и другого игрока одинаковая сумма карт
izvrsiPotezDealera :-
    currentGroup(G),
    zbrojiKarte(Zbroj, 'D', 1), Zbroj >= 17, Zbroj =< 21, zbrojiKarte(Zbroj, 'I', G),
    writeln('PUSH!'),
    postaviIshodGrupe(G, p), !,
    sljedecaGrupa.

% Если дилер решает stand и если игрок проиграл
izvrsiPotezDealera :-
    currentGroup(G),
    zbrojiKarte(ZbrojDealera, 'D', 1), ZbrojDealera >= 17, ZbrojDealera =< 21, zbrojiKarte(ZbrojIgraca, 'I', G),
    ZbrojDealera > ZbrojIgraca,
    writeln('LOSE!'),
    postaviIshodGrupe(G, l), !,
    sljedecaGrupa.

    

% вызывается один из предикатов, в зависимости от того, какой вариант выбран (hit, stand, double, split)
izvrsiPotezIgraca(s) :-
    !, sljedecaGrupa.
    
% если у игрока нет равных карт или если игрок уже трижды делился (всего групп четыре), то игрок не может снова разделить.
izvrsiPotezIgraca(p) :-
    not(mozesplitati),
    writeln('It is not possible to split!'),
    poteziIgraca('I').

% если у игрока нет равных карт или если игрок уже трижды делился (всего групп четыре), то игрок не может снова разделить.
izvrsiPotezIgraca(p) :-
    retract(totalGroup(U)), !, U1 is U + 1,
    assert(totalGroup(U1)),
    splitaj,
    bet(Ulog), uzmiNovac(Ulog), !,  % берем больше денег с игрока, так как он использовал сплит
    poteziIgraca('I').
    
izvrsiPotezIgraca(h) :-
    currentGroup(G),
    totalGroup(U),
    uzmiKartu(Karta), zbrojiKarte(Z, 'I', G),
    write('New card: '), write(Karta), ( U > 1 -> (write(', Group: '), write(G)); true ), nl, !,
    ( Z > 21 -> ( writeln('BUST!'), postaviIshodGrupe(G, l), sljedecaGrupa ); poteziIgraca('I') ).
    

izvrsiPotezIgraca(d) :-
    currentGroup(G),
    brojKartiURukama('I', N, G), N > 2,
    writeln('It is not possible to duplicate! You have more than 2 cards in your hand.'),
    poteziIgraca('I').
    

% если у игрока на руках 2 карты, то он может удвоить
izvrsiPotezIgraca(d) :-
    uzmiKartu(Karta), currentGroup(G),
    totalGroup(Uk),
    write('New card: '), write(Karta), ( Uk > 1 -> (write(', Group: '), write(G)); true ), nl,
    bet(U), uzmiNovac(U),  % берем больше денег с игрока, так как он использовал удвоение
    dupliraj(G),
    zbrojiKarte(Z, 'I', G), !,
    ( Z > 21 -> ( writeln('BUST!'), postaviIshodGrupe(G, l), sljedecaGrupa ); sljedecaGrupa ).



% если настала очередь дилера, а у игрока ранее был блэкджек (без сплитов), то дилер пропускает игру
poteziIgraca('D') :-
    zbrojiKarte(21, 'I', 1), brojKartiURukama('I', 2, 1),
    totalGroup(1).

% если настала очередь дилера, а у игрока ранее была меньшая сумма, равная 21
poteziIgraca('D') :-
    currentGroup(Grupa),
    zbrojiKarte(ZbrojIgraca, 'I', Grupa), ZbrojIgraca =< 21,
    zbrojiKarte(ZbrojDealera, 'D', 1),
    (ZbrojDealera < 17 -> writeln('Dealer new card: '); true), izvrsiPotezDealera.
    
% если настала очередь дилера, а у игрока ранее ВСЕ группы превысили 21, то дилер пропускает игру
poteziIgraca('D') :-
    svigrupePreko21.

% если настала очередь дилера (и у игрока ранее было больше 21), дилер переходит к следующей группе игроков.
poteziIgraca('D') :-
    currentGroup(Grupa),
    zbrojiKarte(ZbrojIgraca, 'I', Grupa), ZbrojIgraca > 21, !,
    sljedecaGrupa.


% Если настала очередь игрока, не являющегося дилером: игрок вводит (h)it / (s)tand / (d)double / s(p)lit, пока сумма его карт не станет меньше 21 или пока он сбрасывает (s), затем
% Если игрок получил блэкджек сразу с первыми двумя картами, казино выплачивает его в соотношении 3:2 (выиграл/вложил). Однако, если у дилера тоже блэкджек, то это PUSH! Здесь нет необходимости задавать исход группы, потому что на этом игра все равно заканчивается и следующая раздача продолжается.
poteziIgraca('I') :-
    brojKartiURukama('I', 2, 1),
    zbrojiKarte(21, 'I', 1),
    totalGroup(1),
    zbrojiKarte(Dealerove, 'D', 1),
    (Dealerove =:= 21 -> isplatiIgracaZaBlackjackPush; isplatiIgracaZaBlackjackWin ).
    
% Если блэкджек только у дилера, то игрок проиграл
poteziIgraca('I') :-
    brojKartiURukama('I', 2, 1),
    zbrojiKarte(Z, 'I', 1), Z =\= 21,
    totalGroup(1),
    zbrojiKarte(21, 'D', 1),
    firstDealerCard('A'),
    writeln('Dealer Blackjack!').
    
% Если у игрока на руках только одна карта, дайте ему еще одну карту
poteziIgraca('I') :-
    currentGroup(G),
    brojKartiURukama('I', 1, G),
    izvrsiPotezIgraca(h).
    
% Если игрок может разделить (и у него есть деньги для разделения), мы добавляем ему эту возможность.
poteziIgraca('I') :-
    mozesplitati,
    bet(U), cash(N), U =< N,
    writeln('Your turn: (h)it / (s)tand / (d)ouble:'), read(X),
    izvrsiPotezIgraca(X).

% Если у него на руках только две карты, он также может использовать double
poteziIgraca('I') :-
    currentGroup(G),
    brojKartiURukama('I', 2, G),
    bet(U), cash(N), U =< N,
    writeln('Your turn: (h)it / (s)tand / (d)ouble:'), read(X),
    izvrsiPotezIgraca(X).

% Он всегда может использовать hit/stand
poteziIgraca('I') :-
    writeln('Your turn: (h)it / (s)tand:'), read(X),
    izvrsiPotezIgraca(X).


% Перед началом каждой новой раздачи проверяется общее количество оставшихся карт. Если это число меньше трети колоды, карты перемешиваются. Все карты также удаляются из рук игрока и дилера
play :-
    gamePrepare,
    totalCardsNumber(Broj), (Broj =< 104 -> cardsShuffle; true),
    placeBet,
    cardsDealing(Skrivena),
    poteziIgraca('I'),
    promijeniIgracaNaPotezu,
    postaviNaPrvuGrupu,
    write('Hidden card dealer: '), write(Skrivena), nl,
    poteziIgraca('D'),
    promijeniIgracaNaPotezu,
    isplatiIgracuNovac(Dobiveno), totalBet(Ulozeno),
    ( not(blackjack) -> ( Dobiveno >= Ulozeno -> writeln('In total: WIN'); writeln('In total: LOSE') ); true ),
    cash(Novac), write('Cash: '), write(Novac), nl, nl,
    writeln('----------------\nNew game\n----------------\n'),
    !, play.