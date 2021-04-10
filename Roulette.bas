Function InitializePrivate() Uint64
1  STORE("owner", SIGNER())
2  STORE("balance", 0)
3  STORE("minBet", 0)
4  STORE("maxBet", 0) // 0 = No limit
5  STORE("bettingSuspended", 0)

// 1 = Red
10  STORE("1_isRed", 1)
11  STORE("3_isRed", 1)
12  STORE("5_isRed", 1)
13  STORE("7_isRed", 1)
14  STORE("9_isRed", 1)
15  STORE("12_isRed", 1)
16  STORE("14_isRed", 1)
17  STORE("16_isRed", 1)
18  STORE("18_isRed", 1)
19  STORE("19_isRed", 1)
20  STORE("21_isRed", 1)
21  STORE("23_isRed", 1)
22  STORE("25_isRed", 1)
23  STORE("27_isRed", 1)
24  STORE("30_isRed", 1)
25  STORE("32_isRed", 1)
26  STORE("34_isRed", 1)
27  STORE("36_isRed", 1)

// 0 = Black
30  STORE("2_isRed", 0)
31  STORE("4_isRed", 0)
32  STORE("6_isRed", 0)
33  STORE("8_isRed", 0)
34  STORE("10_isRed", 0)
35  STORE("11_isRed", 0)
36  STORE("13_isRed", 0)
37  STORE("15_isRed", 0)
38  STORE("17_isRed", 0)
39  STORE("20_isRed", 0)
40  STORE("22_isRed", 0)
41  STORE("24_isRed", 0)
42  STORE("26_isRed", 0)
43  STORE("28_isRed", 0)
44  STORE("29_isRed", 0)
45  STORE("31_isRed", 0)
46  STORE("33_isRed", 0)
47  STORE("35_isRed", 0)

// 1 = Column 1-34
50  STORE("1_column", 1)
51  STORE("4_column", 1)
52  STORE("7_column", 1)
53  STORE("10_column", 1)
54  STORE("13_column", 1)
55  STORE("16_column", 1)
56  STORE("19_column", 1)
57  STORE("22_column", 1)
58  STORE("25_column", 1)
59  STORE("28_column", 1)
60  STORE("31_column", 1)
61  STORE("34_column", 1)

// 2 = Column 2-35
70  STORE("2_column", 2)
71  STORE("5_column", 2)
72  STORE("8_column", 2)
73  STORE("11_column", 2)
74  STORE("14_column", 2)
75  STORE("17_column", 2)
76  STORE("20_column", 2)
77  STORE("23_column", 2)
78  STORE("26_column", 2)
79  STORE("29_column", 2)
80  STORE("32_column", 2)
81  STORE("35_column", 2)

// 3 = Column 3-36
90  STORE("3_column", 3)
91  STORE("6_column", 3)
92  STORE("9_column", 3)
93  STORE("12_column", 3)
94  STORE("15_column", 3)
95  STORE("18_column", 3)
96  STORE("21_column", 3)
97  STORE("24_column", 3)
98  STORE("27_column", 3)
99  STORE("30_column", 3)
100  STORE("33_column", 3)
101  STORE("36_column", 3)

110 RETURN 0
End Function

// Boilerplate functions

Function TransferOwnership(newOwner String) Uint64 
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF IS_ADDRESS_VALID(ADDRESS_RAW(newOwner)) == 1 THEN GOTO 30
21  RETURN 2

30  STORE("tmpOwner", ADDRESS_RAW(newOwner))
40  RETURN 0
End Function

Function ClaimOwnership() Uint64 
10  IF EXISTS("tmpOwner") == 1 THEN GOTO 20
11  RETURN 1

20  IF LOAD("tmpOwner") == SIGNER() THEN GOTO 30
21  RETURN 2

30  STORE("owner", SIGNER())
40  RETURN 0
End Function

Function UpdateCode(code String) Uint64 
10  IF LOAD("owner") == SIGNER() THEN GOTO 20 
11  RETURN 1

20  UPDATE_SC_CODE(code)
30  RETURN 0
End Function

// Owner functions

Function TuneRouletteParameters(minBet Uint64, maxBet Uint64, suspendBetting Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  STORE("minBet", minBet)
30  STORE("maxBet", maxBet)
40  STORE("bettingSuspended", suspendBetting)
50  RETURN 0
End Function

Function Withdraw(amount Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF amount <= LOAD("balance") THEN GOTO 30
21  RETURN 2

30  SEND_DERO_TO_ADDRESS(SIGNER(), amount)
40  STORE("balance", LOAD("balance") - amount - 1)
50  RETURN 0
End Function

// User functions

Function Bet(number Uint64, amountOnNumber Uint64, amountOnRed Uint64, amountOnBlack Uint64, amountOnEven Uint64, amountOnOdd Uint64, amountOn1to18 Uint64, amountOn19to36 Uint64, amountOn1st12 Uint64, amountOn2nd12 Uint64, amountOn3rd12 Uint64, amountOnColumn1to34 Uint64, amountOnColumn2to35 Uint64, amountOnColumn3to36 Uint64) Uint64
10  IF LOAD("bettingSuspended") == 0 THEN GOTO 20
11  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1)
12  RETURN 0

20  IF DEROVALUE() > LOAD("minBet") THEN GOTO 30
21  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1)
22  RETURN 0

