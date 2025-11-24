// simple_assembler_fixed.cpp
// Simple single-file assembler using your CSV opcode table.
// Compile: g++ -std=c++17 simple_assembler_fixed.cpp -O2 -o simple_assembler

#include <bits/stdc++.h>
using namespace std;

/* Embedded CSV (same as before) */
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

/* ------------------ Helpers ------------------ */
static inline string trim(const string &s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == string::npos) return "";
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}
vector<string> split_operands(const string &s) {
    vector<string> out; string cur;
    for (char c : s) {
        if (c == ',') { string t = trim(cur); if (!t.empty()) out.push_back(t); cur.clear(); }
        else cur.push_back(c);
    }
    string t = trim(cur); if (!t.empty()) out.push_back(t);
    return out;
}
bool parse_register(const string &tok, int &regIndex) {
    if (tok.size() >= 2 && (tok[0] == 'r' || tok[0] == 'R')) {
        try { int n = stoi(tok.substr(1)); if (n >= 1 && n <= 8) { regIndex = n - 1; return true; } }
        catch (...) {}
    }
    return false;
}
bool parse_immediate(const string &tok, int32_t &out) {
    string s = tok; if (s.empty()) return false;
    try {
        if (s.size() > 2 && s[0]=='0' && (s[1]=='x' || s[1]=='X')) { out = static_cast<int32_t>(stoul(s, nullptr, 16)); return true; }
        if (s.size() > 2 && s[0]=='0' && (s[1]=='b' || s[1]=='B')) { out = static_cast<int32_t>(stoul(s.substr(2), nullptr, 2)); return true; }
        out = stoi(s, nullptr, 10); return true;
    } catch (...) { return false; }
}

/* ------------------ CSV loader ------------------ */
unordered_map<string, uint16_t> load_opcode_map_from_embedded_csv() {
    unordered_map<string, uint16_t> map;
    istringstream in(OPCODE_CSV);
    string line;
    while (getline(in, line)) {
        string s = trim(line);
        if (s.empty() || s[0] == '#') continue;
        vector<string> toks; string cur;
        for (char c : s) {
            if (c == ',') { toks.push_back(trim(cur)); cur.clear(); } else cur.push_back(c);
        }
        toks.push_back(trim(cur));
        if (toks.size() != 10) continue;
        string mnem = toks[0]; for (auto &c : mnem) c = toupper(c);
        uint16_t code9 = 0;
        for (size_t i = 1; i <= 9; ++i) {
            string bt = toks[i];
            if (!bt.empty() && (bt == "1")) {
                size_t bitIndex = 9 - i; // i=1->8 ... i=9->0
                code9 |= uint16_t(1u << bitIndex);
            }
        }
        map[mnem] = code9 & 0x1FFu;
    }
    return map;
}

/* ------------------ Encoding helper ------------------ */
uint32_t encode_instr(bool has_imm, uint16_t opcode9, int reg1, int reg2, int32_t imm) {
    uint32_t instr = 0;
    if (has_imm) instr |= (1u << 31);
    instr |= (uint32_t(opcode9 & 0x1FFu) << 22);
    uint32_t r1 = (reg1 >= 0 ? uint32_t(reg1 & 0x7) : 0u);
    uint32_t r2 = (reg2 >= 0 ? uint32_t(reg2 & 0x7) : 0u);
    instr |= (r1 << 19);
    instr |= (r2 << 16);
    if (has_imm) { uint16_t immbits = static_cast<uint16_t>(imm & 0xFFFF); instr |= uint32_t(immbits); }
    return instr;
}

/* ------------------ Main loop (fixed buffering) ------------------ */
int main() {
    ios::sync_with_stdio(false);
    // Re-tie cin to cout so prompts flush before input:
    cin.tie(&cout);

    auto opcode_map = load_opcode_map_from_embedded_csv();

    cout << "Simple assembler (single-line). Type an instruction and press enter.\n";
    cout << "Format: MNEMONIC [operand1[,operand2]]\n";
    cout << "Registers: r1..r8  Immediates: 52, -1, 0x34, 0b1101\n";
    cout << "Example: ADD r1,r2   ADD r1,52   INC r3   PD2 58   NOP\n";
    cout << "Ctrl+D (or EOF) to quit.\n\n";

    string line;
    while (true) {
        // Print prompt and flush immediately
        cout << "> " << flush;
        if (!getline(cin, line)) break;
        line = trim(line);
        if (line.empty()) continue;

        // Extract mnemonic and rest
        string mnemonic; string rest;
        {
            istringstream iss(line);
            if (!(iss >> mnemonic)) continue;
            getline(iss, rest);
            rest = trim(rest);
        }
        for (auto &c : mnemonic) c = toupper(c);

        auto it = opcode_map.find(mnemonic);
        if (it == opcode_map.end()) { cerr << "Unknown mnemonic: " << mnemonic << "\n"; continue; }
        uint16_t opcode9 = it->second;

        vector<string> ops = split_operands(rest);
        if (ops.size() > 2) { cerr << "Error: too many operands (max 2)\n"; continue; }

        int reg1 = -1, reg2 = -1; bool has_imm = false; int32_t imm_val = 0; bool parse_error = false;
        for (size_t i = 0; i < ops.size(); ++i) {
            const string &tok = ops[i];
            int r;
            if (parse_register(tok, r)) { if (i == 0) reg1 = r; else reg2 = r; }
            else {
                int32_t v;
                if (!parse_immediate(tok, v)) { cerr << "Error: cannot parse operand '" << tok << "'\n"; parse_error = true; break; }
                has_imm = true; imm_val = v;
            }
        }
        if (parse_error) continue;
        if (has_imm && (imm_val < -32768 || imm_val > 65535)) { cerr << "Error: immediate out of 16-bit range (-32768..65535): " << imm_val << "\n"; continue; }

        uint32_t encoded = encode_instr(has_imm, opcode9, reg1, reg2, imm_val);
        std::ostringstream oss;
        oss << hex << uppercase << setw(8) << setfill('0') << encoded;
        cout << oss.str() << "\n";
    }

    return 0;
}
