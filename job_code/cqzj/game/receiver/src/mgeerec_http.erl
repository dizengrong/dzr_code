%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 30 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeerec_http).

%% API
-export([post/5]).

-include("mgeerec.hrl").

-define(CRLF, "\r\n").


%%%===================================================================
%%% API
%%%===================================================================


%%post数据出去
post(AgentID, GameID, ModuleTuple, MethodTuple, BinaryList) ->

    ?DEBUG("~ts:~w ~ts:~w", ["准备通过HTTP发送数据, 模块", ModuleTuple, "方法", MethodTuple]),
    %%暂时弄一个
    {_, Host, Url}= common_config:get_receiver_http_host(),

    {_PBModule, PHPControllerName} = ModuleTuple,
    {_PBMethod, PHPMethodName} = MethodTuple,
    Content = make_content(AgentID, GameID, BinaryList),

    Url2 = lists:concat([Url, "?r=", common_tool:to_list(PHPControllerName), "/", common_tool:to_list(PHPMethodName)]),

    Data = header_body(Host, Url2, Content),

    case gen_tcp:connect(Host, 80, [inet, list, {active, false}]) of
        {ok, Socket} ->
            gen_tcp:send(Socket, Data),
            do_recv(Socket);
        {error, Reason} ->
            ?ERROR_MSG("~ts:~p~n", ["无法连接到服务器", Reason])
    end.
    

%%构造POST数据
make_content(AgentID, GameID, BinaryList) ->
    Data = 
        lists:map(
          fun(Binary) ->
                  lists:concat(["&data[]=", common_tool:to_list(Binary)])  
          end, BinaryList),

    lists:concat(
      ["agent_id=", 
       AgentID, 
       "&game_no=",
       GameID, 
       lists:concat(Data)
       ]).


%%数据接受
do_recv(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            [H|_] = string:tokens(Data, [13, 10]),

            case string:tokens(H, " ") of
                [_, ResponseNo, ResponseStr] ->  
                    case ResponseNo of
                        "200" ->
                            case ResponseStr of
                                "OK" ->
                                    ?DEBUG("~ts", ["HTTP请求成功"]),
                                    ok;
                                Error ->
                                    ?ERROR_MSG("~ts:~w", ["200返回结果出错", Error]),
                                    error
                            end;
                        ErrorNo ->
                            ?ERROR_MSG("~ts:~w", ["HTTP请求返回状态错误", ErrorNo]),
                            error
                    end;
                Other ->
                    ?ERROR_MSG("~ts:~w", ["未知的HTTP请求返回数据", Other]),
                    error
            end,
            gen_tcp:close(Socket);
        {error, closed} ->
            ?ERROR_MSG("~ts", ["HTTP服务连接关闭"]);
        {error, Reason} ->
            ?ERROR_MSG("~ts: ~p", ["读取HTTP请求结果出错", Reason]),
            gen_tcp:close(Socket)
    end.


%%构造头部和主体数据
header_body(Host, Url, Content) ->
    ContentLength = integer_to_list(erlang:length(Content)),
    %%POST 一定要大写 否则报错:400
    ["POST", " ", Url, " ", "HTTP/1.1", ?CRLF,
     "Host: ", Host, ?CRLF, "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.2.4) Gecko/20100513 Firefox/3.6.4",
     ?CRLF, "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
     ?CRLF, "Accept-Language: zh-cn,zh;q=0.5", 
     ?CRLF, "Accept-Charset: GB2312,utf-8;q=0.7,*;q=0.7",
     ?CRLF, "Keep-Alive: 115", 
     ?CRLF, "Connection: keep-alive",
     ?CRLF, "Referer: http://", Host, Url,
     ?CRLF, "Content-Type: application/x-www-form-urlencoded",
     ?CRLF, "Content-Length: ", ContentLength,
     ?CRLF, ?CRLF, Content].



    
