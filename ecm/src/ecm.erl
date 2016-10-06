-module(ecm).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start/0, stop/0, publish/3, subscribe/1]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

%% Publish a message with topic with a Qos on this client to a broker
publish(Topic, Message, Qos) -> 
	server ! {publish, Topic, Message, Qos}.

%% Subscribe to a topic with this client
subscribe(Topic) -> 
	server ! {subscribe, Topic}.

%% Start this client and establish the connection with the broker
start() ->
	{ok, C} = emqttc:start_link([{host, "176.10.136.208"}, 
                                 {client_id, <<"simpleClient">>}, {proto_ver, 3}]),
	Pid = spawn(fun () -> loop(C) end),
	register(server,Pid).


	%%==============================================
	%%			BUG
	%%=============================================
	%	PresPid = lists:append("precence/", Pid),
	%	publish(<<PresPid>>, precence(), 1).


%% Disconnect from the broker an stop this client
stop() ->
        server ! stop,
        exit(normal).


%% -----------------------------------------------------------------
%% Internal Functions
%% -----------------------------------------------------------------

%% 
loop(C) -> 
  receive
	%% Receive messages from subscribed topics
	{{publish, Topic, Payload}} ->
		io:format("Message from ~s: ~p~n", [Topic, Payload]),
		loop(C);
	
	%% Publish messages with a topic and Qos to the broker
	{publish, Topic, Message, Qos} ->
		Payload = list_to_binary([Message]),
		emqttc:publish(C, Topic, Payload, [{qos, Qos}]),
		loop(C);
	
	%% Subscribe to a topic on the broker
	{subscribe, Topic} ->

		emqttc:subscribe(C, Topic, qos0),
		loop(C);
	
	%% Stop the loop as a part of stopping the client
	stop ->
		ok
  end,
  emqttc:disconnect(C).


%% Provide a precence message in line with PRATA RFC #1
precence() ->
	lists:append("{
  		version: 1,
  		groupName: “X.E.S.”,
  		groupNumber: “5”,
  		connectedAt: “time”,
  		rfcs: [", "1","],
  		clientVersion: “1”,
  		clientSoftware: “GogoDeals”     
	}").
