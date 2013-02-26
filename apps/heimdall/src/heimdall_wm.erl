-module(heimdall_wm).

-include("heimdall_wm.hrl").

-type error() :: {error, term()}.
-type http_verb() :: 'GET' | 'PUT' | 'POST' | 'DELETE' | 'HEAD' | 'OPTIONS'.
-type base_state() :: #base_state{}.
-type wm_req() :: #wm_reqdata{}.

-callback init(list()) ->
    {ok, base_state()} | error().

-callback auth_info(http_verb()) ->
    ignore | any | permission().

-callback forbidden(wm_req(), base_state()) ->
    {{halt, non_neg_integer()}, wm_req(), base_state()} |
    {true, wm_req(), base_state()} |
    {false, wm_req(), base_state()}.

-callback malformed_request(wm_req(), base_state()) ->
    {{halt, non_neg_integer()}, wm_req(), base_state()} |
    {true, wm_req(), base_state()} |
    {false, wm_req(), base_state()}.

-callback validate_request(wm_req(), base_state()) ->
    {{halt, non_neg_integer()}, wm_req(), base_state()} |
    {true, wm_req(), base_state()} |
    {false, wm_req(), base_state()}.
