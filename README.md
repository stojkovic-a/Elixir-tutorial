# Elixir-tutorial <img src="https://cdn.icon-icons.com/icons2/2699/PNG/512/elixir_lang_logo_icon_169207.png" width="48">

Distribuirani key-value store kao primer učenja Elixir-a.

##Svrha tutorijala:

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












