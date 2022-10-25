:- use_module(library(lists), [nth0/3]).
:- use_module(library(random), [random/3]).
:- dynamic card/2, novac/1, cardURukama/3, naPotezu/1, ulog/1, ukupniUlog/1, dupliranaGrupa/1, grupe/2, ukupnoGrupa/1, trenutnaGrupa/1, prvaKartaDealera/1, blackjack/0.
:- retractall(novac(_)), assert(novac(1000)).
:- retractall(naPotezu(_)).
:- retractall(ulog(_)).
:- retractall(ukupniUlog(_)).

%Карты в игре. 6 колод
promijesajKarte :-
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
    
:- retractall(card(_,_)), promijesajKarte.

naPotezu('I').
ulog(0).
    
%************************************************************
%Вспомогательные предикаты

sumaListe([], 0).
sumaListe([H|T], S) :-
    sumaListe(T, S1),
    S is S1 + H.
    
% Суммирует все карты в руках игрока. A превращается в 11, а JQK по 10
zbrojKarata([], 0).
zbrojKarata([H|T], Z) :-
    zbrojKarata(T, Z1),
    (H == 'A' -> Z is Z1 + 11 ;
    (
       ((H == 'J' ; H == 'Q' ; H == 'K') -> Z is Z1 + 10 ;
           Z is Z1 + H
       )
    )).
    
    
brojDobivenihDupliranihGrupa(N) :-
    findall(X, (grupe(X,w), dupliranaGrupa(X)), L),
    length(L, N).

brojDobivenihNedupliranihGrupa(N) :-
    findall(X, (grupe(X,w), not(dupliranaGrupa(X))), L),
    length(L, N).
    
brojPushanihDupliranihGrupa(N) :-
    findall(X, (grupe(X,p), dupliranaGrupa(X)), L),
    length(L, N).
    
brojPushanihNedupliranihGrupa(N) :-
    findall(X, (grupe(X,p), not(dupliranaGrupa(X))), L),
    length(L, N).
    
    
imaDvijeJednakeKarte :-
    trenutnaGrupa(G),
    findall(X, cardURukama('I', X, G), L),
    nth0(0, L, K1), nth0(1, L, K2),
    (K1 == K2; K1 == 'A', K2 == 1; K1 == 1, K2 == 'A').
    
    
svigrupePreko21 :-
    zbrojiKarte(Z1, 'I', 1), zbrojiKarte(Z2, 'I', 2),
    zbrojiKarte(Z3, 'I', 3), zbrojiKarte(Z4, 'I', 4),
    Z1 > 21, Z2 > 21, Z3 > 21, Z4 > 21.
    
    
postaviIshodGrupe(Grupa, Ishod) :-
    retract(grupe(Grupa, _)),
    assert(grupe(Grupa, Ishod)).
    
%************************************************************

% Смена игрока
promijeniIgracaNaPotezu :-
    retract(naPotezu(I)),
    (I == 'I' -> assert(naPotezu('D')); assert(naPotezu('I'))).
    
% этот предикат инициализирует игру для новой раздачи
pripremiIgru :-
    retractall(cardURukama(_,_,_)),  % аргументы: игрок (дилер или другой игрок), карта, группа. Третий аргумент (группа) представляет группу, в которую будет перемещена карта после разделения пары карт.
    retractall(dupliranaGrupa(_)),
    retractall(grupe(_,_)),
    retractall(ukupnoGrupa(_)),
    retractall(trenutnaGrupa(_)),
    retractall(ukupniUlog(_)),
    retractall(prvaKartaDealera(_)),
    retractall(blackjack),
    assert(grupe(1, u)), %представляет все группы, которые есть у игрока (с соответствующими индексами). Второй аргумент может быть: w (win - победа в этой группе над дилером), l (lose - проигрыш в этой группе над дилером), p (push - ни выигрыша, ни проигрыша в этой группе у дилера, равное количество карты), u (unknown - победа или поражение еще не известно)
    assert(trenutnaGrupa(1)),
    assert(ukupnoGrupa(1)),
    assert(ukupniUlog(0)).

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


% vraæa ukupan broj karti tako da pretvara sve èinjenice karte u listu i zbraja ih
ukupanBrojKarti(N) :-
    findall(X, card(_, X), L), !,
    sumaListe(L, N).
    
    
% возвращает количество карт в руке игрока
brojKartiURukama(I, Broj, Grupa) :-
    findall(K, cardURukama(I, K, Grupa), L),
    length(L, Broj).
    
