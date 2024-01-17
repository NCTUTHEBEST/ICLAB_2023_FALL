`include "../00_TESTBED/bem_dm.sv"
`include "Usertype_BEV.sv"
import usertype::*;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter ING_MAX_VAL = (2**$bits(ING)-1);

//======================================
//      FLOW MANAGER
//======================================
class bemFlowMgr;
    local dramMgr _dramMgr;
    local inputMgr _inputMgr;
    local outputMgr _outputMgr;
    local logging _logger;

    function new(int seed, int zeroIngredientN, int zeroIngredientD);
        this._dramMgr = new(seed, zeroIngredientN, zeroIngredientD);
        this._inputMgr = new(seed);
        this._outputMgr = new();
        this._logger = new("BEM Flow Manager");
    endfunction

    function void initializeDram(bit isRandomize, bit isDump);
        if(isRandomize) this._dramMgr.randomizeDram();
        this._dramMgr.loadDramFromDat();
        if(isDump) this._dramMgr.dumpToFile();
    endfunction

    function void randomizeInput();
        this._inputMgr.randomizeInput();
    endfunction

    function void run();
        Barrel_No _id;
        Bev_Bal _processbox;
        // Get the processed barrel(box)
        _id = this._inputMgr.getInputRandMgr().boxId;
        // this._dramMgr.display(_id);
        _processbox = this._dramMgr.getBoxFromId(_id);
        this._inputMgr.setBox(_processbox);
        // Run action
        if(this._inputMgr.getInputRandMgr().action == Make_drink) this._makeDrink(_processbox, _id);
        else if(this._inputMgr.getInputRandMgr().action == Supply) this._supply(_processbox, _id);
        else if(this._inputMgr.getInputRandMgr().action == Check_Valid_Date) this._checkValidDate(_processbox);
        else begin
            _logger.error($sformatf("This action is not valid. Please check with the PATTERN owner"));
        end
    endfunction

    function void _makeDrink(Bev_Bal _processbox, Barrel_No _id);
        Error_Msg _errMsg;
        logic _complete;
        logic[3:0] _isNoIng = 0;
        inputRandMgr _temp = this._inputMgr.getInputRandMgr();
        logic[9:0] _part = getVolume(_temp.bevSize) /
            (getBlackRatio(_temp.bevType) + getGreenRatio(_temp.bevType) +
            getMilkRatio(_temp.bevType) + getPineappleRatio(_temp.bevType));
        ING _ingBlack = _part*getBlackRatio(_temp.bevType);
        ING _ingGreen = _part*getGreenRatio(_temp.bevType);
        ING _ingMilk  = _part*getMilkRatio(_temp.bevType);
        ING _ingPine  = _part*getPineappleRatio(_temp.bevType);
        _errMsg = No_Err;
        // Check valid date
        if(_temp.date.M > _processbox.M) begin
            _errMsg = No_Exp;
        end
        else if(_temp.date.M === _processbox.M && _temp.date.D > _processbox.D) begin
            _errMsg = No_Exp;
        end
        else begin
            // Black Tea
            if(_processbox.black_tea < _ingBlack) begin
                _isNoIng[0] = 1;
            end
            // Green Tea
            if(_processbox.green_tea < _ingGreen) begin
                _isNoIng[1] = 1;
            end
            // Milk
            if(_processbox.milk < _ingMilk) begin
                _isNoIng[2] = 1;
            end
            // Pineapple
            if(_processbox.pineapple_juice < _ingPine) begin
                _isNoIng[3] = 1;
            end
            if(|_isNoIng) begin
                _errMsg = No_Ing;
            end
            else begin
                _processbox.black_tea = _processbox.black_tea - _ingBlack;
                _processbox.green_tea = _processbox.green_tea - _ingGreen;
                _processbox.milk = _processbox.milk - _ingMilk;
                _processbox.pineapple_juice = _processbox.pineapple_juice - _ingPine;
            end
        end
        // Error message
        if(_errMsg === No_Err) begin
            _complete = 1;
        end
        else begin
            _complete = 0;
        end
        // Output
        this._outputMgr.setGoldOutput(_errMsg, _complete);
        this._outputMgr.setBox(_processbox);
        // Dram
        this._dramMgr.setBoxToDram(_id, _processbox);
    endfunction

    function void _supply(Bev_Bal _processbox, Barrel_No _id);
        Error_Msg _errMsg;
        logic _complete;
        inputRandMgr _temp = this._inputMgr.getInputRandMgr();
        _errMsg = No_Err;
        // Black Tea
        if(_processbox.black_tea + _temp.ingBT > ING_MAX_VAL) begin
            _errMsg = Ing_OF;
            _processbox.black_tea = ING_MAX_VAL;
        end
        else begin
            _processbox.black_tea = _processbox.black_tea + _temp.ingBT;
        end
        // Green Tea
        if(_processbox.green_tea + _temp.ingGT > ING_MAX_VAL) begin
            _errMsg = Ing_OF;
            _processbox.green_tea = ING_MAX_VAL;
        end
        else begin
            _processbox.green_tea = _processbox.green_tea + _temp.ingGT;
        end
        // Milk
        if(_processbox.milk + _temp.ingM > ING_MAX_VAL) begin
            _errMsg = Ing_OF;
            _processbox.milk = ING_MAX_VAL;
        end
        else begin
            _processbox.milk = _processbox.milk + _temp.ingM;
        end
        // Pineapple
        if(_processbox.pineapple_juice + _temp.ingPJ > ING_MAX_VAL) begin
            _errMsg = Ing_OF;
            _processbox.pineapple_juice = ING_MAX_VAL;
        end
        else begin
            _processbox.pineapple_juice = _processbox.pineapple_juice + _temp.ingPJ;
        end
        _processbox.M = _temp.date.M;
        _processbox.D = _temp.date.D;
        // Error message
        if(_errMsg === No_Err) begin
            _complete = 1;
        end
        else begin
            _complete = 0;
        end
        // Output
        this._outputMgr.setGoldOutput(_errMsg, _complete);
        this._outputMgr.setBox(_processbox);
        // Dram
        this._dramMgr.setBoxToDram(_id, _processbox);
    endfunction

    function void _checkValidDate(Bev_Bal _processbox);
        Error_Msg _errMsg;
        logic _complete;
        inputRandMgr _temp = this._inputMgr.getInputRandMgr();
        _errMsg = No_Err;
        _complete = 1;
        if(_temp.date.M > _processbox.M) begin
            _errMsg = No_Exp;
            _complete = 0;
        end
        else if(_temp.date.M === _processbox.M) begin
            if(_temp.date.D > _processbox.D) begin
                _errMsg = No_Exp;
                _complete = 0;
            end
        end
        // Output
        this._outputMgr.setGoldOutput(_errMsg, _complete);
        this._outputMgr.setBox(_processbox);
    endfunction

    function bit isCorrect(Error_Msg _errMsgIn, logic _completeIn);
        this._outputMgr.setYourOutput(_errMsgIn, _completeIn);
        if(!this._outputMgr.isCorrect()) begin
            this.displayInput();
            this.displayOutput();
            this.displayDram();
            return 0;
        end
        return 1;
    endfunction

    function inputMgr getInputMgr();
        return this._inputMgr;
    endfunction

    function outputMgr getOutputMgr();
        return this._outputMgr;
    endfunction

    function void displayInput();
        this._inputMgr.display();
    endfunction

    function void displayOutput();
        this._outputMgr.display();
    endfunction

    function void displayDram();
        this._dramMgr.display(this._inputMgr.getInputRandMgr().boxId);
    endfunction
endclass