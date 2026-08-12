Build and run: `docker build -t ai-dev . && docker run -it --rm --privileged ai-dev`

### C

- **Command:** `echo -e '#include <stdio.h>\nvoid main(){printf("%s\\n", "Hello");}' | gcc-16 -x c - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### C++

- **Command:** `echo -e '#include <iostream>\nint main(){std::cout<<"Hello"<<std::endl;}' | g++-16 -x c++ - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### Rust

- **Command:** `echo 'fn main(){println!("Hello")}' | rustc -C linker=gcc-16 -o t - && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### Zig

- **Command:** `printf 'const std = @import("std"); pub fn main() void { std.debug.print("Hello\\n", .{}); }\n' > /tmp/f.zig && zig run /tmp/f.zig`
- **Style:** Compiled, one-stage (run)
- **stdin?** No — needs `.zig` file

### Go

- **Command:** `mkdir -p m && printf 'module h\n' > m/go.mod && printf 'package main\nimport "fmt"\nfunc main() { fmt.Println("Hello") }\n' > m/main.go && go run m/main.go`
- **Style:** Compiled, one-stage (run)
- **stdin?** No — needs `.go` + `go.mod`

### Python

- **Command:** `python3 -c "print('Hello')"`
- **Style:** Interpreted
- **stdin?** Yes — `-c` takes source inline

### Ruby

- **Command:** `echo 'puts "Hello"' | ruby`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### TypeScript (Bun)

- **Command:** `echo 'console.log("Hello")' | bun run -`
- **Style:** JIT-transpiled
- **stdin?** Yes — stdin via `-`

### Java

- **Command:** `echo 'public class OneLine { public static void main(String[] args) { System.out.println("Hello"); } }' > OneLine.java && java OneLine.java`
- **Style:** Compiled, one-stage (Java 11+ single-file source)
- **stdin?** No — needs `.java` file

### Common Lisp (SBCL)

- **Command:** `echo '(format t "Hello~%")' | sbcl --noinform`
- **Style:** Compiled, via REPL
- **stdin?** Yes — pipe feeds REPL

### Clojure

- **Command:** `echo '(println "Hello")' | clj`
- **Style:** JIT-compiled, via REPL
- **stdin?** Yes — pipe feeds REPL

### Elixir

- **Command:** `elixir -e 'IO.puts("Hello")'`
- **Style:** Interpreted, via `-e` eval
- **stdin?** No — source via `-e` flag

### Perl

- **Command:** `echo 'print "Hello\n"' | perl`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### Lua

- **Command:** `echo 'print("Hello")' | lua`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### SQL (DuckDB)

- **Command:** `echo "SELECT 'Hello';" | duckdb`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### R

- **Command:** `echo 'print("Hello")' | R --slave`
- **Style:** Interpreted
- **stdin?** Yes — pipe feeds REPL

### Fortran

- **Command:** `echo 'print*,"Hello";end' | gfortran -ffree-form -x f95 - -o t && ./t`
- **Style:** Compiled, two-stage
- **stdin?** Source via pipe, separate run

### Ada (Alire)

- **Command:** `alr toolchain --select gnat_native gprbuild && alr -n -q init --bin hlo > /dev/null && echo 'with Ada.Text_IO;procedure Hlo is begin Ada.Text_IO.Put_Line("Hello");end;' > hlo/src/hlo.adb && alr -C hlo -q run`
- **Style:** Compiled, one-stage (Alire)
- **stdin?** No — needs project directory

### PHP

- **Command:** `echo '<?= "Hello\n";' | php`
- **Style:** Interpreted
- **stdin?** Yes — pipe is the run

### Swift

- **Command:** `echo 'print("Hello")' | swift -`
- **Style:** Compiled, via interpreter
- **stdin?** Yes — pipe via `-`