% возвращает true, если игрок может разделиться. А именно: если у него две одинаковые карты и если он уже сплитил меньше 3-х раз (то есть если всего групп меньше 4-х)
mozesplitati :-
    trenutnaGrupa(G),
    brojKartiURukama('I', 2, G),
    imaDvijeJednakeKarte,
    ukupnoGrupa(U), U < 4.


% берет деньги с игроков
uzmiNovac(X) :-
    retract(novac(Novac)), Novac2 is Novac - X,
    assert(novac(Novac2)),
    retract(ukupniUlog(U)),
    U1 is U + X, assert(ukupniUlog(U1)).
    
% предикат для входа в начальную роль
unesiUlog :-
    write('Введите вашу ставку: '), read(X),
    novac(Novac), X =< Novac,
    uzmiNovac(X),
    retractall(ulog(_)), assert(ulog(X)).
    
unesiUlog :-
    write('Введите вашу ставку: '), read(X),
    novac(Novac), X > Novac,
    write('Введена слишком большая сумма! У тебя есть: '), write(Novac), write(' $'), nl,
    !, unesiUlog.
    

    
% I - игрок, D дилер
podijeliKarte(D2) :-
    izvuciKartu(I1), izvuciKartu(D1), izvuciKartu(I2), izvuciKartu(D2),
    assert(cardURukama('I', I1, 1)), assert(cardURukama('D', D1, 1)), assert(cardURukama('I', I2, 1)), assert(cardURukama('D', D2, 1)),
    assert(prvaKartaDealera(D1)),
    writeln('Новая раздача. Карты:'),
    write('Дилер: '), write(D1), write(' '), write('X'), nl,
    write('Игрок: '), write(I1), write(' '), write(I2), nl.


% берет карту из колоды и добавляет ее в руку игрока
uzmiKartu(Karta) :-
    naPotezu(I),
    izvuciKartu(Karta), trenutnaGrupa(G),
    assert(cardURukama(I, Karta, G)).
   

% добавляет карты определенного игрока. Сначала он складывает все тузы как одиннадцать, а если общее значение превышает 21, то по одному тузу за раз (меняет столько единиц, сколько необходимо)
zbrojiKarte(Z, I, Grupa) :-
    findall(K, cardURukama(I,K,Grupa), L),
    zbrojKarata(L, Z1),
    (Z1 > 21 ->
    (
       cardURukama(I, 'A', Grupa) -> (retract(cardURukama(I, 'A', Grupa)), assert(cardURukama(I, 1, Grupa)), !, zbrojiKarte(Z, I, Grupa)); (Z is Z1)
    ); Z is Z1).
    

% если игрок получил блэкджек сразу с первыми двумя картами. В этом случае казино платит в соотношении 3:2.
isplatiIgracaZaBlackjackWin :-
    writeln('WIN!'),
    novac(NovacIgraca), ulog(UlogIgraca), NovaVrijednostNovca is NovacIgraca + 1.5 * UlogIgraca,
    retract(novac(_)), assert(novac(NovaVrijednostNovca)), assert(blackjack).
    
% Если и игрок, и дилер получили блэкджек сразу с первыми двумя картами, это push, и деньги возвращаются игроку.
isplatiIgracaZaBlackjackPush :-
    writeln('PUSH'),
    novac(NovacIgraca), ulog(UlogIgraca), NovaVrijednostNovca is NovacIgraca + UlogIgraca,
    retract(novac(_)), assert(novac(NovaVrijednostNovca)), assert(blackjack).

% дает игроку деньги, учитывая количество выигранных групп, количество выигранных удвоенных групп и количество пропушенных групп
isplatiIgracuNovac(Dobiveno) :-
    novac(Novac), ulog(Ulog),
    brojDobivenihDupliranihGrupa(N1),
    brojDobivenihNedupliranihGrupa(N2),
    brojPushanihDupliranihGrupa(N3),
    brojPushanihNedupliranihGrupa(N4),
    Dobiveno is 4 * N1 * Ulog + 2 * (N2 + N3) * Ulog + N4 * Ulog,
    NovaVrijednostNovca is Novac + Dobiveno,
    retract(novac(_)), assert(novac(NovaVrijednostNovca)).



dupliraj(X) :-
    assert(dupliranaGrupa(X)).

% этот предикат берет другую карту и помещает ее в новую группу. После этого он добавляет в старую группу еще одну карту и записывает, какая это карта.
splitaj :-
    trenutnaGrupa(G),
    findall(X, cardURukama('I', X, G), L),
    nth1(2, L, K),
    retract(cardURukama('I', K, G)),
    NovaPozicija is G + 1,
    assert(cardURukama('I', K, NovaPozicija)),
    assert(grupe(NovaPozicija, u)),
    uzmiKartu(Karta), write('Nova card: '), write(Karta), write(', Grupa: '), write(G), nl.
    
