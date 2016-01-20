-module(fluxer_sup).
-behaviour(supervisor).

%% API
-export([start_link/0,start_link/1]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

-define(FLUXER_POOL_SIZE, 10).
-define(FLUXER_POOL_MAX_OVERFLOW, 20).
-define(DEFAULT_SCHEMA, http).
-define(DEFAULT_HOST, "127.0.0.1").
-define(DEFAULT_PORT, 8086).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_link(Args) ->
    supervisor:start_link({local, ?MODULE},?MODULE,[Args]).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

init([]) ->
    PoolName = fluxer:pool_name(),
    PoolArgs = pool_args(PoolName),
    FluxerArgs = fluxer_args(),
    PoolSpec = poolboy:child_spec(PoolName, PoolArgs, FluxerArgs),
    {ok, { {one_for_one, 5, 10}, [PoolSpec]} };
init([Args]) ->
    PoolName = fluxer:pool_name(),
    PoolArgs = pool_args(PoolName),
    Host = proplists:get_value(host,Args,?DEFAULT_HOST),
    Port = proplists:get_value(port, Args, ?DEFAULT_PORT),
    Schema = proplists:get_value(schema, Args, ?DEFAULT_SCHEMA),
    IsSSl = Schema =:= https,
    FluxerArgs = [Host, Port, IsSSl, []],
    PoolSpec = poolboy:child_spec(PoolName, PoolArgs, FluxerArgs),
    {ok, { {one_for_one, 5, 10}, [PoolSpec]} }.
%%====================================================================
%% Internal functions
%%====================================================================
pool_args(PoolName) ->
    PoolSize = application:get_env(fluxer, pool_size, ?FLUXER_POOL_SIZE),
    PoolMaxOverflow = application:get_env(fluxer, pool_max_overflow, ?FLUXER_POOL_MAX_OVERFLOW),
    [{name, {local, PoolName}},
     {worker_module, fluxer},
     {size, PoolSize}, {max_overflow, PoolMaxOverflow}].

fluxer_args() ->
    Schema = application:get_env(fluxer, schema, ?DEFAULT_SCHEMA),
    IsSSL = Schema =:= https,
    Host = application:get_env(fluxer, host, ?DEFAULT_HOST),
    Port = application:get_env(fluxer, port, ?DEFAULT_PORT),
    [Host, Port, IsSSL, []].
