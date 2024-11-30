# Elixir-tutorial <img src="https://cdn.icon-icons.com/icons2/2699/PNG/512/elixir_lang_logo_icon_169207.png" width="48">

Distributed key-value store as an elixir tutorial example.

## Purpose of the Tutorial

This tutorial provieds a practical introduction to Elixir and its capabilities for building distributed, fault-tolerant systems. Through a practical example, a key-value store implemented as an umbrella project, a reader will learn:
  1. How to design and implement fault-tolerant systems using Elixir processes.
  2. The role of key abstractions like Agents, GenServers, and Supervisors in building resilient applications.
  3. How to distribute the workload across multiple nodes.

By the end of this, a read will have a functional understanding of Elixir's core concepts and be able to apply them to create their own scalable and robust applications.

## Getting started

Requires Erlang and, Elixir as specified in the [.tool-versions](./.tool-versions) file.

Elixir installation documentation is available [here](https://elixir-lang.org/install.html).

Erlang installation documentation is available [here](https://www.erlang.org/downloads).

It is suggested to install them using a version manager such as [asdf](https://asdf-vm.com/guide/getting-started.html).

Elixir plugin for asdf is available at (https://github.com/asdf-vm/asdf-elixir) while erlang plugin is available at (https://github.com/asdf-vm/asdf-erlang).

## Building

Building:
```
cd kv_umbrella
mix deps.get
mix compile
```

Starting for development with live reload:

```
iex -S mix
```

Then, to use the app, in a separate terminal:

```
telnet 127.0.0.1 4040
````

## Deployment:

After building the app:

```
MIN_ENV=prod mix release foo
MIX_ENV=prod mix release bar
_build/prod/rel/foo/bin/foo start
_build/prod/rel/bar/bin/bar start
```

Once again to use the app, in a separate terminal:

```
telnet 127.0.0.1 4040
```
> [!TIP]
> ## User instructions:
>
>* Application has a server listening on a port 4040 by default this can be changed by setting the system environment variable PORT to the desired value.
>* Available commands to interact with the Key-Value store are:
>   * **CREATE** _bucket_name_  -  Used to create a new bucket by the name of _bucket_name_ which stores key-value pairs.
>   * **PUT** _bucket_name_ _key_ _value_  -  Sets the given value for a given key in a given bucket.
>   * **GET** _bucket_name_ _key_  -  Return the value associated with a given key in a given bucket.
>   * **DELETE** _bucket_name_ _key_  -  Removes the given key value pair from a given bucket.
>* kv_umbrella/config/runtime.exs defines the routing table for development and for production. It describes how buckets are distributed across available nodes.
>* kv_umbrella/mix.exs defines the number and names of nodes in application. Each of the releases equals to one node.

---

### Getting Started with Elixir:

Before diving into the project demonstration, let's explore a simple "Hello World" demonstartion using Elixir processes. This will help you understand the basics of how processes work in Elixir.
```elixir
defmodule HelloWorld do
  def greet do
    IO.puts("Hello world!")
  end
end

#Start a new process to run the greet function
spawn(fn -> HelloWorld.greet() end)
```

How to Run This Code:
1.  Save the code above to a file named hello_world.exs
2.  Run the file in the Elixir interactive shell (IEx):
```
iex hello_world.exs
```
3.  You should see the following output:
```
Hello world!
```

Explanation:
* The _spawn/2_ function created a new Eliir process that executed the _HelloWorld.greet/0_ function.
* Processes in Elixir are completely isolated, meaning they don't share memory. This isolation is a key ascpet of Elixir's fault tolerance and scalability.

Example: Sending and Receiving Messages:
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
send(pid, "Hello, Elixir!")
```

How to Run This Code:
1. Save the code above to a file names send_receive.exs
2. Run the file in the Elixir interactive shell (IEx):
```
iex send_receive.exs
```
3. You should see the follwoing output:
```
Received message: Hello Elixir!
```

After understanding these examples you are ready to tackle the tutorial project.


## Project description:

Modern distributed applications often face challenges in maintaining high availability, scalability, and fault tolerance, especially in the presence of network failures or unexpected crashes. These challenges are compounded by the need to manage system state across multiple nodes while ensuring minimal downtime.

This project demonstrates a distributed key-value store built using Elixir, a programming language designed for creating fault-tolerant and highly available systems. The underlying BEAM (Bogdan / Björn's Erlang Abstract Machine) virtual machine enables lightweight concurrency and robust process isolation, making Elixir particularly suited for building resilient systems.

By following this tutorial, you will gain a practical understanding of how to leverage Elixir's unique features, such as its supervision trees and actor model concurrency, to build reliable distributed systems.

Firstly project is a umbrella type elixir project which means that it consists of 2 separate applications weakly bound together through a one-way dependency. Applications are in kv_umbrella/apps directory:

| Applications  | Description                                                | 
| ------------- |:----------------------------------------------------------:| 
| kv            | Key-value store. Manages buckets. Periodic permanent save. |
| kv_server     | Listens on a socket. Parses commands. Calls kv methods.   |

---

Elixir achieves fault tolerance throgh concurency. Every elixir application consists of separate Elixir processes. Elixir process are very lightweight and are all executed in a single OS process. Each of the Elixir processes run concurently and their execution is controlled by the Elixir process schedular. In a single Elixir process code is executed sequentially. Each of the Elixir processes can spawn antother procces using a _spawn()_ method. Beside creating each other process can also communicate through message passing. Everything an application needs can subsequently be achived through spawning a process to either execute some statements, to hold a cetrain state, or to supervise and restart another process.

### KV:

* KV.Bucket module is an Agent process. Agents are processes that are designed to hold a cetrain state and return it when needed. Elixir provides _use Agent_ as a way to inject code into a module that will provide us with methods necessary to write to a state and get the value from a state. Here each bucket holds arbitrary number of key-value pairs. Agents are started with a start_link function that must be implemented in a module. State of an agent can be accessed and chaged afterwards with instructions such as:
  * **Agent.get()**
  * **Agent.update()**
  * **Agent.get_and_update()**

You can read more about Agents [here](https://hexdocs.pm/elixir/agents.html).

* KV.Registry is a GenServer process. GenServers are processes that are meant to receive requests as messages from other processes and to handle each message with a corresponding method. Similar to agents code is injected into a module with _use GenServer_ that provides methods needed to receive requests and send replies. Notable methods in KV.Registry module are:
  * **start_link()** method is called to initialize KV.Registry module. It calls _GenServer.start_link()_ method which intializes GenServer. We are required to hadnle the GenServer initialization, that is _use GenServer_ requires that we overload a method **init()**.  Here specifically ets (Erlang Term Storage) and an unnamed map are initialized and set as a state of GenServer. Unnamed map is a simple hash table data structure and regarding ets you can read about it [here](https://hexdocs.pm/elixir/erlang-term-storage.html).
  * Other methods required by _use GenServer_ are **handle_call()** which is a method that handles synchronous requests and **handle_cast()** which is a method that handles asynchronous requests. GenServer also provides a **handle_info()** as a way to handle direct process messages to GenServer.

You can find out more about GenServers [here](https://hexdocs.pm/elixir/genservers.html).
* KV.Saver module is also a GenServer process. This module is worth mentioning because it implements a common Elixir design pattern where GenServer sends message to itself periodically to ensure that an action is executed periodically. Here specifically key-value store content is saved to a file periodically. More info about working with files in elixir can be found [here](https://hexdocs.pm/elixir/io-and-the-file-system.html).

* KV.Supervisor is a Supervisor process. Code is injected with _use Supervisor_. Supervisors are processes that observe other processes and restart them if they crash and/or if they finish executing.
  * **start_link()** here starts the Supervisor by calling its _start_link()_ method.
  * Which we have to implement with a **init()** method. To start a Supervisor we need to define its children. When a Supervisor starts it also starts each of its children. Often, as is also the case here, Supervisor starts other Supervisors and creates a whole hierarchy of supervision. This Supervisor starts one DynamicSupervisor used to monitor buckets. DynamicSupervisors are used when number of children changes dynamically. It also starts modules KV.Saver, KV.Registry and, Task.Supervisor by the name of KV.RouterTasks. Task.Supervisors are used to ensure simple Tasks are executed correctly. More on [Tasks](https://hexdocs.pm/elixir/task-and-gen-tcp.html#tasks).

More on [Supervisors](https://hexdocs.pm/elixir/supervisor-and-application.html) and [DynamicSupervisors](https://hexdocs.pm/elixir/dynamic-supervisor.html).

* KV.Router is module that reads the routing table from _runtime.exs_ and routes requests to the correct node.
* KV module is entrance for the KV application. It injects the code _use Application_ which enables us to implement the starting function of the application:
  * **start()** which starts the top Supervisor in the supervision hierarchy.
* **mix.exs** file in KV application is a file that describes the application and its dependencies. It is also a file where we specify whcih module has the application entrance. Here it is KV module.
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

* KVServer module uses the Erlang's :gen_tcp structure for communication via ports. Specifically using the following methods:
  * **accept()** creates a socket that listens on a given port.
  * **loop_acceptor()** listens for a request on a created sockets and upon receiving a request creates a Task process mean to handle the request asynchronously while it continues to listen for a next request.
  * **serve()** method handles the received requests by envoking appropriate methods for parsing and running the parsed command.
  * **read_line()** reads a line from socket.
  * **write_line()** writes a line through socket.

* KVServer.Command module implements methods for pasing instruction lines read from socket and for calling appropriate methods to handle those instructions:
  * **parse()** parses the given instruction line to instructions and instruction arguments.
  * **lookup()** uses the KV.Router.route/4 method to execute an anonymous function on a node containing the given bucket.
  * **run()** method is overloaded so that it can handle each of the possible instructions by calling the corresponding method from KV applications using remote procedure calls and _lookup()_ method.
 
 * KVServer.Application module is equivalent to the KV module from KV application, i.e., it is an entrance for KV_Server application. As such it implements:
   * **start()** method that reads a port number from system environment variables and also starts the head-of-supervision-tree-hierarchy Supervisor by defining its children specifications and subsequently calling the Supervisor.start_link(). Note that we did not implement the Supervisor by injecting its code in our module like in KV but by directly calling is starting method. Elixir allows both approaches and the first one is favorable when we need to ensure some custom behaviour for our Supervisor.
 * **mix.exs** file has to specify that KV_Server depends on KV application which is done inside of _deps()_ method.
 ```elixir
  defp deps do
    [
      {:kv, in_umbrella: true}
    ]
  end
  ```

## Alternative technologies:

**Why Elixir?**

Several technologies are available for building distributed fault-tolerant systems, including:
  * Akka (Scala): A toolkit for building concurrent, distributed, and fault-tolerant applications using the actor model on the Java Virtual Machine, but its syntax and fault-tolerance patterns are more complex and less intuitive and also Elixir processes are more lightweight.
  * Golang: Provides goroutiens for lightweight concurrency, but lacks built-in support for dsitributed supervision and fault recovery.
  * Node.js with clustering: Enables scaling acroess multiple processes but requires additional libraries for fault tolerance.

Elixir stads out due to:

  * Its tight integration with the BEAM virtual machine, which is optimized for concurrency and fault tolerance.
  * A developer-friendly syntax and built-in tools for handling failures through Supervisors and GenServers.
  * A strong ecosytem for distributed programming.

Therefore Elixir stands out as a choice for scenarios where reliability, scalability, and fault recovery are of critical importance.

---

> [!NOTE]
> Finally the author of this Elixir tutorial strongly suggests watching the following Elixir demonstration video as it provides great insights in Elixir capabilities:
>
><a href="https://www.youtube.com/watch?v=JvBT4XBdoUE
" target="_blank"><img src="http://img.youtube.com/vi/JvBT4XBdoUE/0.jpg" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>
