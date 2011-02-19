(**************************************************************************)
(*                Lablgtk                                                 *)
(*                                                                        *)
(*    This program is free software; you can redistribute it              *)
(*    and/or modify it under the terms of the GNU Library General         *)
(*    Public License as published by the Free Software Foundation         *)
(*    version 2, with the exception described in file COPYING which       *)
(*    comes with the library.                                             *)
(*                                                                        *)
(*    This program is distributed in the hope that it will be useful,     *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of      *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       *)
(*    GNU Library General Public License for more details.                *)
(*                                                                        *)
(*    You should have received a copy of the GNU Library General          *)
(*    Public License along with this program; if not, write to the        *)
(*    Free Software Foundation, Inc., 59 Temple Place, Suite 330,         *)
(*    Boston, MA 02111-1307  USA                                          *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

(* $Id$ *)

open Gobject

(** Signals *)

type id
type 'a marshaller = 'a -> Closure.argv -> unit
type ('a,'b) t =
 { name: string; classe: 'a; marshaller: 'b marshaller }
    (** When writing marshallers, beware that the list omits the 0th
       argument of argv, which is the referent object *)

val stop_emit : unit -> unit
    (** Call [stop_emit ()] in a callback to prohibit further handling
       of the current signal invocation, by calling [emit_stop_by_name].
       Be careful about where you use it, since the concept of current
       signal may be tricky. *)

val connect :
  sgn:('a, 'b) t -> callback:'b -> ?after:bool -> 'a obj -> id
    (** You may use [stop_emit] inside the callback *)

val connect_property : prop:('a, 'b) Gobject.property ->
  callback:(unit -> unit) -> 'a Gobject.obj -> id
    (** Connect to the "notify::foo" signal associated with a property. These
       are emitted each time the property "foo" is changed *)

val user_handler : (exn -> unit) ref
    (** A hook to allow changing the behaviour of exceptions in callbacks
       The default behaviour of printing the exception and ignoring it
       is obtained when [user_handler] is set to [Pervasives.raise] *)
val safe_call : ?where:string -> ('a -> unit) -> 'a -> unit
    (** Safe wrapper for function calls. Tries to handle exceptions
        with user_handler, and reports an error otherwise. *)

external connect_by_name :
  'a obj -> name:string -> callback:g_closure -> after:bool -> id
  = "ml_g_signal_connect_closure"
external disconnect : 'a obj -> id -> unit
  = "ml_g_signal_handler_disconnect"
external emit_stop_by_name : 'a obj -> name:string -> unit
  = "ml_g_signal_stop_emission_by_name"
    (** Unsafe: use [stop_emit] instead. *)
external handler_block : 'a obj -> id -> unit
  = "ml_g_signal_handler_block"
external handler_unblock : 'a obj -> id -> unit
  = "ml_g_signal_handler_unblock"

(** {4 Marshallers} Some marshaller functions, to build signals *)

val marshal_unit : (unit -> unit) marshaller
val marshal_int : (int -> unit) marshaller
val marshal_string : (string -> unit) marshaller

val marshal1 : 'a data_conv -> string -> ('a -> unit) marshaller
val marshal2 :
  'a data_conv -> 'b data_conv -> string -> ('a -> 'b -> unit) marshaller
val marshal3 :
  'a data_conv -> 'b data_conv -> 'c data_conv ->
  string -> ('a -> 'b -> 'c -> unit) marshaller
val marshal4 :
  'a data_conv -> 'b data_conv -> 'c data_conv -> 'd data_conv ->
  string -> ('a -> 'b -> 'c -> 'd -> unit) marshaller
val marshal5 :
  'a data_conv -> 'b data_conv -> 'c data_conv -> 'd data_conv ->
  'e data_conv -> string -> ('a -> 'b -> 'c -> 'd -> 'e -> unit) marshaller
val marshal6 :
  'a data_conv -> 'b data_conv -> 'c data_conv -> 'd data_conv ->
  'e data_conv -> 'f data_conv ->
  string -> ('a -> 'b -> 'c -> 'd -> 'e -> 'f -> unit) marshaller

val marshal0_ret : ret:'a data_conv -> (unit -> 'a) marshaller
val marshal1_ret :
  ret:'a data_conv -> 'b data_conv -> string -> ('b -> 'a) marshaller
