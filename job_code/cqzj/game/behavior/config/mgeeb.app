{application, mgeeb,
 [{description, "Ming game engine behavior server!"},
  {id, "mgeeb"},
  {vsn, "0.1"},
  {modules, [mgeeb]},
  {registered, [mgeeb, mgeeb_sup]},
  {applications, [kernel, stdlib, sasl]},
  {mod, {mgeeb, []}},
  {env, [
		{log_level, 5}]}
  ]}.
