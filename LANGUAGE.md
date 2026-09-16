### c

- **Command:** `echo -e '#include <stdio.h>\nvoid main(){printf("%s\\n", "Hello");}' | gcc-16 -x c - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### cpp

- **Command:** `echo -e '#include <iostream>\nint main(){std::cout<<"Hello"<<std::endl;}' | g++-16 -x c++ - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### csharp

- **Command:** `echo 'System.Console.WriteLine("Hello");' > /tmp/f.cs && dotnet run /tmp/f.cs`
- **Style:** Compiled, one-stage (.NET 10+ file-based app)
- **stdin?** No — needs `.cs` file

### rust

- **Command:** `echo 'fn main(){println!("Hello")}' | rustc -C linker=gcc-16 -o t - && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### zig

- **Command:** `printf 'const std = @import("std"); pub fn main() void { std.debug.print("Hello\\n", .{}); }\n' > /tmp/f.zig && zig run /tmp/f.zig`
- **Style:** Compiled, one-stage (run)
- **stdin?** No — needs `.zig` file

### go

- **Command:** `mkdir -p m && printf 'module h\n' > m/go.mod && printf 'package main\nimport "fmt"\nfunc main() { fmt.Println("Hello") }\n' > m/main.go && go run m/main.go`
- **Style:** Compiled, one-stage (run)
- **stdin?** No — needs `.go` + `go.mod`

### python

- **Command:** `python3 -c "print('Hello')"`
- **Style:** Interpreted
- **stdin?** Yes — `-c` takes source inline

### ruby

- **Command:** `echo 'puts "Hello"' | ruby`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### js

- **Command:** `echo 'console.log("Hello")' | node`
- **Style:** JIT-compiled (V8)
- **stdin?** Yes — pipe is the run

### tsc

- **Command:** `echo 'console.log("Hello")' | bun run -`
- **Style:** JIT-transpiled
- **stdin?** Yes — stdin via `-`

### deno

- **Command:** `echo 'console.log("Hello")' | deno run -`
- **Style:** JIT-compiled (V8)
- **stdin?** Yes — stdin via `-`

### java

- **Command:** `echo 'public class OneLine { public static void main(String[] args) { System.out.println("Hello"); } }' > OneLine.java && java OneLine.java`
- **Style:** Compiled, one-stage (Java 11+ single-file source)
- **stdin?** No — needs `.java` file

### scala

- **Command:** `scala -e 'println("Hello")'`
- **Style:** Compiled (JVM), via `-e` snippet
- **stdin?** No — source via `-e` flag

### lisp

- **Command:** `echo '(format t "Hello~%")' | sbcl --noinform`
- **Style:** Compiled, via REPL
- **stdin?** Yes — pipe feeds REPL

### clojure

- **Command:** `echo '(println "Hello")' | clj`
- **Style:** JIT-compiled, via REPL
- **stdin?** Yes — pipe feeds REPL

### ocaml

- **Command:** `echo 'print_endline "Hello";;' | ocaml -stdin -no-version`
- **Style:** Compiled, via toplevel script mode
- **stdin?** Yes — `-stdin` reads the pipe as a script

### elixir

- **Command:** `elixir -e 'IO.puts("Hello")'`
- **Style:** Interpreted, via `-e` eval
- **stdin?** No — source via `-e` flag

### erlang

- **Command:** `erl -noshell -eval 'io:format("Hello~n"), halt().'`
- **Style:** Compiled, via `-eval` flag
- **stdin?** No — source via `-eval` flag

### perl

- **Command:** `echo 'print "Hello\n"' | perl`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### lua

- **Command:** `echo 'print("Hello")' | lua`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### sql

- **Command:** `echo "SELECT 'Hello';" | duckdb`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### r

- **Command:** `echo 'print("Hello")' | R --slave`
- **Style:** Interpreted
- **stdin?** Yes — pipe feeds REPL

### fortran

- **Command:** `echo 'print*,"Hello";end' | gfortran -ffree-form -x f95 - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### ada

- **Command:** `alr toolchain --select gnat_native gprbuild && alr -n -q init --bin hlo > /dev/null && echo 'with Ada.Text_IO;procedure Hlo is begin Ada.Text_IO.Put_Line("Hello");end;' > hlo/src/hlo.adb && alr -C hlo -q run`
- **Style:** Compiled, one-stage (Alire)
- **stdin?** No — needs project directory

### php

- **Command:** `echo '<?= "Hello\n";' | php`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### swift

- **Command:** `echo 'print("Hello")' | swift -`
- **Style:** Compiled, via interpreter
- **stdin?** Yes — pipe via `-`

### dart

- **Command:** `echo 'void main(){print("Hello");}' > /tmp/f.dart && dart run /tmp/f.dart`
- **Style:** Compiled, JIT one-stage (run)
- **stdin?** No — needs `.dart` file

### julia

- **Command:** `echo 'println("Hello")' | julia -`
- **Style:** JIT-compiled (LLVM)
- **stdin?** Yes — pipe via `-`

### kotlin

- **Command:** `kotlin -e 'println("Hello")'`
- **Style:** Compiled (JVM), via `-e` eval
- **stdin?** No — source via `-e` flag