val marshal2_ret :
  ret:'a data_conv -> 'b data_conv -> 'c data_conv ->
  string -> ('b -> 'c -> 'a) marshaller
val marshal3_ret :
  ret:'a data_conv -> 'b data_conv -> 'c data_conv -> 'd data_conv ->
  string -> ('b -> 'c -> 'd -> 'a) marshaller
val marshal4_ret :
  ret:'a data_conv -> 'b data_conv -> 'c data_conv -> 'd data_conv ->
  'e data_conv -> string -> ('b -> 'c -> 'd -> 'e -> 'a) marshaller

(** {4 Emitter functions} *)

val emit :
  'a Gobject.obj -> sgn:('a, 'b) t ->
  emitter:(cont:('c Gobject.data_set array -> 'd) -> 'b) ->
  conv:(Gobject.g_value -> 'd) -> 'b
val emit_unit : 'a obj -> sgn:('a, unit -> unit) t -> unit
val emit_int : 'a obj -> sgn:('a, int -> unit) t -> int -> unit

(** {4 Default handler override} *)

val override_class_closure : ('a, 'b) t -> g_type -> g_closure -> unit
external chain_from_overridden : Closure.argv -> unit = "ml_g_signal_chain_from_overridden"

(**/**)

(* Internal functions. *)
val enter_callback : (unit -> unit) ref
val exit_callback : (unit -> unit) ref
type saved_state
val push_callback : unit -> saved_state
val pop_callback : saved_state -> bool

module type GlibPropertyAsSignal = sig
  type 'a u
  val connect : 'a Gobject.obj ->
      ('a, 'b) Gobject.property -> id * 'b u
  val disconnect : 'a Gobject.obj -> id -> unit
end

module type GlibPropertyAsEvent = sig
  type 'a u
    val connect : 'a Gobject.obj ->
      ('a, 'b) Gobject.property -> id * 'b u
    val disconnect : 'a Gobject.obj -> id -> unit
end

module type GlibSignalAsEvent = sig
  type 'a u
  val connect : 'a Gobject.obj ->
    ('a, 'b) t -> (f:('c -> unit) -> 'b) -> id * 'c u
  val connect_ret : 'a Gobject.obj ->
    ('a, 'b) t -> cb:('c -> 'd) -> (f:('c -> unit) -> cb:('c -> 'd) ->
      'b) -> id * 'c u
  val disconnect : 'a Gobject.obj -> id -> unit
end

val apply0 : f:(unit -> unit) -> unit -> unit
val apply1 : f:('a -> 'b) -> 'a -> 'b
val apply2 : f:('a * 'b -> 'c) -> 'a -> 'b -> 'c
val apply3 : f:('a * 'b * 'c -> 'd) -> 'a -> 'b -> 'c -> 'd
val apply4 : f:('a * 'b * 'c * 'd -> 'e) -> 'a -> 'b -> 'c -> 'd -> 'e
val apply5 : f:('a * 'b * 'c * 'd * 'e -> 'f) ->
  'a -> 'b -> 'c -> 'd -> 'e -> 'f
val apply6 : f:('a * 'b * 'c * 'd * 'e * 'f -> 'g) ->
  'a -> 'b -> 'c -> 'd -> 'e -> 'f -> 'g
val apply0_ret : f:(unit -> 'b) -> cb:(unit -> 'c) -> unit -> 'c
val apply1_ret : f:('a -> 'b) -> cb:('a -> 'c) -> 'a -> 'c
val apply2_ret : f:('a * 'b -> 'c) -> cb:('a * 'b -> 'd) -> 'a -> 'b -> 'd
val apply3_ret : f:('a * 'b * 'c -> 'd) ->
  cb:('a * 'b * 'c -> 'e) -> 'a -> 'b -> 'c -> 'e
val apply4_ret : f:('a * 'b * 'c * 'd -> 'e) ->
  cb:('a * 'b * 'c * 'd -> 'f) -> 'a -> 'b -> 'c -> 'd -> 'f
val apply5_ret : f:('a * 'b * 'c * 'd * 'e -> 'f) ->
  cb:('a * 'b * 'c * 'd * 'e -> 'g) -> 'a -> 'b -> 'c -> 'd -> 'e -> 'g
val apply6_ret : f:('a * 'b * 'c * 'd * 'e * 'f -> 'g) ->
  cb:('a * 'b * 'c * 'd * 'e * 'f -> 'h) ->
    'a -> 'b -> 'c -> 'd -> 'e -> 'f -> 'h

