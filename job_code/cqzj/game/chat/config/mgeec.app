{application, mgeec,
 [{description, "Ming game engine erlang - chat server!"},
  {id, "mgeec"},
  {vsn, "0.1"},
  {modules, [mgeec]},
  {registered, [mgeec, mgeec_sup]},
  {applications, [kernel, stdlib, sasl]},
  {mod, {mgeec, []}},
  {env, [{acceptor_num, 10}, 
	    {md5key, "this is a md5key!"},
	    {log_level, 6}]}
  ]}.           