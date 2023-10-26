#include "config.h"

#include <cstdlib>
#include <cstring>

#include <string>

#include <simgear/nasal/nasal.h>
#include <simgear/misc/sg_path.hxx>
#include <simgear/structure/exception.hxx>
#include <simgear/debug/logstream.hxx>

#ifdef SYSTEM_SQLITE
  #include "sqlite3.h"
#else
  #include "fg_sqlite3.h"
#endif

// Ghost types
struct DBGhost { sqlite3* db; };
struct StmtGhost { sqlite3_stmt* stmt; };
static void dbDestroy(struct DBGhost* g);
static void stmtDestroy(struct StmtGhost* g);
static naGhostType DBType = { (void(*)(void*))dbDestroy, "sqlite_db" };
static naGhostType StmtType = { (void(*)(void*))stmtDestroy, "sqlite_statement" };
#define DBG(r) ((naGhost_type(r) == &DBType) ? (struct DBGhost*)naGhost_ptr(r) : 0)
#define STMTG(r) ((naGhost_type(r) == &StmtType) ? (struct StmtGhost*)naGhost_ptr(r) : 0)

static void dbDestroy(struct DBGhost* g)
{
    if(g->db) sqlite3_close_v2(g->db);
    g->db = 0;
    free(g);
}

static void stmtDestroy(struct StmtGhost* g)
{
    if(g->stmt) sqlite3_finalize(g->stmt);
    g->stmt = 0;
    free(g);
}

static naRef f_open(naContext c, naRef me, int argc, naRef* args)
{
    struct DBGhost* g;
    if(argc < 1 || !naIsString(args[0]))
        naRuntimeError(c, "Bad/missing argument to sqlite.open");
    g = (DBGhost*)malloc(sizeof(struct DBGhost));

    const auto path = SGPath::fromUtf8(naStr_data(args[0]));
    const SGPath filename = SGPath(path).validate(true);
    if (filename.isNull()) {
        SG_LOG(SG_NASAL, SG_ALERT, "stat(): reading '" <<
        naStr_data(args[0]) << "' denied (unauthorized directory - authorization"
        " no longer follows symlinks; to authorize reading additional "
        "directories, pass them to --allow-nasal-read)");
        naRuntimeError(c, "stat(): access denied (unauthorized directory)");
        return naNil();
    }

    int openFlags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;
    std::string pathUtf8 = path.utf8Str();
    if(sqlite3_open_v2(pathUtf8.c_str(), &g->db, openFlags, NULL))
    {
        const char* msg = sqlite3_errmsg(g->db);
        sqlite3_close_v2(g->db);
        free(g);
        naRuntimeError(c, "sqlite open error: %s", msg);
    }
    sqlite3_busy_timeout(g->db, 60*60*1000); /* One hour */
    return naNewGhost(c, &DBType, g);
}

static naRef f_close(naContext c, naRef me, int argc, naRef* args)
{
    struct DBGhost* g = argc > 0 ? DBG(args[0]) : 0;
    if(!g) naRuntimeError(c, "bad/missing argument to sqlite.close");
    sqlite3_close_v2(g->db);
    g->db = 0;
    return naNil();
}

static naRef f_prepare(naContext c, naRef me, int argc, naRef* args)
{
    naRef db = argc > 0 ? args[0] : naNil();
    naRef s = argc > 1 ? args[1] : naNil();
    const char* tail;
    struct StmtGhost* g;
    struct DBGhost* dbg = DBG(db);
    if(!naIsString(s) || !dbg)
        naRuntimeError(c, "bad/missing argument to sqlite.prepare");
    g = (StmtGhost*)malloc(sizeof(struct StmtGhost));
    if(sqlite3_prepare(dbg->db, naStr_data(s), naStr_len(s), &g->stmt, &tail))
    {
        const char* msg = sqlite3_errmsg(dbg->db);
        if(g->stmt) sqlite3_finalize(g->stmt);
        free(g);
        naRuntimeError(c, "sqlite prepare error: %s", msg);
    }
    return naNewGhost(c, &StmtType, g);
}