30  IF LOAD("maxBet") == 0 THEN GOTO 40
31  IF DEROVALUE() < LOAD("maxBet") THEN GOTO 40
32  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1)
33  RETURN 0

40  DIM totalAmount, returnAmount, winningNumber, winnings as Uint64
50  LET totalAmount = amountOnNumber + amountOnRed + amountOnBlack + amountOnEven + amountOnOdd + amountOn1to18 + amountOn19to36 + amountOn1st12 + amountOn2nd12 + amountOn3rd12 + amountOnColumn1to34 + amountOnColumn2to35 + amountOnColumn3to36

60  IF DEROVALUE() >= totalAmount THEN GOTO 70
61  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1) // Refund SIGNER since they tried to bet more than they sent to the contract.
62  RETURN 0

70  LET returnAmount = DEROVALUE() - totalAmount // Amount of DERO that was sent to the contract but NOT bet on anything. Will be refunded to the SIGNER regardless of the outcome of the bet.

80  LET winningNumber = RANDOM(37)

90  IF winningNumber != number THEN GOTO 100
91  IF amountOnNumber == 0 THEN GOTO 100
92  LET winnings = winnings + (amountOnNumber*36)
93  IF winningNumber == 0 THEN GOTO 230 // Since the winning number is 0, skip all the other checks (red/black, even/odd etc.)

100  IF LOAD(winningNumber+"_isRed") == 0 THEN GOTO 110
101  IF amountOnRed == 0 THEN GOTO 110
102  LET winnings = winnings + (amountOnRed*2)

110  IF amountOnBlack == 0 THEN GOTO 120
111  LET winnings = winnings + (amountOnBlack*2)

120  IF winningNumber % 2 == 0 THEN GOTO 130
121  IF amountOnOdd == 0 THEN GOTO 130
122  LET winnings = winnings + (amountOnOdd*2)

130  IF amountOnEven == 0 THEN GOTO 140
131  LET winnings = winnings + (amountOnEven*2)

140  IF winningNumber >= 1 && winningNumber <= 18 THEN GOTO 150
141  IF amountOn19to36 == 0 THEN GOTO 150
142  LET winnings = winnings + (amountOn19to36*2)

150  IF amountOn1To18 == 0 THEN GOTO 160
151  LET winnings = winnings + (amountOn1To18*2)

160  IF winningNumber >= 1 && winningNumber <= 12 && amountOn1st12 > 0 THEN GOTO 161 ELSE GOTO 170
161  LET winnings = winnings + (amountOn1st12*3)

170  IF winningNumber >= 13 && winningNumber <= 24 && amountOn2nd12 > 0 THEN GOTO 171 ELSE GOTO 180
171  LET winnings = winnings + (amountOn2nd12*3)

180  IF winningNumber >= 25 && winningNumber <= 36 && amountOn3rd12 > 0 THEN GOTO 181 ELSE GOTO 190
181  LET winnings = winnings + (amountOn3rd12*3)

190  IF LOAD(winningNumber+"_column") == 1 && amountOnColumn1to34 > 0 THEN GOTO 191 ELSE GOTO 200
191  LET winnings = winnings + (amountOnColumn1to34*3)

200  IF LOAD(winningNumber+"_column") == 2 && amountOnColumn2to35 > 0 THEN GOTO 201 ELSE GOTO 210
201  LET winnings = winnings + (amountOnColumn2to35*3)

210  IF LOAD(winningNumber+"_column") == 3 && amountOnColumn3to36 > 0 THEN GOTO 211 ELSE GOTO 220
211  LET winnings = winnings + (amountOnColumn3to36*3)

220  IF winnings > 0 THEN GOTO 230
221  IF returnAmount > 0 THEN GOTO 250 ELSE GOTO 260

230  IF LOAD("balance")+DEROVALUE() > winnings THEN GOTO 240
231  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1) // Refund SIGNER since the contract does not have enough funds to pay out the winnings.
232  RETURN 0

240  STORE("balance", LOAD("balance")+DEROVALUE()-winnings)
250  SEND_DERO_TO_ADDRESS(SIGNER(), winnings+returnAmount)
260  RETURN 0
End Function

Function Deposit() Uint64 // Does not perform an "owner check" in order to allow for donations from regular users.
10  STORE("balance", LOAD("balance") + DEROVALUE())
20  RETURN 0
End Function
