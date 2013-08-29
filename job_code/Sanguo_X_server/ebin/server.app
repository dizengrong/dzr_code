
{   
    application, server,
    [   
      {description, "This is game server."},   
      {vsn, "1.0a"},   
      {registered, [server_sup]},   
      {applications, [kernel, stdlib]},   
      {mod, {server_app, []}},   
      {start_phases, []}
    ]   
}.  
