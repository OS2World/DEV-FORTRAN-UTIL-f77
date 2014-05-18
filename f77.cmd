extproc ksh d:/os2/bin/f77.cmd
#           ^- LOCAL CONFIG -^
# NOTE: full path for f77.cmd is required! (CMD.EXE brain damage)
#
# $Id: f77.cmd,v 1.1 1994/09/11 05:47:18 jcp Exp jcp $
#
# f77 "look & feel" script to compile & link Fortran 77 and C code
#
# usage: f77 [options] source_files [-l library]
#
# f77 recognizes the following options;
#
#	-a		enable dynamic allocation of memory for local variables
#
#	-C		compile code to check for legal array subscripts values
#
#	-c		compile only, disable linking by the loader
#
#	-Dmacro[=def]	define a C preprocessor macro name
#
#	-f		allow statements longer than 72 characters
#
#	-g		generate symbol table information for debugging
#
#	-Idir		insert dir at start of search path for include files
#
#	-k		keep .c output from f2c (and .f when compiling .F files)
#
#	-Ldir		insert dir at start of search path for library files
#
#	-Ntnnn		allow nnn entries in table t (passed to f2c)
#
#	-ooutput	name the linker output file "output" instead of a.exe
#
#	-O		compiler tries to reduce code size and execution time
#
#	-P prog:opt	pass "opt" to "prog" compilation phase(cpp,f2c,cc,ld)
#
#       -r8             promote REAL to DOUBLE, COMPLEX to DOUBLE COMPLEX
#
#	-S		generate assembly code only, output goes to .s file
#
#	-Tdir		create temporary files in directory dir
#
#	-u		make the default type of all f77 variables undefined
#
#	-v		print the command line for each subprocess executed
#
#	-w		suppress the printing of all warning messages
#
#	-w66		suppress Fortran 66 compatibility warning messages
#
#	-Zopt		pass EMX -Zopt to compiler and linker (see EMX docs)
#
#	-1		Fortran DO loops are always executed at least once
#
#	input_files	input file(s) with .F, .f, .c, or .o suffix
#
#	-lx		link with object library libx.a (passed to ld).
#
################################################################################
# beg configuration section

# configure the search path for executables
# If for some reason your default executable search path (from your
# config.sys) is incorrect, you can uncomment the two lines below and
# set it here. The '' quotes are needed to keep the shell from
# parsing the ";" as a command seperator. DON'T use "\" in paths!
#
# PATH='d:/os2/bin;d:/os2/usr/emx/bin;c:/os2'
# export PATH;

# configure f2c
F2C=f2c
F2CFLAGS='-Nn1024 -Nx512 -R'

# configure which cpp to use
CPP=gcc
CPPFLAGS='-E -x c'

# configure which C compiler to use
CC=gcc
CCFLAGS=
# C compiler flags for compiling f2c generated .c files
CFLAGS_F2C='-traditional -I/os2/include'
#                        ^LOCAL CONFIG^

# configure which linker to use
LD=gcc
LDFLAGS=
# default libraries when linking using EMX Method 1
METHOD1DEFLIBS='-L/os2/lib -lf2c -lm'
#               ^ LOCAL CONFIG ^
# default libraries when linking using EMX Method 2
# if you use my dynamic support libs, use -lf2clib -lf2cdll
METHOD2DEFLIBS='-L/os2/lib -lf2c -lm'
#               ^ LOCAL CONFIG ^

# configure support executables
# see the README if you don't have these, you'll need them.
BASENAME=basename
ECHO=echo
GETOPT=getopt
RM='rm -f'
SED=sed

# configure suffix to use for .F and .f files
# If you cut your teeth on VAXen, you may prefer FOR=FOR and for=for
FPP=FPP
fpp=fpp
FOR=F
for=f

# configure basename of temporary files
# Should work for those poor souls using the ghastly FAT file system.
tempbase=f77_$$

# end configuration section
################################################################################

# initialize

# (these are automagically reset when the -Zomf option is encountered)
OBJ=O
obj=o
OBJFILES=
DEFLIBS=$METHOD1DEFLIBS
# default executable name
OUTFILE=a.exe

