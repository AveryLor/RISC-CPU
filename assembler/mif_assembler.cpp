#include <bits/stdc++.h>
using namespace std;

// ------------------------ Utility functions ------------------------
string trim(const string &s){
    size_t start = s.find_first_not_of(" \t"); 
    if(start==string::npos) return "";
    size_t end = s.find_last_not_of(" \t");
    return s.substr(start,end-start+1);
}

string strip_comments(const string &s){
    size_t pos = s.find(';'); 
    if(pos==string::npos) return trim(s);
    return trim(s.substr(0,pos));
}

bool parse_register(const string &s,int &reg){
    if(s.size()!=2 || (s[0]!='r' && s[0]!='R')) return false;
    if(s[1]<'1' || s[1]>'8') return false;
    reg = s[1]-'1';
    return true;
}

bool parse_immediate(const string &s,int32_t &val){
    try{
        if(s.size()>2 && s[0]=='0' && s[1]=='x') val = stoi(s,nullptr,16);
        else if(s.size()>2 && s[0]=='0' && s[1]=='b') val = stoi(s.substr(2),nullptr,2);
        else val = stoi(s,nullptr,10);
        return true;
    } catch(...){ return false; }
}

vector<string> split_operands(const string &s){
    vector<string> res; istringstream iss(s); string tok;
    while(getline(iss,tok,',')) res.push_back(trim(tok));
    return res;
}

// ------------------------ Opcode map from CSV ------------------------
map<string,uint16_t> load_opcode_map(){
    map<string,uint16_t> m;
    // Format: NOP,0,0,0,0,0,0,0,0,0 (convert first 9 bits into uint16_t)
    vector<pair<string,string>> csv = {
        {"NOP","000000000"},
        {"MVW","011110000"},
        {"MVL","011010000"},
        {"MVU","011101000"},
        {"INC","010110000"},
        {"ADD","010010000"},
        {"SUB","010100000"},
        {"MUL","011000000"},
        {"LDW","100110000"},
        {"LDL","100010000"},
        {"LDU","100101000"},
        {"STW","101110000"},
        {"STL","101010000"},
        {"STU","101101000"},
        {"DI1","110010000"},
        {"EN1","110100000"},
        {"PD1","110110000"},
        {"AM1","111000000"},
        {"DH1","111010000"},
        {"DQ1","111100000"},
        {"DE1","111110000"},
        {"DI2","110010100"},
        {"EN2","110100010"},
        {"PD2","110110010"},
        {"AM2","111000010"},
        {"DH2","111010010"},
        {"DQ2","111100010"},
        {"DE2","111110010"},
        {"DI3","110011000"},
        {"EN3","110101000"},
        {"PD3","110111000"},
        {"AM3","111001000"},
        {"DI4","110011100"},
        {"EN4","110101100"},
        {"PD4","110111100"},
        {"AM4","111001100"}
    };
    for(auto &[name,bits]:csv){
        uint16_t opcode=0;
        for(int i=0;i<9;i++){
            if(bits[i]=='1') opcode |= (1<<(8-i));
        }
        m[name]=opcode;
    }
    return m;
}

// ------------------------ Encode function ------------------------
uint32_t encode_instr(bool has_imm,uint16_t opcode9,int reg1,int reg2,int32_t imm){
    uint32_t val=0;
    if(has_imm) val |= (1u<<31);
    val |= (uint32_t(opcode9&0x1FF))<<22;
    if(reg1>=0) val |= (reg1&7)<<19;
    if(reg2>=0) val |= (reg2&7)<<16;
    if(has_imm) val |= uint32_t(imm&0xFFFF);
    return val;
}

// ------------------------ Encode line ------------------------
uint32_t encode_line(const string &line, const map<string,uint16_t> &opcode_map){
    string l=line;
    istringstream iss(l); string mnemonic; iss>>mnemonic;
    for(auto &c:mnemonic) c=toupper(c);
    auto it = opcode_map.find(mnemonic);
    if(it==opcode_map.end()){ cerr<<"Unknown mnemonic: "<<mnemonic<<"\n"; exit(1); }
    uint16_t opcode9 = it->second;

    string rest; getline(iss, rest); rest = trim(rest);
    auto ops = split_operands(rest);

    int reg1=-1, reg2=-1; bool has_imm=false; int32_t imm_val=0;
    for(size_t i=0;i<ops.size();i++){
        int r; int32_t v;
        if(parse_register(ops[i],r)){ if(i==0) reg1=r; else reg2=r; }
        else if(parse_immediate(ops[i],v)){ has_imm=true; imm_val=v; }
        else{ cerr<<"Cannot parse operand: "<<ops[i]<<"\n"; exit(1); }
    }
    return encode_instr(has_imm,opcode9,reg1,reg2,imm_val);
}

