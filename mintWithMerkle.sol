// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;
    address private ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    bytes32[] public hashes;

    constructor() ERC721("My721Token", "MTK") {            
        string[4] memory transactions = [
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000"
        ];

        for (uint i = 0; i < transactions.length; i++) {
            hashes.push(keccak256(abi.encodePacked(transactions[i])));
        }

        uint n = transactions.length;
        uint offset = 0;

        while (n > 0) {
            for (uint i = 0; i < n - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(hashes[offset + i], hashes[offset + i + 1])
                    )
                );
            }
            offset += n;
            n = n / 2;
        }
    }

    function getLength() public view returns (uint) {
        return hashes.length;
    }

    //function packArray() public {
    //  for (uint i =0; i < getLength(); i++)
    //    hashes[i] = keccak256(abi.encodePacked(0x0000000000000000000000000000000000000000));
    //}

    function reHash() private {
        for (uint i = 0; i < hashes.length; i++) {
            hashes[i] = (keccak256(abi.encodePacked(hashes[i])));
        }

        uint n = hashes.length;
        uint offset = 0;

        while (n > 0) {
            for (uint i = 0; i < n - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(hashes[offset + i], hashes[offset + i + 1])
                    )
                );
            }
            offset += n;
            n = n / 2;
        }
    }

    function getRoot() public view returns (bytes32) {
        return hashes[hashes.length - 1];
    }

    function packTokenURI(uint256 tokenId) public pure returns (string memory) {

        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "MyToken #', tokenId.toString(), '"',
            '"description": "Token Description"',
            '}'
        );
                    
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
                )
        );        
    }    

    function packLeafData( address to, uint256 tokenId) public view returns(bytes32) {
        string memory currentTokenURI = packTokenURI(tokenId);
        return keccak256(abi.encodePacked(msg.sender, to, tokenId, currentTokenURI));
    }

    function mint(        
        address to
    ) external {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        
        bytes32 leafData = packLeafData(to, newTokenId);
        hashes[newTokenId] = leafData;
        reHash();
    }
}