// FIXME: need to catch and re-throw errors from the callback.  Right
// now they just get silently eaten.
static naRef run_query(naContext c, sqlite3* db, sqlite3_stmt* stmt,
                       naRef callback)
{
    naContext subc = naIsNil(callback) ? 0 : naSubContext(c);
    naRef* fields = 0;
    naRef val, row, result = subc ? naNil() : naNewVector(c);
    int i, cols=0, stat;
    while((stat = sqlite3_step(stmt)) != SQLITE_DONE) {
        if(stat != SQLITE_ROW)
            naRuntimeError(c, "sqlite step error: %s", sqlite3_errmsg(db));
        if(!fields) {
            cols = sqlite3_column_count(stmt);
            fields = (naRef*)malloc(cols * sizeof(naRef));
            for(i=0; i<cols; i++) {
                const char* s = sqlite3_column_name(stmt, i);
                naRef fn = naStr_fromdata(naNewString(c), (char*)s, strlen(s));
                // Do we really want to use the global intern table here?
                fields[i] = naInternSymbol(fn);
            }
        }
        row = naNewHash(c);
        for(i=0; i<cols; i++) {
            int type = sqlite3_column_type(stmt, i);
            if(type == SQLITE_BLOB || type == SQLITE_TEXT)
                val = naStr_fromdata(naNewString(c),
                                     (char*)sqlite3_column_blob(stmt, i),
                                     sqlite3_column_bytes(stmt, i));
            else
                val = naNum(sqlite3_column_double(stmt, i));
            naHash_set(row, fields[i], val);
        }
        if(!subc) {
            naVec_append(result, row);
        } else {
            naCall(subc, callback, 1, &row, naNil(), naNil());
            if(naGetError(subc)) naRethrowError(subc);
        }
    }
    if(subc) naFreeContext(subc);
    free(fields);
    return result;
}

static naRef f_exec(naContext c, naRef me, int argc, naRef* args)
{
    naRef callback = naNil();
    naRef db = argc > 0 ? args[0] : naNil();
    naRef stmt = argc > 1 ? args[1] : naNil();
    int i, bindings = 2;
    if(naIsString(stmt)) {
        naRef args[2]; args[0] = db; args[1] = stmt;
        stmt = f_prepare(c, naNil(), 2, args);
    }
    if(!DBG(db) || !STMTG(stmt))
        naRuntimeError(c, "bad/missing argument to sqlite.exec");
    if(argc > bindings && naIsFunc(args[bindings]))
        callback = args[bindings++];
    sqlite3_reset(STMTG(stmt)->stmt);
    for(i=bindings; i<argc; i++) {
        int err=0, bidx=i-bindings+1;
        if(naIsString(args[i]))
            err = sqlite3_bind_text(STMTG(stmt)->stmt, bidx,
                                    naStr_data(args[i]),
                                    naStr_len(args[i]), SQLITE_TRANSIENT);
        else if(naIsNum(args[i]))
            err = sqlite3_bind_double(STMTG(stmt)->stmt, bidx, args[i].num);
        else
            naRuntimeError(c, "sqlite.exec cannot bind non-scalar");
        if(err)
            naRuntimeError(c, "sqlite bind error: %s",
                           sqlite3_errmsg(DBG(db)->db));
    }
    return run_query(c, DBG(db)->db, STMTG(stmt)->stmt, callback);
}

static naRef f_finalize(naContext c, naRef me, int argc, naRef* args)
{
    struct StmtGhost* g = argc > 0 ? STMTG(args[0]) : 0;
    if(!g) naRuntimeError(c, "bad/missing argument to sqlite.finalize");
    sqlite3_finalize(g->stmt);
    g->stmt = 0;
    return naNil();
}

static naCFuncItem funcs[] = {
    { (char*)"open", f_open },
    { (char*)"close", f_close },
    { (char*)"prepare", f_prepare },
    { (char*)"exec", f_exec },
    { (char*)"finalize", f_finalize },
    { 0 }
};

naRef naInit_sqlite(naContext c)
{
    return naGenLib(c, funcs);
}
