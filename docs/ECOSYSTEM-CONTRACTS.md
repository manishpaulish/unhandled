# Effect contracts, derived

What each library asks its callers to handle, read out of the compiler's
own typed trees rather than written by hand. OCaml 5's effect handlers are
untyped, so nothing else in the ecosystem states this, and no hand-written
version would stay true for long.

`...unknown` in a set means the contract is incomplete at that function
because it calls into code with no `.cmt` available. It is printed rather
than rounded away: a contract that quietly stops short is worth less than
one that says where it stops.

Regenerate with `bash bench/contracts.sh`.

Analyser build `00878a7c6328`, generated 2026-08-27.

## cabal

```
module Cabal__Gemini_cli
  Cabal__Gemini_cli.read_project_file may perform {Eio__core.Suspend.Suspend}
  Cabal__Gemini_cli.check_project_config may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Session_event_log
  Cabal__Session_event_log.append_line may perform {Eio__core.Suspend.Suspend}
  Cabal__Session_event_log.try_append may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_session_start may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_session_end may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_turn_start may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_turn_end may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_turn_failed may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.write_raw_event may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Session_event_log.list_sessions may perform {Eio__core.Suspend.Suspend}
  Cabal__Session_event_log.read_events may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Copilot_cli
  Cabal__Copilot_cli.read_project_file may perform {Eio__core.Suspend.Suspend}
  Cabal__Copilot_cli.validate_strict_json_file may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Copilot_cli.check_project_config may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Opencode_cli
  Cabal__Opencode_cli.ensure_mcp_in_opencode_json may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Opencode_cli.ensure_mcp_if_config_applied may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Opencode_cli.read_opencode_backup may perform {Eio__core.Suspend.Suspend}
  Cabal__Opencode_cli.try_restore    may perform {Eio__core.Suspend.Suspend}
  Cabal__Opencode_cli.check_opencode_mutation may perform {Eio__core.Suspend.Suspend}
  Cabal__Opencode_cli.run_task       may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Backend_process
  Cabal__Backend_process.capture_version_output may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.check_available may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.write_mcp_config may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.setup_mcp_config may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Backend_process.cleanup_mcp_config may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.run_git     may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.get_git_diff may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.diff_untracked_file may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.get_git_diff_content may perform {Eio__core.Suspend.Suspend}
  Cabal__Backend_process.run_process may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Backend_process.run_task_with may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Session_trimmer
  Cabal__Session_trimmer.fork_trimmed may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Codex_cli
  Cabal__Codex_cli.read_project_file may perform {Eio__core.Suspend.Suspend}
  Cabal__Codex_cli.check_project_config may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Mock_agent
  Cabal__Mock_agent.load_rules       may perform {Eio__core.Suspend.Suspend}
  Cabal__Mock_agent.run_task         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cabal__Resource_guardian
  Cabal__Resource_guardian.kill_registered_pids may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Resource_guardian.poll_once_1012 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cabal__Resource_guardian.run       may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_native_json_schema_backends
  Dune__exe__Test_native_json_schema_backends.rmdir_r may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_native_json_schema_backends.init_git_repo may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_native_json_schema_backends.run_native_e2e_for_backend may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_real_backend_smoke
  Dune__exe__Test_real_backend_smoke.availability_with_timeout may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_real_backend_smoke.run_backend may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_demo_627
  Dune__exe__Test_demo_627.run_cmd_eio may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_demo_627.rmdir_r_eio may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_demo_627.run_715   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_demo_627.init_git_repo_eio may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_demo_627.run_enforcer_schema_compliance_for_backend may perform {Eio__core.Suspend.Suspend, ...unknown}

763 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## capnp-rpc

```
module Capnp_rpc__Leak_handler
  Capnp_rpc__Leak_handler.run        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Capnp_rpc__Leak_handler.ref_leak_detected may perform {Eio__core.Suspend.Suspend, ...unknown}

925 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## caqti-eio

```
module Caqti_eio_unix__System_unix
  Caqti_eio_unix__System_unix.Unix.f_533 may perform {Eio__core.Suspend.Suspend}
  Caqti_eio_unix__System_unix.Unix.poll may perform {Eio__core.Suspend.Suspend}

module Caqti_eio__System
  Caqti_eio__System.pp_390           may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Sequencer.create may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Sequencer.enqueue may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Alarm.schedule   may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Alarm.unschedule may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.Sockaddr.tcp may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.getaddrinfo  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.Socket.output_char may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.Socket.output_string may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.Socket.flush may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.Socket.input_char may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.Socket.really_input may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.Socket.close may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.tcp_flow_of_socket may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.start_writer may perform {Eio__core.Suspend.Suspend, ...unknown}
  Caqti_eio__System.Net.socket_of_flow may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.socket_of_tls_flow may perform {Eio__core.Suspend.Suspend}
  Caqti_eio__System.Net.connect_tcp  may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Main_eio_unix
  Dune__exe__Main_eio_unix.connect_1439 may perform {Eio__core.Suspend.Suspend, ...unknown}

3189 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## cohttp-bench

```
module Cohttp_eio__Io
  Cohttp_eio__Io.IO.refill           may perform {Eio__core.Suspend.Suspend}
  Cohttp_eio__Io.IO.with_input_buffer may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Io.IO.read_line        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Io.IO.read             may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Io.IO.write            may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cohttp_eio__Client
  Cohttp_eio__Client.call_on_socket  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Client.tcp_address     may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Client.scheme_conn_of_uri may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Client.make_tunnel     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cohttp_eio__Utils
  Cohttp_eio__Utils.loop_842         may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Utils.flow_to_writer   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Cohttp_eio__Server
  Cohttp_eio__Server.read            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.write           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.respond         may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.respond_string  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.handle_1395     may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.callback        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Cohttp_eio__Server.run             may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Test_forward_proxy
  Dune__exe__Test_forward_proxy.Req_data.send may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_forward_proxy.Req_data.get may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_forward_proxy.handler_590 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_forward_proxy.run_proxy_server may perform {Eio__core.Suspend.Suspend, ...unknown}

