// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./TREESTokenConfig.sol";
import "./utils/BokkyPooBahsDateTimeLibrary.sol";

// ----------------------------------------------------------------------------
// TREESToken - TREES Token Contract
//
// Copyright (c) 2021 SAFETREES.
// https://safetrees.space/
//
// ----------------------------------------------------------------------------

contract TREESToken is ERC721,
    TREESTokenConfig,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable {
    using Counters for Counters.Counter;

    uint256 public _challengeEndTime;
    uint256 public _challengeStartTime;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    struct TreeMetadata {
        bytes16 tree_longitue;
        bytes16 tree_latitude;
        uint16 tree_type;
        bytes16 tree_height;
    }

    mapping(uint256 => string) _tokenLinks;

    // read more @ https://github.com/kiecodes/nft/blob/master/contracts/Date.sol
    // https://github.com/abdk-consulting/abdk-libraries-solidity

    constructor(uint endMonths) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        _challengeStartTime = block.timestamp;
        _challengeEndTime = BokkyPooBahsDateTimeLibrary.addMonths(_challengeStartTime, endMonths);

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory tokenLink) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "TREESToken: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 generatedTokenId = _tokenIdTracker.current();
        _mint(to, generatedTokenId);

        // link to the meta data of token ID
        _tokenLinks[generatedTokenId] = tokenLink;

        // increase token id
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "TREESToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "TREESToken: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // TODO
    /**
     * @dev check challenge is completed.
     * read more at: https://medium.com/coinmonks/testing-time-dependent-logic-in-ethereum-smart-contracts-1b24845c7f72
     *
     * check the contract must not be paused, current date is less than expiry date or sold total presale token
     */
    function hasClosed() whenNotPaused public view returns (bool) {
        return false;
    }

    /**
     * @dev return url of token id url meta data
    * Requirements:
     *
     * - `tokenId` must exist.
     *
     */
    function getTokenLink(uint256 tokenId) public view returns (string memory link) {
        require(_exists(tokenId), "TREESToken: operator query for nonexistent token");
        return _tokenLinks[tokenId];
    }
}
