// TODO
// inheritance for input/output

`include "Usertype_BEV.sv"
import usertype::*;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter DRAM_OFFSET = 'h10000;
parameter DRAM_SHIFT  = 8;
parameter DRAM_PATH = "../00_TESTBED/DRAM/dram.dat";
parameter BOX_NUM = 256;

// String control
// Should use %0s
string reset_color       = "\033[1;0m";
string txt_black_prefix  = "\033[1;30m";
string txt_red_prefix    = "\033[1;31m";
string txt_green_prefix  = "\033[1;32m";
string txt_yellow_prefix = "\033[1;33m";
string txt_blue_prefix   = "\033[1;34m";

string bkg_black_prefix  = "\033[40;1m";
string bkg_red_prefix    = "\033[41;1m";
string bkg_green_prefix  = "\033[42;1m";
string bkg_yellow_prefix = "\033[43;1m";
string bkg_blue_prefix   = "\033[44;1m";
string bkg_white_prefix  = "\033[47;1m";


//======================================
//      Utility
//======================================
function logic[9:0] getVolume(Bev_Size in);
    if(in===L) return 960;
    if(in===M) return 720;
    if(in===S) return 480;
endfunction

function logic[1:0] getBlackRatio(Bev_Type in);
    if(in===Black_Tea) return 1;
    if(in===Milk_Tea) return 3;
    if(in===Extra_Milk_Tea) return 1;
    if(in===Super_Pineapple_Tea) return 1;
    if(in===Super_Pineapple_Milk_Tea) return 2;
    return 0;
endfunction

function logic[1:0] getGreenRatio(Bev_Type in);
    if(in===Green_Tea) return 1;
    if(in===Green_Milk_Tea) return 1;
    return 0;
endfunction

function logic[1:0] getMilkRatio(Bev_Type in);
    if(in===Milk_Tea) return 1;
    if(in===Extra_Milk_Tea) return 1;
    if(in===Green_Milk_Tea) return 1;
    if(in===Super_Pineapple_Milk_Tea) return 1;
    return 0;
endfunction

function logic[1:0] getPineappleRatio(Bev_Type in);
    if(in===Pineapple_Juice) return 1;
    if(in===Super_Pineapple_Tea) return 1;
    if(in===Super_Pineapple_Milk_Tea) return 1;
    return 0;
endfunction

//======================================
//      Utility
//======================================
class logging;
    function new(string step);
        _step = step;
    endfunction

    function void info(string meesage);
        $display("[Info] %s - %s", this._step, meesage);
    endfunction

    function void error(string meesage);
        $display("[Error] %s - %s", this._step, meesage);
        $finish;
    endfunction
    string _step;
endclass

//======================================
//      DATA MODEL
//======================================
//**************************************
//      Dram Manager
//**************************************
class boxRandMgr;
    function new(int seed);
        this.srandom(seed);
        this._logger = new("Barrel(Box) Random Manager");
    endfunction

    constraint range{
        this.blackTea inside { [0:(2**$bits(ING)-1)] };
        this.greenTea inside { [0:(2**$bits(ING)-1)] };
        this.milk inside { [0:(2**$bits(ING)-1)] };
        this.pineappleJuice inside { [0:(2**$bits(ING)-1)] };
        this.month inside { [1:12] };
        this.day inside {[1:31]};
        if (this.month == 2) {
            this.day inside {[1:28]};
        } else if (this.month==4 || this.month==6 || this.month==9 || this.month==11) {
            this.day inside {[1:30]};
        }
    }

    function void display();
        Bev_Bal out = getBox();
        _logger.info("Info");
        _logger.info($sformatf("%p", out));
    endfunction

    function Bev_Bal getBox();
        Bev_Bal out;
        out.black_tea = this.blackTea;
        out.green_tea = this.greenTea;
        out.milk = this.milk;
        out.pineapple_juice = this.pineappleJuice;
        out.M = this.month;
        out.D = this.day;
        return out;
    endfunction

    local logging _logger;
    local rand ING blackTea;
    local rand ING greenTea;
    local rand ING milk;
    local rand ING pineappleJuice;
    local rand Month month;
    local rand Day day;
endclass

class dramMgr;
    function new(int seed, int zeroIngredientN, int zeroIngredientD);
        _seed = seed;
        _zeroIngredientN = zeroIngredientN;
        _zeroIngredientD = zeroIngredientD;
        this._logger = new("Dram Manager");
    endfunction

    function void randomizeDram();
        boxRandMgr _boxRandMgr = new(_seed);
        Bev_Bal out;
        int file;
        _logger.info("Randomize the DRAM data");
        _logger.info($sformatf("File Path : %s", DRAM_PATH));
        _logger.info($sformatf("Random Seed : %d", this._seed));
        file = $fopen(DRAM_PATH,"w");
        for(int i=0 ; i<BOX_NUM ; i=i+1) begin
            integer addr = DRAM_OFFSET + i*DRAM_SHIFT;
            void'(_boxRandMgr.randomize());
            // _boxRandMgr.display();
            out = _boxRandMgr.getBox();
            if(({$random(this._seed)} % this._zeroIngredientD) < this._zeroIngredientN) begin
                out.milk = 1;
                out.pineapple_juice = 1;
                out.green_tea = 1;
                out.black_tea = 1;
            end
            $fwrite(file, "@%5h\n", addr);
            $fwrite(file, "%2h %2h %2h %2h\n",
                out.D,
                out.pineapple_juice[7:0],
                {out.milk[3:0], out.pineapple_juice[11:8]},
                out.milk[11:4]
            );
			// $fwrite(file, "%2h %2h %2h %2h\n",
                // out.D,
                // 8'd0,
                // 8'd0,
                // 8'd0
            // );
            $fwrite(file, "@%5h\n", addr+4);
            $fwrite(file, "%2h %2h %2h %2h\n",
                out.M,
                out.green_tea[7:0],
                {out.black_tea[3:0], out.green_tea[11:8]},
                out.black_tea[11:4]
            );
			// $fwrite(file, "%2h %2h %2h %2h\n",
                // out.M,
                // 8'd0,
                // 8'd0,
                // 8'd0
            // );
        end
        $fclose(file);
    endfunction

    function void loadDramFromDat();
        $readmemh( DRAM_PATH, golden_DRAM );
    endfunction

    function void setBoxToDram(Barrel_No id, Bev_Bal box);
        {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+7], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+6][7:4]} = box.black_tea;
        {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+6][3:0], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+5]} = box.green_tea;
        {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+3], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+2][7:4]} = box.milk;
        {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+2][3:0], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+1]} = box.pineapple_juice;
        this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+4] = box.M;
        this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT] = box.D;
    endfunction

    function Bev_Bal getBoxFromId(Barrel_No id);
        Bev_Bal out;
        out.black_tea       = {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+7], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+6][7:4]};
        out.green_tea       = {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+6][3:0], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+5]};
        out.milk            = {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+3], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+2][7:4]};
        out.pineapple_juice = {this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+2][3:0], this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+1]};
        out.M = this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT+4];
        out.D = this.golden_DRAM[DRAM_OFFSET+id*DRAM_SHIFT];
        return out;
    endfunction

    function void display(Barrel_No id);
        Bev_Bal out;
        _logger.info($sformatf("%s=====================%s", bkg_yellow_prefix, reset_color));
        _logger.info($sformatf("%s=     Dram Info     =%s", bkg_yellow_prefix, reset_color));
        _logger.info($sformatf("%s=====================%s", bkg_yellow_prefix, reset_color));
        out = getBoxFromId(id);
        _logger.info($sformatf("[Id / Addr] : %3d / @%5h", id, DRAM_OFFSET+id*DRAM_SHIFT));
        _logger.info($sformatf("Black Tea : %4d / %3h", out.black_tea, out.black_tea));
        _logger.info($sformatf("Green Tea : %4d / %3h", out.green_tea, out.green_tea));
        _logger.info($sformatf("Milk : %4d / %3h", out.milk, out.milk));
        _logger.info($sformatf("Pineapple Juice : %4d / %3h", out.pineapple_juice, out.pineapple_juice));
        _logger.info($sformatf("Date\(M/D\) : %2d / %2d", out.M, out.D));
    endfunction

    function void dumpToFile();
        int file;
        Bev_Bal out;
        file = $fopen("dram_check.txt","w");
        for(int i=0 ; i<BOX_NUM ; i=i+1) begin
            out = getBoxFromId(i);
            $fwrite(file, "================================================\n");
            $fwrite(file, "[Id / Addr] : %3d / @%5h\n", i, DRAM_OFFSET+i*DRAM_SHIFT);
            $fwrite(file, "Pineapple Juice : %4d / %3h\n", out.pineapple_juice, out.pineapple_juice);
            $fwrite(file, "Milk : %4d / %3h\n", out.milk, out.milk);
            $fwrite(file, "Green Tea : %4d / %3h\n", out.green_tea, out.green_tea);
            $fwrite(file, "Black Tea : %4d / %3h\n", out.black_tea, out.black_tea);
            $fwrite(file, "Date\(M/D\) : %2d / %2d\n", out.M, out.D);
            $fwrite(file, "================================================\n");
        end
        $fclose(file);
    endfunction

    local logging _logger;
    local logic [7:0] golden_DRAM[ (DRAM_OFFSET+0) : ((DRAM_OFFSET+BOX_NUM*8)-1) ];
    local int _seed;
    local int _zeroIngredientN;
    local int _zeroIngredientD;
endclass

//**************************************
//      Input Manager
//**************************************
class inputRandMgr;
    function new(int seed);
        this.srandom(seed);
        this._logger = new("Input Random Manager");
    endfunction

    constraint range{
        this.action inside { Make_drink, Supply, Check_Valid_Date };
        // this.action inside { Make_drink };
        // this.action inside { Supply };
        // this.action inside { Check_Valid_Date };
        this.bevType inside { Black_Tea, Milk_Tea, Extra_Milk_Tea, 
                Green_Tea, Green_Milk_Tea, Pineapple_Juice,
                Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
        // this.bevType inside { Extra_Milk_Tea };
        this.bevSize inside { L, M, S };
        this.boxId inside { [0:(2**$bits(Barrel_No)-1)] };
        this.ingBT inside { [0:(2**$bits(ING)-1)] };
        this.ingGT inside { [0:(2**$bits(ING)-1)] };
        this.ingM inside { [0:(2**$bits(ING)-1)] };
        this.ingPJ inside { [0:(2**$bits(ING)-1)] };
        this.date.M inside { [1:12] };
        this.date.D inside {[1:31]};
        if (this.date.M == 2) {
            this.date.D inside {[1:28]};
        } else if (this.date.M==4 || this.date.M==6 || this.date.M==9 || this.date.M==11) {
            this.date.D inside {[1:30]};
        }
    }

    function void display();
        _logger.info($sformatf("%s=============================%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("%s=     Random Input Info     =%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("%s=============================%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("Action : %s", this.action.name()));
        _logger.info($sformatf("Beverage type : %s", this.bevType.name()));
        _logger.info($sformatf("Beverage size : %s", this.bevSize.name()));
        _logger.info($sformatf("Date\(M/D\) : %2d/%2d", this.date.M, this.date.D));
        _logger.info($sformatf("Barrel(Box) Id : %d ", this.boxId));
        _logger.info($sformatf("Ingredient Black Tea : %d ", this.ingBT));
        _logger.info($sformatf("Ingredient Green Tea : %d ", this.ingGT));
        _logger.info($sformatf("Ingredient Milk : %d ", this.ingM));
        _logger.info($sformatf("Ingredient Pineapple Juice : %d ", this.ingPJ));
    endfunction

    rand Action action;
    rand Bev_Type bevType;
    rand Bev_Size bevSize;
    rand Date date;
    rand Barrel_No boxId;
    rand ING ingBT;
    rand ING ingGT;
    rand ING ingM;
    rand ING ingPJ;

    local logging _logger;
endclass

class inputMgr;
    function new(int seed);
        this._seed = seed;
        this._inputRandMgr = new(seed);
        this._logger = new("Input Manager");
    endfunction

    function void randomizeInput();
        void'(this._inputRandMgr.randomize());
    endfunction

    function void setBox(Bev_Bal box);
        this._box.black_tea = box.black_tea;
        this._box.green_tea = box.green_tea;
        this._box.milk = box.milk;
        this._box.pineapple_juice = box.pineapple_juice;
        this._box.M = box.M;
        this._box.D = box.D;
    endfunction

    function Bev_Bal getBox();
        return this._box;
    endfunction

    function inputRandMgr getInputRandMgr();
        return this._inputRandMgr;
    endfunction

    function void display();
        // Only for make_drink
        // For sv, it needs to initialize the variable from the beginning of the function
        logic[9:0] _part = getVolume(this._inputRandMgr.bevSize) /
            (getBlackRatio(this._inputRandMgr.bevType) + getGreenRatio(this._inputRandMgr.bevType) +
            getMilkRatio(this._inputRandMgr.bevType) + getPineappleRatio(this._inputRandMgr.bevType));
        ING _ingBlack = _part*getBlackRatio(this._inputRandMgr.bevType);
        ING _ingGreen = _part*getGreenRatio(this._inputRandMgr.bevType);
        ING _ingMilk  = _part*getMilkRatio(this._inputRandMgr.bevType);
        ING _ingPine  = _part*getPineappleRatio(this._inputRandMgr.bevType);

        _logger.info($sformatf("%s======================%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("%s=     Input Info     =%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("%s======================%s", bkg_blue_prefix, reset_color));
        _logger.info($sformatf("Action : %s", this._inputRandMgr.action.name()));
        case(this._inputRandMgr.action)
            Make_drink : begin
                _logger.info($sformatf("Beverage type : %s", this._inputRandMgr.bevType.name()));
                _logger.info($sformatf("Beverage size : %s / (%d)", this._inputRandMgr.bevSize.name(), getVolume(this._inputRandMgr.bevSize)));
                _logger.info($sformatf("Date\(M/D\) : %2d / %2d", this._inputRandMgr.date.M, this._inputRandMgr.date.D));
                _logger.info($sformatf("Barrel(Box) Id : %d ", this._inputRandMgr.boxId));
                _logger.info($sformatf("Ratio & Volume "));
                _logger.info($sformatf("    Black Tea : %d / %d ", getBlackRatio(this._inputRandMgr.bevType), _ingBlack));
                _logger.info($sformatf("    Green Tea : %d / %d ", getGreenRatio(this._inputRandMgr.bevType), _ingGreen));
                _logger.info($sformatf("    Milk : %d / %d", getMilkRatio(this._inputRandMgr.bevType), _ingMilk));
                _logger.info($sformatf("    Pineapple Juice : %d / %d", getPineappleRatio(this._inputRandMgr.bevType), _ingPine));
            end
            Supply : begin
                _logger.info($sformatf("Date\(M/D\) : %2d / %2d", this._inputRandMgr.date.M, this._inputRandMgr.date.D));
                _logger.info($sformatf("Barrel(Box) Id : %d ", this._inputRandMgr.boxId));
                _logger.info($sformatf("Ingredient Black Tea : %d / %h ", this._inputRandMgr.ingBT, this._inputRandMgr.ingBT));
                _logger.info($sformatf("Ingredient Green Tea : %d / %h ", this._inputRandMgr.ingGT, this._inputRandMgr.ingGT));
                _logger.info($sformatf("Ingredient Milk : %d / %h", this._inputRandMgr.ingM, this._inputRandMgr.ingM));
                _logger.info($sformatf("Ingredient Pineapple Juice : %d / %h", this._inputRandMgr.ingPJ, this._inputRandMgr.ingPJ));
            end
            Check_Valid_Date : begin
                _logger.info($sformatf("Date\(M/D\) : %2d / %2d", this._inputRandMgr.date.M, this._inputRandMgr.date.D));
                _logger.info($sformatf("Barrel(Box) Id : %d ", this._inputRandMgr.boxId));
            end
        endcase
        _logger.info($sformatf("%s=======================%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=     (Before)        =%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=     Barrel Info     =%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=======================%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("Date\(M/D\) : %2d / %2d", this._box.M, this._box.D));
        _logger.info($sformatf("Black Tea : %4d / %3h", this._box.black_tea, this._box.black_tea));
        _logger.info($sformatf("Green Tea : %4d / %3h", this._box.green_tea, this._box.green_tea));
        _logger.info($sformatf("Milk : %4d / %3h", this._box.milk, this._box.milk));
        _logger.info($sformatf("Pineapple Juice : %4d / %3h", this._box.pineapple_juice, this._box.pineapple_juice));
    endfunction

    local inputRandMgr _inputRandMgr;
    local logging _logger;
    local Bev_Bal _box;
    local int _seed;
endclass

class outputMgr;
    function new();
        this._logger = new("Output Manager");
        this.reset();
    endfunction

    function void reset();
        _goldComplete = 0;
        _goldErrMsg   = No_Err;
        _yourComplete = 0;
        _yourErrMsg   = No_Err;
    endfunction

    function bit isComplete();
        return _goldComplete;
    endfunction

    function bit isCorrect();
        return (_yourComplete===_goldComplete) && (_yourErrMsg===_goldErrMsg);
    endfunction

    function void setGoldOutput(Error_Msg _errMsgIn, logic _completeIn);
        _goldErrMsg = _errMsgIn;
        _goldComplete = _completeIn;
    endfunction

    function void setYourOutput(Error_Msg _errMsgIn, logic _completeIn);
        _yourErrMsg = _errMsgIn;
        _yourComplete = _completeIn;
    endfunction

    function void setBox(Bev_Bal box);
        this._box.black_tea = box.black_tea;
        this._box.green_tea = box.green_tea;
        this._box.milk = box.milk;
        this._box.pineapple_juice = box.pineapple_juice;
        this._box.M = box.M;
        this._box.D = box.D;
    endfunction

    function Bev_Bal getBox();
        return this._box;
    endfunction

    function void display();
        _logger.info($sformatf("%0s==============================%0s", bkg_red_prefix, reset_color));
        _logger.info($sformatf("%0s=        Output Info         =%0s", bkg_red_prefix, reset_color));
        _logger.info($sformatf("%0s==============================%0s", bkg_red_prefix, reset_color));
        _logger.info($sformatf("       [Complete] | [Err Msg]"));
        _logger.info($sformatf("[Gold] [%8d] | [%7s]", this._goldComplete, this._goldErrMsg.name()));
        _logger.info($sformatf("[Your] [%8d] | [%7s]", this._yourComplete, this._yourErrMsg.name()));
        _logger.info($sformatf("%s=======================%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=     (After)         =%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=     Barrel Info     =%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("%s=======================%s", bkg_green_prefix, reset_color));
        _logger.info($sformatf("Date\(M/D\) : %2d / %2d", this._box.M, this._box.D));
        _logger.info($sformatf("Black Tea : %4d / %3h", this._box.black_tea, this._box.black_tea));
        _logger.info($sformatf("Green Tea : %4d / %3h", this._box.green_tea, this._box.green_tea));
        _logger.info($sformatf("Milk : %4d / %3h", this._box.milk, this._box.milk));
        _logger.info($sformatf("Pineapple Juice : %4d / %3h", this._box.pineapple_juice, this._box.pineapple_juice));
    endfunction

    local logging _logger;
    local Error_Msg _goldErrMsg;
    local Error_Msg _yourErrMsg;
    local logic _goldComplete;
    local logic _yourComplete;
    local Bev_Bal _box;
endclass