
#include <iterator>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <vector>
#include <string>
#include <map>

#define DEG2RAD(a)		(3.141592657*(a)/180.0)

// https://stackoverflow.com/questions/1120140/how-can-i-read-and-parse-csv-files-in-c
class CSVRow
{
    public:
        std::string_view operator[](std::size_t index) const
        {
            return std::string_view(&m_line[m_data[index] + 1], m_data[index + 1] -  (m_data[index] + 1));
        }
        std::size_t size() const
        {
            return m_data.size() - 1;
        }
        void readNextRow(std::istream& str)
        {
            std::getline(str, m_line);

            m_data.clear();
            m_data.emplace_back(-1);
            std::string::size_type pos = 0;
            while((pos = m_line.find(',', pos)) != std::string::npos)
            {
                m_data.emplace_back(pos);
                ++pos;
            }
            // This checks for a trailing comma with no data after it.
            pos   = m_line.size();
            m_data.emplace_back(pos);
        }
    private:
        std::string         m_line;
        std::vector<int>    m_data;
};

std::istream& operator>>(std::istream& str, CSVRow& data)
{
    data.readNextRow(str);
    return str;
}

class CSVIterator
{
    public:
        typedef std::input_iterator_tag     iterator_category;
        typedef CSVRow                      value_type;
        typedef std::size_t                 difference_type;
        typedef CSVRow*                     pointer;
        typedef CSVRow&                     reference;

        CSVIterator(std::istream& str)  :m_str(str.good()?&str:NULL) { ++(*this); }
        CSVIterator()                   :m_str(NULL) {}

        // Pre Increment
        CSVIterator& operator++()               {if (m_str) { if (!((*m_str) >> m_row)){m_str = NULL;}}return *this;}
        // Post increment
        CSVIterator operator++(int)             {CSVIterator    tmp(*this);++(*this);return tmp;}
        CSVRow const& operator*()   const       {return m_row;}
        CSVRow const* operator->()  const       {return &m_row;}

        bool operator==(CSVIterator const& rhs) {return ((this == &rhs) || ((this->m_str == NULL) && (rhs.m_str == NULL)));}
        bool operator!=(CSVIterator const& rhs) {return !((*this) == rhs);}
    private:
        std::istream*       m_str;
        CSVRow              m_row;
};

class CSVRange
{
    std::istream&   stream;
    public:
        CSVRange(std::istream& str)
            : stream(str)
        {}
        CSVIterator begin() const {return CSVIterator{stream};}
        CSVIterator end()   const {return CSVIterator{};}
};

// https://stackoverflow.com/questions/17642882/c-2d-map-like-a-2d-array
template<typename T>
class Graph {
private:
    typedef std::map<std::pair<size_t,size_t>, T> graph_type;
    graph_type graph;
    class SrcVertex {
    private:
        graph_type& graph;
        size_t vert_src;
    public:
        SrcVertex(graph_type& graph): graph(graph) {}
        T& operator[](size_t vert_dst) {
            return graph[std::make_pair(vert_src, vert_dst)];
        }
        void set_vert_src(size_t vert_src) {
            this->vert_src = vert_src;
        }
    } src_vertex_proxy;
public:
    Graph(): src_vertex_proxy(graph) {}
    SrcVertex& operator[](size_t vert_src) {
        src_vertex_proxy.set_vert_src(vert_src);
        return src_vertex_proxy;
    }
};


// own code by Erik Hofman
class JSBSim
{
public:
    std::string name;
    std::vector<int> date;
    std::vector<int> time;
    std::vector<double> a, b;
    Graph<double> CDi, CDo, CDtot, CDtrefftz;
    Graph<double> CFx, CFy, CFz, CL;
    Graph<double> CMx, CMy, CMz;

    JSBSim(std::istream& file)
    {
        // every section contains 39 lines
        size_t alpha, beta;
        for(auto& row: CSVRange(file))
        {
            if (row[0] == "Results_Name") {
                if (row[1] != "VSPAERO_History") break;
                name = row[1];
            }

            char *end;
            const char *start = row[row.size()-1].data();
            double d = std::strtod(start, &end);
            if (row[0] == "Alpha") {
                alpha = d*100;
                if (!a.size() || d > a.back()) a.push_back(d);
            } else if (row[0] == "Beta") {
                beta = d*100;
               if (!b.size() || d > b.back())  b.push_back(d);
            } if (row[0] == "CDi") {
                CDi[alpha][beta] = d;
            } if (row[0] == "CDo") {
                CDo[alpha][beta] = d;
            } if (row[0] == "CDtot") {
                CDtot[alpha][beta] = d;
            } if (row[0] == "CDtrefftz") {
                CDtrefftz[alpha][beta] = d;
            } if (row[0] == "CFx") {
                CFx[alpha][beta] = d;
            } if (row[0] == "CFy") {
                CFy[alpha][beta] = d;
            } if (row[0] == "CFz") {
                CFz[alpha][beta] = d;
            } if (row[0] == "CL") {
                CL[alpha][beta] = d;
            } if (row[0] == "CMx") {
                CMx[alpha][beta] = d;
            } if (row[0] == "CMy") {
                CMy[alpha][beta] = d;
            } if (row[0] == "CMz") {
                CMz[alpha][beta] = d;
            }
        }
    }
    ~JSBSim() = default;

    void print_table(Graph<double>& type, std::string name) {
        std::cout << name << std::endl;
        std::cout << std::setw(10) << "  ";
        for (int j=0; j<b.size(); ++j) {
            std::cout << std::setw(8) << DEG2RAD(b[j]);
        }
        std::cout << std::endl;

        for (int i=0; i<a.size(); ++i) {
            std::cout << std::setw(8) << DEG2RAD(a[i]) << "  ";
            for (int j=0; j<b.size(); ++j) {
                std::cout << std::setw(8) << type[a[i]*100][b[j]*100];
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;
}

private:
    template <typename T>
    void push_vector(std::vector<T>& dst, const CSVRow& row) {
        for (int i=1; i<row.size(); ++i)
        {
            char *end;
            const char *start = row[i].data();
            double d = std::strtod(start, &end);
            dst.push_back(d);
        }
    }
};

int main(int argc, char *argv[])
{
    std::ifstream file(argv[1]);
    JSBSim jsb(file);

    std::cout << "Name: " << jsb.name << std::endl;

    std::cout << std::fixed << std::showpoint << std::setprecision(3);

    std::cout << "LIFT:" << std::endl;
    jsb.print_table(jsb.CL, "CL");

    std::cout << "DRAG:" << std::endl;
    jsb.print_table(jsb.CDi, "CDi (Induced Drag)");
    jsb.print_table(jsb.CDo, "CDo (Parasitic Drag)");
    jsb.print_table(jsb.CDtot, "CDtot (CDi + CDo)");
    jsb.print_table(jsb.CDtrefftz, "CDtrefftz (Trefftz Method)");

    std::cout << "FORCES:" << std::endl;
    jsb.print_table(jsb.CFx, "CFx (Drag)");
    jsb.print_table(jsb.CFy, "CFy (Side)");
    jsb.print_table(jsb.CFz, "CFz (Lift)");

    std::cout << "MOMENTS:" << std::endl;
    jsb.print_table(jsb.CMx, "CMx (Roll)");
    jsb.print_table(jsb.CMy, "CMy (Pitch)");
    jsb.print_table(jsb.CMz, "CMz (Yaw)");
}
