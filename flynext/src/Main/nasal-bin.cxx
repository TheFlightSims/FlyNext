
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#include <pthread.h>
#endif

#include <simgear/nasal/nasal.h>
#include <simgear/io/sg_mmap.hxx>
#include <simgear/misc/sg_path.hxx>

#define HAVE_SQLITE 1

using namespace std;

void checkError(naContext ctx)
{
    int i;
    if(naGetError(ctx)) {
        fprintf(stderr, "Runtime error: %s\n  at %s, line %d\n",
                naGetError(ctx), naStr_data(naGetSourceFile(ctx, 0)),
                naGetLine(ctx, 0));

        for(i=1; i<naStackDepth(ctx); i++)
            fprintf(stderr, "  called from: %s, line %d\n",
                    naStr_data(naGetSourceFile(ctx, i)),
                    naGetLine(ctx, i));
        exit(1);
    }
}

// A Nasal extension function (prints its argument list to stdout)
static naRef print(naContext c, naRef me, int argc, naRef* args)
{
    int i;
    for(i=0; i<argc; i++) {
        naRef s = naStringValue(c, args[i]);
        if(naIsNil(s)) continue;
        fwrite(naStr_data(s), 1, naStr_len(s), stdout);
    }
    return naNil();
}

static void initAllowedPaths()
{
    SGPath::clearListOfAllowedPaths(false); // clear list of read-allowed paths
    SGPath::clearListOfAllowedPaths(true);  // clear list of write-allowed paths

    // Allow reading and writing anywhere
    SGPath::addAllowedPathPattern("*", false); // read operations
    SGPath::addAllowedPathPattern("*", true);  // write operations
}

#define NASTR(s) naStr_fromdata(naNewString(ctx), (s), strlen((s)))
int main(int argc, char** argv)
{
    naRef *args, code, nasal, result;
    struct Context *ctx;
    int fsize, errLine, i;
    char *buf;

    if(argc < 2) {
        fprintf(stderr, "nasal: must specify a script to run\n");
        exit(1);
    }

    initAllowedPaths();         // for SGPath::validate()

    // MMap the contents of the file.
    SGPath script(argv[1]);
    SGMMapFile f(script);
    f.open(SG_IO_IN);
    buf = (char*)f.get();
    fsize= f.get_size();

    // Create an interpreter context
    ctx = naNewContext();

    // Parse the code in the buffer.  The line of a fatal parse error
    // is returned via the pointer.
    code = naParseCode(ctx, NASTR(script.c_str()), 1, buf, fsize, &errLine);
    if(naIsNil(code)) {
        fprintf(stderr, "Parse error: %s at line %d\n",
                naGetError(ctx), errLine);
        exit(1);
    }
    f.close();

    // Make a hash containing the standard library functions.  This
    // will be the namespace for a new script
    nasal = naInit_std(ctx);

    // Add application-specific functions (in this case, "print" and
    // the math library) to the nasal if desired.
    naAddSym(ctx, nasal, (char*)"print", naNewFunc(ctx, naNewCCode(ctx, print)));

    // Add extra libraries as needed.
    naAddSym(ctx, nasal, (char*)"utf8", naInit_utf8(ctx));
    naAddSym(ctx, nasal, (char*)"math", naInit_math(ctx));
    naAddSym(ctx, nasal, (char*)"bits", naInit_bits(ctx));
    naAddSym(ctx, nasal, (char*)"io", naInit_io(ctx));
#ifndef _WIN32
    naAddSym(ctx, nasal, (char*)"unix", naInit_unix(ctx));
#endif
    naAddSym(ctx, nasal, (char*)"thread", naInit_thread(ctx));
#ifdef HAVE_PCRE
    naAddSym(ctx, nasal, (char*)"regex", naInit_regex(ctx));
#endif
#ifdef HAVE_SQLITE
    naAddSym(ctx, nasal, (char*)"sqlite", naInit_sqlite(ctx));
#endif
#ifdef HAVE_READLINE
    naAddSym(ctx, nasal, (char*)"readline", naInit_readline(ctx));
#endif
#ifdef HAVE_GTK
    // Gtk goes in as "_gtk" -- there is a higher level wrapper module
    naAddSym(ctx, nasal, (char*)"_gtk", naInit_gtk(ctx));
    naAddSym(ctx, nasal, (char*)"cairo", naInit_cairo(ctx));
#endif

    // Bind the "code" object from naParseCode into a "function"
    // object.  This is optional, really -- we could also just pass
    // the nasal hash as the final argument to naCall().  But
    // having the global nasal in an outer scope means that we
    // won't be polluting it with the local variables of the script.
    code = naBindFunction(ctx, code, nasal);

    // Build the arg vector
    args = (naRef*)malloc(sizeof(naRef) * (argc-2));
    for(i=0; i<argc-2; i++)
        args[i] = NASTR(argv[i+2]);

    // Run it.
    result = naCall(ctx, code, argc-2, args, naNil(), naNil());
    (void)result; // surpeess a compiler waring;
    free(args);

#if 0
    // Test for naContinue() feature.  Keep trying until it reports
    // success.
    while(naGetError(ctx)) {
        printf("Err: \"%s\", calling naContinue()...\n", naGetError(ctx));
        naContinue(ctx);
    }
#endif

    checkError(ctx);
    return 0;
}
#undef NASTR
