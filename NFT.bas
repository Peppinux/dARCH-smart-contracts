Function Initialize() Uint64
10  STORE("name", "My NFT")
20  STORE("description", "Just some test NFT.")
30  STORE("uri", "https://ipfsorwhatever.io/ipfs/etcetcetc")

40  ADD_VALUE(SIGNER(), 100000) // Mint the ONE, unique, token. The five zeros are actually decimals.

// Owners history only keeps tracks of exchanges made through this contract (minting, sale, auction). Can't keep track of prvivate TXs of the token between wallets.
50  STORE("ownersCount", 0)
60  setOwner(SIGNER())

70  STORE("upForSale", 0)
80  STORE("sellingPrice", 0)

90  STORE("auctioned", 0)
100  STORE("reservePrice", 0)
// TODO: Bidding system
110  RETURN 0
End Function

// Private functions

Function setOwner(address String) Uint64
10  DIM rawAddress as String
20  LET rawAddress = ADDRESS_RAW(address)

30  IF IS_ADDRESS_VALID(rawAddress) == 1 THEN GOTO 40
31  RETURN 100

40  STORE("owner", rawAddress)

50  DIM count as Uint64
60  LET count = LOAD("ownersCount") + 1
70  STORE("owner_"+count, rawAddress)
80  STORE("ownersCount", count)
90  RETURN 0
End Function

// Owner functions

Function TransferOwnership(newOwner) Uint64 // Transfer the ownership of the token publicly. Not necessary since tokens can be transferred through wallet TXs.
10  IF TOKENVALUE() > 0 THEN GOTO 12
11  RETURN 1
12  IF TOKENVALUE() == 100000 THEN GOTO 20 // Proves full ownership of the token.
13  ADD_VALUE(SIGNER(), TOKENVALUE()) // If full ownership is not proved, refund.
14  RETURN 2

20  IF LOAD("owner") != ADDRESS_RAW(newOwner) THEN GOTO 30
21  ADD_VALUE(SIGNER(), TOKENVALUE()) // Refund owner
22  RETURN 3 // Can't give ownership to the the current owner (duh)

30  IF setOwner(newOwner) == 0 THEN GOTO 40
31  ADD_VALUE(SIGNER(), TOKENVALUE()) // Refund owner if setOwner returned error
32  RETURN 4

40  ADD_VALUE(ADDRESS_RAW(newOwner), TOKENVALUE()) // Send the token to the new owner
50  RETURN 0
End Function

Function ClaimOwnership() Uint64 // Claim public ownership of the token if it was received privately thorugh a wallet TX. Not necessary, but an option. Needed if a private owner wants to put token up for sale or auction it off.
10  IF TOKENVALUE() > 0 THEN GOTO 12
11  RETURN 1
12  IF TOKENVALUE() == 100000 THEN GOTO 20 // Proves full ownership of the token.
13  ADD_VALUE(SIGNER(), TOKENVALUE()) // If full ownership is not proved, refund.
14  RETURN 2

20  ADD_VALUE(SIGNER(), TOKENVALUE()) // Now that the owner has proved ownership, they can get the token back.

30  IF LOAD("owner") != SIGNER() THEN GOTO 40
31  RETURN 2 // SIGNER is already the current public owner of the token so there is no need to claim ownership.

40  setOwner(SIGNER())
50  RETURN 0
End Function

Function SellToken(price Uint64) Uint64 // Set a fixed price for the token. The first person that buys it (BuyToken function) gets it.
10  IF TOKENVALUE() > 0 THEN GOTO 12
11  RETURN 1
12  IF TOKENVALUE() == 100000 THEN GOTO 20 // Proves full ownership of the token.
13  ADD_VALUE(SIGNER(), TOKENVALUE()) // If full ownership is not proved, refund.
14  RETURN 2

20  IF LOAD("owner") == SIGNER() THEN GOTO 30 // Only the current public owner can put the token up for sale.
21  ADD_VALUE(SIGNER(), TOKENVALUE()) // Refund
22  RETURN 3

30  IF LOAD("upForSale") == 0 && LOAD("auctioned") == 0 THEN GOTO 40 // Token cannot be already up for sale or auctioned.
31  RETURN 4

40  STORE("upForSale", 1)
50  STORE("sellingPrice", price)
60  RETURN 0
End Function

Function CancelSale() Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 1

20  IF LOAD("upForSale") == 1 THEN GOTO 30
21  RETURN 2

30  ADD_VALUE(SIGNER(), 100000) // Give the token back to the owner.
40  STORE("upForSale", 0)
50  STORE("sellingPrice", 0)
60  RETURN 0
End Function

Function AuctionToken() Uint64 // WIP
10  RETURN 0
End Function

Function CancelAuction() Uint64 // WIP
10  RETURN 0
End Function

Function AcceptLastBid() Uint64 // WIP
10  RETURN 0
End Function

// Buyer functions

Function BuyToken() Uint64
10  IF LOAD("owner") != SIGNER() THEN GOTO 20 // Owner can't buy their own token.
11  RETURN 1

20  IF LOAD("upForSale") == 1 THEN GOTO 30
21  RETURN 2

30  IF DEROVALUE() >= LOAD("sellingPrice") THEN GOTO 40
31  SEND_DERO_TO_ADDRESS(SIGNER(), DEROVALUE()) // Refund buyer if funds sent were not sufficient.
32  RETURN 3

40  SEND_DERO_TO_ADDRESS(LOAD("owner"), DEROVALUE()) // Seller gets the DERO.
50  ADD_VALUE(SIGNER(), 100000) // While buyer gets the token.
60  setOwner(SIGNER())
70  RETURN 0
End Function

Function Bid() Uint64 // WIP
10  RETURN 0
End Function
