   This is one of my first proggies, it demonstrates the handling of command line parameters without the use of the C library, although it copies (more or less) its behaviour. 

   The _argc variable returns the number of arguments, while _argv stores adresses to null-term strings containing the parameters. The first one is the executable file name. When all the processing is done, [_argv] must (or at least should) be HeapFree-ed. 

   There is no black magic used here. Labels are self-explaniatory and the code is preety straight-forward, but it does give newbies the chance of exercising ASM programming by optimizing proggies written by rookies like myself.
