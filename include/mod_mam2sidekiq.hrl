-define(MODULE_VERSION, <<"1.1.0-478">>).
-define(NS_MAM_SIDEKIQ, <<"xmpp:mam:hausgold:sidekiq">>).

%% A macro to convert a record to tuple{[tuples]} for jiffy (JSON) encoding
-define(record_to_tuple(Rec, Ref),
        {lists:zip(record_info(fields, Rec), tl(tuple_to_list(Ref)))}).

-record(job, {class = 'undefined' :: binary(),
              jid = 'undefined' :: binary(),
              args = [] :: nonempty_list(string()),
              created_at = 0 :: non_neg_integer(),
              enqueued_at = 0 :: non_neg_integer()}).
