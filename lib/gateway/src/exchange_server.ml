open! Core
open! Async
open Jsip_types
open Jsip_order_book

type t =
  { engine : Matching_engine.t
  ; dispatcher : Dispatcher.t
  ; request_writer : Order.Request.t Pipe.Writer.t
  ; tcp_server : (Socket.Address.Inet.t, int) Tcp.Server.t
  ; port : int
  }

let request_queue_size_budget = 1024

module Connection_state = struct
  type t = { mutable session : Session.t option }
end

let handle_submit ~request_writer (request : Order.Request.t) =
  let%map () = Pipe.write_if_open request_writer request in
  Ok ()
;;

let start_matching_loop ~engine ~dispatcher request_reader =
  don't_wait_for
    (Pipe.iter_without_pushback request_reader ~f:(fun request ->
       let events = Matching_engine.submit engine request in
       Dispatcher.dispatch dispatcher events))
;;

let start ~symbols ~port () =
  let engine = Matching_engine.create symbols in
  let dispatcher = Dispatcher.create () in
  let request_reader, request_writer = Pipe.create () in
  Pipe.set_size_budget request_writer request_queue_size_budget;
  start_matching_loop ~engine ~dispatcher request_reader;
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations:
        [ Rpc.Rpc.implement
            Rpc_protocol.submit_order_rpc
            (fun (state : Connection_state.t) request ->
               match state.session with
               | Some session ->
                 let participant = Session.participant session in
                 let request = { request with participant } in
                 handle_submit ~request_writer request
               | None -> return (Or_error.error_string "not logged in"))
        ; Rpc.Rpc.implement' Rpc_protocol.book_query_rpc (fun state symbol ->
            ignore state;
            Matching_engine.book engine symbol
            |> Option.map ~f:Order_book.snapshot)
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.market_data_rpc
            (fun state symbols ->
               ignore state;
               let reader =
                 Dispatcher.subscribe_market_data dispatcher symbols
               in
               return (Ok reader))
        ; Rpc.Pipe_rpc.implement Rpc_protocol.audit_log_rpc (fun state () ->
            ignore state;
            let reader = Dispatcher.subscribe_audit dispatcher in
            return (Ok reader))
        ; Rpc.Rpc.implement
            Rpc_protocol.login_rpc
            (fun (state : Connection_state.t) name ->
               let name = String.strip name in
               if String.is_empty name
               then return (Or_error.error_string "Name is empty")
               else (
                 let participant = Participant.of_string name in
                 let%map session =
                   Dispatcher.set_up_session dispatcher participant
                 in
                 state.session <- Some session;
                 Ok participant))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.session_feed_rpc
            (fun (state : Connection_state.t) () ->
               match state.session with
               | Some session -> return (Ok (Session.reader session))
               | None -> return (Or_error.error_string "not logged in"))
        ; Rpc.Rpc.implement
            Rpc_protocol.cancel_order_rpc
            (fun (state : Connection_state.t) client_order_id ->
               match state.session with
               | Some session ->
                 let participant = Session.participant session in
                 let events =
                   Matching_engine.cancel engine participant client_order_id
                 in
                 Dispatcher.dispatch dispatcher events;
                 return (Ok ())
               | None -> return (Or_error.error_string "not logged in"))
        ]
      ~on_unknown_rpc:`Close_connection
      ~on_exception:Log_on_background_exn
  in
  let%map tcp_server =
    Rpc.Connection.serve
      ~implementations
      ~initial_connection_state:(fun _addr conn ->
        let state = { Connection_state.session = None } in
        don't_wait_for
          (let%bind () = Rpc.Connection.close_finished conn in
           match state.session with
           | Some session -> Dispatcher.clean_up_session dispatcher session
           | None -> Deferred.return ());
        state)
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ()
  in
  let actual_port = Tcp.Server.listening_on tcp_server in
  { engine; dispatcher; request_writer; tcp_server; port = actual_port }
;;

let port t = t.port

let close t =
  Pipe.close t.request_writer;
  Tcp.Server.close t.tcp_server
;;

let close_finished t = Tcp.Server.close_finished t.tcp_server
