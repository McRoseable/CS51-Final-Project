(* Conway's Game of Life *)

(* Compile with ocamlopt -o life graphics.cmxa ourlife.ml *)
(* Run with ./life *)

type state = Dead | Alive
type cell = {state : state; age : int}
type grid = cell array array

module View : 
sig
  val size_x : int
  val size_y : int
  val draw : grid -> unit
  val close : unit -> unit
  val rand_init : unit -> int
end =
struct

  open Graphics
    
  let argc = Array.length Sys.argv;
  if argc < 3 then Printf.printf "Needs three arguments, [rules] [width] [height]"
else
  let width = Sys.argv.(2);
  let height = Sys.argv.(3);
  let rules = Sys.argv.(1);

  let () =
    open_graph (Sys.getenv "DISPLAY" ^ " " ^ width ^ "x" ^ height);
    display_mode false;
    set_window_title "Game of Life"

  let size_x = size_x ()
  let size_y = size_y ()

  let rand_init () = 
    Random.self_init();
    Random.int 255
  
  let r = rand_init()
  let s = rand_init()
  let t = rand_init()

  let draw w =
    let n = Array.length w in
    let m = Array.length w.(0) in
    let x = size_x / n in
    let y = size_y / m in
    for i = 0 to n - 1 do
      for j = 0 to m - 1 do
        set_color (match w.(i).(j).state with Dead -> white | Alive -> 
	  Graphics.rgb (w.(i).(j).age+r) (w.(i).(j).age+s) (w.(i).(j).age+t));
	let a = i * x in
	let b = j * y in
	fill_rect a b x y;
      done
    done;
    synchronize ()

  let close = close_graph

end

module Model : 
sig
  val next_state : unit -> unit
  val default_size : int
  val get_x : unit -> int
  val get_y : unit -> int
  val set_x : int -> unit
  val set_y : int -> unit
  val rand : unit -> unit
end = 
struct

  let default_size = 64
  let x = ref default_size
  let y = ref default_size

  let w = ref [||] (* <-- Empty Array *)

  let get_x () = Array.length !w
  let get_y () = Array.length !w.(0)

  let set_x n = 
    assert (n > 0); 
    x := n

  let set_y n =
    assert (n > 0);
    y := n

  let rand =
    Random.self_init ();
    fun () -> 
      w := Array.init !x (fun _ -> Array.init !y 
	(fun _ -> if Random.bool () then {state = Dead; age = 0} else {state = Alive; age = 0}));
      View.draw !w

  let () = rand ()
  (* Random initialization of [w] *)

  let neighbors w x y =
    let h = Array.length w - 1 in
    let v = Array.length w.(0) - 1 in
    let wi = w.(x) in
    let wp = w.(if x = 0 then h else x - 1) in
    let wn = w.(if x = h then 0 else x + 1) in
    let yp = if y = 0 then v else y - 1 in
    let yn = if y = v then 0 else y + 1 in
    [ wp.(y).state; wp.(yp).state; wi.(yp).state; wn.(yp).state; wn.(y).state; wn.(yn).state; wi.(yn).state; wp.(yn).state]

  let next_one_state x y = 
    let n = 
      List.fold_left (* make this compatible with new cell type *)
	(fun a -> function Alive -> a + 1 | Dead -> a) 0 (neighbors !w x y)
    in
    match !w.(x).(y).state with
    | Dead ->
      if n = 3
      then {state = Alive; age = 0}
      else {state = Dead; age = !w.(x).(y).age + 1}
    | Alive ->
      if n < 2 || n > 3
      then {state = Dead; age = 0}
      else {state = Alive; age = !w.(x).(y).age + 1}

  let next_state () =
    let x = get_x () in
    let y = get_y () in
    w := Array.init x (fun i -> Array.init y (next_one_state i));
    View.draw !w
end

let () = 
    while true do Model.next_state () done
