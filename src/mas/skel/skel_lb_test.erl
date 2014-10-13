%% @author jstypka <jasieek@student.agh.edu.pl>
%% @version 1.1

-module(skel_lb_test).
-export([start/1]).


%% ====================================================================
%% API functions
%% ====================================================================

start(Data) ->

    Fun = fun(short) ->
                  io:format("short ~p~n",[self()]),
                  short;
             (long) ->
                  timer:sleep(1000),
                  io:format("long ~p~n",[self()]),
                  long
          end,

    Workflow = {map, [Fun], 2},

    _Result = skel:do([Workflow], [Data]).