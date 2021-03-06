-module(estore_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-include("$RECORDS_PATH/estore.hrl").

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  Dbs = estore_utils:get_config(dbs), 
  Pools = if Dbs /= undefined -> start_pools(Dbs);
    true -> []
  end,
  run_init(Dbs),
  {ok,{{one_for_one, 5,10},Pools}}.

start_pools(Dbs) ->
  lists:foldl(fun({Name,_Config},Acc) -> 
    Pools = estore_utils:get_db_config(Name,pools),
    if is_list(Pools) =:= true ->
      io:fwrite("Starting pool for ~p~n",[Name]),
      Acc ++ start_db_pools(Name,Pools);
    true -> Acc ++ [] end
  end,[],Dbs).

start_db_pools(Db,Pools) ->
  WorkerName = list_to_atom(atom_to_list(?APP) ++ "_" 
    ++ atom_to_list(Db) ++ "_worker"),
  lists:map(fun({Name,Args}) ->
    SizeArgs = estore_utils:get_value(pool_size,Args,undefined),
    WorkerArgs = estore_utils:get_value(worker_args,Args,undefined),
    PoolArgs = [{name, {local, Name}},
      {worker_module, WorkerName}] ++ SizeArgs,
      poolboy:child_spec(Name,PoolArgs,WorkerArgs)
    end,Pools).

run_init(Dbs) ->
  lists:foldl(fun({Name,Config},Acc) -> 
    InitResult = case estore_utils:get_value(init,Config,false) of
      true -> estore:init(Name);
      _ -> {Name,no_init}
    end,  
    Acc ++ [InitResult]
  end,[],Dbs).