t=$tempbase
cOPT=1
kOPT=1
oOPT=1
sOPT=1
vOPT=1
rc=0

check_directory()
{
	test -d "$1"
	case $? in
		0) ;;
		*)	$ECHO "directory: $1 does not exist, or is not a directory" 1>&2
			exit $? ;;
	esac
}

check_file()
{
	test -f "$1"
	case $? in
		0) ;;
		*)	$ECHO "file: $1 does not exist, or is not a regular file" 1>&2
			exit $? ;;
	esac
}

execute_process()
{
	case $vOPT in
		0) $ECHO "$1" 1>&2 ;;
	esac
	eval "$1"
	rc=$?
	case $rc in
		0) ;;
		*) exit $rc ;;
	esac
}

# define trap handler

clean_up()
{
	execute_process "$RM $t.$FOR $t.c"
}

# install trap handler

trap "clean_up; exit \$rc" 0

# shift off the /path/f77.cmd (the one *we* provide on the extproc line)
#  *and* the really useful "f77.cmd" compliments of OS/2 CMD.EXE

shift 2

# parse command line options

set -- `$GETOPT "acCD:fgI:kL:N:Oo:P:r:ST:uvwZ:16" $*`

case $? in
	0) ;;
	*) exit 1 ;;
esac

while
	test X$1 != X--
do

	case "$1" in

	-a)
		F2CFLAGS="$F2CFLAGS -a"
		shift
		;;

	-C)
		F2CFLAGS="$F2CFLAGS -C"
		shift
		;;

	-c)
		cOPT=0
		shift
		;;

	-D)
		CCFLAGS="$CCFLAGS -D$2"
		CPPFLAGS="$CPPFLAGS -D$2"
		shift 2
		;;

	-f)
		F2CFLAGS="$F2CFLAGS -f"
		shift
		;;

	-g)
		CCFLAGS="$CCFLAGS -g"
		LDFLAGS="$LDFLAGS -g"
		shift
		;;

	-I)
		check_directory "$2"
		CCFLAGS="$CCFLAGS -I$2"
		CPPFLAGS="$CPPFLAGS -I$2"
		shift 2
		;;

	-k)
		kOPT=0
		shift
		;;

	-L)
		check_directory "$2"
		OBJFILES="$OBJFILES -L$2"
		shift 2
		;;

	-N)
		F2CFLAGS="$F2CFLAGS -N$2"
		shift 2
		;;

	-O)
		CCFLAGS="$CCFLAGS -O"
		shift
		;;

	-o)
		OUTFILE=$2
		oOPT=0
		shift 2
		;;

	-P)
		case $2 in
			cpp:*)	CPPFLAGS="$CPPFLAGS `$ECHO $2 |$SED 's/^cpp://'`"
				;;
			f2c:*)	F2CFLAGS="$F2CFLAGS `$ECHO $2 |$SED 's/^f2c://'`"
				;;
			cc:*)	CCFLAGS="$CCFLAGS `$ECHO $2 | $SED 's/^cc://'`"
				;;
			ld:*)	LDFLAGS="$LDFLAGS `$ECHO $2 | $SED 's/^ld://'`"
				;;
			*)	$ECHO "warning: option -P $2 was ignored" 1>&2
				;;
		esac
		shift 2
		;;

	-r)
		case $2 in
			8)	F2CFLAGS="$F2CFLAGS -r8"
				;;
			*)	$ECHO "warning: -r$2 option was ignored" 1>&2
				;;
		esac
		shift 2
		;;

	-S)
		CCFLAGS="$CCFLAGS -S"
		sOPT=0
		cOPT=0
		shift
		;;

	-T)
		check_directory "$2"
		F2CFLAGS="$F2CFLAGS -T$2"
		t=$2/$tempbase
		shift 2
		;;

	-u)
		F2CFLAGS="$F2CFLAGS -u"
		shift
		;;

	-v)
		CCFLAGS="$CCFLAGS -v"
		LDFLAGS="$LDFLAGS -v"
		vOPT=0
		shift
		;;

	-w)
		F2CFLAGS="$F2CFLAGS -w"
		case $2 in
			-6)	shift
				case $2 in
					-6)	F2CFLAGS="$F2CFLAGS"66
						shift ;;
				esac ;;
		esac
		shift
		;;

	-Z)
		case $2 in
			omf)	OBJ=OBJ
				obj=obj
				DEFLIBS=$METHOD2DEFLIBS
				;;
		esac
		CCFLAGS="$CCFLAGS -Z$2"
		LDFLAGS="$LDFLAGS -Z$2"
		shift 2
		;;

	-1)
		F2CFLAGS="$F2CFLAGS -onetrip"
		shift
		;;

	*)
		$ECHO "warning: option $1 was ignored" 1>&2
		shift
		;;

	esac

