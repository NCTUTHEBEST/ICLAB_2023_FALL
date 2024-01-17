## Low Power Design

第8次Lab難度比Lab7上升了一些 (觀念沒有變難，design的部分比較難)

這次Lab看大助的課程設計，有時候會需要重新打一個新的design，有時候會沿用之前的設計 (我們這屆沿用Lab4)

這次Lab有一個需要注意的spec是，clock gating前後的design，power consumption要下降到一定的%數

這邊推薦一招，把without clock gating的design power弄高一點 (讓本來沒在transition的DFF動起來 XD)

這樣就算有clock gating的design power沒有很小，還是可以達到spec (偷吃步，如果有人真的搞不定可以參考一下)

----------------------------------------------------------------------------------------------

### **心得**

這次Lab我記得搞了好長一段時間，一下子JG很難過，一下子power壓不下來 (痛苦@@)

power的部分就照我上面講的絕對超過50%以上 (身邊的朋友屢試不爽 XD)

至於JG的部分，如果軟體上面把所有的IP都當作black box去檢查其IO，請馬上跟助教反應

因為如果JG去檢查每一個IP的IO的話，上面所講的壓power的方式就沒效了 (但JG確實也不應該都檢查，到時候你們就知道了)

寫完這次Lab之後就開心了，加油加油 (後面超涼 哈哈)


