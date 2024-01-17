import math
import random
# ========================================================
# Project:  Lab01 reference code
# File:     Test_data_gen_ref.py
# Author:   Lai Lin-Hung @ Si2 Lab
# Date:     2021.09.15
# ========================================================

# ++++++++++++++++++++ Import Package +++++++++++++++++++++

# ++++++++++++++++++++ Function +++++++++++++++++++++
def compare (my_list) :
    for i in range(0, 6) :
        for j in range(i + 1, 6) :
            if (my_list[i] < my_list[j]) :
                temp = my_list[i]
                my_list[i] = my_list[j]
                my_list[j] = temp
            else :
                my_list[i] = my_list[i]




def gen_test_data(input_file_path,output_file_path):
    # initial File path
    pIFile = open(input_file_path, 'r')
    pOFile = open(output_file_path, 'w')
    
    w = [0] * 6
    vgs = [0] * 6
    vds = [0] * 6
    Id = [0] * 6
    gm = [0] * 6
    #   Set Pattern number 
    # PATTERN_NUM = 10
    # pIFile.write(str(PATTERN_NUM) + "\n")
    # pIFile.write("\n")
    PATTERN_NUM = int(pIFile.read(2))
    for j in range(PATTERN_NUM):
        mode = 0
        out_n = 0
        # Todo: 
        # You can generate test data here
        mode = random.randint(0, 3) 
        i = 0 
        take_mode = 0
        for line in pIFile.readlines() :
            if line == "\n" : 
                continue
            else :
                if take_mode == 0 :
                    mode = int(line)
                    print(mode)
                    take_mode = 1
                    continue
                else :
                    s = line.split(' ')
                    w[i] = int(s[0])
                    vgs[i] = int(s[1])
                    vds[i] = int(s[2])
                    # w[i] = random.randint(1, 7)
                    # vgs[i] = random.randint(1, 7)
                    # vds[i] = random.randint(1, 7)  
                    if ( ((vgs[i] - 1) > vds[i]) ) :
                        Id[i] = math.floor( (w[i] * (2*(vgs[i] - 1)*vds[i] - vds[i] * vds[i])) / 3 )
                        gm[i] = math.floor( (2 * w[i] *vds[i]) / 3 )
                    else :
                        Id[i] = math.floor( (w[i] * (vgs[i] - 1) * (vgs[i] - 1)) / 3 )
                        gm[i] = math.floor( (2 * w[i] * (vgs[i] - 1)) / 3 ) 
                    
                    i = i + 1
                    

            if i == 6 :
                i = 0 
                take_mode = 0
                compare(Id)
                compare(gm)  
                print(Id) 
                if (mode == 0) :
                    out_n = math.floor((gm[3] + gm[4] + gm[5]) / 3)
                elif (mode == 2) :
                    out_n = math.floor((gm[0] + gm[1] + gm[2]) / 3)
                elif (mode == 1) :
                    out_n = math.floor((3 * Id[3] + 4 * Id[4] + 5 * Id[5]) / 12)
                else :
                    out_n = math.floor((3 * Id[0] + 4 * Id[1] + 5 * Id[2]) / 12)

                pOFile.write(f"{out_n}\n")
            else :
                continue


        # print ("Before sorting")
        # print(Id)
        # print(gm)
        # print ("\n")
        # compare(Id)
        # compare(gm)
        # print ("After sorting")
        # print(Id)
        # print(gm)
        # print("\n")

        # if (mode == 0) :
        #     out_n = math.floor((gm[3] + gm[4] + gm[5]) / 3)
        # elif (mode == 1) :
        #     out_n = math.floor((gm[0] + gm[1] + gm[2]) / 3)
        # elif (mode == 2) :
        #     out_n = math.floor((3 * Id[3] + 4 * Id[4] + 5 * Id[5]) / 12)
        # else :
        #     out_n = math.floor((3 * Id[0] + 4 * Id[1] + 5 * Id[2]) / 12)

        # Output file
        # pIFile.write(f"{mode}\n")
        # for i in range(6):
        #     pIFile.write(f"{w[i]} {vgs[i]} {vds[i]}\n")
        # pIFile.write("\n")
        # pOFile.write(f"{out_n}\n")


# ++++++++++++++++++++ main +++++++++++++++++++++
def main():
    gen_test_data("input.txt","output.txt")

if __name__ == '__main__':
    main()