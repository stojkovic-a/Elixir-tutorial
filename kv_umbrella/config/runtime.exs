import Config
config :iex, default_prompt: ">>>"
config :kv, :routing_table, [{?a..?z, node()}]
config :kv, :save_time, 10000
if config_env() == :prod do
  config :kv, :routing_table, [
    {?a..?m, :"foo@diffine-pc"},
    {?n..?z, :"bar@diffine-pc"}
  ]
end
