%% @author jstypka <jasieek@student.agh.edu.pl>
%% @version 1.1

-module(skel_main).
-export([start/3]).

-include ("mas.hrl").

%% ====================================================================
%% API functions
%% ====================================================================

-spec start(Time::pos_integer(), sim_params(), config()) -> ok.
start(Time, SP, Cf = #config{islands = Islands, agent_env = Env}) ->
    topology:start_link(self(), Islands, Cf#config.topology),
    skel_logger:start_link(Cf),
    misc_util:seed_random(),
    misc_util:clear_inbox(),
    Population = [{I, Env:initial_agent(SP)} ||
                     _ <- lists:seq(1, Cf#config.population_size),
                     I <- lists:seq(1, Islands)],
    {_Time, _Result} = timer:tc(fun main/4, [Population, Time, SP, Cf]),
    topology:close(),
    skel_logger:close().
%%     io:format("Total time:   ~p s~nFitness:     ~p~n", [_Time / 1000000, _Result]).

%% ====================================================================
%% Internal functions
%% ====================================================================

%% TODO add generic statistics (funstats)
%% @doc Main program loop
-spec main([tuple()], non_neg_integer(), sim_params(), config()) -> float().
main(Population, Time, SP, Cf) ->
    Environment = Cf#config.agent_env,
    EndTime = misc_util:add_miliseconds(os:timestamp(), Time),
    Workers = 4,

    TagFun = fun({Home, Agent}) ->
                     {{Home, Environment:behaviour_function(Agent, SP)}, Agent}
             end,

    MigrateFun = fun({{Home, migration}, Agent}) ->
                         {{topology:getDestination(Home), migration}, Agent};
                    (OtherAgent)->
                         OtherAgent
                 end,

    GroupFun = fun misc_util:group_by/1,

    LogFun = fun(Chunks) ->
                     Counter = misc_util:create_new_counter(Cf),
                     Counts = misc_util:add_interactions_to_counter([{B, A} || {{_H, B}, A} <- Chunks], Counter),
                     skel_logger:report_result(fight, dict:fetch(fight, Counts)),
                     skel_logger:report_result(reproduce, dict:fetch(reproduction, Counts)),
                     skel_logger:report_result(death, dict:fetch(death, Counts)),
                     skel_logger:report_result(migration, dict:fetch(migration, Counts)),
                     Chunks
             end,

    ShuffleFun = fun(Agents) ->
                         misc_util:shuffle(lists:flatten(Agents))
                 end,

    GLfun = fun(Shuffled) ->
                    Grouped = GroupFun(Shuffled),
                    LogFun(Grouped)
         end,


    TMfun = fun (Agents) ->
                 Tagged = lists:map(TagFun,
                                    Agents),
                 _Migrated = lists:map(MigrateFun,
                                      Tagged)
         end,


    Work = {seq, fun({{Home, Behaviour}, Agents}) ->
                         NewAgents = misc_util:meeting_proxy({Behaviour, Agents}, skel, SP, Cf),
                         [{Home, A} || A <- NewAgents]
                 end },


    Workflow = {pipe, [{seq, GLfun},
                       {map, [Work,
                              {seq, TMfun}], Workers},
                       {seq, ShuffleFun}]},

    [_FinalIslands] = skel:do([{seq, TMfun},
                               {feedback,
                                [Workflow],
                                _While = fun(Agents) ->
                                                 Fitness = lists:max([Fitness || {_, {_, Fitness, _}} <- Agents]),
                                                 PopulationSize = length(Agents),
                                                 skel_logger:report_result(fitness, Fitness),
                                                 skel_logger:report_result(population, PopulationSize),
                                                 os:timestamp() < EndTime
                                         end}],
                              [Population]),
    result.