2697 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## domainslib

```
module Domainslib__Task
  Domainslib__Task.await             may perform {Domainslib__Task.Wait}
  Domainslib__Task.await_613         may perform {Domainslib__Task.Wait}
  Domainslib__Task.work_834          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_for_reduce may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.work_857          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_for      may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_scan     may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.work_915          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_find     may perform {Domainslib__Task.Wait, ...unknown}

72 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## eio_linux

```
module Dune__exe__Stress_semaphore
  Dune__exe__Stress_semaphore.main   may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Stress_release
  Dune__exe__Stress_release.run_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_release.main     may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Stress_proc
  Dune__exe__Stress_proc.echo_337    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_proc.run_in_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_proc.main        may perform {Eio__core.Suspend.Suspend}

module Eio_posix__Sched
  Eio_posix__Sched.enter             may perform {Eio_posix__Sched.Enter, ...unknown}

module Dune__exe__Test_devices
  Dune__exe__Test_devices.with_blocking_fd may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Open_beneath
  Dune__exe__Open_beneath.check      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Open_beneath.test       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Open_beneath.test_denied may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Main
  Dune__exe__Main.scan_mli           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Main.scan               may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Server
  Dune__exe__Server.traceln          may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Server.handle_client    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Server.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Client
  Dune__exe__Client.traceln          may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Client.run              may perform {Eio__core.Suspend.Suspend}

module Eio_unix
  Eio_unix.sleep                     may perform {Private.Get_monotonic_clock, ...unknown}

module Eio_unix__Private
  Eio_unix__Private.await_readable   may perform {Eio_unix__Private.Await_readable}
  Eio_unix__Private.await_writable   may perform {Eio_unix__Private.Await_writable}
  Eio_unix__Private.pipe             may perform {Eio_unix__Private.Pipe}

module Eio_unix__Thread_pool
  Eio_unix__Thread_pool.run_in_systhread may perform {Eio_unix__Thread_pool.Run_in_systhread, ...unknown}

module Eio_unix__Net
  Eio_unix__Net.import_socket_stream may perform {Eio_unix__Net.Import_socket_stream}
  Eio_unix__Net.import_socket_listening may perform {Eio_unix__Net.Import_socket_listening}
  Eio_unix__Net.import_socket_datagram may perform {Eio_unix__Net.Import_socket_datagram}
  Eio_unix__Net.socketpair_stream    may perform {Eio_unix__Net.Socketpair_stream}
  Eio_unix__Net.socketpair_datagram  may perform {Eio_unix__Net.Socketpair_datagram}

module Eio_utils__Suspended
  Eio_utils__Suspended.tid           may perform {Eio__core.Suspend.Suspend}
  Eio_utils__Suspended.continue      may perform {Eio__core.Suspend.Suspend, ...unknown}
  Eio_utils__Suspended.discontinue   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio_utils__Zzz
  Eio_utils__Zzz.pop                 may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio_utils__Dla
  Eio_utils__Dla.await_301           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Fake_sched
  Dune__exe__Fake_sched.cancel       may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Rcfd
  Dune__exe__Rcfd.close_fd           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Rcfd.close              may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Rcfd.remove             may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio__core__Cancel
  Eio__core__Cancel.protect          may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub_checked      may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub              may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub_unchecked    may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.Fiber_context.get_vars may perform {Eio__core__Cancel.Fiber_context.Get_context}

module Eio__core__Fiber
  Eio__core__Fiber.fork_raw          may perform {Eio__core__Fiber.Fork}
  Eio__core__Fiber.fork              may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_daemon       may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_promise      may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_promise_exn  may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.forks             may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.is_cancelled      may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.check             may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.with_binding      may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.without_binding   may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.fork_coroutine    may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_seq          may perform {Eio__core__Fiber.Fork, ...unknown}

module Eio__core__Switch
  Eio__core__Switch.run_protected    may perform {Eio__core__.Cancel.Get_context, ...unknown}

module Eio__core__Suspend
  Eio__core__Suspend.enter_unchecked may perform {Eio__core__Suspend.Suspend, ...unknown}
  Eio__core__Suspend.enter           may perform {Eio__core__Suspend.Suspend, ...unknown}

