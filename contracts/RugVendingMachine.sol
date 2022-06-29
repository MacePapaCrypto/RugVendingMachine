// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RugVendingMachine is IERC721Receiver, Ownable {
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
    uint public ftmFee;

    //Constructor - Empty for now
    constructor(
        uint _ftmFee
    ) {
        ftmFee = _ftmFee;
    }

    //External Functions
    /*
    * @dev This function is called by the user to exchange their rugs for one ghostly
    * @params _collection - collection address of NFTs being exchanged
    * @params _tokenIDs - Array of tokenIDs owned by msg.sender
    */
    function takeMyRugs(address _collection, uint[] calldata _tokenIDs) external payable {
        //Error handling
        require(ruggedCollections[_collection] > 0, "Must be an accepted collection");
        //Get length one time here, so _tokenIDs.length isn't called multiple times in the loop
        uint len = _tokenIDs.length;
        require(ghostlyIDsInContract.length >= len, "Not enough ghostlys in contract");
        require(len == ruggedCollections[_collection], "Must submit required number of NFTs from the collection");
        require(msg.value == ftmFee, "Did not pay fee");
        //Loop through the required NFTs to send them to the contract
        for(uint i = 0; i < len; i++) {
            //Transfer the tokens from msg.sender to this.address, i.e. to the contract
            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenIDs[i]);
            //Increment the count mapped to _collection by 1
            balanceOfRuggedNFTs[_collection]++;
        }
        //Send the ghostly that is preloaded into the contract
        IERC721(ghostlyCollectionAddress).safeTransferFrom(address(this), msg.sender, _chooseGhostlyFromContract());
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
            IERC721(ghostlyCollectionAddress).safeTransferFrom(msg.sender, address(this), _tokenIDs[i]);
            //We push the token ID into the array
            //Though its just an array, we are treating it as a stack
            //We will manage the tokenIDs to send based on what is at the top of the stack
            ghostlyIDsInContract.push(_tokenIDs[i]);
        }
    }

    /*
    * @dev Sets the fee amount in ftm per rug exchange
    * @params _amount - ftm value to set the fee to, in wei
    */
    function setFee(uint _amount) external onlyOwner {
        ftmFee = _amount;
    }

    /*
    * @dev Withdraw the token specified by the input token address from the contract to msg.sender
    * @param token - Address of token to withdraw, zero address withdraws native ftm
    */
    function withdrawERC20(address _token) external onlyOwner {
        if(_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        }
        else {
            uint amount = IERC20(_token).balanceOf(address(this));
            require(amount > 0, "Cannot withdraw nothing");
            IERC20(_token).transfer(msg.sender, amount);
        }
    }

    /*
    * @dev Withdraw the ERC721 tokens from the contract to msg.sender
    * @params _collection - collection address of the NFTs to be withdrawn
    * @params _tokenIDs - Array of IDs of the tokens to be withdrawn
    */
    function withdrawERC721(address _collection, uint[] calldata _tokenIDs) external onlyOwner {
        uint len = _tokenIDs.length;
        for(uint i = 0; i < len; i++) {
            IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenIDs[i]);
            balanceOfRuggedNFTs[_collection]--;
        }
    }

    //Make sure we can receive NFTs
    function onERC721Received(address, address, uint256, bytes calldata) public returns(bytes4) {
        return this.onERC721Received.selector;
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