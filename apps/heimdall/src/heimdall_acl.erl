-module(heimdall_acl).

-include("heimdall.hrl").

-export([add_access/5,
         add_access_set/5,
         add_full_access/4,
         check_access/4,
         check_any_access/3,
         clear_access/3,
         make_ejson_acl/2,
         make_ejson_action/3,
         parse_acl_json/2]).

%% @doc Add permission on target for authorizee
add_access(Permission, TargetType, TargetId, AuthorizeeType, AuthorizeeId) ->
    case heimdall_db:create_ace(TargetType, TargetId, AuthorizeeType, AuthorizeeId,
                                Permission) of
        ok ->
            ok;
        {error, <<"null value in column \"authorizee\" violates not-null constraint">>} ->
            throw({db_error, {non_existent_authorizee_for_acl,
                              AuthorizeeType, AuthorizeeId}});
        {error, Error} ->
            throw({db_error, Error})
    end.

%% @doc Add permission on target for list of authorizees
add_access_set(_Perm, _Type, _Id, _OtherType, []) ->
    ok;
add_access_set(Permission, TargetType, TargetId, AuthorizeeType,
               [AuthorizeeId | AuthorizeeList]) ->
    add_access(Permission, TargetType, TargetId, AuthorizeeType, AuthorizeeId),
    add_access_set(Permission, TargetType, TargetId, AuthorizeeType,
                   AuthorizeeList).

%% @doc Add all permissions on target for authorizee
add_full_access(TargetType, TargetId, AuthorizeeType, AuthorizeeId) ->
    case {AuthorizeeType, AuthorizeeId} of
        {actor, undefined} ->
            % The user we're giving access to doesn't exist (this will happen
            % when an actor creation request is made with with no requestor
            % supplied) so don't add any access
            ok;
        {actor, superuser} ->
            % The user we're giving access to doesn't exist (i.e., this is
            % a superuser request) so don't add any access
            ok;
        {Type, Id} ->
            % TODO: this should be a postgres function instead
            add_access(create, TargetType, TargetId, Type, Id),
            add_access(read, TargetType, TargetId, Type, Id),
            add_access(update, TargetType, TargetId, Type, Id),
            add_access(delete, TargetType, TargetId, Type, Id),
            add_access(grant, TargetType, TargetId, Type, Id)
    end.

%% @doc Check to see if requestor has permission on a particular target
check_access(TargetType, TargetId, RequestorId, Permission) ->
    case RequestorId of
        superuser ->
            true;
        Id ->
            heimdall_db:has_permission(TargetType, TargetId, Id, Permission)
    end.

%% @doc Check to see if requestor has any permission on a particular target
check_any_access(TargetType, TargetId, RequestorId) ->
    check_access(TargetType, TargetId, RequestorId, create) or
        check_access(TargetType, TargetId, RequestorId, read) or
        check_access(TargetType, TargetId, RequestorId, update) or
        check_access(TargetType, TargetId, RequestorId, delete) or
        check_access(TargetType, TargetId, RequestorId, grant).

%% @doc Clear permission (for given permission type) on target for all actors and groups
clear_access(TargetType, TargetId, Permission) ->
    % TODO: this needs to be a postgres function
    case heimdall_db:delete_acl(actor, TargetType, TargetId, Permission) of
        {error, Error} ->
            throw({db_error, Error});
        ok ->
            case heimdall_db:delete_acl(group, TargetType, TargetId, Permission) of
                {error, Error} ->
                    throw({db_error, Error});
                ok ->
                    ok
            end
    end.

%% @doc Return all ACL members for given member type on an ID
%%
%% I.e., return all actors or groups with read permission for a supplied AuthzID
%% of a given type (we'd be more generic about it, but we need the type to find
%% the correct tables in the DB to return the answer).
acl_members(ForType, MemberType, ForId, Permission) ->
    case heimdall_db:acl_membership(ForType, MemberType, ForId,
                                    Permission) of
        {error, Error} ->
            throw({db_error, Error});
        List ->
            List
    end.

%% @doc Create full EJSON object for permission type on given ID
%%
%% This is returned by the GET /<type>/<id>/acl/<action> endpoint
make_ejson_action(Permission, ForType, ForId) ->
    {[{<<"actors">>,
       acl_members(ForType, actor, ForId, Permission)},
      {<<"groups">>,
       acl_members(ForType, group, ForId, Permission)}]}.

%% @doc Create EJSON object fragment for permission type on given ID
%%
%% This is a fragment for a specific permission, part of what make_ejson_acl
%% returns
make_ejson_part(Permission, ForType, ForId) ->
    {Permission, make_ejson_action(Permission, ForType, ForId)}.

%% @doc Create full EJSON object for given ID
%%
%% This is returned by the GET /<type>/<id>/acl endpoint
make_ejson_acl(ForType, ForId) ->
    {[make_ejson_part(<<"create">>, ForType, ForId),
      make_ejson_part(<<"read">>, ForType, ForId),
      make_ejson_part(<<"update">>, ForType, ForId),
      make_ejson_part(<<"delete">>, ForType, ForId),
      make_ejson_part(<<"grant">>, ForType, ForId)]}.

%% @doc Parse supplied JSON ACL object, return members it contains
%%
%% This is used by the PUT /<type>/<id>/acl/<action> endpoint
parse_acl_json(Json, Action) ->
    try
        Ejson = heimdall_wm_util:decode(Json),
        Actors = ej:get({<<"actors">>}, Ejson),
        Groups = ej:get({<<"groups">>}, Ejson),
        case {Actors, Groups} of
            {ActorList, GroupList} when is_list(ActorList) andalso is_list(GroupList) ->
                {ActorList, GroupList};
            {_, _} ->
                throw({error, invalid_json})
        end
    catch
        throw:{error, {_, invalid_json}} ->
            throw({error, invalid_json});
        throw:{error, {_, truncated_json}} ->
            throw({error, invalid_json})
    end.