module Dune__exe__Bench_cancel
  Dune__exe__Bench_cancel.run_sender may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_cancel.run_sender_371 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_cancel.run_bench  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_cancel.main       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_cancel.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_fstat
  Dune__exe__Bench_fstat.run_fiber   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_fstat.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_semaphore
  Dune__exe__Bench_semaphore.spin    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_worker_441 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_507 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_semaphore.main    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_semaphore.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_stream
  Dune__exe__Bench_stream.spin       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_sender may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_recv   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_bench  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stream.main       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stream.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_systhread
  Dune__exe__Bench_systhread.run_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_systhread.time    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_systhread.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_mutex
  Dune__exe__Bench_mutex.run_worker  may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_mutex.run_bench   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_mutex.main        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_mutex.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_promise
  Dune__exe__Bench_promise.spin      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.run_server may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.run_client may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.bench_resolved may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.maybe_spin may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.main      may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.run       may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_stat
  Dune__exe__Bench_stat.with_tmp_dir may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stat.aux_1391     may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.bench_stat   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.bench_1551   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.run_bench    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.run          may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Bench_copy
  Dune__exe__Bench_copy.run_client   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_copy.time         may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_copy.run          may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Bench_yield
  Dune__exe__Bench_yield.main        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_yield.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_condition
  Dune__exe__Bench_condition.run_publisher may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_consumer may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_consumer_428 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_condition.main    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_condition.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_fd
  Dune__exe__Bench_fd.run1_829       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_fd.run            may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_http
  Dune__exe__Bench_http.aux_351      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.parse_headers may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.handle_connection may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.run_client   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.main         may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_http.run          may perform {Eio__core.Suspend.Suspend, ...unknown}

1528 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## eio-trace

```
module Dune__exe__Dump
  Dune__exe__Dump.main               may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Main
  Dune__exe__Main.ui_909             may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Main.cmd                may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Record
  Dune__exe__Record.aux_921          may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.trace            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.spawn_child      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Record.get_cursor       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Gc_stats
  Dune__exe__Gc_stats.process_event  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Gc_stats.analyse        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Gc_stats.main           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Server
  Dune__exe__Server.handle_client    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Server.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Client
  Dune__exe__Client.run              may perform {Eio__core.Suspend.Suspend}

228 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## forester

```
module Forester_compiler__Cache
  Forester_compiler__Cache.Item.check_timestamp may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Cache.get_changed_paths may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Build_latex
  Forester_compiler__Build_latex.resources_dir may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Build_latex.latex_to_svg may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__LaTeX_pipeline
  Forester_compiler__LaTeX_pipeline.pipe_latex_dvi may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.pipe_dvi_svg may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.pipe_latex_svg may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.latex_to_svg may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Eio_util
  Forester_compiler__Eio_util.path_of_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.path_of_file may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.paths_of_dirs may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.paths_of_files may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.ensure_context_of_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.ensure_remove_file may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.with_open_tmp_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.run_process may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.file_exists may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.try_create_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.try_create_file may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.copy_to_dir may perform {Eio__core.Suspend.Suspend}

module Forester_compiler__Dir_scanner
  Forester_compiler__Dir_scanner.find_tree may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Phases
  Forester_compiler__Phases.run_jobs may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Expand
  Forester_compiler__Expand.entered_range may perform {Forester_compiler__Expand.Entered_range}
  Forester_compiler__Expand.expand_eff may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.get_xml_attrs may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.get_arg_opt may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_method may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_lambda may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand   may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_tree_inner may perform {Forester_compiler__Expand.Entered_range, ...unknown}

module Forester_compiler__Imports
  Forester_compiler__Imports.load_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.resolve_uri_to_code may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_code may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_node may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.dependencies may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.fixup   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.build   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Driver
  Forester_compiler__Driver.update   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2316  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.batch_run may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2330  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.language_server may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2341  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.run_with_history may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2352  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.collect_emitted_errors may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_compiler
  Dune__exe__Test_compiler.test_batch_run may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_compiler.test_reparsing may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_import_graph
  Dune__exe__Test_import_graph.test_import_graph may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_errors
  Dune__exe__Test_errors._test_853   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_server__Server
  Forester_server__Server.lookup_font may perform {Eio__core.Suspend.Suspend}
  Forester_server__Server.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_frontend__Forester
  Forester_frontend__Forester.create_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.output_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.copy_contents_of_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.render_forest may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Lsp_server
  Forester_lsp__Lsp_server.Request.handle may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Lsp_server.Notification.handle may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Call_hierarchy
  Forester_lsp__Call_hierarchy.incoming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Call_hierarchy.outgoing may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__LspEio
  Forester_lsp__LspEio.Header.loop_866 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Header.read   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Header.write  may perform {Eio__core.Suspend.Suspend}
  Forester_lsp__LspEio.Message.read  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Message.write may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.init          may perform {Eio__core.Suspend.Suspend}

