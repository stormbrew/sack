Sack: Stream-Oriented Rack
==========================
This library is an experiment in attempting a different solution to
server applications that need to stream and/or manage their own thread
pooling.

It inverts the rack-style request handling by having the application
ask for requests rather than be given them through a block that assumes
the entire request will take place within that block. The application is
then free to handle the request as it wishes, in whatever timeframe it
wishes.

This mechanism avoids the contortions necessary to make a rack request
asynchronous by assuming that they will be to begin with. It also avoids
the incompatibilities that arise from expectations of synchronicity in
existing middleware, though it does this by defining a whole new contract
rather than working with the existing one.

It is also compatible with rack in both directions. It is trivially possible
to adapt a conventional rack application into this framework, and the 
only current implementation of a server is in fact a rack server.

Contracts
=========

Server Contract
---------------
A Sack Server is any object that responds to the following methods as defined:

* obj#initialize(options)
  options is a hash of key/value pairs that identify how the server should
  operate. The only well defined options are Host and Port, which have
  the obvious meanings.
* obj#start
  runs the server in the current thread, making requests available as described
  below in obj#wait.
* obj#wait
  waits for a request to come in and then returns it.
* obj#stop
  stops the server gracefully, allowing all requests currently in operation to
  complete if possible while no longer accepting further connections. It may 
  act like stop! after a reasonable wait period, however.
* obj#stop!
  stops the server immediately, without regard for connected clients.

Middleware Contract
-------------------
Middleware must appear, for all intents and purposes, as if it is a Server.
The only difference is initialize(). Any other methods listed in Server must
be passed through to the parent middleware (which may be a Server), with or
without modification.

In particular, obj#wait may return a wrapped request object that handles
the behaviour of the request differently (such as by logging data, compressing
it, etc).

For examples, see the lib/middleware directory.

* obj#initialize(parent, *args)
  Takes a parent middleware/server and any number of other arguments as
  appropriate to defining the function of the middleware.

Request Contract
----------------
The request object returned by a server or middleware #wait method must respond
to the following methods as described. Other methods may be added, but they must
not modify the behaviour of these methods:

* obj#env
  returns a Rack-style environment object. Refer to the rack spec for
  details about what may or may not be in the env object. It should
  have 'sack.version' rather than 'rack.version' (or in addition to). sack.version
  MUST NOT be set implicitly to Sack::VERSION, it should be set to the version
  of sack the originating object was written to.
* obj#headers(status, headers) => body
  give it a status code and a header hash, and it returns a body object to be
  filled out with #<< and completed with #done. See below for explanations of
  those. Repeated calls to #headers will result in undefined behaviour, and
  possibly exceptions. Don't do it.
* body#<<(data)
  Data to be sent to the client. Should be sent as soon as possible. Should raise
  an error if the client connection has been closed in the meantime.
* body#done
  Indicates that the request has been completed.
* body#open?
  Should be false if done has been called or the connection has been closed by
  the client.

