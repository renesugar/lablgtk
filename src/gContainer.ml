(* $Id$ *)

open Misc
open Gtk
open GtkBase
open GObj
open GData

class focus obj = object
  val obj = obj
  method circulate = Container.focus obj
  method set : 'a. ?(#is_widget as 'a) -> unit = fun ?child ->
    let child = may_map child fun:(#as_widget) in
    Container.set_focus_child obj (optboxed child)
  method set_hadjustment ?adj =
    Container.set_focus_hadjustment obj (optboxed (adjustment_option adj))
  method set_vadjustment ?adj =
    Container.set_focus_vadjustment obj (optboxed (adjustment_option adj))
end

class container obj = object
  inherit widget obj
  method add : 'b . (#is_widget as 'b) -> unit =
    fun w -> Container.add obj w#as_widget
  method remove : 'b. (#is_widget as 'b) -> unit =
    fun w -> Container.remove obj w#as_widget
  method children = List.map fun:(new widget_wrapper) (Container.children obj)
  method set_border_width = Container.set_border_width obj
  method focus = new focus obj
end

class container_signals obj = object
  inherit widget_signals obj
  method add :callback =
    GtkSignal.connect ?sig:Container.Signals.add ?obj
      ?callback:(fun w -> callback (new widget_wrapper w))
  method remove :callback =
    GtkSignal.connect ?sig:Container.Signals.remove ?obj
      ?callback:(fun w -> callback (new widget_wrapper w))
end

class container_wrapper obj = object
  inherit container obj
  method connect = new container_signals ?obj
end

class virtual ['a,'b] item_container obj = object (self)
  inherit widget obj
  method add : 'c. ('a #is_item as 'c) -> _ =
    fun w -> Container.add obj w#as_item
  method remove : 'c. ('a #is_item as 'c) -> _ =
    fun w -> Container.remove obj w#as_item
  method private virtual wrap : Gtk.widget obj -> 'b
  method children : 'b list =
    List.map fun:self#wrap (Container.children obj)
  method set_border_width = Container.set_border_width obj
  method focus = new focus obj
  method virtual insert : 'c. ('a #is_item as 'c) -> pos:int -> unit
  method append : 'c. ('a #is_item as 'c) -> unit =
    fun w -> self#insert w pos:(-1)
  method prepend : 'c. ('a #is_item as 'c) -> unit =
    fun w -> self#insert w pos:0
end

class item_signals obj = object
  inherit container_signals obj
  method select = GtkSignal.connect sig:Item.Signals.select obj
  method deselect = GtkSignal.connect sig:Item.Signals.deselect obj
  method toggle = GtkSignal.connect sig:Item.Signals.toggle obj
end
