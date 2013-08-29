%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :排行榜专用最小堆
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_minheap).

-include("mgeew.hrl").


-export([
         new_heap/2,
         new_heap/4,
         get_top_element/1,
         insert/4,
         pop/2,
         is_full/1,
         is_empty/1,
         get_heap_size/1,
         get_max_heap_size/1,
         delete/3,
         update_heap/5,
         clear_heap/1,
         key_find/2
        ]).

%%
%%================API FUCTION=======================
%%
%%新创建一个空堆
new_heap(ModuleKey, HeapSize) ->
    put({ModuleKey,max_heapsize},HeapSize),
    put({ModuleKey,heapsize},0),
    put({ModuleKey,mark},0).


%%新创建一个堆并初始化一些元素
new_heap(ModuleName,ModuleKey, HeapSize, ElementList) ->
    new_heap(ModuleKey, HeapSize),
    lists:foreach(fun({Element,Key}) -> insert(ModuleName,ModuleKey,Element,Key) end,ElementList).


%%获取堆顶元素
get_top_element(ModuleKey) ->
    case is_empty(ModuleKey) of
        true->
            undefined;
        false ->
            get({ModuleKey,0})
    end. 


%%插入新的元素
insert(ModuleName,ModuleKey,Element,Key) ->
    case is_full(ModuleKey) of
        true ->
            nil;
        false ->
            Size = get_heap_size(ModuleKey),
            set_new_element(ModuleKey,Size,Element,Key),
            filter_up(ModuleName,ModuleKey,Size),
            put({ModuleKey,heapsize},Size+1)
    end.


%%删除堆顶的元素
pop(ModuleName,ModuleKey) ->
    case is_empty(ModuleKey) of
        true ->
            nil;
        false ->
            {TopElement,TopKey} = get({ModuleKey,0}),
            erase({ModuleKey,key,TopKey}),
            LastIndex = get_heap_size(ModuleKey) - 1,
            {LastElement,LastKey} = get({ModuleKey,LastIndex}),
            set_new_element(ModuleKey,0,LastElement,LastKey),
            put({ModuleKey,heapsize},LastIndex),
            filter_down(ModuleName,ModuleKey,0),
            TopElement
    end.


%%删除堆中的某一元素然后维护堆
delete(ModuleName,ModuleKey,Key) ->
    case get({ModuleKey,key,Key}) of
        undefined ->
            nil;
        Index ->
            erase({ModuleKey,key,Key}),
            LastIndex = get_heap_size(ModuleKey) - 1,
            {LastElement,LastKey} = get({ModuleKey,LastIndex}),
            set_new_element(ModuleKey,Index,LastElement,LastKey),
            put({ModuleKey,heapsize},LastIndex),
            filter(ModuleName,ModuleKey,Index,LastElement,LastKey)
    end.


get_heap_size(ModuleKey) ->    
    get({ModuleKey,heapsize}).

get_max_heap_size(ModuleKey) ->    
    get({ModuleKey,max_heapsize}).


%%判断是否堆满      
is_full(ModuleKey) ->
    MaxHeapSize = get({ModuleKey,max_heapsize}),
    HeapSize = get({ModuleKey,heapsize}),
    HeapSize >= MaxHeapSize.

%%判断堆是否为空
is_empty(ModuleKey) ->
    HeapSize = get({ModuleKey,heapsize}),
    HeapSize =:= 0.

update_heap(Rank,Key,DBName,ModuleName,ModuleKey) ->  
	case is_full(ModuleKey) of
		true ->   
			case get({ModuleKey,key,Key}) of
				undefined ->
					case get_top_element(ModuleKey) of
						undefined ->
							{fail,undefined};
						{MinRank,MinKey} ->
							case ModuleName:cmp(Rank,MinRank) of
								true ->
									%%如果比最低的还低且堆满则不处理
									{fail,out_of_rank};
								false ->
									db:dirty_delete(DBName,MinKey),
									db:dirty_write(DBName,Rank),
									pop(ModuleName,ModuleKey),
									insert(ModuleName,ModuleKey,Rank,Key)
							end
					end;
				Index ->
					db:dirty_write(DBName,Rank),
					update(ModuleName,ModuleKey,Key,Rank,Index)
			end;
		false -> 
			db:dirty_write(DBName,Rank), 
			insert(ModuleName,ModuleKey,Rank,Key)
	end.

