-define(MODULE_VERSION, <<"0.1.0-325">>).
-define(NS_MAM_SIDEKIQ, <<"xmpp:mam:hausgold:sidekiq">>).

%% A macro to convert a record to tuple{[tuples]} for jiffy (JSON) encoding
-define(record_to_tuple(Rec, Ref),
        {lists:zip(record_info(fields, Rec), tl(tuple_to_list(Ref)))}).

-record(job, {class = 'undefined' :: binary(),
              jid = 'undefined' :: binary(),
              args = [] :: nonempty_list(string()),
              created_at = 0 :: non_neg_integer(),
              enqueued_at = 0 :: non_neg_integer()}).

%% <event xmlns="xmpp:mam:hausgold:sidekiq">
%%   <meta
%%     type='chat'
%%     from='bob.local/Bob Mustermann (UUID)'
%%     to='alice@jabber.local/Alice Mustermann (UUID)'
%%     id='1560857013427582'
%%     />
%%   <message
%%     xml:lang='en'
%%     to='alice@jabber.local'
%%     from='bob@jabber.local/98198947957023277897618'
%%     id='40dc0a07-acaa-4585-988b-1c7e151b97d5'
%%     xmlns='jabber:client'>
%%     <body>
%%       Try to copy the THX protocol, maybe it will
%%       calculate the auxiliary matrix!
%%     </body>
%%   </message>
%% </event>

%% <event xmlns="xmpp:mam:hausgold:sidekiq">
%%   <meta
%%     type='groupchat'
%%     from='bob.local/Bob Mustermann (UUID)'
%%     to='room-name@conference.jabber.local'
%%     id='1560857013427582'
%%     />
%%   <message
%%     xml:lang='en'
%%     to='room-name@conference.jabber.local'
%%     from='bob@jabber.local/98198947957023277897618'
%%     id='40dc0a07-acaa-4585-988b-1c7e151b97d5'
%%     xmlns='jabber:client'>
%%     <body>
%%       Try to copy the THX protocol, maybe it will
%%       calculate the auxiliary matrix!
%%     </body>
%%   </message>
%% </event>
