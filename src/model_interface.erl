-module(model_interface).

-callback make(Name :: record()) -> 
  'ok'|tuple('error', Reason :: string()).
 
-callback save(Name :: record()) -> 
  'ok'|tuple('error', Reason :: string()).

-callback delete(Name :: record()) -> 
  'ok'|tuple('error', Reason :: string()).

-callback find(Name :: atom(), Conditions :: list()) -> 
  Records :: list() | tuple('error', Reason :: string()).