module Forester_lsp__Did_create_files
  Forester_lsp__Did_create_files.compute may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp
  Forester_lsp.print_exn             may perform {Eio__core.Suspend.Suspend}
  Forester_lsp.initialize            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp.event_loop            may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Diagnostics
  Forester_lsp__Diagnostics.compute  may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Change_configuration
  Forester_lsp__Change_configuration.compute may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Semantic_tokens
  Forester_lsp__Semantic_tokens.tokenize_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.tokens may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.tokenize_document may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.on_full_request may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Main
  Dune__exe__Main.init               may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Main.init_cmd           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Main.cmd                may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_test__Prelude
  Forester_test__Prelude.with_open_tmp_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.with_test_forest may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.find_tree   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.find_doc    may perform {Eio__core.Suspend.Suspend, ...unknown}

676 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## geojsone

```
module Geojsone_eio
  Geojsone_eio.src_of_flow           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Geojsone_eio.dst_of_flow           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Test
  Dune__exe__Test.with_src           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test.buffer_to_dst      may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Test_iters
  Dune__exe__Test_iters.buffer_to_dst may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_iters.value_to_buffer may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.value_to_string may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.print_geometry may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.print_property may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.with_src     may perform {Eio__core.Suspend.Suspend}

743 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## gluten-eio

```
module Gluten_eio
  Gluten_eio.IO_loop.writev          may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.read_once       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.read            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.shutdown        may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.read_1225       may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.write_loop_step_1267 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.write_loop_1266 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.start           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Server.create_connection_handler may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Server.create_upgradable_connection_handler may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Client.create           may perform {Eio__core.Suspend.Suspend, ...unknown}

134 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## grpc-examples

```
module Grpc_eio__Server
  Grpc_eio__Server.Rpc.bidirectional_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.client_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.server_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.unary         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Grpc_eio__Seq
  Grpc_eio__Seq.write                may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Seq.close_writer         may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Seq.create_reader_writer may perform {Eio__core.Suspend.Suspend}

module Grpc_eio__Connection
  Grpc_eio__Connection.grpc_send_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}

module Grpc_eio__Client
  Grpc_eio__Client.trailers_handler_433 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.make_trailers_handler may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Client.response_handler_499 may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Client.get_response_and_bodies may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.call              may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.bidirectional_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.client_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.server_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.unary         may perform {Eio__core.Suspend.Suspend, ...unknown}

132 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## h2-eio

```
module H2_eio
  H2_eio.Client.ping                 may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Eio_h2spec
  Dune__exe__Eio_h2spec.set_interval may perform {Eio__core.Suspend.Suspend, ...unknown}

656 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## hedgehog

```
module Hedgehog__Property
  Hedgehog__Property.assert_         may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.===             may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.diff            may perform {Hedgehog__Property.Fail, ...unknown}
  Hedgehog__Property.failure         may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.annotate        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.footnote        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.tripping        may perform {Hedgehog__Property.Fail, Hedgehog__Property.WriteLog, ...unknown}
  Hedgehog__Property.eval_result     may perform {Hedgehog__Property.Fail, ...unknown}
  Hedgehog__Property.cover           may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.classify        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.label           may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.collect         may perform {Hedgehog__Property.WriteLog, ...unknown}

128 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## inotify-eio

```
module Eio_inotify
  Eio_inotify.read                   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Eio_inotify.with_timeout           may perform {Eio__core.Suspend.Suspend}
  Eio_inotify.try_read               may perform {Eio__core.Suspend.Suspend, ...unknown}

25 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## kaun

```
module Nx_effect
  Nx_effect.full                     may perform {Nx_effect.E_const_scalar, ...unknown}

3460 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## domainslib

```
module Domainslib__Task
  Domainslib__Task.await             may perform {Domainslib__Task.Wait}
  Domainslib__Task.await_613         may perform {Domainslib__Task.Wait}
  Domainslib__Task.work_834          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_for_reduce may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.work_857          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_for      may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_scan     may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.work_915          may perform {Domainslib__Task.Wait, ...unknown}
  Domainslib__Task.parallel_find     may perform {Domainslib__Task.Wait, ...unknown}

72 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## eio_linux

