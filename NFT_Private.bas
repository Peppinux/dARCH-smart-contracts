Function InitializePrivate() Uint64
// NFT Metadata
// This values are constant. In order to avoid tampering, there will be no way to edit them after initialization.
10  STORE("name", "Name goes here")
20  STORE("description", "Description goes here.")
30  STORE("author", "Author goes here")
40  STORE("uri", "https://ipfsorwhatever.io/ipfs/etcetcetc")

// Since anyone can create a contract and write some metadata into it, this variable is an attempt at avoiding counterfeits.
// It is optional and is supposed to be set after the creation of the contract, by using the SetProof function.
// It should link to a proof of creation by the author (e.g., a tweet made by the certified Twitter account of the author in which they state they are selling the NFT and provide the SCID of this contract).
50  STORE("proof", "")

// Send the actual unique token to the creator of the contract.
60  sendNFT(SIGNER())

// Init sales system.
// If you want to put the token up for sale from the get go, replace line 70 with "setSaleValues(SIGNER(), 1, price_goes_here, designated_buyer_or_empty_string_goes_here)"
// and comment out or remove line 60. Failing to do so would result in more than one token in circulation.
// It's not the default option because it doesn't allow SetProof function to be called.
70  setSaleValues("", 0, 0, "")

/*  NOTE:
        While sales happen on-chain, auctions are to be delegated to an off-chain service.
        Although an on-chain auction system could be implemented, like it is in the Public version of this contract, I decided against it in order to:
        - Avoid bloating the blockchain. (For this reason, one could decide to remove the Auction system from the Public version as well)
        - Avoid storing addresses in publicaly viewable variables. (If this isn't an issue, one could decide to implement the Auction system in this Private version as well)
*/

80  RETURN 0
End Function

// Internal functions

// Fixed version of ADDRESS_RAW. Avoids panics when trying to convert an adddress which is already in raw form. Instead, returns the raw address itself. Still panics if the address is actually invalid.
Function addressRaw(address String) String
10  IF IS_ADDRESS_VALID(address) == 1 THEN GOTO 20
11  RETURN ADDRESS_RAW(address)

20  RETURN address
End Function

// Version of SEND_DERO_TO_ADDRESS that subtracts 0.00001 DERO from the amount sent. Needed because the contract won't work without at least 0.00001 DERO inside.
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

// Ownership is proven solely by sending the token to the contract. Since this is the private version of an NFT contract, no trace of ownership is kept through STOREd addresses.
Function isOwner() Uint64
10  IF TOKENVALUE() > 0 THEN GOTO 20 // A fraction of token isn't enough to prove ownership.
11  RETURN 0

20  IF TOKENVALUE() == 100000 THEN GOTO 30
21  ADD_VALUE(SIGNER(), TOKENVALUE()) // If full ownership is not proved, refund.
22  RETURN 0

30  RETURN 1
End Function

Function setSaleValues(seller String, forSale Uint64, sellingPrice Uint64, designatedBuyer String) Uint64
10  STORE("seller", seller) // We are forced to store the address of the seller in order to send them the coins when the token sale happens. If they really care about the privacy of their address, they can create an alt account. Same goes for the designated buyer.
20  STORE("forSale", forSale)
30  STORE("sellingPrice", sellingPrice)

40  IF designatedBuyer != "" THEN GOTO 50
41  STORE("designatedBuyer", "")
42  RETURN 0

50  STORE("designatedBuyer", addressRaw(designatedBuyer))
60  RETURN 0
End Function

// Owner functions

Function SetProof(proof String) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  STORE("proof", proof)
30  RETURN 0
End Function

// Set a fixed price for the token. If designatedBuyer is left empty (""), the first person that buys it (BuyNFT function) gets it. Otherwise, only the designatedBuyer will by able to execute the function.
Function SellNFT(price Uint64, designatedBuyer String) Uint64
10  IF isOwner() == 1 THEN GOTO 20
11  RETURN 0

20  setSaleValues(SIGNER(), 1, price, designatedBuyer)
30  RETURN 0
End Function

Function CancelSale() Uint64
10  IF LOAD("forSale") == 1 THEN GOTO 20
11  RETURN 1

20  IF LOAD("seller") == SIGNER() THEN GOTO 30
21  RETURN 2

30  sendNFT(SIGNER()) // Send token back to the owner.
40  setSaleValues("", 0, 0, "")
50  RETURN 0
End Function

// The Burn function doesn't really need to do anything. Once the NFT is sent to the contract using this function, nobody will own it anymore.
// Therefore, nobody will be able to sell and buy. No new copies will be minted since that only happens at initialization.
Function Burn() Uint64
10  RETURN TOKENVALUE()
End Function

// Buyer functions

Function BuyNFT() Uint64
10  IF LOAD("forSale") == 1 THEN GOTO 20
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund buyer if token isn't for sale.
12  RETURN 0

20  DIM designatedBuyer as String
21  LET designatedBuyer = LOAD("designatedBuyer")

30  IF designatedBuyer == "" || designatedBuyer == SIGNER() THEN GOTO 40
31  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund if buyer wasn't the designated one (if one was set).
32  RETURN 0

40  DIM price as Uint64
41  LET price = LOAD("sellingPrice")

50  IF DEROVALUE() >= price THEN GOTO 60
51  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund buyer if funds sent were not enough.
52  RETURN 0

60  sendDeroToAddress(LOAD("seller"), DEROVALUE())
70  sendNFT(SIGNER())
80  setSaleValues("", 0, 0, "")
90  RETURN 0
End Function
