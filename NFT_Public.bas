Function InitializePrivate() Uint64
// NFT Metadata
// This values are constant. In order to avoid tampering, there will be no way to edit them after initialization.
10  STORE("name", "Name goes here")
20  STORE("description", "Description goes here.")
30  STORE("author", "Author goes here")
40  STORE("uri", "https://ipfsorwhatever.io/ipfs/etcetcetc")

// Since anyone can create a contract and write some metadata into it, this variable is an attempt at avoiding counterfeits.
// It is optional and is supposed to be set after the creation of the contract, by using the SetProof function.
// It should link to a proof of creation by the author (e.g., a tweet made by the certified Twitter account of the author in which they state they are selling the NFT and provide the SCID of this contract)
50  STORE("proof", "")

// Send the actual unique token to the creator of the contract
60  sendNFT(SIGNER())

// Owners history only keeps tracks of exchanges made through this contract (minting, sale, claim).
// Can't keep track of prvivate TXs of the token between wallets.
70  STORE("ownersCount", 0)
80  setPublicOwner(SIGNER(), "MINTING")

// Init sales system.
// If you want to put the token up for sale from the get go, replace line 90 with "setSaleValues(1, price_goes_here, designated_buyer_or_empty_string_goes_here)"
// and comment out or remove lines 60 and 80. Failing to do so would result in more than one token in circulation.
// It's not the default option because it doesn't allow SetProof function to be called.
90  setSaleValues(0, 0, "")

// Init auction system.
// If you want to put the token on auction from the get go, replace line 100 with "setAuctionValues(1, reserve_price_goes_here, 0)"
// and comment out or remove lines 60 and 80. Failing to do so would result in more than one token in circulation.
// It's not the default option because it doesn't allow SetProof function to be called.
100  setAuctionValues(0, 0, 0)
110  RETURN 0
End Function

// Internal functions

// Fixed version of ADDRESS_RAW. Avoids panics when trying to convert an adddress which is already in raw form. Instead, returns the raw address itself. Still panics if the address is actually invalid.
Function addressRaw(address String) String
10  IF IS_ADDRESS_VALID(address) == 1 THEN GOTO 20
11  RETURN ADDRESS_RAW(address)

20  RETURN address
End Function

// Version of SEND_DERO_TO_ADDRESS that keeps 0.00001 DERO from the transaction. Needed because the contract won't work without at least 0.00001 DERO inside.
// In a future where SC TXs on mainnet will require the payment of a fee, this function can be updated to subtract the cost of the fee as well.
Function sendDeroToAddress(address String, amount Uint64) Uint64
10  DIM actualAmount as Uint64
11  LET actualAmount = 0

20  IF amount <= 1 THEN GOTO 50

30  LET actualAmount = amount - 1
40  SEND_DERO_TO_ADDRESS(addressRaw(address), actualAmount)
50  RETURN actualAmount
End Function

Function sendNFT(address String) Uint64
10  ADD_VALUE(addressRaw(address), 100000) // Send ONE token to address. The five zeros are actually decimals.
20  RETURN 0
End Function

Function isOwner() Uint64
10  IF TOKENVALUE() > 0 THEN GOTO 20  // A fraction of token isn't enough to prove ownership.
11  RETURN 0

20  IF TOKENVALUE() == 100000 THEN GOTO 30
21  ADD_VALUE(SIGNER(), TOKENVALUE()) // If full ownership is not proved, refund.
22  RETURN 0

30  RETURN 1
End Function

Function isPublicOwner() Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 0

20  RETURN 1
End Function

Function setPublicOwner(address String, method String) Uint64
10  DIM rawAddress as String
11  LET rawAddress = addressRaw(address)

20  DIM newCount as Uint64
21  LET newCount = LOAD("ownersCount") + 1

30  STORE("owner", rawAddress)
40  STORE("ownersCount", newCount)
50  STORE("OWNER_"+newCount, rawAddress)
60  STORE("OWNER_"+newCount+"_Method", method)
70  RETURN 0
End Function

Function setSaleValues(forSale Uint64, sellingPrice Uint64, designatedBuyer String) Uint64
10  STORE("forSale", forSale)
20  STORE("sellingPrice", sellingPrice)

30  IF designatedBuyer != "" THEN GOTO 40
31  STORE("designatedBuyer", "")
32  RETURN 0

40  STORE("designatedBuyer", addressRaw(designatedBuyer))
50  RETURN 0
End Function

// Owner functions

Function SetProof(proof String) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  IF isPublicOwner() == 1 THEN GOTO 30
21  RETURN 1

30  STORE("proof", proof)
40  RETURN 0
End Function