clear_heap(ModuleKey) ->
    Size = get_heap_size(ModuleKey),
    lists:foreach(
      fun(Index) -> 
              case get({ModuleKey,Index}) of
                  {_,Key} ->
                      erase({ModuleKey,Index}), 
                      erase({ModuleKey,key,Key});
                  undefined ->
                      ?DEBUG("reset_ranking_heap_error,modulekey=~w,index=~w",[ModuleKey,Size])
              end
      end,lists:seq(0,Size)).
%%     erase({ModuleKey,max_heapsize}),
%%     erase({ModuleKey,heapsize}),
%%     erase({ModuleKey,mark}).
    
    
key_find(ModuleKey,Key) ->
    case erlang:get({ModuleKey,key,Key}) of
        undefined ->
            undefined;
        Index ->
            erlang:get({ModuleKey,Index})
    end.
%%
%%================LOCAL FUCTION=======================
%%
%%跟新堆中元素的值然后重新维护堆
update(ModuleName,ModuleKey,Key,Element,Index) ->
    set_new_element(ModuleKey,Index,Element,Key),
    filter(ModuleName,ModuleKey,Index,Element,Key).


set_new_element(ModuleKey,Index,Element,Key) ->
    put({ModuleKey,Index},{Element,Key}),
    put({ModuleKey,key,Key},Index).


filter(ModuleName,ModuleKey,Index,Element,_Key) ->
    ParentIndex = trunc((Index - 1) / 2),
    {ParentElement,_ParentKey} = get({ModuleKey,ParentIndex}),
    case ModuleName:cmp(ParentElement,Element) of
        false ->
            %%新的值比父节点小的时候往上跟新
            filter_up(ModuleName,ModuleKey,Index);
        true ->
            %%新的值比父亲节点大的时候往下跟新
            filter_down(ModuleName,ModuleKey,Index)
    end.


filter_up(ModuleName,ModuleKey,Index) ->
    CurrentIndex = Index,
    ParentIndex = trunc((Index - 1) / 2),
    {TargetElement,TargetKey} = get({ModuleKey,CurrentIndex}),
    NewCurrentIndex = filter_up2(CurrentIndex,ParentIndex,TargetElement,ModuleName,ModuleKey),
    set_new_element(ModuleKey,NewCurrentIndex,TargetElement,TargetKey).

filter_up2(0,_,_,_,_) ->
    0;
filter_up2(CurrentIndex,ParentIndex,TargetElement,ModuleName,ModuleKey) ->
    {ParentElement,ParentKey} = get({ModuleKey,ParentIndex}),
    case ModuleName:cmp(ParentElement,TargetElement) of
        true ->
            CurrentIndex;
        false ->
            set_new_element(ModuleKey,CurrentIndex,ParentElement,ParentKey),
            filter_up2(ParentIndex, trunc((ParentIndex-1)/2), TargetElement,ModuleName,ModuleKey)
    end.


filter_down(ModuleName,ModuleKey,Index) ->
    CurrentIndex = Index,
    ChildIndex = 2*Index + 1,
    {TargetElement,TargetKey} = get({ModuleKey,CurrentIndex}),
    HeapSize = get({ModuleKey,heapsize}),
    NewCurrentIndex = filter_down2(CurrentIndex,ChildIndex,TargetElement,HeapSize,ModuleName,ModuleKey),
    set_new_element(ModuleKey,NewCurrentIndex,TargetElement,TargetKey).
    

filter_down2(CurrentIndex,ChildIndex,TargetElement,HeapSize,ModuleName,ModuleKey) ->
    case ChildIndex < HeapSize of
        false ->
            CurrentIndex;
        true ->
            case ChildIndex + 1 < HeapSize of
                true ->
                    {Element1,_} = get({ModuleKey,ChildIndex+1}),
                    {Element2,_} = get({ModuleKey,ChildIndex}),
                    case ModuleName:cmp(Element1,Element2) of
                        true ->
                            NewChildIndex = ChildIndex + 1;
                        false ->
                            NewChildIndex = ChildIndex
                    end;
                false ->
                    NewChildIndex = ChildIndex
            end,
            {ChildElement,ChildKey} = get({ModuleKey,NewChildIndex}),
            case ModuleName:cmp(TargetElement,ChildElement) of
                true ->
                    CurrentIndex;
                false ->
                    set_new_element(ModuleKey,CurrentIndex,ChildElement,ChildKey),
                    filter_down2(NewChildIndex,NewChildIndex*2+1,TargetElement,HeapSize,ModuleName,ModuleKey)
            end
    end.
        