```
module Dune__exe__Stress_semaphore
  Dune__exe__Stress_semaphore.main   may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Stress_release
  Dune__exe__Stress_release.run_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_release.main     may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Stress_proc
  Dune__exe__Stress_proc.echo_337    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_proc.run_in_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Stress_proc.main        may perform {Eio__core.Suspend.Suspend}

module Eio_posix__Sched
  Eio_posix__Sched.enter             may perform {Eio_posix__Sched.Enter, ...unknown}

module Dune__exe__Test_devices
  Dune__exe__Test_devices.with_blocking_fd may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Open_beneath
  Dune__exe__Open_beneath.check      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Open_beneath.test       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Open_beneath.test_denied may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Main
  Dune__exe__Main.scan_mli           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Main.scan               may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Server
  Dune__exe__Server.traceln          may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Server.handle_client    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Server.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Client
  Dune__exe__Client.traceln          may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Client.run              may perform {Eio__core.Suspend.Suspend}

module Eio_unix
  Eio_unix.sleep                     may perform {Private.Get_monotonic_clock, ...unknown}

module Eio_unix__Private
  Eio_unix__Private.await_readable   may perform {Eio_unix__Private.Await_readable}
  Eio_unix__Private.await_writable   may perform {Eio_unix__Private.Await_writable}
  Eio_unix__Private.pipe             may perform {Eio_unix__Private.Pipe}

module Eio_unix__Thread_pool
  Eio_unix__Thread_pool.run_in_systhread may perform {Eio_unix__Thread_pool.Run_in_systhread, ...unknown}

module Eio_unix__Net
  Eio_unix__Net.import_socket_stream may perform {Eio_unix__Net.Import_socket_stream}
  Eio_unix__Net.import_socket_listening may perform {Eio_unix__Net.Import_socket_listening}
  Eio_unix__Net.import_socket_datagram may perform {Eio_unix__Net.Import_socket_datagram}
  Eio_unix__Net.socketpair_stream    may perform {Eio_unix__Net.Socketpair_stream}
  Eio_unix__Net.socketpair_datagram  may perform {Eio_unix__Net.Socketpair_datagram}

module Eio_utils__Suspended
  Eio_utils__Suspended.tid           may perform {Eio__core.Suspend.Suspend}
  Eio_utils__Suspended.continue      may perform {Eio__core.Suspend.Suspend, ...unknown}
  Eio_utils__Suspended.discontinue   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio_utils__Zzz
  Eio_utils__Zzz.pop                 may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio_utils__Dla
  Eio_utils__Dla.await_301           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Fake_sched
  Dune__exe__Fake_sched.cancel       may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Rcfd
  Dune__exe__Rcfd.close_fd           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Rcfd.close              may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Rcfd.remove             may perform {Eio__core.Suspend.Suspend, ...unknown}

module Eio__core__Cancel
  Eio__core__Cancel.protect          may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub_checked      may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub              may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.sub_unchecked    may perform {Eio__core__Cancel.Get_context, ...unknown}
  Eio__core__Cancel.Fiber_context.get_vars may perform {Eio__core__Cancel.Fiber_context.Get_context}

module Eio__core__Fiber
  Eio__core__Fiber.fork_raw          may perform {Eio__core__Fiber.Fork}
  Eio__core__Fiber.fork              may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_daemon       may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_promise      may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_promise_exn  may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.forks             may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.is_cancelled      may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.check             may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.with_binding      may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.without_binding   may perform {Eio__core__.Cancel.Get_context, ...unknown}
  Eio__core__Fiber.fork_coroutine    may perform {Eio__core__Fiber.Fork, ...unknown}
  Eio__core__Fiber.fork_seq          may perform {Eio__core__Fiber.Fork, ...unknown}

module Eio__core__Switch
  Eio__core__Switch.run_protected    may perform {Eio__core__.Cancel.Get_context, ...unknown}

module Eio__core__Suspend
  Eio__core__Suspend.enter_unchecked may perform {Eio__core__Suspend.Suspend, ...unknown}
  Eio__core__Suspend.enter           may perform {Eio__core__Suspend.Suspend, ...unknown}

module Dune__exe__Bench_cancel
  Dune__exe__Bench_cancel.run_sender may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_cancel.run_sender_371 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_cancel.run_bench  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_cancel.main       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_cancel.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_fstat
  Dune__exe__Bench_fstat.run_fiber   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_fstat.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_semaphore
  Dune__exe__Bench_semaphore.spin    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_worker_441 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_507 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_semaphore.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_semaphore.main    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_semaphore.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_stream
  Dune__exe__Bench_stream.spin       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_sender may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_recv   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stream.run_bench  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stream.main       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stream.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_systhread
  Dune__exe__Bench_systhread.run_domain may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_systhread.time    may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_systhread.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_mutex
  Dune__exe__Bench_mutex.run_worker  may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_mutex.run_bench   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_mutex.main        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_mutex.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_promise
  Dune__exe__Bench_promise.spin      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.run_server may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.run_client may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_promise.bench_resolved may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.maybe_spin may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.main      may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_promise.run       may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_stat
  Dune__exe__Bench_stat.with_tmp_dir may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_stat.aux_1391     may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.bench_stat   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.bench_1551   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.run_bench    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_stat.run          may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Bench_copy
  Dune__exe__Bench_copy.run_client   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_copy.time         may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_copy.run          may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Bench_yield
  Dune__exe__Bench_yield.main        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_yield.run         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_condition
  Dune__exe__Bench_condition.run_publisher may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_consumer may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_consumer_428 may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_condition.run_bench may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_condition.main    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_condition.run     may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_fd
  Dune__exe__Bench_fd.run1_829       may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_fd.run            may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Bench_http
  Dune__exe__Bench_http.aux_351      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.parse_headers may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.handle_connection may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.run_client   may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Bench_http.main         may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Bench_http.run          may perform {Eio__core.Suspend.Suspend, ...unknown}

1528 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## eio-trace

```
module Dune__exe__Dump
  Dune__exe__Dump.main               may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Main
  Dune__exe__Main.ui_909             may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Main.cmd                may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Record
  Dune__exe__Record.aux_921          may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.trace            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.spawn_child      may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Record.get_cursor       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Record.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Gc_stats
  Dune__exe__Gc_stats.process_event  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Gc_stats.analyse        may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Gc_stats.main           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Server
  Dune__exe__Server.handle_client    may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Server.run              may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Client
  Dune__exe__Client.run              may perform {Eio__core.Suspend.Suspend}

