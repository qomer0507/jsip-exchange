open! Core
open! Async
open Jsip_gateway
open Jsip_types

let with_server ~symbols f =
  let%bind server = Exchange_server.start ~symbols ~port:0 () in
  let port = Exchange_server.port server in
  Monitor.protect
    (fun () -> f ~server ~port)
    ~finally:(fun () -> Exchange_server.close server)
;;

type client = { conn : Rpc.Connection.t }

let login conn participant =
  Rpc.Rpc.dispatch_exn Rpc_protocol.login_rpc conn participant >>| ok_exn
;;

let connect_as ~port participant =
  let where =
    Tcp.Where_to_connect.of_host_and_port { host = "localhost"; port }
  in
  (* let%map x = y in f x

     Deferred.map y ~f:(fun x -> f x) = Deferred.bind y ~f:(fun x -> return
     (f x))
  *)
  let%bind conn = Rpc.Connection.client where >>| Result.ok_exn in
  let client = { conn } in
  let%bind (_ : Participant.t) =
    login client.conn (Participant.to_string participant)
  in
  let%map session_feed, _metadata =
    Rpc.Pipe_rpc.dispatch_exn Rpc_protocol.session_feed_rpc client.conn ()
  in
  don't_wait_for
    (Pipe.iter_without_pushback session_feed ~f:(fun event ->
       let e = Protocol.format_event event in
       print_endline [%string "[%{Participant.to_string participant}] %{e}"]));
  client
;;

let connection client = client.conn

let rpc_submit client request =
  Rpc.Rpc.dispatch_exn Rpc_protocol.submit_order_rpc client.conn request
  >>| ok_exn
;;

let rpc_book client symbol =
  Rpc.Rpc.dispatch_exn Rpc_protocol.book_query_rpc client.conn symbol
;;
