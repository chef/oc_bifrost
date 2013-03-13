-module(heimdall_wm_group_member_resource).

-include("heimdall_wm_rest_endpoint.hrl").
-include_lib("stats_hero/include/stats_hero.hrl").

-export([delete_resource/2,
         from_json/2]).

init(Config) ->
    heimdall_wm_base:init(?MODULE, Config).

allowed_methods(Req, State) ->
    {['PUT', 'DELETE'], Req, State}.

validate_request(Req, State) ->
    heimdall_wm_base:validate_requestor(Req, State).

auth_info(Verb) when Verb =:= 'PUT';
                     Verb =:= 'DELETE' ->
    update.

from_json(Req, #base_state{reqid = ReqId,
                           authz_id = AuthzId,
                           member_type = MemberType,
                           member_id = MemberId} = State) ->
    case ?SH_TIME(ReqId, heimdall_db, add_to_group, (MemberType, MemberId, AuthzId)) of
        ok ->
            {true, wrq:set_resp_body(<<"{}">>, Req), State};
        {error, ErrorString} ->
            case heimdall_wm_error:db_error_string_to_atom(ErrorString) of
                null_violation ->
                    heimdall_wm_error:set_db_exception(Req, State,
                                                       {non_existent_member_for_group,
                                                        MemberType, MemberId});
                group_cycle ->
                    heimdall_wm_error:set_db_exception(Req, State, {group_cycle, MemberId});
                Error ->
                    heimdall_wm_error:set_db_exception(Req, State, Error)
            end
    end.

delete_resource(Req, #base_state{reqid = ReqId,
                                 authz_id = AuthzId,
                                 member_type = MemberType,
                                 member_id = MemberId} = State) ->
    case ?SH_TIME(ReqId, heimdall_db, remove_from_group, (MemberType, MemberId, AuthzId)) of
        ok ->
            {true, wrq:set_resp_body(<<"{}">>, Req), State};
        {error, not_found_in_group} ->
            heimdall_wm_error:set_db_exception(Req, State, {not_found_in_group,
                                                            MemberId});
        {error, Error} ->
            heimdall_wm_error:set_db_exception(Req, State, Error)
    end.