// ------------------------ MIF writer ------------------------
bool write_mif(const string &outpath, const vector<uint32_t> &mem, const vector<string> &mem_comment) {
    const uint32_t DEPTH = 1u<<16, WIDTH=32;
    ofstream out(outpath); if(!out) return false;

    out<<"DEPTH = "<<DEPTH<<";\nWIDTH = "<<WIDTH<<";\n";
    out<<"ADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\n\nCONTENT BEGIN\n";

    uint32_t addr=0;
    while(addr<DEPTH){
        uint32_t val=mem[addr];
        string comment = (addr<mem_comment.size()) ? mem_comment[addr] : "";

        uint32_t run_start=addr;
        while(addr+1<DEPTH && mem[addr+1]==val && (addr+1>=mem_comment.size() || mem_comment[addr+1].empty())) addr++;
        uint32_t run_end=addr;

        if(run_start==run_end){
            out<<"    "<<hex<<uppercase<<setw(4)<<setfill('0')<<run_start
               <<" : "<<hex<<uppercase<<setw(8)<<setfill('0')<<val<<";";
            if(!comment.empty()){
                int space=36-int(4+3+8); 
                if(space<1) space=1;
                out<<string(space,' ')<<"-- "<<comment;
            }
            out<<"\n";
        } else{
            out<<"    ["<<hex<<uppercase<<setw(4)<<setfill('0')<<run_start
               <<" .. "<<hex<<uppercase<<setw(4)<<setfill('0')<<run_end
               <<"] : "<<hex<<uppercase<<setw(8)<<setfill('0')<<val<<";\n";
        }
        addr++;
    }

    out<<"END;\n";
    return true;
}

// ------------------------ Main ------------------------
int main(int argc, char **argv){
    ios::sync_with_stdio(false); cin.tie(nullptr);
    if(argc!=3){ cerr<<"Usage: "<<argv[0]<<" input.asm output.mif\n"; return 1; }
    string inpath=argv[1], outpath=argv[2];

    auto opcode_map = load_opcode_map();
    ifstream fin(inpath); if(!fin){ cerr<<"Failed to open "<<inpath<<"\n"; return 2; }

    vector<uint32_t> memory(1u<<16,0x00000000);
    vector<string> mem_comment(1u<<16,"");
    size_t current_address=0;
    string rawline; size_t lineno=0;

    while(getline(fin,rawline)){
        ++lineno;
        string line = strip_comments(rawline);
        if(line.empty()) continue;

        string lline = line; transform(lline.begin(), lline.end(), lline.begin(), ::toupper);

        // .ORG
        if(lline.substr(0,4)==".ORG"){
            istringstream iss(line.substr(4)); string addrstr; iss>>addrstr;
            int32_t addr; if(!parse_immediate(addrstr,addr)||addr<0||addr>65535){ cerr<<"Error line "<<lineno<<": invalid .org\n"; return 3; }
            current_address = addr;
            continue;
        }

        // .FILL
        if(lline.substr(0,5)==".FILL"){
            istringstream iss(line.substr(5)); string countstr; iss>>countstr;
            int32_t count; if(!parse_immediate(countstr,count)||count<=0){ cerr<<"Error line "<<lineno<<": invalid .fill count\n"; return 4; }
            string rest; getline(iss,rest); rest=trim(rest);

            uint32_t val;
            if(rest.empty()){ val=0x00000000; } 
            else { val = encode_line(rest, opcode_map); }

            if(current_address+count>65536){ cerr<<"Error line "<<lineno<<": .fill exceeds memory\n"; return 5; }
            for(int i=0;i<count;i++){
                memory[current_address] = val;
                mem_comment[current_address] = rest;
                current_address++;
            }
            continue;
        }

        // regular instruction
        uint32_t val = encode_line(line, opcode_map);
        memory[current_address] = val;
        mem_comment[current_address] = line;
        current_address++;
    }

    if(!write_mif(outpath,memory,mem_comment)){ cerr<<"Failed to write "<<outpath<<"\n"; return 6; }
    cout<<"Wrote "<<outpath<<" (memory filled to 65536 addresses)\n";
    return 0;
}
