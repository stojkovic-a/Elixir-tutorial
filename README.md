# Elixir-tutorial <img src="https://cdn.icon-icons.com/icons2/2699/PNG/512/elixir_lang_logo_icon_169207.png" width="48">

Distribuirani key-value store kao primer učenja Elixir-a.

## Svrha tutorijala:

Ovaj tutorijal pruža praktični uvod u Elixir i njegove sposobnosti za razvijanje distribuiranih sistema otpornih na greške, kroz praktičan primer, key-value store, implementiran kao umbrella projekat, čitalac će naučiti:
  1. Kako da projektuje i implementira sisteme otporne na greške korišćenjem Elixir procesa.
  2. Ulogu ključnih abstrakcija poput Agenata(Agents), GenServer-a i Supervizora(Supervisor) pri kreiranju pouzdanih aplikacija.
  3. Kako da distribuira opterećenje kroz više čvorova.

Na kraju ovog tutorijala, čitalac će inati funkcionalno razumevanje osnovnih koncepata Elixir-a i moći će da ih primeni za kreiranje sopstvenih skalabilnih i pouzdanih aplikacija.

## Getting started

Potrebni su Erlang i Elixir u verzijama navedenim u faju [.tool-versions](./.tool-versions).

Dokumentacija za Elixir instalaciju je dostupna na [linku](https://elixir-lang.org/install.html).

Dokumentacija za Erlang instalaciju je dostupna na [linku](https://www.erlang.org/downloads).

Preporučuje se instalacija putem menadžera verzija kao što je [asdf](https://asdf-vm.com/guide/getting-started.html).

Plugin za Elixir u okviru asdf nalazi se [ovde](https://github.com/asdf-vm/asdf-elixir), dok je plugin za Erlang dostupan [ovde](https://github.com/asdf-vm/asdf-erlang).

## Building

Building:
```
cd kv_umbrella
mix deps.get
mix compile
```

Pokretanje za razvoj sa live reload-om:

```
iex -S mix
```

Za korišćenje aplikacije otvorite novi terminal:

```
telnet 127.0.0.1 4040
````

## Deploy-ovanje:

Nakon build-ovanje aplikacije:

```
MIN_ENV=prod mix release foo
MIX_ENV=prod mix release bar
_build/prod/rel/foo/bin/foo start
_build/prod/rel/bar/bin/bar start
```

Ponovo, kako bi se koristila aplikacija, u novom terminalu uneti:

```
telnet 127.0.0.1 4040
```
> [!TIP]
> ## Uputstvo za korisnike:
>
> * Aplikacija podrazumevano sluša na portu 4040, ovo se može promeniti postavljanjem system environment promenljive PORT na željenu vrednost.
> * Dostupne komande za interakciju sa key-value store-om su:
>   * **CREATE** _ime_bucket-a_ - Kreira novi bucket sa datim imenom za čuvanje key-value parova.
>   * **PUT** _ime_bucket-a_ _ključ_ _vrednost_ - Postavlja vrednost za dati ključ u odgovarajući bucket.
>   * **GET** _ime_bucket-a_ _ključ_ - Vraća vrednost za dati ključ iz odgovarajućeg bucket-a.
>   * **DELETE** _ime_bucket-a_ _ključ_ - Uklanja dati ključ i njegovu vrednost iz odgovarajućeg bucket-a.
> * Fajl kv_umbrella/config/runtime.exs definiše tabelu rutiranja za development i production. Opisuje kako su bucket-i distribuirani kroz dostupne čvorove sistema.
> * Fajl kv_umbrella/mix.exs definiše broj i imena čvorova u aplikaciji. Svaki release kreira jedan čvor.

---

## Uvod u Elixir

Pre nego što pređemo na glavni projekat, evo par jednostavnih "Hello World" primera korišćenja Elixir procesa. Njihov cilj je da objasne osnove upotrebe procesa u Elixir-u.
```elixir
defmodule HelloWorld do
  def greet do
    IO.puts("Hello world!")
  end
end

#Start a new process to run the greet function
spawn(fn -> HelloWorld.greet() end)
```

Kako pokrenuti:
1. Sačuvajte kod iznad u fajl po imenu hello_world.exs
2. Pokrenite fajl u Elixir interaktivnom okruženju (IEx):
```
iex hello_world.exs
```
3.  Očekivani output:
```
Hello world!
```

Objašnjenje:
* _spawn/2_ funkcija kreira novi Elixir process koji će izvršiti _HelloWorld.greet/0_ funkciju.
* Procesi u Elixiru su kompletno izolovani i ne dele memoriju. Ova izolacija je ključni aspekt Elixir-ove otpornosti na greške i skalabilnosti. 

Primer: Slanje i primanje poruka:
```elixir
defmodule Messenger do
  def listen do
    receive do
      message -> 
        IO.puts("Received message: #{message}")
    end
  end
end

# Start a new process and send it a message
pid = spawn(Messenger, :listen, [])
send(pid, "Hello Elixir!")
```

Kako pokrenuti:
1. Sačuvajte kod iznad u fajl po imenu send_receive.exs
2. Pokrenite fajl u Elixir interaktivnom okruženju (IEx):
```
iex send_receive.exs
```
3.  Očekivani output:
```
Received message: Hello Elixir!
```

Objašnjenje:
* Funckija receive sluša dok ne dobije bilo koju poruku poslatu procesu i po prijemu štampa primljenu poruku.
* Proces koji izvršava receive funkciju se kreira i njgov pid se smešta u promenljivu.
* Iz trenutnog procesa se šalje poruka procesu koji izvršava receive funkciju.

Nakon što su ovi primeri jasni spremni ste da pređete na tutorijal projekat.


## Opis projekta:

Izazovi sa kojima se često suočavaju moderne distribuirane aplikacije su održavanje visoke dostupnosti, skalabilnosti i otpornosti na greške, posebno u slučajevima prisustva mrežnih grešaka i neočekivanih otkaza. Ovi izazovi se dodatno komplikuju potrebom za upravljanje stanjem sistema na više čvorova a pri tome održavanjem minimalnog prekida rada.

Ovaj projekat demonstrira distribuiran key-value store razvijen u Elixir-u, programskom jeziku projektovanom za kreiranje sistema otpornih na greške sa visokom dostupnošću. BEAM (Bogdan / Björn's Erlang Abstract Machine) virtuelna mašina na kojoj se izvršavaju aplikacije pisane u Elixir-u, omogućava lightwieght konkurentnost i robusnu izolaciju procesa, što čini Elixir dobrim izborom za razvijanje otpronish sistema.

Praćenjem ovog tutorijala, čitalac će steći praktično razumevanje korišćenja Elixir-ovih jedinstvenih karakteristika poput stabla supervizije i modela konkurentnosti i kako da ih upotrebi za razvijanje otpornih distribuiranih sistema.

Najpre, projekat je umbrella tip elixir projekat, što znači da se sastoji od 2 odvojene aplikacije koju su slabo povezane kroz jednosmeran dependency. Aplikacije su u direktorijumu kv_umbrella/apps:

| Aplikacije    | Opis                                                               | 
| ------------- |:------------------------------------------------------------------:| 
| kv            | Key-value store. Upravlja bucket-ima. Periodično trajsno snimanje. |
| kv_server     | Sluša na socket-u. Parsira komande. Poziva kv metode.              |

---

Elixir postiže otpornost na greške korišćenjem konkurentnosti. Svaka Elixir aplikacija se sastoji od odvojenih Elixir procesa. Elixir procesi su veoma lagani po pitanje resursa i izvršavaju se u jednom OS procesu. Svaki Elixir proces se izvršava konkurentno i njihovim izvršenjem upravlja Elixir proces schedular. Schedular u osnovi funkcioniše po Round Robin principu sa određenim modifikacijama koje nastoje da poboljšaju performanse sistema kao celine. U okviru jednog Elixir procesa kod se izvršava sekvencijalno. Svaki Elixir proces može da započne novi proces korišćenjem _spawn()_ metode. Pored međusobnog kreiranja svaki proces takođe može i da komunicira preko slanja poruka sa drugim procesima. Sve što je potrebno za rad jedne aplikacije se može postići kreiranjem procesa koji će ili izvršiti funkcije ili održavati određeno stanje ili nadgledati i po potrebi restartovati druge procese.

### KV:

* KV.Bucket moduo je Agent proces. Agenti su procesi koji su kreirani tako da imaju određeno stanje koje pamte i vraćaju ga po potrebi. Elixir pruža _use Agent_ kao način da se u moduo injektuje kod koji će nam obezbediti metode potrebne za upis u stanje i vraćanje vrednosti stanja. U ovom projektu svaki bucket čuva proizvoljan broj key-value parova. Agenti se pokreću start_link funkcijom koje mora biti implementirana u modulu. Stanju agenta se može pristupati i može biti naknadno menjano instrukcijama poput:
  * **Agent.get()**
  * **Agent.update()**
  * **Agent.get_and_update()**
 
Dokumentaciju za Agente možete naći [ovde](https://hexdocs.pm/elixir/agents.html).

* KV.Registry je GenServer proces. GenServer-i su procesi koji obezbeđuju klijent-server komunikaciju između procesa. GenServer proces konkretno prima zahteve u vidu poruka od drugih procesa i za svaku poruku izvršava  odgovarajuću metodu. Slično kao kog Agent-a kod se injektuje u moduo korišćenjem _use GenServer_ makroa koji obezbeđuje metode za primanje zahteva i slanje odgovora. Značajne metode u KV.Registry modulu su:
  * **start_link()** metoda se poziva kako bi inicijalizovali KV.Registry moduo. Ona poziva _GenServer.start_link()_ metodu  koja inicijalizuje GenServer. Mi moramo da napišemo i kod koji će izvršiti deo inicijalizacije GenServer-a, odnosno _use GenServer_ zahteva overload-ovanje metode **init()**. Konkretno ovde ets (Erlang Term Storage) i bezimena mapa se inicijalizuju i postavljaju kao stanje GenServer-a. Neimenova mapa je jednostavna heš tabela dok je ets ugrađeni tip keš-a u Elixir-u. O ets tabeli možete saznati više [ovde](https://hexdocs.pm/elixir/erlang-term-storage.html).
  * Ostale metode koje _use GenServer_ zahteva su **handle_call()** što je metoda koja upravlja sinhronim zahtevima i **handle_cast()** metoda koja upravlja asinhronim zahtevima. GenServer takođe pruža i **handle_info)=** kao način za hendlovanje direktnih poruka od strane procesa GenServer-u.

Više o GenServer-ima možete pronaći [here](https://hexdocs.pm/elixir/genservers.html).
* KV.Saver moduo je takođe GenServer proces. Ovaj moduo pominjemo zato što implementira česti Elixir projektni obrazac kod koga GenServer periodično šalje poruke samom sebi kako bi obezbedio da se neka funkcija izvršava periodično. Ovde konkretno sadržaj key-value paroa se povremeno snima u fajl u stalnoj memoriji. Vise o radu sa fajlovima možete naći [ovde](https://hexdocs.pm/elixir/io-and-the-file-system.html).

* KV.Superviosr je Supervisor proces. Kod je u njega injektovan pomoću _use Supervisor_. Supervisor procesi nadgeldaju druge procese i restartuju ih nakon njihovog pada ili završetka izvršenja, na osnovu izabrane strategije restartovanja.
  * **start_link()** ovde pokreće Supervisor pozivanjem njegove _start_link()_ metode.
  * Na nama je da implementiramo deo pokretranja Supervisor-a **init()** metodom. Od ove metode se očekuje da definiše decu procese Supervisor-a. Kada se Superviosr pokrene on će ujedno pokrenuti i svaki od navedenih dece. Ćesto, kao što je i ovde slučaj, Supervisor pokreće druge Supervisor-e i kreira čitavu hijerarhiju supervizije. Ovde Supervisor pokreće jedan DynamicSupervisor koji će nadgledati bucket procese. DynamicSupervisor-i se koriste kada se broj dece menja dinamički. Glavni Supervisor ovde takođe pokreće i module KV.Saver, KV.Registry i Task.Supervisor po imenu KV.RouterTasks. Task.Superviosr-i se koriste za nadgledanje jednostavnih Task-ova koji ne zahtevaju definisanje posebnig modula. Vise o [Task-ovima](https://hexdocs.pm/elixir/task-and-gen-tcp.html#tasks).

Vise o [Supervisor-ima](https://hexdocs.pm/elixir/supervisor-and-application.html) i [DynamicSupervisor-ima](https://hexdocs.pm/elixir/dynamic-supervisor.html).

* KV.Router je moduo koji čita routing tabelu iz _runtime.exs_ i rutira zahteve onom čvoru u distribuiranom sistemu na kome treba izvršiti taj zahtev.
* KV moduo je ulaz u KV aplikaciju. Injektuje kod sa _use Application_ koji omogućava implementiranje početne metode aplikacije:
  * **start()** koja pokreće glavni Supervisor u hijerarhiji Supervisor-a.
* **mix.exs** fajl u KV aplikaciji je fajle koji opisuje aplikaciju i njene dependency-je. Ovaj fajl takođe specificira moduo koji predstavlja ulaz u aplikaciju. Dakle to je prethodno pomenuti KV moduo.  
```elixir
  def application do
    [
      extra_applications: [:logger, :jason],
      env: [routing_table: []],
      mod: {KV, []}
    ]
  end
```

### KV_Server:

* KVServer moduo koristi Erlang-ovu :gen_tcp strukturu za komunikaciju preko socketa na određenom portu. Konkretno koriste se sledeće metode:
  * **accept()** kreira novi socket koji sluša na datom portu.
  * **loop_accpetor()** osluškuje za zahtev na kreiranom sokcet-u i kada zahtev stigne kreira Task proces koji hendluje zahtev asinhrono dok on nastavlja da osluškuje za sledeći zahtev.
  *  **serve()** metoda obrađuje primljeni zahtev tako što poziiva metode za parsiranje i izvršavanje parsirane komande.
  *  **read_line()** čita red teksta iz socket-a.
  *  **write_line()** upisuje red teksta preko socket-a.

* KVServer.Command moduo implementira metoda za parsiranje instrukcija pročitanih iz socket-a i za pozivanje odgovarajućih metoda na osnovu tih instrukcija:
  * **parse()** parsira dati instrukcioni string na komandu i argumente.
  * **lookup()** koristi KV.Router.route/4 metodu kako bi izvršio anonimnu funkciju na čvoru koji je zadužen za dati bucket.
  * **run()** metoda je overload-ovano tako da može da izvrši svaku moguću instrukciju, pozivanjem odgovarajuće metode KV aplikacije RPC principom uz pomoć _lookup()_ metode.
 
* KVServer.Application moduo je ekvivalent KV modulu iz KV aplikacije, tj. on je ulaz za KV_Server aplikaicju. Kao takav on implementira:
  * **start()** metodu koju čita broj porta iz sistemske environment promenljive i takođe pokreće Supervisor koji se nalazi na čelu hijerarhije supervizije, definišući njegovu decu procese i zatim pozivajući Supervisor.start_link() metodu. Obratiti pažnju da ovde nismo implementirali Supervisor injektovanjem koda u nas moduo već smo direktno zvali metodu koja ga pokreće. Elixir omogućava oba ova pristupa, tako da je prvi pristup poželjan kada je potrebno da obezbedimo neko svojstveno ponašanje za naš Supervisor.
* **mix.exs** fajl specificira da KV_Server zavisi od KV aplikacije, tj. definiše dependency. Ovo specificiranje se vrši u _deps()_ metodi.
 ```elixir
  defp deps do
    [
      {:kv, in_umbrella: true}
    ]
  end
  ```

## Alternativne tehnologije:

**Zašto Elixir?**

Par tehnologija postoji za razvoj distribuiranih sistema otpornih na greške, uključujući:
  * Akka (Scala): Toolkit za razvoj konkurentnih, distribuiranih i otpornih na greške aplikacija korišćenjem akter modela na Java Virtualnoj Mašini, međutim njegova sintaksa i obrasci za otpornost na greške su isuviše kompleksni i neintuitivni, pored toga Elixir procesi su manje zahtevni po pitanju resursa.
  * Golang: Pruža goroutines za lightweight konkurentnost, ali nedostaje mu ugrađena podrška za distribuirano nadgledanje i oporavak od grešaka.
  * Node.js with clustering: Omogućava skaliranje kroz više procesa ali zahteva dodatne biblioteke za otpornost na greške.

Elixir se izdvaja zato što:

  * Njegova integracija sa BEAM virtualnom mašinom je optimizovana za konkurentnost i otpornost na greške.
  * Sintaksa je developer friendly i postoje ugrađeni alati za hendlovanje grešaka korišćenjem Supervisor-a i GenServer-a.
  * Jak ekosistem za distribuirano programiranje.

Dakle Elixir se izdvaja kao izbor u scenariju kada su pouzdanost, skalabilnost i oporavak od greški od kritične važnosti.

---


> [!NOTE]
> Na posletku autor ovog Elixir tutorijala predlaže da se odlgeda sledeći Elixir demonstracioni video jer su u njemu na kreativan način prikazane mogućnosti Elixir-a:
>
><a href="https://www.youtube.com/watch?v=JvBT4XBdoUE
" target="_blank"><img src="http://img.youtube.com/vi/JvBT4XBdoUE/0.jpg" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>
