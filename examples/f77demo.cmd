@echo off
rem Note: you need to use "call f77" from OS/2 CMD.EXE scripts
echo First, a simple example.
echo Compile hello.fpp to hello.exe in one step.
echo We use the -v (verbose) option to watch everything going on.
pause
echo f77 -o hello.exe -v hello.fpp
call f77 -o hello.exe -v hello.fpp
echo OK, now we will run hello.exe...
pause
hello
echo Next, compile hello.fpp with the cpp macro "FUNKY" defined.
echo We will use EMX method 2, and keep the intermediate .f,.c files
pause
echo f77 -c -DFUNKY -k -v -Zomf -Zmtd hello.fpp
call f77 -c -DFUNKY -k -v -Zomf -Zmtd hello.fpp
echo Now, link hello.obj, hello.def to hello.exe executable
pause
echo f77 -o hello.exe -v -Zomf -Zmtd hello.obj hello.def
call f77 -o hello.exe -v -Zomf -Zmtd hello.obj hello.def
echo OK, now we will run hello.exe...
pause
hello
pause
echo Thats all folks!
