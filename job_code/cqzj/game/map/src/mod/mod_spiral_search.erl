%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% Description: 二维坐标由里向外顺时针搜索
%%% Created : 11 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_spiral_search).

-export([get_walkable_pos/4]).

-include("mgeem.hrl").

get_walkable_pos(MapID, X, Y, N) ->
    spiral_search(MapID, X, Y, X, Y, N, 1, 0).

spiral_search(MapID, X, Y, CX, CY, N, CN, Dir) ->
    case N =:= CN orelse CX =< 0 orelse CY =< 0 of
        true ->
            {error, not_found};
        _ ->
            case mcm:is_walkable(MapID, {CX, CY}) of
                true ->
                    {CX, CY};
                _ ->
                    if
                        Dir =:= 0 ->
                            dir_right(MapID, X, Y, CX, CY, N, CN, Dir);
                        Dir =:= 1 ->
                            dir_down(MapID, X, Y, CX, CY, N, CN, Dir);
                        Dir =:= 2 ->
                            dir_left(MapID, X, Y, CX, CY, N, CN, Dir);
                        true ->
                            dir_up(MapID, X, Y, CX, CY, N, CN, Dir)
                    end
            end
    end.

dir_right(MapID, X, Y, CX, CY, N, CN, Dir) ->
    NX = CX + 1,

    case NX > X + CN of
        true ->
            dir_down(MapID, X, Y, CX, CY, N, CN, 1);
        _ ->
            spiral_search(MapID, X, Y, NX, CY, N, CN, Dir)
    end.

dir_down(MapID, X, Y, CX, CY, N, CN, Dir) ->
    NY = CY - 1,

    case NY < Y - CN of
        true ->
            dir_left(MapID, X, Y, CX, CY, N, CN, 2);
        _ ->
            case CX =:= X + CN andalso NY =:= Y of
                true ->
                    spiral_search(MapID, X, Y, CX, NY, N, CN+1, 0);
                _ ->
                    spiral_search(MapID, X, Y, CX, NY, N, CN, Dir)
            end
    end.

dir_left(MapID, X, Y, CX, CY, N, CN, Dir) ->
    NX = CX - 1,

    case NX < X - CN of
        true ->
            dir_up(MapID, X, Y, CX, CY, N, CN, 3);
        _ ->
            spiral_search(MapID, X, Y, NX, CY, N, CN, Dir)
    end.

dir_up(MapID, X, Y, CX, CY, N, CN, Dir) ->
    NY = CY + 1,

    case NY > Y + CN of
        true ->
            dir_right(MapID, X, Y, CX, CY, N, CN, 0);
        _ ->
            spiral_search(MapID, X, Y, CX, NY, N, CN, Dir)
    end.
