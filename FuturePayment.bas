Function InitializePrivate() Uint64
10  STORE("owner", SIGNER())
20  STORE("balance", 0)
30  STORE("recipient", "") // recipient and height can either be set here or through the SetRecipientAndHeight function
40  STORE("height", 0) // Minimum height the funds can be withdrawn at by the recipient
50  STORE("paymentAccepted", 0)
60  RETURN 0
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

// Owner functions

Function SetRecipientAndHeight(address String, height Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  DIM rawAddress as String
30  LET rawAddress = ADDRESS_RAW(address)

40  IF IS_ADDRESS_VALID(rawAddress) == 1 THEN GOTO 50
41  RETURN 2

50  IF LOAD("paymentAccepted") == 0 THEN GOTO 60
51  RETURN 3

60  STORE("recipient", rawAddress)
70  STORE("height", height)
80  RETURN 0
End Function

// User functions

Function AcceptPayment() Uint64
10  IF ADDRESS_RAW(LOAD("recipient")) == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("paymentAccepted") == 0 THEN GOTO 30
21  RETURN 2

30  STORE("paymentAccepted", 1)
40  RETURN 0
End Function

Function Withdraw(amount Uint64) Uint64
10  IF LOAD("paymentAccepted") == 1 THEN GOTO 20
11  IF LOAD("owner") == SIGNER() THEN GOTO 60 // The owner che withdraw only if the payment has not been accepted by the recipient yet.
12  RETURN 1

20  IF ADDRESS_RAW(LOAD("recipient")) == SIGNER() THEN GOTO 30
21  RETURN 2

30  DIM height as Uint64
40  LET height = LOAD("height")
50  IF height == 0 THEN GOTO 60
51  IF BLOCK_HEIGHT() >= height THEN GOTO 60
52  RETURN 3

60  DIM balance as Uint64
70  LET balance = LOAD("balance")

80  IF amount <= balance THEN GOTO 90
81  RETURN 4

90  SEND_DERO_TO_ADDRESS(SIGNER(), amount)
100  STORE("balance", balance - amount)
110  RETURN 0
End Function

Function Deposit() Uint64 // Does not perform an "owner check" because why not let anyone that wants to send their funds?
10  STORE("balance", LOAD("balance") + DEROVALUE())
20  RETURN 0
End Function