// Transfer the ownership of the token publicly. Not necessary since tokens can be transferred through wallet TXs.
Function TransferOwnership(newOwner String) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  IF LOAD("owner") != addressRaw(newOwner) THEN GOTO 30
21  sendNFT(SIGNER()) // Can't give ownership to the the current owner (duh). Refund owner.
22  RETURN 0

30  sendNFT(newOwner)
40  setPublicOwner(newOwner, "TRANSFER_PUBLIC")
50  RETURN 0
End Function

// Claim public ownership of the token if it was received privately thorugh a wallet TX. Not necessary, but an option.
// Needed if a private owner wants to put token up for sale.
Function ClaimOwnership() Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  sendNFT(SIGNER()) // Now that the SIGNER has proved ownership, they can get the token back.

30  IF isPublicOwner() == 0 THEN GOTO 40
31  RETURN 0 // SIGNER is already the current public owner of the token so there is no need to claim ownership.

40  setPublicOwner(SIGNER(), "TRANSFER_PRIVATE")
50  RETURN 0
End Function

// Set a fixed price for the token. If designatedBuyer is left empty (""), the first person that buys it (BuyNFT function) gets it. Otherwise, only the designatedBuyer will by able to execute the function.
Function SellNFT(price Uint64, designatedBuyer String) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  IF isPublicOwner() == 1 THEN GOTO 30 // Only the current public owner can put the token up for sale. If they actually own the token but not publically, they need to ClaimOwnership first.
21  sendNFT(SIGNER()) // Refund.
22  RETURN 0

// No need to check if the token is already up for sale or on auction. If it is, the owner simply could not send another one to this function.

40  setSaleValues(1, price, designatedBuyer)
50  RETURN 0
End Function

Function CancelSale() Uint64
10  IF LOAD("forSale") == 1 THEN GOTO 20
11  RETURN 1

20  IF LOAD("owner") == SIGNER() THEN GOTO 30
21  RETURN 2

30  sendNFT(SIGNER()) // Send token back to the owner.
40  setSaleValues(0, 0, "")
50  RETURN 0
End Function

Function Burn() Uint64
10  IF TOKENVALUE() > 0 THEN GOTO 20
11  RETURN 0

20  STORE("owner", "TOKEN_BURNT")
30  RETURN TOKENVALUE()
End Function

Function StartAuction(reservePrice Uint64) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  IF isPublicOwner() == 1 THEN GOTO 30 // Only the current public owner can put the token on auction. If they actually own the token but not publically, they need to ClaimOwnership first.
21  sendNFT(SIGNER()) // Refund.
22  RETURN 0

// No need to check if the token is already up for sale or on auction. If it is, the owner simply could not send another one to this function.

30  setAuctionValues(1, reservePrice, 0)
40  RETURN 0
End Function

Function CancelAuction() Uint64
10  IF LOAD("onAuction") == 1 THEN GOTO 20
11  RETURN 1

20  IF LOAD("owner") == SIGNER() THEN GOTO 30
21  RETURN 2

30  sendNFT(SIGNER()) // Send token back to the owner.
40  setAuctionValues(0, 0, 0)
// Bidders will have to call WithdrawBalance to get the coins they bid back.
50  RETURN 0
End Function

Function AcceptLastBid() Uint64
10  IF LOAD("onAuction") == 1 THEN GOTO 20
11  RETURN 1

20  IF LOAD("owner") == SIGNER() THEN GOTO 30
21  RETURN 2

30  DIM lastBid as Uint64
31  LET lastBid = getLastBid()
32  DIM lastBidder as String
33  LET lastBidder = getLastBidder()

40  sendDeroToAddress(LOAD("owner"), lastBid)
50  setPublicOwner(lastBidder, "AUCTION_"+lastBid)
60  sendNFT(lastBidder)
70  decreaseBalance(lastBidder, lastBid)
80  setAuctionValues(0, 0, 0)
// Losing bidders will have to call WithdrawBalance to get the coins they bid back.
// By calling the same function, winning bidder will get any extra amount he deposited that wasn't needed to cover their bid.
90  RETURN 0
End Function

// Buyer functions

Function BuyNFT() Uint64
10  IF LOAD("forSale") == 1 THEN GOTO 20
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund buyer if token isn't for sale.
12  RETURN 0

20  IF isPublicOwner() == 0 THEN GOTO 30
21  sendDeroToAddress(SIGNER(), DEROVALUE()) // Owner can't buy their own token. Needs to CancelSale instead. Refund owner.
22  RETURN 0

30  DIM designatedBuyer as String
31  LET designatedBuyer = LOAD("designatedBuyer")

