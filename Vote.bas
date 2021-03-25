Function InitializePrivate() Uint64
10  STORE("owner", SIGNER())
20  STORE("VOTEPARAM_MinHeight", 0) // Default: 0 is the minimum height.
30  STORE("VOTEPARAM_MaxHeight", 0) // Default: 0 means there is not a maximum height.
40  STORE("VOTEPARAM_MinOption", 0) // Default: 0 is the lowest option value.
50  STORE("VOTEPARAM_MaxOption", 0) // Default: 0 means that the default Uint64 max value is the highest option value.
60  STORE("VOTEPARAM_ParamsSet", 0) // Boolean to make sure params are only set once (using SetVoteParams function) to avoid any kind of tampering of the vote by the owner of the contract.
70  STORE("VOTE_PotentialVotersCount", 0) // Number of addresses that have the right to vote.
80  STORE("VOTE_ActualVotersCount", 0) // Number of addresses that have actually voted.
90  STORE("VOTE_VotesCount", 0)
100  STORE("VOTE_Finished", 0)
110  STORE("VOTE_ForceFinished", 0)
120  STORE("VOTE_FinishedAtHeight", 0)
130  RETURN 0
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

Function SetVoteParams(minHeight Uint64, maxHeight Uint64, minOption Uint64, maxOption Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("VOTE_Finished") == 0 THEN GOTO 30
21  RETURN 2

30  IF LOAD("VOTEPARAM_ParamsSet") == 0 THEN GOTO 40
31  RETURN 3

40  STORE("VOTEPARAM_MinHeight", minHeight)
50  STORE("VOTEPARAM_MaxHeight", maxHeight)
60  STORE("VOTEPARAM_MinOption", minOption)
70  STORE("VOTEPARAM_MaxOption", maxOption)
80  STORE("VOTEPARAM_ParamsSet", 1)
90  RETURN 0
End Function

Function GiveRightToVote(address String) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("VOTE_Finished") == 0 THEN GOTO 30
21  RETURN 2

30  IF IS_ADDRESS_VALID(ADDRESS_RAW(address)) == 1 THEN GOTO 40
31  RETURN 3

40  IF EXISTS(ADDRESS_RAW(address)+"_HasRight") == 0 THEN GOTO 50
41  IF LOAD(ADDRESS_RAW(address)+"_HasRight") == 0 THEN GOTO 50
42  RETURN 4

50  STORE(ADDRESS_RAW(address)+"_HasRight", 1)
60  STORE(ADDRESS_RAW(address)+"_HasVoted", 0)
70  STORE("VOTE_PotentialVotersCount", LOAD("VOTE_PotentialVotersCount") + 1)
80  RETURN 0
End Function

Function RevokeRightToVote(address String) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("VOTE_Finished") == 0 THEN GOTO 30
21  RETURN 2

30  IF IS_ADDRESS_VALID(ADDRESS_RAW(address)) == 1 THEN GOTO 40
31  RETURN 3

40  IF EXISTS(ADDRESS_RAW(address)+"_HasRight") == 1 THEN GOTO 50
41  RETURN 4

50  IF LOAD(ADDRESS_RAW(address)+"_HasRight") == 1 THEN GOTO 60
51  RETURN 5

60  IF LOAD(ADDRESS_RAW(address)+"_HasVoted") == 0 THEN GOTO 70
61  RETURN 6

70  STORE(ADDRESS_RAW(address)+"_HasRight", 0)
80  STORE("VOTE_PotentialVotersCount", LOAD("VOTE_PotentialVotersCount") - 1)
90  RETURN 0
End Function

Function ClosePoll(ignoreHeight Uint64) Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("VOTE_Finished") == 0 THEN GOTO 30
21  RETURN 2

30  DIM maxHeight as Uint64
40  LET maxHeight = LOAD("VOTEPARAM_MaxHeight")
50  IF maxHeight == 0 THEN GOTO 70
51  IF BLOCK_HEIGHT() > maxHeight THEN GOTO 70
52  IF ignoreHeight == 1 THEN GOTO 60
53  RETURN 3

60  STORE("VOTE_ForceFinished", 1)

70  STORE("VOTE_Finished", 1)
80  STORE("VOTE_FinishedAtHeight", BLOCK_HEIGHT())
90  RETURN 0
End Function

// User functions

Function Vote(option Uint64) Uint64
10  IF LOAD("VOTE_Finished") == 0 THEN GOTO 20
11  RETURN 1

20  IF EXISTS(SIGNER()+"_HasRight") == 1 THEN GOTO 30
21  RETURN 2

30  IF LOAD(SIGNER()+"_HasRight") == 1 THEN GOTO 40
31  RETURN 3

40  IF LOAD(SIGNER()+"_HasVoted") == 0 THEN GOTO 50
41  RETURN 4

50  DIM minHeight, maxHeight, minOption, maxOption as Uint64
60  LET minHeight = LOAD("VOTEPARAM_MinHeight")
70  LET maxHeight = LOAD("VOTEPARAM_MaxHeight")
80  LET minOption = LOAD("VOTEPARAM_MinOption")
90  LET maxOption = LOAD("VOTEPARAM_MaxOption")

100  IF option >= minOption THEN GOTO 110
101  RETURN 5

110  IF maxOption == 0 THEN GOTO 120
111  IF option <= maxOption THEN GOTO 120
112  RETURN 6

120  IF BLOCK_HEIGHT() >= minHeight THEN GOTO 130
121  RETURN 7

130  IF maxHeight == 0 THEN GOTO 140
131  IF BLOCK_HEIGHT() <= maxHeight THEN GOTO 140
132  RETURN 8

140  IF EXISTS("VOTE_Option_"+option) == 1 THEN GOTO 150
141  STORE("VOTE_Option_"+option, 0)
150  STORE("VOTE_Option_"+option, LOAD("VOTE_Option_"+option)+1)
160  STORE("VOTE_ActualVotersCount", LOAD("VOTE_ActualVotersCount")+1)
170  STORE("VOTE_VotesCount", LOAD("VOTE_VotesCount")+1)
180  STORE(SIGNER()+"_HasVoted", 1)
190  RETURN 0
End Function