% если это последняя группа игроков, мы останавливаем игру, а дилер продолжает
sljedecaGrupa :-
    trenutnaGrupa(G), ukupnoGrupa(G).

% если это не последняя группа игроков, мы увеличиваем текущую группу и требуем ввода игроков для следующей группы
sljedecaGrupa :-
    trenutnaGrupa(T), ukupnoGrupa(U),
    T < U, T1 is T + 1,
    retract(trenutnaGrupa(_)), assert(trenutnaGrupa(T1)), !,
    (naPotezu('I') -> ( writeln('Sljedeca grupa'), poteziIgraca('I') ); izvrsiPotezDealera ).


% когда дилер начнет играть, он должен будет сравнить свою руку со всеми своими картами. Поэтому перед этим необходимо установить текущую группу игроков на 1
postaviNaPrvuGrupu :-
    retractall(trenutnaGrupa(_)),
    assert(trenutnaGrupa(1)).


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
    trenutnaGrupa(G),
    postaviIshodGrupe(G, w), !,
    sljedecaGrupa.
    
% Если дилер решает stand и если игрок прошел 21
izvrsiPotezDealera :-
    trenutnaGrupa(G),
    zbrojiKarte(ZbrojDealera, 'D', 1), ZbrojDealera >= 17, ZbrojDealera =< 21, zbrojiKarte(ZbrojIgraca, 'I', G),
    ZbrojIgraca > 21, !,
    sljedecaGrupa.
    
% Если игрок выиграл
izvrsiPotezDealera :-
    trenutnaGrupa(G),
    zbrojiKarte(ZbrojDealera, 'D', 1), ZbrojDealera >= 17, ZbrojDealera =< 21, zbrojiKarte(ZbrojIgraca, 'I', G),
    ZbrojIgraca > ZbrojDealera,
    writeln('WIN!'),
    postaviIshodGrupe(G, w), !,
    sljedecaGrupa.

% Если дилер решает snad и если у дилера и другого игрока одинаковая сумма карт
izvrsiPotezDealera :-
    trenutnaGrupa(G),
    zbrojiKarte(Zbroj, 'D', 1), Zbroj >= 17, Zbroj =< 21, zbrojiKarte(Zbroj, 'I', G),
    writeln('PUSH!'),
    postaviIshodGrupe(G, p), !,
    sljedecaGrupa.

% Если дилер решает stand и если игрок проиграл
izvrsiPotezDealera :-
    trenutnaGrupa(G),
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
    writeln('Nije moguce split-ati!'),
    poteziIgraca('I').

% если у игрока нет равных карт или если игрок уже трижды делился (всего групп четыре), то игрок не может снова разделить.
izvrsiPotezIgraca(p) :-
    retract(ukupnoGrupa(U)), !, U1 is U + 1,
    assert(ukupnoGrupa(U1)),
    splitaj,
    ulog(Ulog), uzmiNovac(Ulog), !,  % uzmimamo od igraèa još novca, buduæi da je koristio split
    poteziIgraca('I').
    
izvrsiPotezIgraca(h) :-
    trenutnaGrupa(G),
    ukupnoGrupa(U),
    uzmiKartu(Karta), zbrojiKarte(Z, 'I', G),
    write('Nova card: '), write(Karta), ( U > 1 -> (write(', Grupa: '), write(G)); true ), nl, !,
    ( Z > 21 -> ( writeln('BUST!'), postaviIshodGrupe(G, l), sljedecaGrupa ); poteziIgraca('I') ).
    

izvrsiPotezIgraca(d) :-
    trenutnaGrupa(G),
    brojKartiURukama('I', N, G), N > 2,
    writeln('Nije moguce duplirati! U ruci imate vise od 2 karte.'),
    poteziIgraca('I').
    

% если у игрока на руках 2 карты, то он может удвоить
izvrsiPotezIgraca(d) :-
    uzmiKartu(Karta), trenutnaGrupa(G),
    ukupnoGrupa(Uk),
    write('Nova card: '), write(Karta), ( Uk > 1 -> (write(', Grupa: '), write(G)); true ), nl,
    ulog(U), uzmiNovac(U),  % uzmimamo od igraèa još novca, buduæi da je koristio double
    dupliraj(G),
    zbrojiKarte(Z, 'I', G), !,
    ( Z > 21 -> ( writeln('BUST!'), postaviIshodGrupe(G, l), sljedecaGrupa ); sljedecaGrupa ).