228 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## forester

```
module Forester_compiler__Cache
  Forester_compiler__Cache.Item.check_timestamp may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Cache.get_changed_paths may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Build_latex
  Forester_compiler__Build_latex.resources_dir may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Build_latex.latex_to_svg may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__LaTeX_pipeline
  Forester_compiler__LaTeX_pipeline.pipe_latex_dvi may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.pipe_dvi_svg may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.pipe_latex_svg may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__LaTeX_pipeline.latex_to_svg may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Eio_util
  Forester_compiler__Eio_util.path_of_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.path_of_file may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.paths_of_dirs may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.paths_of_files may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.ensure_context_of_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.ensure_remove_file may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.with_open_tmp_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.run_process may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.file_exists may perform {Eio__core.Suspend.Suspend}
  Forester_compiler__Eio_util.try_create_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.try_create_file may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Eio_util.copy_to_dir may perform {Eio__core.Suspend.Suspend}

module Forester_compiler__Dir_scanner
  Forester_compiler__Dir_scanner.find_tree may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Phases
  Forester_compiler__Phases.run_jobs may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Expand
  Forester_compiler__Expand.entered_range may perform {Forester_compiler__Expand.Entered_range}
  Forester_compiler__Expand.expand_eff may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.get_xml_attrs may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.get_arg_opt may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_method may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_lambda may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand   may perform {Forester_compiler__Expand.Entered_range, ...unknown}
  Forester_compiler__Expand.expand_tree_inner may perform {Forester_compiler__Expand.Entered_range, ...unknown}

module Forester_compiler__Imports
  Forester_compiler__Imports.load_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.resolve_uri_to_code may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_code may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.analyse_node may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.dependencies may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.fixup   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Imports.build   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_compiler__Driver
  Forester_compiler__Driver.update   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2316  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.batch_run may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2330  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.language_server may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2341  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.run_with_history may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.go_2352  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_compiler__Driver.collect_emitted_errors may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_compiler
  Dune__exe__Test_compiler.test_batch_run may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_compiler.test_reparsing may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_import_graph
  Dune__exe__Test_import_graph.test_import_graph may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Test_errors
  Dune__exe__Test_errors._test_853   may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_server__Server
  Forester_server__Server.lookup_font may perform {Eio__core.Suspend.Suspend}
  Forester_server__Server.run        may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_frontend__Forester
  Forester_frontend__Forester.create_tree may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.output_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.copy_contents_of_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_frontend__Forester.render_forest may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Lsp_server
  Forester_lsp__Lsp_server.Request.handle may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Lsp_server.Notification.handle may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Call_hierarchy
  Forester_lsp__Call_hierarchy.incoming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Call_hierarchy.outgoing may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__LspEio
  Forester_lsp__LspEio.Header.loop_866 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Header.read   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Header.write  may perform {Eio__core.Suspend.Suspend}
  Forester_lsp__LspEio.Message.read  may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.Message.write may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__LspEio.init          may perform {Eio__core.Suspend.Suspend}

module Forester_lsp__Did_create_files
  Forester_lsp__Did_create_files.compute may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp
  Forester_lsp.print_exn             may perform {Eio__core.Suspend.Suspend}
  Forester_lsp.initialize            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp.event_loop            may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Diagnostics
  Forester_lsp__Diagnostics.compute  may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Change_configuration
  Forester_lsp__Change_configuration.compute may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_lsp__Semantic_tokens
  Forester_lsp__Semantic_tokens.tokenize_path may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.tokens may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.tokenize_document may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_lsp__Semantic_tokens.on_full_request may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Main
  Dune__exe__Main.init               may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Main.init_cmd           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Main.cmd                may perform {Eio__core.Suspend.Suspend, ...unknown}

module Forester_test__Prelude
  Forester_test__Prelude.with_open_tmp_dir may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.with_test_forest may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.find_tree   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Forester_test__Prelude.find_doc    may perform {Eio__core.Suspend.Suspend, ...unknown}

676 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## geojsone

```
module Geojsone_eio
  Geojsone_eio.src_of_flow           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Geojsone_eio.dst_of_flow           may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Test
  Dune__exe__Test.with_src           may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test.buffer_to_dst      may perform {Eio__core.Suspend.Suspend}

module Dune__exe__Test_iters
  Dune__exe__Test_iters.buffer_to_dst may perform {Eio__core.Suspend.Suspend}
  Dune__exe__Test_iters.value_to_buffer may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.value_to_string may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.print_geometry may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.print_property may perform {Eio__core.Suspend.Suspend, ...unknown}
  Dune__exe__Test_iters.with_src     may perform {Eio__core.Suspend.Suspend}

