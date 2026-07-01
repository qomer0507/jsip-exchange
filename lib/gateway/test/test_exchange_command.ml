open! Core
open Jsip_types
open Jsip_gateway

let print_parse line =
  match Exchange_command.parse line with
  | Error err -> print_endline [%string "ERROR: %{Error.to_string_hum err}"]
  | Ok (Submit req) -> print_endline [%string "%{req#Order.Request}"]
  | Ok (Book symbol) -> print_endline [%string "BOOK %{symbol#Symbol}"]
  | Ok (Subscribe symbol) ->
    print_endline [%string "SUBSCRIBE %{symbol#Symbol}"]
;;

let%expect_test "parse: basic buy" =
  print_parse "BUY AAPL 100 150.25";
  [%expect {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse: basic sell" =
  print_parse "SELL TSLA 50 200.00";
  [%expect {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse: case insensitive verb" =
  print_parse "buy AAPL 100 150.00";
  print_parse "Buy AAPL 100 150.00";
  [%expect
    {|
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    |}]
;;

let%expect_test "parse: with IOC time-in-force" =
  print_parse "BUY AAPL 100 150.00 IOC";
  [%expect {|
    ERROR: invalid client_order_id: AAPL
    exception: (Failure "Int.of_string: \"AAPL\"")
    |}]
;;

let%expect_test "parse: with explicit DAY" =
  print_parse "SELL AAPL 200 151.00 DAY";
  [%expect {|
    ERROR: invalid client_order_id: AAPL
    exception: (Failure "Int.of_string: \"AAPL\"")
    |}]
;;

let%expect_test "parse: with participant" =
  print_parse "BUY AAPL 100 150.00 as Alice";
  [%expect {|
    ERROR: invalid client_order_id: AAPL
    exception: (Failure "Int.of_string: \"AAPL\"")
    |}]
;;

let%expect_test "parse: with TIF and participant" =
  print_parse "SELL GOOG 75 2800.50 IOC as Bob";
  [%expect {|
    ERROR: invalid client_order_id: GOOG
    exception: (Failure "Int.of_string: \"GOOG\"")
    |}]
;;

let%expect_test "parse: symbol casing preserved" =
  print_parse "BUY aapl 100 150.00";
  [%expect {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse: extra whitespace is ignored" =
  print_parse " BUY   AAPL 100 150.00 ";
  [%expect {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse: price with dollar sign" =
  print_parse "BUY AAPL 100 $150.25";
  [%expect {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse: book" =
  print_parse "BOOK AAPL";
  [%expect {| BOOK AAPL |}]
;;

let%expect_test "parse: subscribe case insensitive" =
  print_parse "subscribe AAPL";
  [%expect {| SUBSCRIBE AAPL |}]
;;

let%expect_test "parse error: empty string" =
  print_parse "";
  print_parse " ";
  [%expect {|
    ERROR: empty command
    ERROR: empty command
    |}]
;;

let%expect_test "parse error: unknown command" =
  print_parse "HOLD AAPL 100 150.00";
  [%expect
    {| ERROR: ("Exchange_command.Verb.of_string: invalid string" (value Hold)) |}]
;;

let%expect_test "parse error: missing fields" =
  print_parse "BUY AAPL";
  print_parse "BUY";
  [%expect
    {|
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    |}]
;;

let%expect_test "parse error: invalid size" =
  print_parse "BUY AAPL abc 150.00";
  print_parse "BUY AAPL 0 150.00";
  print_parse "BUY AAPL -5 150.00";
  [%expect
    {|
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]
    |}]
;;

let%expect_test "parse error: invalid price" =
  print_parse "BUY AAPL 100 xyz";
  [%expect
    {| ERROR: expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>] |}]
;;

let%expect_test "parse error: unknown time-in-force" =
  print_parse "BUY AAPL 100 150.00 QQQ";
  [%expect
    {|
    ERROR: invalid client_order_id: AAPL
    exception: (Failure "Int.of_string: \"AAPL\"")
    |}]
;;

let%expect_test "parse error: book missing symbol" =
  print_parse "BOOK";
  [%expect {| ERROR: expected: BOOK <symbol> |}]
;;

let%expect_test "parse error: subscribe missing symbol" =
  print_parse "SUBSCRIBE";
  [%expect {| ERROR: expected: SUBSCRIBE <symbol> |}]
;;

let%expect_test "default participant: used when none specified" =
  let default_participant = Participant.of_string "DefaultTrader" in
  let command =
    Exchange_command.parse ~default_participant "BUY AAPL 100 150.00"
    |> ok_exn
  in
  match command with
  | Submit req ->
    print_endline [%string "participant=%{req.participant#Participant}"]
  | _ -> [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  "expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as <name>]"
  Raised at Base__Error.raise in file "src/error.ml", line 17, characters 38-66
  Called from Base__Error.raise in file "src/error.ml" (inlined), line 25, characters 47-66
  Called from Base__Or_error.ok_exn in file "src/or_error.ml" (inlined), line 100, characters 17-44
  Called from Jsip_gateway_test__Test_exchange_command.(fun) in file "lib/gateway/test/test_exchange_command.ml", lines 156-157, characters 4-83
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 359, characters 10-25
  |}]
;;

let%expect_test "default participant: overridden by explicit as" =
  let default_participant = Participant.of_string "DefaultTrader" in
  let command =
    Exchange_command.parse
      ~default_participant
      "BUY AAPL 100 150.00 as Alice"
    |> ok_exn
  in
  match command with
  | Submit req ->
    print_endline [%string "participant=%{req.participant#Participant}"]
  | _ -> [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
   "invalid client_order_id: AAPL\
  \nexception: (Failure \"Int.of_string: \\\"AAPL\\\"\")"
  Raised at Base__Error.raise in file "src/error.ml", line 17, characters 38-66
  Called from Base__Error.raise in file "src/error.ml" (inlined), line 25, characters 47-66
  Called from Base__Or_error.ok_exn in file "src/or_error.ml" (inlined), line 100, characters 17-44
  Called from Jsip_gateway_test__Test_exchange_command.(fun) in file "lib/gateway/test/test_exchange_command.ml", lines 179-182, characters 4-104
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 359, characters 10-25
  |}]
;;