% если настала очередь дилера, а у игрока ранее был блэкджек (без сплитов), то дилер пропускает игру
poteziIgraca('D') :-
    zbrojiKarte(21, 'I', 1), brojKartiURukama('I', 2, 1),
    ukupnoGrupa(1).

% если настала очередь дилера, а у игрока ранее была меньшая сумма, равная 21
poteziIgraca('D') :-
    trenutnaGrupa(Grupa),
    zbrojiKarte(ZbrojIgraca, 'I', Grupa), ZbrojIgraca =< 21,
    zbrojiKarte(ZbrojDealera, 'D', 1),
    (ZbrojDealera < 17 -> writeln('Nove karte dealera: '); true), izvrsiPotezDealera.
    
% если настала очередь дилера, а у игрока ранее ВСЕ группы превысили 21, то дилер пропускает игру
poteziIgraca('D') :-
    svigrupePreko21.

% если настала очередь дилера (и у игрока ранее было больше 21), дилер переходит к следующей группе игроков.
poteziIgraca('D') :-
    trenutnaGrupa(Grupa),
    zbrojiKarte(ZbrojIgraca, 'I', Grupa), ZbrojIgraca > 21, !,
    sljedecaGrupa.


% Если настала очередь игрока, не являющегося дилером: игрок вводит (h)it / (s)tand / (d)double / s(p)lit, пока сумма его карт не станет меньше 21 или пока он сбрасывает (s), затем
% Если игрок получил блэкджек сразу с первыми двумя картами, казино выплачивает его в соотношении 3:2 (выиграл/вложил). Однако, если у дилера тоже блэкджек, то это PUSH! Здесь нет необходимости задавать исход группы, потому что на этом игра все равно заканчивается и следующая раздача продолжается.
poteziIgraca('I') :-
    brojKartiURukama('I', 2, 1),
    zbrojiKarte(21, 'I', 1),
    ukupnoGrupa(1),
    zbrojiKarte(Dealerove, 'D', 1),
    (Dealerove =:= 21 -> isplatiIgracaZaBlackjackPush; isplatiIgracaZaBlackjackWin ).
    
% Если блэкджек только у дилера, то игрок проиграл
poteziIgraca('I') :-
    brojKartiURukama('I', 2, 1),
    zbrojiKarte(Z, 'I', 1), Z =\= 21,
    ukupnoGrupa(1),
    zbrojiKarte(21, 'D', 1),
    prvaKartaDealera('A'),
    writeln('у Дилера Блэкджек!').
    
% Если у игрока на руках только одна карта, дайте ему еще одну карту
poteziIgraca('I') :-
    trenutnaGrupa(G),
    brojKartiURukama('I', 1, G),
    izvrsiPotezIgraca(h).
    
% Если игрок может разделить (и у него есть деньги для разделения), мы добавляем ему эту возможность.
poteziIgraca('I') :-
    mozesplitati,
    ulog(U), novac(N), U =< N,
    writeln('Выберете действие: (h)it / (s)tand / (d)ouble:'), read(X),
    izvrsiPotezIgraca(X).

% Если у него на руках только две карты, он также может использовать double
poteziIgraca('I') :-
    trenutnaGrupa(G),
    brojKartiURukama('I', 2, G),
    ulog(U), novac(N), U =< N,
    writeln('Unesite opciju: (h)it / (s)tand / (d)ouble:'), read(X),
    izvrsiPotezIgraca(X).

% Он всегда может использовать hit/stand
poteziIgraca('I') :-
    writeln('Unesite opciju: (h)it / (s)tand:'), read(X),
    izvrsiPotezIgraca(X).


% Перед началом каждой новой раздачи проверяется общее количество оставшихся карт. Если это число меньше трети колоды, карты перемешиваются. Все карты также удаляются из рук игрока и дилера
igraj :-
    pripremiIgru,
    ukupanBrojKarti(Broj), (Broj =< 104 -> promijesajKarte; true),
    unesiUlog,
    podijeliKarte(Skrivena),
    poteziIgraca('I'),
    promijeniIgracaNaPotezu,
    postaviNaPrvuGrupu,
    write('Skrivena card dealera: '), write(Skrivena), nl,
    poteziIgraca('D'),
    promijeniIgracaNaPotezu,
    isplatiIgracuNovac(Dobiveno), ukupniUlog(Ulozeno),
    ( not(blackjack) -> ( Dobiveno >= Ulozeno -> writeln('Ukupno: WIN'); writeln('Ukupno: LOSE') ); true ),
    novac(Novac), write('Novac: '), write(Novac), nl, nl,
    writeln('Nova igra'),
    !, igraj.