40  IF designatedBuyer == "" || designatedBuyer == SIGNER() THEN GOTO 50
41  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund if buyer wasn't the designated one (if one was set).
42  RETURN 0

50  DIM price as Uint64
51  LET price = LOAD("sellingPrice")

60  IF DEROVALUE() >= price THEN GOTO 70
61  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund buyer if funds sent were not enough.
62  RETURN 0

70  sendDeroToAddress(LOAD("owner"), DEROVALUE())
80  sendNFT(SIGNER())
90  setPublicOwner(SIGNER(), "SALE_"+price)
100  setSaleValues(0, 0, "")
110  RETURN 0
End Function

Function Bid(amount Uint64) Uint64
10  IF LOAD("onAuction") == 1 THEN GOTO 20
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund bidder if token isn't on auction.
12  RETURN 0

20  IF isPublicOwner() == 0 THEN GOTO 30
21  sendDeroToAddress(SIGNER(), DEROVALUE()) // Owner can't bid on their own token. Needs to CancelAuction instead. Refund owner.
22  RETURN 0

30  DIM bidderBalance, total as Uint64
31  IF EXISTS(SIGNER()+"_Balance") == 0 THEN GOTO 40
32  LET bidderBalance = LOAD(SIGNER()+"_Balance")
40  LET total = bidderBalance + DEROVALUE()

50  IF total >= amount THEN GOTO 60
51  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund bidder if the amount of coins they sent + their balance already in contract isn't enough to cover the amount they want to bid.
52  RETURN 0

60  IF LOAD("reservePrice") < amount THEN GOTO 70
61  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund bidder if the amount they want to bid is less than the reserve price.
62  RETURN 0

70  IF getLastBid() < amount THEN GOTO 80
71  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund bidder if the amount they want to bid is less than the last, highest bid.
72  RETURN 0

80  IF getLastBidder() != SIGNER() THEN GOTO 90
81  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund bidder if they are already the last, highest bidder.
82  RETURN 0

90  increaseBalance(SIGNER(), DEROVALUE())
100  addBid(amount, SIGNER())
110  RETURN 0
End Function

Function WithdrawBalance() Uint64
10  IF getLastBidder() != SIGNER() THEN GOTO 20
11  RETURN 1 // Can't let the current highest bidder withdraw.

20  DIM amount as Uint64
21  LET amount = getBalance(SIGNER())

30  decreaseBalance(SIGNER(), amount)
40  sendDeroToAddress(SIGNER(), amount)
50  RETURN 0
End Function

// Auction system internal functions

Function setAuctionValues(onAuction Uint64, reservePrice Uint64, bidsCount Uint64) Uint64
10  STORE("onAuction", onAuction)
20  STORE("reservePrice", reservePrice)
30  STORE("bidsCount", bidsCount)
40  RETURN 0
End Function

Function getLastBid() Uint64
10  DIM bidsCount as Uint64
11  LET bidsCount = LOAD("bidsCount")

20  IF bidsCount > 0 THEN GOTO 30
21  RETURN 0

30  RETURN LOAD("BID_"+bidsCount+"_Amount")
End Function

Function addBid(amount Uint64, bidder String) Uint64
10  DIM newCount as Uint64
11  LET newCount = LOAD("bidsCount") + 1

20  STORE("bidsCount", newCount)
30  STORE("BID_"+newCount+"_Amount", amount)
40  STORE("BID_"+newCount+"_Bidder", addressRaw(bidder))
50  RETURN 0
End Function

Function getLastBidder() String
10  DIM bidsCount as Uint64
11  LET bidsCount = LOAD("bidsCount")

20  IF bidsCount > 0 THEN GOTO 30
21  RETURN ""

30  RETURN LOAD("BID_"+bidsCount+"_Bidder")
End Function

Function getBalance(bidder String) Uint64
10  IF EXISTS(addressRaw(bidder)+"_Balance") THEN GOTO 20
11 RETURN 0

20  RETURN LOAD(addressRaw(bidder)+"_Balance")
End Function

Function increaseBalance(bidder String, amount Uint64) Uint64
10  DIM newBalance as Uint64
11  LET newBalance = getBalance(bidder) + amount

20  STORE(addressRaw(bidder)+"_Balance", newBalance)
30  RETURN newBalance
End Function

Function decreaseBalance(bidder String, amount Uint64) Uint64
10  DIM balance, newBalance as Uint64
11  LET balance = getBalance(bidder)

20  IF amount <= balance THEN GOTO 30
21  RETURN balance

30  LET newBalance = balance - amount

40  STORE(addressRaw(bidder)+"_Balance", newBalance)
50  RETURN newBalance
End Function
