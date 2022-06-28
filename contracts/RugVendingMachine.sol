// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contract/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contract/token/ERC721/IERC721.sol";

contract RugVendingMachine is IERC721Receiver, IERC721 {
    //Map collection to amount needed for one ghostly
    /*
    * Rugged Collections Accepted At Launch
    * GuitarGirls - 0x2650b24eDaf512CDfc7ba0d077B0467e1Dc53D16 - 3 for 1
    * RoomPixes - 0x32e13161E30acD5CEe7919bA8B07C2543f50f936 - 15 for 1
    * ChubbyCats - 0xa8cfa4f0a588eF547789910369E87e5b9958b173 - 7 for 1
    * CyberPunks - 0x0 - 5 for 1
    */
    mapping(address => uint) public ruggedCollections;
    mapping(address => uint) public balanceOfRuggedNFTs;
    uint[] public ghostlyIDsInContract;
    address public immutable ghostlyCollectionAddress = 0x4EaB37d5C62fa3bff8F7A5FFce6a88cFC098749C;
    

    //Constructor - Empty for now
    constructor(){}

    //External Functions
    /*
    * @dev This function is called by the user to exchange their rugs for one ghostly
    * @params _collection - collection address of NFTs being exchanged
    * @params _tokenIDs - Array of tokenIDs owned by msg.sender
    */
    function takeMyRugs(address _collection, uint[] calldata _tokenIDs) external {
        //Error handling
        require(ruggedCollections[_collection] > 0, "Must be an accepted collection");
        //Get length one time here, so _tokenIDs.length isn't called multiple times in the loop
        uint len = _tokenIDs.length;
        require(ghostlyIDsInContract.length >= len, "Not enough ghostlys in contract");
        require(len == ruggedCollections[_collections], "Must submit required number of NFTs from the collection");
        //Loop through the required NFTs to send them to the contract
        for(uint i = 0; i < len; i++) {
            //Transfer the tokens from msg.sender to this.address, i.e. to the contract
            IERC721(collection).safeTransferFrom(msg.sender, this.address, _tokenIds[i]);
            //Increment the count mapped to _collection by 1
            balanceOfRuggedNFTs[_collection]++;
        }
        //Send the ghostly that is preloaded into the contract
        IERC721(ghostlyCollectionAddress).safeTransferFrom(this.address, msg.sender, _chooseGhostlyFromContract());
    }

    /*
    * @dev Loads up the contract with ghostly NFTs to be dispensed to users
    * @params _tokenIDs - Array of IDs to be sent
    * @note Need to optimize this for at least a few hundred transfers at a time.
    */
    function loadTheGhosts(uint[] calldata _tokenIDs) external onlyOwner {
        uint len = _tokenIDs.length;
        //Probably need to add unchecked here
        for(uint i = 0; i < len; i++) {
            IERC721(ghostlyCollectionAddress).safeTransferFrom(msg.sender, this.address, _tokenIDs[i]);
            //We push the token ID into the array
            //Though its just an array, we are treating it as a stack
            //We will manage the tokenIDs to send based on what is at the top of the stack
            ghostlyIDsInContract.push(_tokenIDs[i]);
        }
    }

    //Make sure we can receive NFTs
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }

    //Internal Functions
    /*
    * @dev takes a tokenID from the known tokenIds owned by the contract
    */
    function _chooseGhostlyFromContract() internal returns (uint) {
        uint len = ghostlyIDsInContract.length;
        //Grab the last tokenID in the array
        uint outID = ghostlyIDsInContract[len-1];
        //Remove the token from the array
        ghostlyIDsInContract.pop();
        return outID;
    }
}