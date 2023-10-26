#pragma once

#include <simgear/compiler.h>

#include <string>
#include <list>
#include <fstream>


#define DELIMITERS " \t"
#define COMMENT "#"

#define MAXLINE 400   // Max size of the line of the input file

typedef std::list<std::string> stack; //list to contain the input file "command_lines"

class ParseFile
{
        private:
                
                ::stack commands;
                std::ifstream file;
                void readFile();

        public:

                ParseFile() {}
                ParseFile(const std::string fileName);
                ~ParseFile();

                
                void removeComments(std::string& inputLine);
                std::string getToken(std::string inputLine, int tokenNo);
                void storeCommands(std::string inputLine);
                ::stack getCommands();
};
