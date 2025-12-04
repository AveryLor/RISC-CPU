// simple_assembler_binary.cpp
#include <bits/stdc++.h>
using namespace std;

/* CSV */
static const char *OPCODE_CSV = R"CSV(
NOP,0,0,0,0,0,0,0,0,0
MVW,0,1,1,1,1,X,X,X,X
MVL,0,1,1,0,1,X,X,X,X
MVU,0,1,1,1,0,X,X,X,X
INC,0,1,0,1,1,X,X,X,X
ADD,0,1,0,0,1,X,X,X,X
SUB,0,1,0,1,0,X,X,X,X
MUL,0,1,1,0,0,X,X,X,X
LDW,1,0,0,1,1,X,X,X,X
LDL,1,0,0,0,1,X,X,X,X
LDU,1,0,0,1,0,X,X,X,X
STW,1,0,1,1,1,X,X,X,X
STL,1,0,1,0,1,X,X,X,X
STU,1,0,1,1,0,X,X,X,X
DI1,1,1,0,0,1,0,0,X,X
EN1,1,1,0,1,0,0,0,X,X
PD1,1,1,0,1,1,0,0,X,X
AM1,1,1,1,0,0,0,0,X,X
DH1,1,1,1,0,1,0,0,X,X
DQ1,1,1,1,1,0,0,0,X,X
DE1,1,1,1,1,1,0,0,X,X
DI2,1,1,0,0,1,0,1,X,X
EN2,1,1,0,1,0,0,1,X,X
PD2,1,1,0,1,1,0,1,X,X
AM2,1,1,1,0,0,0,1,X,X
DH2,1,1,1,0,1,0,1,X,X
DQ2,1,1,1,1,0,0,1,X,X
DE2,1,1,1,1,1,0,1,X,X
DI3,1,1,0,0,1,1,0,X,X
EN3,1,1,0,1,0,1,0,X,X
PD3,1,1,0,1,1,1,0,X,X
AM3,1,1,1,0,0,1,0,X,X
DI4,1,1,0,0,1,1,1,X,X
EN4,1,1,0,1,0,1,1,X,X
PD4,1,1,0,1,1,1,1,X,X
AM4,1,1,1,0,0,1,1,X,X
)CSV";

static inline string trim(const string &s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == string::npos) return "";
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b-a+1);
}

vector<string> split_operands(const string &s) {
    vector<string> v; string cur;
    for(char c: s) {
        if(c == ',') { string t = trim(cur); if(!t.empty()) v.push_back(t); cur.clear(); }
        else cur.push_back(c);
    }
    string t = trim(cur);
    if(!t.empty()) v.push_back(t);
    return v;
}

bool parse_register(const string &tok, int &reg) {
    if(tok.size() >= 2 && (tok[0]=='r' || tok[0]=='R')) {
        try {
            int n = stoi(tok.substr(1));
            if(n>=1 && n<=8) { reg = n-1; return true; }
        } catch(...) {}
    }
    return false;
}

bool parse_immediate(const string &tok, int32_t &out) {
    try {
        if(tok.size()>2 && tok[0]=='0' && (tok[1]=='x'||tok[1]=='X'))
            out = static_cast<int32_t>(stoul(tok, nullptr, 16));
        else if(tok.size()>2 && tok[0]=='0' && (tok[1]=='b'||tok[1]=='B'))
            out = static_cast<int32_t>(stoul(tok.substr(2), nullptr, 2));
        else
            out = stoi(tok);
        return true;
    } catch(...) { return false; }
}

unordered_map<string,uint16_t> load_map() {
    unordered_map<string,uint16_t> m;
    istringstream in(OPCODE_CSV);
    string line;
    while(getline(in,line)) {
        line = trim(line);
        if(line.empty() || line[0]=='#') continue;
        vector<string> t; string cur;
        for(char c: line) {
            if(c==',') { t.push_back(trim(cur)); cur.clear(); }
            else cur.push_back(c);
        }
        t.push_back(trim(cur));
        if(t.size()!=10) continue;
        string mn = t[0]; for(char &c:mn) c = toupper(c);
        uint16_t code9=0;
        for(size_t i=1;i<=9;i++)
            if(t[i]=="1") code9 |= (1u << (9-i));
        m[mn] = code9 & 0x1FFu;
    }
    return m;
}

uint32_t encode_instr(bool has_imm, uint16_t opcode9, int r1, int r2, int32_t imm) {
    uint32_t v=0;
    if(has_imm) v |= (1u<<31);
    v |= (uint32_t(opcode9 & 0x1FFu) << 22);
    if(r1>=0) v |= (uint32_t(r1&0x7) << 19);
    if(r2>=0) v |= (uint32_t(r2&0x7) << 16);
    if(has_imm) v |= (uint32_t(imm) & 0xFFFFu);
    return v;
}

string to_binary32(uint32_t x) {
    string s;
    for(int i=31;i>=0;i--) {
        s.push_back((x & (1u<<i)) ? '1':'0');
        
    }
    return s;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(&cout);

    auto map = load_map();

    cout << "Binary Assembler.\n";
    cout << "Example: ADD r1,r2 | INC r3 | ADD r1,52 | NOP\n\n";

    string line;
    while(true) {
        cout << "> " << flush;
        if(!getline(cin,line)) break;
        line = trim(line);
        if(line.empty()) continue;

        string mn, rest;
        { istringstream iss(line); iss >> mn; getline(iss,rest); }
        rest = trim(rest);
        for(char &c:mn) c = toupper(c);

        if(!map.count(mn)) { cerr<<"Unknown mnemonic: "<<mn<<"\n"; continue; }

        auto ops = split_operands(rest);
        if(ops.size()>2) { cerr<<"Too many operands\n"; continue; }

        int r1=-1, r2=-1;
        bool has_imm=false;
        int32_t imm_val=0;
        bool error=false;

        for(size_t i=0;i<ops.size();i++) {
            int tmp;
            if(parse_register(ops[i], tmp)) {
                if(i==0) r1 = tmp;
                else r2 = tmp;
            } else {
                if(!parse_immediate(ops[i], imm_val)) {
                    cerr<<"Bad operand: "<<ops[i]<<"\n"; error=true; break;
                }
                has_imm=true;
            }
        }
        if(error) continue;

        uint32_t code = encode_instr(has_imm, map[mn], r1, r2, imm_val);
        cout << to_binary32(code) << "\n";
    }
}
