-module(top_level_runs_SUITE).


-include_lib("common_test/include/ct.hrl").

-export([all/0,
         init_per_testcase/2,
         end_per_testcase/2]).

-export([simple_run/1]).


all() ->
    [simple_run].


init_per_testcase( _Any, _Config) ->
    _Config.

end_per_testcase(_Any, _Config) ->
    _Config.



simple_run(_Config) ->
    [emas:start(Backend,
                1000) || Backend <- [%skel_main,
                                     %sequential,
                                     hybrid,
                                     concurrent
                                    ] ].