done

# parse source file arguments

shift

while
	test -n "$1"
do

	case "$1" in

	*.c)
		check_file "$1"
		$ECHO $1: 1>&2
		b=`$BASENAME $1 .c`
		case $cOPT in
			0)	case $oOPT in
					0)	o=$OUTFILE ;;
					*)	case $sOPT in
							0) o=$b.s ;;
							*) o=$b.$obj ;;
						esac ;;
				esac ;;
			*)	o=$b.$obj ;;
		esac
		CMD="$CC -c -o $o $CCFLAGS $1"
		execute_process "$CMD"
		OBJFILES="$OBJFILES $o"
		case $cOPT in 1) cOPT=2 ;; esac
		shift
		;;

	*.DEF|*.def)
		check_file "$1"
		OBJFILES="$OBJFILES $1"
		case $cOPT in 1) cOPT=2 ;; esac
		shift
		;;

	*.$FPP|*.$fpp|*.$FOR|*.$for)
		check_file "$1"
		case "$1" in
			*.$FPP)	b=`$BASENAME $1 .$FPP`
				case $kOPT in
					0) f=$b.$FOR ;;
					*) f=$t.$FOR ;;
				esac
				CMD="$CPP $CPPFLAGS $1 | $SED '/^#/d' > $f"
				execute_process "$CMD"
				O=$OBJ
				;;
			*.$fpp)	b=`$BASENAME $1 .$fpp`
				case $kOPT in
					0) f=$b.$for ;;
					*) f=$t.$for ;;
				esac
				CMD="$CPP $CPPFLAGS $1 | $SED '/^#/d' > $f"
				execute_process "$CMD"
				O=$obj
				;;
			*.$FOR)	b=`$BASENAME $1 .$FOR`
				f=$1
				O=$OBJ
				;;
			*.$for)	b=`$BASENAME $1 .$for`
				f=$1
				O=$obj
				;;
		esac
		case $kOPT in
			0) c=$b.c ;;
			*) c=$t.c ;;
		esac
		CMD="$F2C $F2CFLAGS < $f > $c"
		execute_process "$CMD"
		case $cOPT in
			0)	case $oOPT in
					0)	o=$OUTFILE ;;
					*)	case $sOPT in
							0) o=$b.s ;;
							*) o=$b.$O ;;
						esac ;;
				esac ;;
			*)	o=$b.$O ;;
		esac
		CMD="$CC -c -o $o $CFLAGS_F2C $CCFLAGS $c"
		execute_process "$CMD"
		OBJFILES="$OBJFILES $o"
		case $cOPT in 1) cOPT=2 ;; esac
		shift
		;;

	*.$OBJ|*.$obj)
		check_file "$1"
		OBJFILES="$OBJFILES $1"
		case $cOPT in 1) cOPT=2 ;; esac
		shift
		;;

	-L)
		check_directory "$2"
		OBJFILES="$OBJFILES -L$2"
		case $cOPT in 1) cOPT=2 ;; esac
		shift 2
		;;

	-l)
		OBJFILES="$OBJFILES -l$2"
		case $cOPT in 1) cOPT=2 ;; esac
		shift 2
		;;

	-o)
		OUTFILE=$2
		shift 2
		;;

	*)
		OBJFILES="$OBJFILES $1"
		case $cOPT in 1) cOPT=2 ;; esac
		shift
		;;

	esac

done

# final link phase

case $cOPT in
	2)	CMD="$LD -o $OUTFILE $LDFLAGS $OBJFILES $DEFLIBS"
		execute_process "$CMD"
		;;
esac

exit $rc
