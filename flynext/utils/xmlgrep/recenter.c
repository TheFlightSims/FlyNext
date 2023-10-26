#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include <xml.h>

char *
getCommandLineOption(int argc, char **argv, char const *option)
{
    int slen = strlen(option);
    char *rv = 0;
    int i;

    for (i=0; i<argc; i++)
    {
        if (strncmp(argv[i], option, slen) == 0)
        {
            rv = "";
            i++;
            if (i<argc) rv = argv[i];
        }
    }

    return rv;
}

void
show_help()
{
    printf("Usage: recenter <file>\n");
    printf("Calculates the center location of all models in a file,\n");
    printf("recenters all models around (0, 0, 0) and reports the\n");
    printf("center location.\n");
    exit(-1);
}

const char *delimiter = " ";
void print_xml(void *id, double x, double y, double z, char offsets, char* name)
{
  static int level = 1;
  void *xid = xmlMarkId(id);
  unsigned int num;

  num = xmlNodeGetNum(xid, "*");
  if (num == 0)
  {
    if (offsets && strcasecmp(name, "offsets"))
    {
       double val = xmlGetDouble(id);
       if (!strcasecmp(name, "x-m")) {
         printf("%.3f", val-x);
       } else if (!strcasecmp(name, "y-m")) {
         printf("%.3f", val-y);
       } else if (!strcasecmp(name, "z-m")) {
         printf("%.3f", val-z);
       } else {
         printf("%.3f", val);
       }
    }
    else
    {
      char *s;
      s = xmlGetString(xid);
      if (s)
      {
        printf("%s", s);
        free(s);
      }
    }
  }
  else
  {
    unsigned int i, q;
    for (i=0; i<num; i++)
    {
      if (xmlNodeGetPos(id, xid, "*", i) != 0)
      {
        char name[256];

        xmlNodeCopyName(xid, (char *)&name, 256);

        printf("\n");
        for(q=0; q<level; q++) printf("%s", delimiter);
        printf("<%s>", name);
        level++;
        if (!offsets) offsets = !strcasecmp(name, "offsets");
        print_xml(xid, x, y, z, offsets, name);
        level--;
        printf("</%s>", name);
      }
      else printf("error\n");
    }
    printf("\n");
    for(q=1; q<level; q++) printf("%s", delimiter);
  }
}


int
main(int argc, char **argv)
{
    const char *fname;
    void *rid;

    if (argc != 2) {
        show_help();
    }

    fname = argv[1];
    rid = xmlOpen(fname);
    if (rid)
    {
        void *pid = xmlNodeGet(rid, "PropertyList");
        if (pid)
        {
            double x, y, z;
            int i, num;
            void *mid;

            x = y = z = 0.0;

            mid = xmlMarkId(pid);
            num = xmlNodeGetNum(pid, "model");
            for (i=0; i<num; i++)
            {
                if (xmlNodeGetPos(pid, mid, "model", i) != 0)
                {
                    void *oid = xmlNodeGet(mid, "offsets");
                    if (oid)
                    {
                        x += xmlNodeGetDouble(oid, "x-m");
                        y += xmlNodeGetDouble(oid, "y-m");
                        z += xmlNodeGetDouble(oid, "z-m");
                        xmlFree(oid);
                    }
                }
            }
            xmlFree(mid);

            x /= (double)num;
            y /= (double)num;
            z /= (double)num;

            printf("<!--\n");
            printf("  center: x-m: %5.3f\n", x);
            printf("  center: y-m: %5.3f\n", y);
            printf("  center: z-m: %5.3f\n", z);
            printf("-->\n");

            print_xml(rid, x, y, z, 0, "");
            xmlFree(pid);
        }
        xmlClose(rid);
    }
    return 0;
}
