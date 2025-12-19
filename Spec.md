Plan implementacji mcts dla warcabow.

1. Reprezentacja stanow(stan planszy, gracz na ruchu, dodatkowe informacje)
plansza 8x8, pionki 12 na gracza na czarnych, pionki poruszaja sie na skos => tylko 32 pola planszy sa uzyte, zatem stan planszy mozna reprezentowac 4 intami i 2 dod. bajtami, czyli po prostu 5 intow:
wp: int32, 1 jesli jest bialy pionek na danym polu, 0 wpp, mapowanie pol todo
wq: int32, analogicznie dla bialych damek
bp: int32, analogicznie dla czarnych pionow
bq: int32, analogizcnie dla czarnych damek
meta: int32, flaga informujaca o kolejce, counter ruchow damka bez bicia itd.
do tego nalezy dostarczyc kilka niezbednych funkcji, najwazniejsza to cos w stylu FindAllLegalMoves(State), powinna byc na host i na device oraz musi byc szybka, powinna tez dzialac na warpie szybko.

2. Intro MCTS
Algorytm wykorzystuje drzewiasta reprezentacje stanow gry w dowolna gre, stan poczatkowy to korzen potem kazdy ruch to przejscie do innego stanu. Jako, ze przestrzen stanow ciekawszych gier jest ogromna, dla warcabow to ok. 10^20, wiec checmy modelowac tylko te dobre ruchy, aby drzewo zmiescilo sie w pamieci.
W MTCS mamy 4 zapetlone fazy (do wyczerpania jakis resourcow):
1. Selection: wybieramy sciezke od korzenia do liscia na podstawie wzoru UCB(opisane ponizej)
2. Expansion: Dodajemy lisc tam gdzie skonczylismy Selection
3. Simulation: Symulujemy gre do konca losowymi ruchami, wynikiem moze byc wygrana, remis, lub porazka (1, 0.5, 0)
4. Backpropagation: na podstawie wyniku symulacji aktualizujemy wszystkie liscie az do korzenia.

3. UCB i metryki do Selection
Problem exploration vs. exploitation, w fazie selekcji musimy podjac decyzje o eksploracji nowego wariantu, lub eksploatacji takiego, ktory daje dobre wyniki, mozemy uzyc kilku podejsc, najpopularniejszy zdaje sie byc UCB, ktory wyglada mniej wiecej tak: a* = argmax_{a ∈ A(v)} [ Q(v,a) + c·√(ln N(v) / N(v,a)) ], gdzie A(v) to dostepne ruchy, N(v) to ile razy odwiedzilimy juz v, N(v, a) to ile razy wybralismy a w wezle v, Q(v, a) to natomiast srednia wynikow symulacji dla v, a, wszystkie te dane trzeba bedzie trzymac w reprezentacji drzewa. To jest dobre podejscie do "uczenia" drzewa, do gry mozna uzyc metryk, ktore nie dopuszczaja eksploatacji, czyli w praktyce mozna modyfikowac parametr c, czyli parametr eksploracji, zrownowazony wynosi sqrt(2), wiec dla gry mozna przyjac mniejsze c(wieksza eksploatacja). 

4. Sposoby zrownoleglania
Istnieja 3 glowne podejscia do zrownoleglania MCTS:
1. Leaf Parallelization, zrownoleglamy faze 3. Simulation, po prostu wykonujemy duzo losowych symulacji ze stanu danego liscia, calkiem latwe
2. Root Parallelization, pracujemy na wielu drzewach MCTS rownolegle, sa rozne podejscia pozniejszego laczenia tych drzew, najlepiej jak te drzewa sa rozlaczne
3. Tree Parallelization, rownolegle w drzewie wybieramy K sciezek w fazie selection (potrzebna synchronizacja)
Mozna laczyc te podejscia, leaf parallelization mozna w zasadzie uzyc zawsze, bo jest to najbardziej oczywisty punkt zrownoleglenia, a wiec 2 ciekawe podejscia sa nastepujace:
1. Root+Leaf, budujemy kilka drzew, w kazdym jednoczesnie robimy faze 1 bez synchronizacji, potem rownolegle robimy fazy 2, 3 i na koniec 4 tez bez synchronizacji, potem trzeba laczyc te drzewa.
2. Tree+Leaf, mamy jedno drzewo, rownolegle robimy faze 1 z synchronizacja, potem rownolegle, 2 i 3, a potem 4 z synchronizacja.

5. Problem z reprezentacja drzewa, faza 2
Najwiekszym problemem implementacyjnym zdaje sie byc reprezentacja drzewa w pamieci, standardowe podejscie, czyli cos w stylu CSR, czyli wierzcholki jako tablica, potem indeks pierwszego i ilosc dzieci w SoA, jest dobre dla GPU, ale dynamiczne dodawanie wierzcholka jest trudne, aktualnie moj najlepszy pomysl polega na trzymaniu standardowych tablic + jakies dane pod algorytm i dodajac k >= 1 nowych wierzcholkow checemy zbudowac 3 maksymalnie duze bufory(dla metadanych typu childIndex, childCount, parent i tak musi byc duzo maksymalnych buforow), chcemy trzymac w jednym stan przed dodaniem, w drugim shift, czyli o ile chcemy przesunac wartosc w trzecim docelowym buforze no i jeszcze trzeba dodac te nowe wierzcholki, zlozonosc to powinno miec O(N) ale idealnie zrownoleglone pod katem pamieci i operacji, wiec jest szansa, ze bedzie szybkie, poza tym kazdy wierzcholek moze byc numerem kolejnego indexu metadanych, wiec metadane dla wierzcholkow po prostu dodajemy na ostatni index jakiejs tam tablicy dla nich przeznaczonej.

6. Problem z uncoalesced access
Z uwagi na istote algorytmu MCTS nie jestem pewien czy da sie temu w ogole zapobiec, ale w fazach 1, 4 poszczegolne watki musza czytac odlegle miejsca w pamieci, wiec tu na pewno bedzie jakies waskie gardlo.

7. Sytuacja, w ktorej w trakcie gry trafiamy na niezbadane nody, powinnismy je chyba "dosymulowac"?

8. Sytuacja, w ktorej trafiamy na juz istniejacy stan tylko inna sciezka, powinna byc jakos madrze obsluzona, ale wtedy jest problem z faza 4, bo bysmy musieli symulowac wielu rodzicow
