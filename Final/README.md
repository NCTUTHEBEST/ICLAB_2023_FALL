## Final Project

期末專題是各位的最後一關了，難度雖然沒有很簡單，但因為這時候只剩期末專題，寫起來應該比既沒有壓力 

通常期末專題都會是設計一顆單核或雙核CPU (雙核我是沒看過，但有聽說某一屆是做雙核)

然後難點就在於，會需要同時用到register、SRAM、DRAM的溝通 (那個delay真的很煩 @@)

這次專題有一個點特別需要注意，就是如果遇到SRAM input在06出現timing violation

回去01把SRAM input都擋一級register就可以避免 (為了改這個，頭超痛.......)

至於performance的話，我個人是完全沒捲，cycle time直接用default XD (OT有打出來就可以躺了，所以OT很重要)

------------------------------------------------------------------------------------

### **心得**

這次期末專題遇到了蠻多狀況

一開始我想切pipeline，結果中途才發現有data hazard的問題 (Spec有寫，我都沒在看 QQ)

寫完design也A完，結果06跳出timing violation

擋一級register因為後面訊號也都要延後一個cycle，也改超久 (但最後還是弄完了，要相信自己 XD)
