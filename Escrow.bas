Function InitializePrivate() Uint64
10  STORE("owner", SIGNER())
20  STORE("balance", 0)
30  STORE("depositor", "")
40  STORE("beneficiary", "")
50  STORE("agent", "")
60  STORE("agentFee", 100) // Fee in 1/10000 parts, granularity .01%. E.g., 1000 = 10%, 100 = 1%, 50 = 0.5%, 3 = 0.03%.
70  STORE("status", 0) // 0 = Contract unresolved. 1 = Contract fulfilled. 2 = Depositor refunded.
RETURN 0
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

Function TuneEscrowParameters(depositor String, beneficiary String, agent String, agentFee Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("status") == 0 THEN GOTO 30
21  RETURN 2

30  DIM depositorRaw, beneficiaryRaw, agentRaw as String

40  LET depositorRaw = ADDRESS_RAW(depositor)
50  IF IS_ADDRESS_VALID(depositorRaw) == 1 THEN GOTO 60
51  RETURN 3

60  STORE("depositor", depositorRaw)

70  LET beneficiaryRaw = ADDRESS_RAW(beneficiary)
80  IF IS_ADDRESS_VALID(beneficiaryRaw) == 1 THEN GOTO 90
81  RETURN 4

90  STORE("beneficiary", beneficiaryRaw)

100  LET agentRaw = ADDRESS_RAW(agent)
110  IF IS_ADDRESS_VALID(agentRaw) == 1 THEN GOTO 120
111  RETURN 5

120  STORE("agent", agentRaw)

130  IF agentFee <= 10000 THEN GOTO 140
131  RETURN 6

140  STORE("agentFee", agentFee)
150  RETURN 0
End Function

// User functions

Function Deposit() Uint64
10  IF ADDRESS_RAW(LOAD("depositor")) == SIGNER() || LOAD("owner") == SIGNER() THEN GOTO 20
11  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1)
12  RETURN 0

20  IF LOAD("status") == 0 THEN GOTO 30
21  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()-1)
22  RETURN 0

30  STORE("balance", LOAD("balance") + DEROVALUE())
40  RETURN 0
End Function

Function ForfeitAgentFee() Uint64
10  IF ADDRESS_RAW(LOAD("agent")) == SIGNER() THEN GOTO 20
11  RETURN 1

20  STORE("agentFee", 0)
30  RETURN 0
End Function

Function Fulfill() Uint64
10  IF ADDRESS_RAW(LOAD("agent")) == SIGNER() || ADDRESS_RAW(LOAD("depositor")) == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("status") == 0 THEN GOTO 30
21  RETURN 2

30  RETURN sendFunds(1)
End Function

Function RefundDepositor() Uint64
10  IF ADDRESS_RAW(LOAD("agent")) == SIGNER() || ADDRESS_RAW(LOAD("beneficiary")) == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("status") == 0 THEN GOTO 30
21  RETURN 2

30  RETURN sendFunds(2)
End Function

// Private functions

Function sendFunds(recipient Uint64) Uint64 // recipient: 1 = beneficiary, 2 = depositor.
10  DIM balance, agentFee, funds as Uint64
20  LET balance = LOAD("balance")
30  LET agentFee = balance * LOAD("agentFee") / 10000
40  LET funds = balance - agentFee

50  DIM recipientAddress as String

60  IF recipient == 1 || recipient == 2 THEN GOTO 70
61  RETURN 100

70  IF recipient == 1 THEN GOTO 71 ELSE GOTO 80
71  LET recipientAddress = ADDRESS_RAW(LOAD("beneficiary"))

80  IF recipient == 2 THEN GOTO 81 ELSE GOTO 90
81  LET recipientAddress = ADDRESS_RAW(LOAD("depositor"))

90  SEND_DERO_TO_ADDRESS(ADDRESS_RAW(LOAD("agent")), agentFee)
100  SEND_DERO_TO_ADDRESS(recipientAddress, funds-1)
110  STORE("balance", 0)
120  STORE("status", recipient)
130  RETURN 0
End Function