743 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## gluten-eio

```
module Gluten_eio
  Gluten_eio.IO_loop.writev          may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.read_once       may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.read            may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.shutdown        may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.read_1225       may perform {Eio__core.Suspend.Suspend}
  Gluten_eio.IO_loop.write_loop_step_1267 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.write_loop_1266 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.IO_loop.start           may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Server.create_connection_handler may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Server.create_upgradable_connection_handler may perform {Eio__core.Suspend.Suspend, ...unknown}
  Gluten_eio.Client.create           may perform {Eio__core.Suspend.Suspend, ...unknown}

134 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## grpc-examples

```
module Grpc_eio__Server
  Grpc_eio__Server.Rpc.bidirectional_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.client_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.server_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Server.Rpc.unary         may perform {Eio__core.Suspend.Suspend, ...unknown}

module Grpc_eio__Seq
  Grpc_eio__Seq.write                may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Seq.close_writer         may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Seq.create_reader_writer may perform {Eio__core.Suspend.Suspend}

module Grpc_eio__Connection
  Grpc_eio__Connection.grpc_send_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}

module Grpc_eio__Client
  Grpc_eio__Client.trailers_handler_433 may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.make_trailers_handler may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Client.response_handler_499 may perform {Eio__core.Suspend.Suspend}
  Grpc_eio__Client.get_response_and_bodies may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.call              may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.bidirectional_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.client_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.server_streaming may perform {Eio__core.Suspend.Suspend, ...unknown}
  Grpc_eio__Client.Rpc.unary         may perform {Eio__core.Suspend.Suspend, ...unknown}

132 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## h2-eio

```
module H2_eio
  H2_eio.Client.ping                 may perform {Eio__core.Suspend.Suspend, ...unknown}

module Dune__exe__Eio_h2spec
  Dune__exe__Eio_h2spec.set_interval may perform {Eio__core.Suspend.Suspend, ...unknown}

656 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## hedgehog

```
module Hedgehog__Property
  Hedgehog__Property.assert_         may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.===             may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.diff            may perform {Hedgehog__Property.Fail, ...unknown}
  Hedgehog__Property.failure         may perform {Hedgehog__Property.Fail}
  Hedgehog__Property.annotate        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.footnote        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.tripping        may perform {Hedgehog__Property.Fail, Hedgehog__Property.WriteLog, ...unknown}
  Hedgehog__Property.eval_result     may perform {Hedgehog__Property.Fail, ...unknown}
  Hedgehog__Property.cover           may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.classify        may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.label           may perform {Hedgehog__Property.WriteLog}
  Hedgehog__Property.collect         may perform {Hedgehog__Property.WriteLog, ...unknown}

128 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## inotify-eio

```
module Eio_inotify
  Eio_inotify.read                   may perform {Eio__core.Suspend.Suspend, ...unknown}
  Eio_inotify.with_timeout           may perform {Eio__core.Suspend.Suspend}
  Eio_inotify.try_read               may perform {Eio__core.Suspend.Suspend, ...unknown}

25 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## kaun

```
module Nx_effect
  Nx_effect.full                     may perform {Nx_effect.E_const_scalar, ...unknown}

3460 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

## picos

