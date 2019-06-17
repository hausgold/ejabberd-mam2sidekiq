-module(mod_mam2sidekiq).
-author("hermann.mayer92@gmail.com").
-behaviour(gen_mod).
-export([%% ejabberd module API
         start/2, stop/1, reload/3, depends/2, mod_opt_type/1,
         %% Hooks
         on_store_mam_message/6
        ]).

-include("ejabberd.hrl").
-include("logger.hrl").
-include("xmpp.hrl").
-include("mod_mam.hrl").
-include("mod_mam2sidekiq.hrl").

-callback store(#job{}) -> ok.

%% Start the module by implementing the +gen_mod+ behaviour. Here we register
%% the hooks to listen to, for the custom MAM bridging functionality.
-spec start(binary(), gen_mod:opts()) -> ok.
start(Host, _Opts) ->
  %% Register hooks
  %% Run the MUC IQ hook after mod_mam (101)
  ejabberd_hooks:add(store_mam_message,
                     Host, ?MODULE, on_store_mam_message, 101),
  %% Log the boot up of the module
  ?INFO_MSG("[M2S] Start MAM bridge (v~s) for ~s", [?MODULE_VERSION, Host]),
  ok.

%% Stop the module, and deregister all hooks.
-spec stop(binary()) -> any().
stop(Host) ->
  %% Deregister the custom XMPP codec
  xmpp:unregister_codec(hg_read_markers),
  %% Deregister all the hooks
  ejabberd_hooks:delete(muc_process_iq, Host, ?MODULE, on_muc_iq, 101),
  %% Signalize we are done with stopping the module
  ?INFO_MSG("[M2S] Stop MAM/Sidekiq bridge", []),
  ok.

%% Inline reload the module in case of external triggered +ejabberdctl+ reloads.
-spec reload(binary(), gen_mod:opts(), gen_mod:opts()) -> ok.
reload(_Host, _NewOpts, _OldOpts) -> ok.

%% Hook on all MAM (message archive management) storage requests to grab the
%% stanza packet and write it out to Redis in a Sidekiq compatible format. This
%% is the core of this module and takes care of the message bridging for third
%% party applications.
-spec on_store_mam_message(message() | drop, binary(), binary(), jid(),
                           chat | groupchat, recv | send) -> message().
on_store_mam_message(#message{} = Packet, _LUser, _LServer, _Peer,
                     Type, recv) ->
  %% Write the Sidekiq job to the Redis queue (list)
  store(create_job(create_event(Packet, Type))),
  %% Pass through the input message packet
  Packet;
on_store_mam_message(Packet, _LUser, _LServer, _Peer, _Type, _Dir) -> Packet.

%% Convert the given +#job+ instance to its binary JSON representation and push
%% it to the Redis queue (list) in order to be picked up by Sidekiq as a
%% regular job.
-spec store(#job{}) -> ok.
store(#job{} = Job) ->
  %% Encode the given job to JSON
  Json = encode_job(Job),
  %% Push the new job to the Redis list
  case ejabberd_redis:q(["LPUSH", queue(), Json]) of
    {ok, _} -> ok;
    Errs -> ?ERROR_MSG("[M2S] Failed to add job to Redis list. (~s)", [Json])
  end,
  ok.

%% Encode the given +#job+ record to its binary JSON representation.
-spec encode_job(#job{}) -> binary().
encode_job(#job{} = Job) ->
  case catch jiffy:encode(?record_to_tuple(job, Job)) of
    {'EXIT', Reason} ->
      ?ERROR_MSG("[M2S] Failed to encode job to JSON:~n"
                 "** Content = ~p~n"
                 "** Err = ~p",
                 [Job, Reason]),
      <<>>;
    Encoded -> Encoded
  end.

%% Put all the job data together and create a new +#job+ record instance. This
%% data structure will be passed to the Redis backend where it is encoded to
%% JSON and put on the configured Sidekiq queue (list).
-spec create_job(binary()) -> #job{}.
create_job(Event) ->
  %% Fetch the current UNIX time (epoch in seconds)
  Now = get_current_unix_time(),
  %% Assemble the job record which can be passed to our Redis behaviour
  #job{class = gen_mod:get_module_opt(global, ?MODULE, sidekiq_class, <<"">>),
       jid = get_job_id(),
       args = [Event, <<"xmpp-mam">>],
       created_at = Now,
       enqueued_at = Now}.

%% Assemble a wrapping XML event element with meta data. This serves as first
%% argument to the Sidekiq job and contains the actual MAM message and relevant
%% meta data.
-spec create_event(message(), chat | groupchat) -> binary().
create_event(#message{} = Packet, Type) ->
  %% Assemble the meta data XML blob for the Sidekiq job event/message wrapper
  Meta = #xmlel{name = "meta",
                attrs = [{"type", misc:atom_to_binary(Type)},
                         {"id", get_stanza_id(Packet)},
                         {"from", nickname_jid(Packet, from, Type)},
                         {"to", nickname_jid(Packet, to, Type)}]},
  %% Build the wrapping event
  fxml:element_to_binary(#xmlel{name = "event",
                                attrs = [{"xmlns", ?NS_MAM_SIDEKIQ}],
                                children = [Meta, xmpp:encode(Packet)]}).

%% Fetch the JID with nickname resource for the given message packet.
-spec nickname_jid(message(), from | to, chat | groupchat) -> string().
nickname_jid(#message{} = Packet, Dir, chat) ->
  Jid = get_jid(Packet, Dir),
  %% @TODO: Fetch the nickname from the Roster. (sql: rosterusers#jid -> #nick)
  %%        jid:replace_resource(Jid, Nick)
  jid:encode(Jid);
nickname_jid(#message{} = Packet, Dir, groupchat) ->
  Jid = get_jid(Packet, Dir),
  %% @TODO: Fetch the nickname for the target MUC/(sender/receiver).
  %%        jid:replace_resource(Jid, Nick)
  jid:encode(Jid);
nickname_jid(_Packet, _Dir, _Type) -> <<"unknown">>.

%% Calculate the current UNIX time stamp.
-spec get_current_unix_time() -> integer().
get_current_unix_time() ->
  {MegaSecs, Secs, _MicroSecs} = erlang:timestamp(),
  MegaSecs * 1000000 + Secs.

%% Generate a new random job id for Sidekiq.
%% (12-byte random number as 24 char hex string)
-spec get_job_id() -> binary().
get_job_id() ->
  Chrs = list_to_tuple("abcdef0123456789"),
  ChrsSize = size(Chrs),
  F = fun(_, R) -> [element(rand:uniform(ChrsSize), Chrs) | R] end,
  list_to_binary(lists:foldl(F, "", lists:seq(1, 24))).

%% Access the to/from JID of a given message dynamically.
-spec get_jid(message(), from | to) -> jid().
get_jid(#message{from = From} = _Packet, from) -> jid:remove_resource(From);
get_jid(#message{to = To} = _Packet, to) -> jid:remove_resource(To);
get_jid(_Packet, _Dir) -> ok.

%% Extract the stanza id from a message packet and convert it to a string.
-spec get_stanza_id(stanza()) -> string().
get_stanza_id(#message{meta = #{stanza_id := ID}}) ->
  integer_to_list(ID).

%% Assemble the Redis key for the list to write to, which will be picked up by
%% Sidekiq.
-spec queue() -> binary().
queue() ->
  Queue = gen_mod:get_module_opt(global, ?MODULE, sidekiq_queue, <<"">>),
  <<"queue:", Queue/binary>>.

%% Some ejabberd custom module API fullfilments
-spec depends(binary(), gen_mod:opts()) -> [{module(), hard | soft}].
depends(_Host, _Opts) -> [{mod_mam, hard}].

%% Parse or handle our configuration inputs
-spec mod_opt_type(atom()) -> fun((term()) -> term()) | [atom()].
mod_opt_type(O)
  when O == sidekiq_queue; O == sidekiq_class ->
    fun iolist_to_binary/1;
mod_opt_type(_) ->
  [ram_db_type, sidekiq_queue, sidekiq_class].