```
module Picos_lwt
  Picos_lwt.await                    may perform {Picos.Trigger.Await, ...unknown}

module Picos_std_awaitable
  Picos_std_awaitable.Awaitable.Awaiters.await may perform {Picos.Trigger.Await}

module Picos_std_event__Event
  Picos_std_event__Event.sync_as     may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_event__Event.sync        may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_event__Event.select      may perform {Picos.Trigger.Await, ...unknown}

module Picos
  Picos.Trigger.await                may perform {Picos.Trigger.Await}
  Picos.Fiber.current                may perform {Picos.Fiber.Current}
  Picos.Fiber.spawn                  may perform {Picos.Fiber.Spawn}
  Picos.Fiber.yield                  may perform {Picos.Fiber.Yield}
  Picos.Fiber.Maybe.to_fiber_or_current may perform {Picos.Fiber.Current}
  Picos.Fiber.Maybe.or_current       may perform {Picos.Fiber.Current}
  Picos.Fiber.Maybe.current_if       may perform {Picos.Fiber.Current}
  Picos.Fiber.Maybe.current_and_check_if may perform {Picos.Fiber.Current, ...unknown}

module Picos_std_structured__Run
  Picos_std_structured__Run.spawn    may perform {Picos.Fiber.Spawn, ...unknown}

module Picos_std_structured__Flock
  Picos_std_structured__Flock.get    may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Flock.terminate_after may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Flock.terminate may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Flock.error  may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Flock.fork_as_promise may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Flock.fork   may perform {Picos.Fiber.Current, ...unknown}

module Picos_std_structured__Bundle
  Picos_std_structured__Bundle.await may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_structured__Bundle.raised may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_structured__Bundle.returned may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_structured__Bundle.join_after_pass may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Bundle.plug  may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_structured__Bundle.fork_as_promise_pass may perform {Picos.Fiber.Spawn, ...unknown}
  Picos_std_structured__Bundle.fork_pass may perform {Picos.Fiber.Spawn, ...unknown}
  Picos_std_structured__Bundle.join_after may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Bundle.fork  may perform {Picos.Fiber.Spawn, ...unknown}
  Picos_std_structured__Bundle.fork_as_promise may perform {Picos.Fiber.Spawn, ...unknown}

module Picos_std_structured__Control
  Picos_std_structured__Control.raise_if_canceled may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Control.block may perform {Picos.Fiber.Current, Picos.Trigger.Await}
  Picos_std_structured__Control.protect may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_structured__Control.terminate_after may perform {Picos.Fiber.Current, ...unknown}

module Picos_std_sync__Condition
  Picos_std_sync__Condition.wait     may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}

module Picos_std_sync__Conditions
  Picos_std_sync__Conditions.lock_forbidden_334 may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_sync__Conditions.wait    may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}

module Picos_std_sync__Mutex
  Picos_std_sync__Mutex.unlock       may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_sync__Mutex.lock_as      may perform {Picos.Trigger.Await, ...unknown}
  Picos_std_sync__Mutex.lock         may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}
  Picos_std_sync__Mutex.try_lock     may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_sync__Mutex.protect      may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}

module Picos_std_sync__Lazy
  Picos_std_sync__Lazy.force         may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}

module Picos_std_finally
  Picos_std_finally.check_released   may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.forbidden        may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.release_and_reraise may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.release_and_return may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.drop             may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.drop_and_reraise_as may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.drop_and_reraise may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.await_transferred_or_dropped may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}
  Picos_std_finally.instantiate      may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}
  Picos_std_finally.transfer         may perform {Picos.Fiber.Current, Picos.Trigger.Await, ...unknown}
  Picos_std_finally.move             may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.finally          may perform {Picos.Fiber.Current, ...unknown}
  Picos_std_finally.lastly           may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_structured
  Dune__exe__Test_structured.check   may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_schedulers
  Dune__exe__Test_schedulers.awaiter_880 may perform {Picos.Trigger.Await}
  Dune__exe__Test_schedulers.test_cross_scheduler_wakeup may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_server_and_client
  Dune__exe__Test_server_and_client.server_looping_943 may perform {Picos.Fiber.Current, ...unknown}
  Dune__exe__Test_server_and_client.server_recursive_1060 may perform {Picos.Fiber.Current, ...unknown}
  Dune__exe__Test_server_and_client.client_1075 may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Picos
  Dune__exe__Picos.Trigger.await     may perform {Dune__exe__Picos.Trigger.Await, ...unknown}
  Dune__exe__Picos.Fiber.current     may perform {Dune__exe__Picos.Fiber.Current}
  Dune__exe__Picos.Fiber.spawn       may perform {Dune__exe__Picos.Fiber.Spawn}
  Dune__exe__Picos.Fiber.yield       may perform {Dune__exe__Picos.Fiber.Yield}
  Dune__exe__Picos.Fiber.Maybe.to_fiber_or_current may perform {Dune__exe__Picos.Fiber.Current}
  Dune__exe__Picos.Fiber.Maybe.or_current may perform {Dune__exe__Picos.Fiber.Current}
  Dune__exe__Picos.Fiber.Maybe.current_if may perform {Dune__exe__Picos.Fiber.Current}
  Dune__exe__Picos.Fiber.Maybe.current_and_check_if may perform {Dune__exe__Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_io_cohttp
  Dune__exe__Test_io_cohttp.main     may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_picos
  Dune__exe__Test_picos.run_in_fiber may perform {Picos.Fiber.Spawn, ...unknown}
  Dune__exe__Test_picos.either_815   may perform {Picos.Fiber.Current, ...unknown}
  Dune__exe__Test_picos.test_computation_tx may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_select
  Dune__exe__Test_select.test_intr   may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Test_sync
  Dune__exe__Test_sync.Fiber.start   may perform {Picos.Fiber.Spawn, ...unknown}

module Dune__exe__Bench_spawn
  Dune__exe__Bench_spawn.work_468    may perform {Picos.Fiber.Spawn, ...unknown}

module Dune__exe__Bench_fib
  Dune__exe__Bench_fib.exp_fib       may perform {Picos.Fiber.Spawn, ...unknown}
  Dune__exe__Bench_fib.work_534      may perform {Picos.Fiber.Spawn, ...unknown}

module Dune__exe__Bench_current
  Dune__exe__Bench_current.loop_334  may perform {Picos.Fiber.Current, ...unknown}
  Dune__exe__Bench_current.work_332  may perform {Picos.Fiber.Current, ...unknown}
  Dune__exe__Bench_current.work_329  may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Bench_fls_excluding_current
  Dune__exe__Bench_fls_excluding_current.work_368 may perform {Picos.Fiber.Current, ...unknown}

module Dune__exe__Bench_binaries
  Dune__exe__Bench_binaries.run_suite may perform {Picos.Fiber.Current, ...unknown}

968 function(s) omitted: their effects depend on calls into code with no .cmt available.
```

