// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.10;


// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



contract Proxy {

    struct AddressSlot {
        address value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);


    constructor(address _logic) payable {
        //gas: removed assert
        //assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view returns (address) {
        return getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        //gas: removed require: no funds can be of loss (delegate calls to deposit will fail)
        //require(isContract(newImplementation), "ERC1967: new implementation is not a contract");
        getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface IVault {
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;
  function initialize(address _owner, address registryAddress, address stable, address stakeContract, address interestModule) external;
  function liquidateVault(address liquidationKeeper, address liquidator) external returns (bool);
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface IMainRegistry {
  function addAsset(address, uint256[] memory) external;
  function getTotalValue(
              address[] calldata _assetAddresses, 
              uint256[] calldata _assetIds,
              uint256[] calldata _assetAmounts,
              uint256 numeraire
            ) external view returns (uint256);
  function factoryAddress() external view returns (address);
  function numeraireToInformation(uint256 numeraire) external view returns (uint64, uint64, address, address, address, string memory);
}
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract Factory is ERC721 {
  using Strings for uint256;

  struct vaultVersionInfo {
    address registryAddress;
    address logic;
    address stakeContract;
    address interestModule;
  }

  mapping (address => bool) public isVault;
  mapping (uint256 => vaultVersionInfo) public vaultDetails;

  uint256 public currentVaultVersion;
  bool public factoryInitialised;
  bool public newVaultInfoSet;

  address[] public allVaults;
  mapping(address => uint256) public vaultIndex;

  string public baseURI;

  address public owner;

  address public liquidatorAddress;

  uint256 public numeraireCounter;
  mapping (uint256 => address) public numeraireToStable;

  event VaultCreated(address indexed vaultAddress, address indexed owner, uint256 id);

  modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
  }

  constructor() ERC721("Arcadia Vault", "ARCADIA") {
    owner = msg.sender;
  }

  /** 
    @notice Function returns the total number of vaults
    @return numberOfVaults The total number of vaults 
  */
    function allVaultsLength() external view returns (uint256 numberOfVaults) {
      numberOfVaults = allVaults.length;
    }

  /** 
    @notice Function to set a new contract for the liquidation logic
    @dev Since vaults to be liquidated, together with the open debt, are transferred to the protocol,
         New logic can be set without needing to increment the vault version.
    @param _newLiquidator The new liquidator contract
  */
    function setLiquidator(address _newLiquidator) public onlyOwner {
      liquidatorAddress = _newLiquidator;
    }

  /** 
    @notice Function confirms the new contracts to be used for new deployed vaults
    @dev Two step function to confirm new logic to be used for new deployed vaults.
         Changing any of the contracts does NOT change the contracts for already deployed vaults,
         unless the vault owner explicitly chooses to upgrade their vault version to a newer version
         ToDo Add a time lock between setting a new vault version, and confirming a new vault version
         If no new vault info is being set (newVaultInfoSet is false), this function will not do anything
         The variable factoryInitialised is set to true as soon as one vault version is confirmed
  */
  function confirmNewVaultInfo() public onlyOwner {
    if (newVaultInfoSet) {
      unchecked {++currentVaultVersion;}
      newVaultInfoSet = false;
      if(!factoryInitialised) {
        factoryInitialised = true;
      }
    }
  }

  /** 
    @notice Function to set new contracts to be used for new deployed vaults
    @dev Two step function to confirm new logic to be used for new deployed vaults.
         Changing any of the contracts does NOT change the contracts for already deployed vaults,
         unless the vault owner explicitly choose to upgrade their vault version to a newer version
         ToDo Add a time lock between setting a new vault version, and confirming a new vault version
         Changing any of the logic contracts with this function does NOT immediately take effect,
         only after the function 'confirmNewVaultInfo' is called.
         If a new Main Registry contract is set, all the Numeraires currently stored in the Factory 
         (and the corresponding Stable Contracts) must also be stored in the new Main registry contract.
    @param registryAddress The contract addres of the Main Registry
    @param logic The contract address of the Vault logic
    @param stakeContract The contract addres of the Staking Contract
    @param interestModule The contract address of the Interest Rate Module
  */
  function setNewVaultInfo(address registryAddress, address logic, address stakeContract, address interestModule) external onlyOwner {
    vaultDetails[currentVaultVersion+1].registryAddress = registryAddress;
    vaultDetails[currentVaultVersion+1].logic = logic;
    vaultDetails[currentVaultVersion+1].stakeContract = stakeContract;
    vaultDetails[currentVaultVersion+1].interestModule = interestModule;
    newVaultInfoSet = true;

    //If there is a new Main Registry Contract, Check that numeraires in factory and main registry match
    if (factoryInitialised && vaultDetails[currentVaultVersion].registryAddress != registryAddress) {
      address mainRegistryStableAddress;
      for (uint256 i; i < numeraireCounter;) {
        (,,,,mainRegistryStableAddress,) = IMainRegistry(registryAddress).numeraireToInformation(i);
        require(mainRegistryStableAddress == numeraireToStable[i], "FTRY_SNVI:No match numeraires MR");
        unchecked {++i;}
      }
    }
  }

  /** 
  @notice Function adds numeraire and corresponding stable contract to the factory
  @dev Numeraires can only be added by the latest Main Registry
  @param numeraire An identifier (uint256) of the Numeraire
  @param stable The contract address of the corresponding ERC20 token pegged to the numeraire
  */
  function addNumeraire(uint256 numeraire, address stable) external {
    require(vaultDetails[currentVaultVersion].registryAddress == msg.sender, "FTRY_AN: Add Numeraires via MR");
    numeraireToStable[numeraire] = stable;
    unchecked {++numeraireCounter;}
  }

  /** 
  @notice Returns address of the most recent Main Registry
  @return registry The contract addres of the Main Registry of the latest Vault Version
  */
  function getCurrentRegistry() view external returns (address registry) {
    registry = vaultDetails[currentVaultVersion].registryAddress;
  }

  /** 
  @notice Function used to create a Vault
  @dev This is the starting point of the Vault creation process. 
  @param salt A salt to be used to generate the hash.
  @param numeraire An identifier (uint256) of the Numeraire
  */
  function createVault(uint256 salt, uint256 numeraire) external virtual returns (address vault) {
    require(numeraire <= numeraireCounter - 1, "FTRY_CV: Unknown Numeraire");

    bytes memory initCode = type(Proxy).creationCode;
    bytes memory byteCode = abi.encodePacked(initCode, abi.encode(vaultDetails[currentVaultVersion].logic));

    assembly {
      vault := create2(0, add(byteCode, 32), mload(byteCode), salt)
    }
    IVault(vault).initialize(msg.sender, 
                              vaultDetails[currentVaultVersion].registryAddress, 
                              numeraireToStable[numeraire], 
                              vaultDetails[currentVaultVersion].stakeContract, 
                              vaultDetails[currentVaultVersion].interestModule);
    
    
    allVaults.push(vault);
    isVault[vault] = true;

    _mint(msg.sender, allVaults.length - 1);
    emit VaultCreated(vault, msg.sender, allVaults.length - 1);
  }

  /** 
    @notice Function used to transfer a vault between users
    @dev This method overwrites the safeTransferFrom function in ERC721.sol to also transfer the vault proxy contract to the new owner.
    @param from sender.
    @param to target.
    @param id of the vault that is about to be transfered.
  */
  function safeTransferFrom(address from, address to, uint256 id) override public {
      _safeTransferFrom(from, to, id);
  }

  /** 
    @notice Internal function used to transfer a vault between users
    @dev This function is used to transfer a vault between users.
         Overriding to transfer ownership of linked vault.
    @param from sender.
    @param to target.
    @param id of the vault that is about to be transfered.
  */
  function _safeTransferFrom(address from, address to, uint256 id) internal {
    IVault(allVaults[id]).transferOwnership(to);
    transferFrom(from, to, id);
    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /** 
    @notice Function used by a keeper to start the liquidation of a vualt.
    @dev This function is called by an external user or a bbot to start the liquidation process of a vault.
    @param vault Vault that needs to get liquidated.
  */
  function liquidate(address vault) external {
    _liquidate(vault, msg.sender);
  }

  /** 
    @notice Internal function used to start the liquidation of a vualt.
    @dev 
    @param vault Vault that needs to get liquidated.
    @param sender The msg.sender of the liquidator. Also the 'keeper'
  */
  function _liquidate(address vault, address sender) internal {
    require(IVault(vault).liquidateVault(sender, liquidatorAddress), "FTRY: Vault liquidation failed");
    // Vault version read via Ivault?
    IVault(allVaults[vaultIndex[vault]]).transferOwnership(liquidatorAddress);
    _liquidateTransfer(vault);
  }

  /** 
    @notice Helper transfer function that allows the contract to transfer ownership of the erc721.
    @dev This function is called by the contract when a vault is liquidated. 
         This includes a transfer of ownership of the vault.
         We circumvent the ERC721 transfer function.
    @param vault Vault that needs to get transfered.
  */
  function _liquidateTransfer(address vault) internal {
    address from = ownerOf[vaultIndex[vault]];
    unchecked {
      balanceOf[from]--;
      balanceOf[liquidatorAddress]++;
    }

    ownerOf[vaultIndex[vault]] = liquidatorAddress;

    delete getApproved[vaultIndex[vault]];
    emit Transfer(from, liquidatorAddress, vaultIndex[vault]);
  }

  /** 
    @notice Function that stores a new base URI.
    @dev tokenURI's of Arcadia Vaults are not meant to be immutable
        and might be updated later to allow users to
        choose/create their own vault art,
        as such no URI freeze is added.
    @param newBaseURI the new base URI to store
  */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /** 
    @notice Function that returns the token URI as defined in the erc721 standard.
    @param tokenId The id if the vault
    @return uri The token uri.
  */
  function tokenURI(uint256 tokenId) public view override returns (string memory uri) {

    require(ownerOf[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function onERC721Received(address, address, uint256, bytes calldata ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





interface IVaultPaperTrading is IVault {
  function _stable() external view returns (address);
  function initialize(address _owner, address registryAddress, address stable, address stakeContract, address interestModule, address tokenShop) external;
  function debt() external returns(uint128 _openDebt, uint16 _collThres, uint8 _liqThres, uint64 _yearlyInterestRate, uint32 _lastBlock, uint8 _numeraire);
  function withdraw(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external;
  function deposit(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external;
}

contract FactoryPaperTrading is Factory {
  address tokenShop;

  /** 
    @notice returns contract address of individual vaults
    @param id The id of the Vault
    @return vaultAddress The contract address of the individual vault
  */
  function getVaultAddress(uint256 id) external view returns(address vaultAddress) {
    vaultAddress = allVaults[id];
  }

  /** 
    @notice Function to set a new contract for the tokenshop logic
    @param _tokenShop The new tokenshop contract
  */
  function setTokenShop(address _tokenShop) public onlyOwner {
    tokenShop = _tokenShop;
  }

  /** 
  @notice Function used to create a Vault
  @dev This is the starting point of the Vault creation process. 
  @param salt A salt to be used to generate the hash.
  @param numeraire An identifier (uint256) of the Numeraire
*/
  function createVault(uint256 salt, uint256 numeraire) external override returns (address vault) {
    bytes memory initCode = type(Proxy).creationCode;
    bytes memory byteCode = abi.encodePacked(initCode, abi.encode(vaultDetails[currentVaultVersion].logic));

    assembly {
        vault := create2(0, add(byteCode, 32), mload(byteCode), salt)
    }

    allVaults.push(vault);
    isVault[vault] = true;

    IVaultPaperTrading(vault).initialize(msg.sender, 
                              vaultDetails[currentVaultVersion].registryAddress, 
                              numeraireToStable[numeraire], 
                              vaultDetails[currentVaultVersion].stakeContract, 
                              vaultDetails[currentVaultVersion].interestModule,
                              tokenShop);


    _mint(msg.sender, allVaults.length -1);
    emit VaultCreated(vault, msg.sender, allVaults.length);
  }

}

// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the ΓÇ£SoftwareΓÇ¥), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED ΓÇ£AS ISΓÇ¥, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2╦å7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // e╦å(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2╦å6
    int256 constant a1 = 6235149080811616882910000000; // e╦å(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2╦å5
    int256 constant a2 = 7896296018268069516100000000000000; // e╦å(x2)
    int256 constant x3 = 1600000000000000000000; // 2╦å4
    int256 constant a3 = 888611052050787263676000000; // e╦å(x3)
    int256 constant x4 = 800000000000000000000; // 2╦å3
    int256 constant a4 = 298095798704172827474000; // e╦å(x4)
    int256 constant x5 = 400000000000000000000; // 2╦å2
    int256 constant a5 = 5459815003314423907810; // e╦å(x5)
    int256 constant x6 = 200000000000000000000; // 2╦å1
    int256 constant a6 = 738905609893065022723; // e╦å(x6)
    int256 constant x7 = 100000000000000000000; // 2╦å0
    int256 constant a7 = 271828182845904523536; // e╦å(x7)
    int256 constant x8 = 50000000000000000000; // 2╦å-1
    int256 constant a8 = 164872127070012814685; // e╦å(x8)
    int256 constant x9 = 25000000000000000000; // 2╦å-2
    int256 constant a9 = 128402541668774148407; // e╦å(x9)
    int256 constant x10 = 12500000000000000000; // 2╦å-3
    int256 constant a10 = 113314845306682631683; // e╦å(x10)
    int256 constant x11 = 6250000000000000000; // 2╦å-4
    int256 constant a11 = 106449445891785942956; // e╦å(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

contract mathtest {

    function pow(uint256 base, uint256 power) public pure returns (uint256) {
        return LogExpMath.pow(base, power);
    }
}
interface IERC20 {
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function balanceOf(address) external view returns (uint256);
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}
interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function transferFrom(address from, address to, uint256 id) external;
}
interface IERC1155 {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
  }
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface ILiquidator {
  function startAuction(address vaultAddress, uint256 life, address liquidator, address originalOwner, uint128 openDebt, uint8 liqThres) external returns (bool);
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface IRegistry {
  function batchIsWhiteListed(address[] calldata assetAddresses, uint256[] calldata assetIds) external view returns (bool);
  function getTotalValue(
                  address[] calldata _assetAddresses, 
                  uint256[] calldata _assetIds,
                  uint256[] calldata _assetAmounts,
                  uint256 numeraire
                ) external view returns (uint256);
  function getListOfValuesPerCreditRating(
                  address[] calldata _assetAddresses, 
                  uint256[] calldata _assetIds,
                  uint256[] calldata _assetAmounts,
                  uint256 numeraire
                ) external view returns (uint256[] memory);
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface IRM {
  function getYearlyInterestRate(uint256[] memory ValuesPerCreditRating, uint256 minCollValue) external view returns (uint64);
}


/** 
  * @title An Arcadia Vault used to deposit a combination of all kinds of assets
  * @author Arcadia Finance
  * @notice Users can use this vault to deposit assets (ERC20, ERC721, ERC1155, ...). 
            The vault will denominate all the pooled assets into one numeraire.
            An increase of value of one asset will offset a decrease in value of another asset.
            Users can take out a credit line against the single denominated value.
            Ensure your total value denomination remains above the liquidation threshold, or risk being liquidated!
  * @dev A vault is a smart contract that will contain multiple assets.
         Using getValue(<numeraire>), the vault returns the combined total value of all (whitelisted) assets the vault contains.
         Integrating this vault as means of collateral management for your own protocol that requires collateral is encouraged.
         Arcadia's vault functions will guarantee you a certain value of the vault.
         For whitelists or liquidation strategies specific to your protocol, contact: dev at arcadia.finance
 */ 
contract Vault {

  uint256 public constant yearlyBlocks = 2628000;

  /*///////////////////////////////////////////////////////////////
                INTERNAL BOOKKEEPING OF DEPOSITED ASSETS
  ///////////////////////////////////////////////////////////////*/
  address[] public _erc20Stored;
  address[] public _erc721Stored;
  address[] public _erc1155Stored;

  uint256[] public _erc721TokenIds;
  uint256[] public _erc1155TokenIds;

  /*///////////////////////////////////////////////////////////////
                          EXTERNAL CONTRACTS
  ///////////////////////////////////////////////////////////////*/
  address public _registryAddress; /// to be fetched somewhere else?
  address public _stable;
  address public _stakeContract;
  address public _irmAddress;

  // Each vault has a certain 'life', equal to the amount of times the vault is liquidated.
  // Used by the liquidator contract for proceed claims
  uint256 public life;

  address public owner; 


  bool public initialized;

  struct debtInfo {
    uint128 _openDebt;
    uint16 _collThres; //factor 100
    uint8 _liqThres; //factor 100
    uint64 _yearlyInterestRate; //factor 10**18
    uint32 _lastBlock;
    uint8 _numeraire;
  }

  debtInfo public debt;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // set the vault logic implementation to the msg.sender
  // NOTE: this does not represent the owner of the proxy vault!
  //       The owner of this contract (not the derived proxies) 
  //       should not have any privilages!
  constructor() {
    owner = msg.sender;
  }

    /**
   * @dev Throws if called by any account other than the factory adress.
   */
  modifier onlyFactory() {
    require(msg.sender == IMainRegistry(_registryAddress).factoryAddress(), "Not factory");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                  REDUCED & MODIFIED OPENZEPPELIN OWNABLE
      Reduced to functions needed, while modified to allow
      a transfer of ownership of this vault by a transfer
      of ownership of the accompanying ERC721 Vault NFT
      issued by the factory. Owner of Vault NFT = ower of vault
  ///////////////////////////////////////////////////////////////*/

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyFactory {
    require(newOwner != address(0), "Ownable: caller is not the owner");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /** 
    @notice Initiates the variables of the vault
    @dev A proxy will be used to interact with the vault logic.
         Therefore everything is initialised through an init function.
         This function will only be called (once) in the same transaction as the proxy vault creation through the factory.
         Costly function (156k gas)
    @param _owner The tx.origin: the sender of the 'createVault' on the factory
    @param registryAddress The 'beacon' contract to which should be looked at for external logic.
    @param stable The contract address of the stablecoin of Arcadia Finance
    @param stakeContract The stake contract in which stablecoin can be staked. 
                         Used when syncing debt: interest in stable is minted to stakecontract.
    @param irmAddress The contract address of the InterestRateModule, which calculates the going interest rate
                      for a credit line, based on the underlying assets.
  */
  function initialize(address _owner, address registryAddress, address stable, address stakeContract, address irmAddress) external payable virtual {
    require(initialized == false);
    _registryAddress = registryAddress;
    owner = _owner;
    debt._collThres = 150;
    debt._liqThres = 110;
    _stable = stable;
    _stakeContract = stakeContract;
    _irmAddress = irmAddress;

    initialized = true;
  }

  /** 
    @notice The function used to deposit assets into the proxy vault by the proxy vault owner.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get deposited. If multiple asset IDs of the same contract address
         are deposited, the assetAddress must be repeated in assetAddresses.
         The ERC20 get deposited by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner to avoid attacks where malicous actors can deposit 1 wei assets,
         increasing gas costs upon credit issuance and withrawals.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be deposited one address,
                          even if multiple assets of the same contract address are deposited.
    @param assetIds The asset IDs that will be deposited for ERC721 & ERC1155. 
                    When depositing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be deposited. 
    @param assetTypes The types of the assets to be deposited.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
  function deposit(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external payable virtual onlyOwner {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");
    

    require(IRegistry(_registryAddress).batchIsWhiteListed(assetAddresses, assetIds), "Not all assets are whitelisted!");

    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        _depositERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        _depositERC721(msg.sender, assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        _depositERC1155(msg.sender, assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

  }

  ////////
  function getLengths() public view returns (uint256, uint256, uint256, uint256) {
    return (_erc20Stored.length, _erc721Stored.length, _erc721TokenIds.length, _erc1155Stored.length);
  }

  function returnLists() public view returns (address[] memory, address[] memory, uint256[] memory, address[] memory, uint256[] memory) {
    return (_erc20Stored, _erc721Stored, _erc721TokenIds, _erc1155Stored, _erc1155TokenIds);
  }

  function getValueGas(uint8 numeraire) public view returns (uint256) {
    return getValue(numeraire);
  }

  function viewReq(uint256 amount) public view returns (uint256) {
    return (getValue(debt._numeraire) * 100) / (getOpenDebt() + amount);
  }
  ////////

  /** 
    @notice Internal function used to deposit ERC20 tokens.
    @dev Used for all tokens types = 0. Note the transferFrom, not the safeTransferFrom to allow legacy ERC20s.
         After successful transfer, the function checks whether the same asset has been deposited. 
         This check is done using a loop: writing it in a mapping vs extra loops is in favor of extra loops in this case.
         If the address has not yet been seen, the ERC20 token address is stored.
    @param _from Address the tokens should be taken from. This address must have pre-approved the proxy vault.
    @param ERC20Address The asset address that should be transferred.
    @param amount The amount of ERC20 tokens to be transferred.
  */
  function _depositERC20(address _from, address ERC20Address, uint256 amount) internal {

    require(IERC20(ERC20Address).transferFrom(_from, address(this), amount), "Transfer from failed");

    bool addrSeen;
    uint256 erc20StoredLength = _erc20Stored.length;
    for (uint256 i; i < erc20StoredLength;) {
      if (_erc20Stored[i] == ERC20Address) {
        addrSeen = true;
        break;
      }
      unchecked {++i;}
    }

    if (!addrSeen) {
      _erc20Stored.push(ERC20Address); //TODO: see what the most gas efficient manner is to store/read/loop over this list to avoid duplicates
    }
  }

  /** 
    @notice Internal function used to deposit ERC721 tokens.
    @dev Used for all tokens types = 1. Note the safeTransferFrom. No amounts are given since ERC721 are one-off's.
         After successful transfer, the function pushes the ERC721 address to the stored token and stored ID array.
         This may cause duplicates in the ERC721 stored addresses array, but this is intended. 
    @param _from Address the tokens should be taken from. This address must have pre-approved the proxy vault.
    @param ERC721Address The asset address that should be transferred.
    @param id The ID of the token to be transferred.
  */
  function _depositERC721(address _from, address ERC721Address, uint256 id) internal {
    
    IERC721(ERC721Address).transferFrom(_from, address(this), id);
    
    _erc721Stored.push(ERC721Address); //TODO: see what the most gas efficient manner is to store/read/loop over this list to avoid duplicates
    _erc721TokenIds.push(id);
  }

  /** 
    @notice Internal function used to deposit ERC1155 tokens.
    @dev Used for all tokens types = 2. Note the safeTransferFrom.
         After successful transfer, the function checks whether the combination of address & ID has already been stored.
         If not, the function pushes the new address and ID to the stored arrays.
         This may cause duplicates in the ERC1155 stored addresses array, but this is intended. 
    @param _from TAddress the tokens should be taken from. This address must have pre-approved the proxy vault.
    @param ERC1155Address The asset address that should be transferred.
    @param id The ID of the token to be transferred.
    @param amount The amount of ERC1155 tokens to be transferred.
  */
  function _depositERC1155(address _from, address ERC1155Address, uint256 id, uint256 amount) internal {

      IERC1155(ERC1155Address).safeTransferFrom(_from, address(this), id, amount, "");

      bool addrSeen;

      uint256 erc1155StoredLength = _erc1155Stored.length;
      for (uint256 i; i < erc1155StoredLength;) {
        if (_erc1155Stored[i] == ERC1155Address) {
          if (_erc1155TokenIds[i] == id) {
            addrSeen = true;
            break;
          }
        }
        unchecked {++i;}
      }

      if (!addrSeen) {
        _erc1155Stored.push(ERC1155Address); //TODO: see what the most gas efficient manner is to store/read/loop over this list to avoid duplicates
        _erc1155TokenIds.push(id);
      }
  }

  /** 
    @notice Processes withdrawals of assets by and to the owner of the proxy vault.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get withdrawn. If multiple asset IDs of the same contract address
         are to be withdrawn, the assetAddress must be repeated in assetAddresses.
         The ERC20 get withdrawn by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner.
         Will fail if balance on proxy vault is not sufficient for one of the withdrawals.
         Will fail if "the value after withdrawal / open debt (including unrealised debt) > collateral threshold".
         If no debt is taken yet on this proxy vault, users are free to withraw any asset at any time.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be withdrawn one address,
                          even if multiple assets of the same contract address are withdrawn.
    @param assetIds The asset IDs that will be withdrawn for ERC721 & ERC1155. 
                    When withdrawing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be withdrawn. 
    @param assetTypes The types of the assets to be withdrawn.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
  function withdraw(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external payable virtual onlyOwner {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");

    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        _withdrawERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        _withdrawERC721(msg.sender, assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        _withdrawERC1155(msg.sender, assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

    uint256 openDebt = getOpenDebt();
    if (openDebt != 0) {
      require((getValue(debt._numeraire) * 100 / openDebt) > debt._collThres , "Cannot withdraw since the collateral value would become too low!" );
    }

  }

  /** 
    @notice Internal function used to withdraw ERC20 tokens.
    @dev Used for all tokens types = 0. Note the transferFrom, not the safeTransferFrom to allow legacy ERC20s.
         After successful transfer, the function checks whether the proxy vault has any leftover balance of said asset.
         If not, it will pop() the ERC20 asset address from the stored addresses array.
         Note: this shifts the order of _erc20Stored! 
         This check is done using a loop: writing it in a mapping vs extra loops is in favor of extra loops in this case.
    @param to Address the tokens should be sent to. This will in any case be the proxy vault owner
              either being the original user or the liquidator!.
    @param ERC20Address The asset address that should be transferred.
    @param amount The amount of ERC20 tokens to be transferred.
  */
  function _withdrawERC20(address to, address ERC20Address, uint256 amount) internal {

    require(IERC20(ERC20Address).transfer(to, amount), "Transfer from failed");

    if (IERC20(ERC20Address).balanceOf(address(this)) == 0) {
      uint256 erc20StoredLength = _erc20Stored.length;
      for (uint256 i; i < erc20StoredLength;) {
        if (_erc20Stored[i] == ERC20Address) {
          _erc20Stored[i] = _erc20Stored[erc20StoredLength-1];
          _erc20Stored.pop();
          break;
        }
        unchecked {++i;}
      }
    }
  }

  /** 
    @notice Internal function used to withdraw ERC721 tokens.
    @dev Used for all tokens types = 1. Note the safeTransferFrom. No amounts are given since ERC721 are one-off's.
         After successful transfer, the function checks whether any other ERC721 is deposited in the proxy vault.
         If not, it pops the stored addresses and stored IDs (pop() of two arrs is 180 gas cheaper than deleting).
         If there are, it loops through the stored arrays and searches the ID that's withdrawn, 
         then replaces it with the last index, followed by a pop().
         Sensitive to ReEntrance attacks! SafeTransferFrom therefore done at the end of the function.
    @param to Address the tokens should be taken from. This address must have pre-approved the proxy vault.
    @param ERC721Address The asset address that should be transferred.
    @param id The ID of the token to be transferred.
  */
  function _withdrawERC721(address to, address ERC721Address, uint256 id) internal {

    uint256 tokenIdLength = _erc721TokenIds.length;

    if (tokenIdLength == 1) { // there was only one ERC721 stored on the contract, safe to remove both lists
      _erc721TokenIds.pop();
      _erc721Stored.pop();
    }
    else {
      for (uint256 i; i < tokenIdLength;) {
        if (_erc721TokenIds[i] == id && _erc721Stored[i] == ERC721Address) {
          _erc721TokenIds[i] = _erc721TokenIds[tokenIdLength-1];
          _erc721TokenIds.pop();
          _erc721Stored[i] = _erc721Stored[tokenIdLength-1];
          _erc721Stored.pop();
          break;
        }
        unchecked {++i;}
      }
    }

    IERC721(ERC721Address).safeTransferFrom(address(this), to, id);

  }

  /** 
    @notice Internal function used to withdraw ERC1155 tokens.
    @dev Used for all tokens types = 2. Note the safeTransferFrom.
         After successful transfer, the function checks whether there is any balance left for that ERC1155.
         If there is, it simply transfers the tokens.
         If not, it checks whether it can pop() (used for gas savings vs delete) the stored arrays.
         If there are still other ERC1155's on the contract, it looks for the ID and token address to be withdrawn
         and then replaces it with the last index, followed by a pop().
         Sensitive to ReEntrance attacks! SafeTransferFrom therefore done at the end of the function.
    @param to Address the tokens should be taken from. This address must have pre-approved the proxy vault.
    @param ERC1155Address The asset address that should be transferred.
    @param id The ID of the token to be transferred.
    @param amount The amount of ERC1155 tokens to be transferred.
  */
  function _withdrawERC1155(address to, address ERC1155Address, uint256 id, uint256 amount) internal {

    uint256 tokenIdLength = _erc1155TokenIds.length;
    if (IERC1155(ERC1155Address).balanceOf(address(this), id) - amount == 0) {
      if (tokenIdLength == 1) {
        _erc1155TokenIds.pop();
        _erc1155Stored.pop();
      }
      else {
        for (uint256 i; i < tokenIdLength;) {
          if (_erc1155TokenIds[i] == id) {
            if (_erc1155Stored[i] == ERC1155Address) {
            _erc1155TokenIds[i] = _erc1155TokenIds[tokenIdLength-1];
             _erc1155TokenIds.pop();
            _erc1155Stored[i] = _erc1155Stored[tokenIdLength-1];
            _erc1155Stored.pop();
            break;
            }
          }
          unchecked {++i;}
        }
      }
    }

    IERC1155(ERC1155Address).safeTransferFrom(address(this), to, id, amount, "");
  }

  /** 
    @notice Generates three arrays about the stored assets in the proxy vault
            in the format needed for vault valuation functions.
    @dev No balances are stored on the contract. Both for gas savings upon deposit and to allow for rebasing/... tokens.
         Loops through the stored asset addresses and fills the arrays. 
         The vault valuation function fetches the asset type through the asset registries.
         There is no importance of the order in the arrays, but all indexes of the arrays correspond to the same asset.
    @return assetAddresses An array of asset addresses.
    @return assetIds An array of asset IDs. Will be '0' for ERC20's
    @return assetAmounts An array of the amounts/balances of the asset on the proxy vault. wil be '1' for ERC721's
  */
  function generateAssetData() public view returns (address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) {
    uint256 totalLength;
    unchecked{totalLength = _erc20Stored.length + _erc721Stored.length + _erc1155Stored.length;} //cannot practiaclly overflow. No max(uint256) contracts deployed
    assetAddresses = new address[](totalLength);
    assetIds = new uint256[](totalLength);
    assetAmounts = new uint256[](totalLength);

    uint256 i;
    uint256 erc20StoredLength = _erc20Stored.length;
    address cacheAddr;
    for (; i < erc20StoredLength;) {
      cacheAddr = _erc20Stored[i];
      assetAddresses[i] = cacheAddr;
      //assetIds[i] = 0; //gas: no need to store 0, index will continue anyway
      assetAmounts[i] = IERC20(cacheAddr).balanceOf(address(this));
      unchecked {++i;}
    }

    uint256 j;
    uint256 erc721StoredLength = _erc721Stored.length;
    for (; j < erc721StoredLength;) {
      cacheAddr = _erc721Stored[j];
      assetAddresses[i] = cacheAddr;
      assetIds[i] = _erc721TokenIds[j];
      assetAmounts[i] = 1;
      unchecked {++i;}
      unchecked {++j;}
    }

    uint256 k;
    uint256 erc1155StoredLength = _erc1155Stored.length;
    for (; k < erc1155StoredLength;) {
      cacheAddr = _erc1155Stored[k];
      assetAddresses[i] = cacheAddr;
      assetIds[i] = _erc1155TokenIds[k];
      assetAmounts[i] = IERC1155(cacheAddr).balanceOf(address(this), _erc1155TokenIds[k]);
      unchecked {++i;}
      unchecked {++k;}
    }
  }

  /** 
    @notice Returns the total value of the vault in a specific numeraire (0 = USD, 1 = ETH, more can be added)
    @dev Fetches all stored assets with their amounts on the proxy vault.
         Using a specified numeraire, fetches the value of all assets on the proxy vault in said numeraire.
    @param numeraire Numeraire to return the value in. For example, 0 (USD) or 1 (ETH).
    @return vaultValue Total value stored on the vault, expressed in numeraire.
  */
  function getValue(uint8 numeraire) public view returns (uint256 vaultValue) {
    (address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) = generateAssetData();
    vaultValue = getValueOfAssets(numeraire, assetAddresses, assetIds, assetAmounts);
  }

  /** 
    @notice Returns the total value of the assets provided as input.
    @dev Although mostly an internal function, it's put public such that users/... can estimate the combined value of a series of assets
         without them having to be stored on the vault.
    @param numeraire Numeraire to return the value in. For example, 0 (USD) or 1 (ETH).
    @param assetAddresses A list of all asset addresses. Index in the three arrays are concerning the same asset.
    @param assetIds  A list of all asset IDs. Can be '0' for ERC20s. Index in the three arrays are concerning the same asset.
    @param assetAmounts A list of all amounts. Will be '1' for ERC721's. Index in the three arrays are concerning the same asset.
    @return vaultValue Total value of the given assets, expressed in numeraire.
  */
  function getValueOfAssets(uint8 numeraire, address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) public view returns (uint256 vaultValue) {
    // needs to check whether all assets are actually owned
    // -> not be done twice since this function is called by getValue which already has that check
    // should account for a 'must stop at value x'
    // stop at value x should be done in lower contract
    // extra input: stop value

    vaultValue = IRegistry(_registryAddress).getTotalValue(assetAddresses, assetIds, assetAmounts, numeraire);
  }


  ///////////////
  ///////////////
  ///////////////

  /** 
    @notice Calculates the yearly interest (in 1e18 decimals).
    @dev Based on an array with values per credit rating (tranches) and the minimum collateral value needed for the debt taken,
         returns the yearly interest rate in a 1e18 decimal number.
    @param valuesPerCreditRating An array of values, split per credit rating.
    @param minCollValue The minimum collateral value based on the amount of open debt on the proxy vault.
    @return yearlyInterestRate The yearly interest rate in a 1e18 decimal number.
  */
  function calculateYearlyInterestRate(uint256[] memory valuesPerCreditRating, uint256 minCollValue) public view returns (uint64 yearlyInterestRate) {
    yearlyInterestRate = IRM(_irmAddress).getYearlyInterestRate(valuesPerCreditRating, minCollValue);
  }

  /** 
    @notice Internal function: sets the yearly interest rate (in a 1e18 decimal).
    @param valuesPerCreditRating An array of values, split per credit rating.
    @param minCollValue The minimum collateral value based on the amount of open debt on the proxy vault.
  */
  function _setYearlyInterestRate(uint256[] memory valuesPerCreditRating, uint256 minCollValue) private {
    debt._yearlyInterestRate = calculateYearlyInterestRate(valuesPerCreditRating, minCollValue);
  }

  /** 
    @notice Sets the yearly interest rate of the proxy vault, in the form of a 1e18 decimal number.
    @dev First syncs all debt to realise all unrealised debt. Fetches all the asset data and queries the
         Registry to obtain an array of values, split up according to the credit rating of the underlying assets.
  */
  function setYearlyInterestRate() public {
    syncDebt();
    uint256 minCollValue;
    //gas: can't overflow: uint128 * uint16 << uint256
    unchecked {minCollValue = uint256(debt._openDebt) * debt._collThres / 100;} 
    (address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) = generateAssetData();
    uint256[] memory ValuesPerCreditRating = IRegistry(_registryAddress).getListOfValuesPerCreditRating(assetAddresses, assetIds, assetAmounts, debt._numeraire);

    _setYearlyInterestRate(ValuesPerCreditRating, minCollValue);
  }

  /** 
    @notice Can be called by the proxy vault owner to take out (additional) credit against
            his assets stored on the proxy vault.
    @dev amount to be provided in stablecoin decimals. 
    @param amount The amount of credit to take out, in the form of a pegged stablecoin with 18 decimals.
  */
  function takeCredit(uint128 amount) public onlyOwner {
    (address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) = generateAssetData();
    _takeCredit(amount, assetAddresses, assetIds, assetAmounts);
  }

  // https://twitter.com/0x_beans/status/1502420621250105346
  /** 
    @notice Returns the sum of all uints in an array.
    @param _data An uint256 array.
    @return sum The combined sum of uints in the array.
  */
  function sumElementsOfList(uint[] memory _data) public payable returns (uint sum) {
    //cache
    uint256 len = _data.length;

    for (uint i = 0; i < len;) {
        // optimizooooor
        assembly {
            sum := add(sum, mload(add(add(_data, 0x20), mul(i, 0x20))))
        }

        // iykyk
        unchecked {++i;}
    }
  }
  
  /** 
    @notice Syncs all unrealised debt (= interest) on the proxy vault.
    @dev Public function, can be called by any user to keep the game fair and to allow keeps to
         sync the debt before in case a liquidation can be triggered.
         To Find the unrealised debt over an amount of time, you need to calculate D[(1+r)^x-1].
         The base of the exponential: 1 + r, is a 18 decimals fixed point number
         with r the yearly interest rate.
         The exponent of the exponential: x, is a 18 decimals fixed point number.
         The exponent x is calculated as: the amount of blocks since last sync divided by the average of 
         blocks produced over a year (using a 12s average block time).
         Any debt being realised will be accompanied by a mint of stablecoin of equal amounts.
         Bookkeeping requires total open (realised) debt of the system = totalsupply of stablecoin.
         _yearlyInterestRate = 1 + r expressed as 18 decimals fixed point number
  */
  function syncDebt() public {
    uint128 base;
    uint128 exponent;
    uint128 unRealisedDebt;
    
    unchecked {
      //gas: can't overflow: 1e18 + uint64 <<< uint128
      base = uint128(1e18) + debt._yearlyInterestRate;

      //gas: only overflows when blocks.number > 894262060268226281981748468
      //in practice: assumption that delta of blocks < 341640000 (150 years)
      //as foreseen in LogExpMath lib
      exponent = uint128((block.number - debt._lastBlock) * 1e18 / yearlyBlocks);

      //gas: taking an imaginary worst-case D- tier assets with max interest of 1000%
      //over a period of 5 years
      //this won't overflow as long as opendebt < 3402823669209384912995114146594816
      //which is 3.4 million billion *10**18 decimals

      unRealisedDebt = uint128(debt._openDebt * (LogExpMath.pow(base, exponent) - 1e18) / 1e18);
    }

    //gas: could go unchecked as well, but might result in opendebt = 0 on overflow
    debt._openDebt += unRealisedDebt;
    debt._lastBlock = uint32(block.number);

    if (unRealisedDebt > 0) {
      IERC20(_stable).mint(_stakeContract, unRealisedDebt);
    }
  }

  /** 
    @notice Internal function to take out credit.
    @dev Syncs debt to cement unrealised debt. 
         MinCollValue is calculated without unrealised debt since it is zero.
         Gets the total value of assets per credit rating.
         Calculates and sets the yearly interest rate based on the values per credit rating and the debt to be taken out.
         Mints stablecoin to the vault owner.
  */
  function _takeCredit(
    uint128 amount,
    address[] memory _assetAddresses, 
    uint256[] memory _assetIds,
    uint256[] memory _assetAmounts
  ) private {

    syncDebt();

    uint256 minCollValue;
    //gas: can't overflow: uint129 * uint16 << uint256
    unchecked {minCollValue = uint256((uint256(debt._openDebt) + amount) * debt._collThres) / 100;}

    uint256[] memory valuesPerCreditRating = IRegistry(_registryAddress).getListOfValuesPerCreditRating(_assetAddresses, _assetIds, _assetAmounts, debt._numeraire);
    uint256 vaultValue = sumElementsOfList(valuesPerCreditRating);

    require(vaultValue >= minCollValue, "Cannot take this amount of extra credit!" );

    _setYearlyInterestRate(valuesPerCreditRating, minCollValue);

    //gas: can only overflow when total opendebt is
    //above 340 billion billion *10**18 decimals
    //could go unchecked as well, but might result in opendebt = 0 on overflow
    debt._openDebt += amount;
    IERC20(_stable).mint(owner, amount);
  }

  /** 
    @notice Calculates the total open debt on the proxy vault, including unrealised debt.
    @dev Debt is expressed in an uint128 as the stored debt is an uint128 as well.
         _yearlyInterestRate = 1 + r expressed as 18 decimals fixed point number
    @return openDebt Total open debt, as a uint128.
  */
  function getOpenDebt() public view returns (uint128 openDebt) {
    uint128 base;
    uint128 exponent;
    unchecked {
      //gas: can't overflow as long as interest remains < 1744%/yr
      base = uint128(1e18) + debt._yearlyInterestRate;

      //gas: only overflows when blocks.number > ~10**20
      exponent = uint128((block.number - debt._lastBlock) * 1e18 / yearlyBlocks);
    }

    //with sensible blocks, can return an open debt up to 3e38 units
    //gas: could go unchecked as well, but might result in opendebt = 0 on overflow
    openDebt = uint128(debt._openDebt * LogExpMath.pow(base, exponent) / 1e18); 
  }

  /** 
    @notice Calculates the remaining credit the owner of the proxy vault can take out.
    @dev Returns the remaining credit in the numeraire in which the proxy vault is initialised.
    @return remainingCredit The remaining amount of credit a user can take, 
                            returned in the decimals of the stablecoin.
  */
  function getRemainingCredit() public view returns (uint256 remainingCredit) {
    uint256 currentValue = getValue(debt._numeraire);
    uint256 openDebt = getOpenDebt();

    uint256 maxAllowedCredit;
    //gas: cannot overflow unless currentValue is more than
    // 1.15**57 *10**18 decimals, which is too many billions to write out
    unchecked {maxAllowedCredit = (currentValue * 100) / debt._collThres;}

    //gas: explicit check is done to prevent underflow
    unchecked {remainingCredit = maxAllowedCredit > openDebt ? maxAllowedCredit - openDebt : 0;}
  }

  /** 
    @notice Function used by owner of the proxy vault to repay any open debt.
    @dev Amount of debt to repay in same decimals as the stablecoin decimals.
         Amount given can be greater than open debt. Will only transfer the required
         amount from the user's balance.
    @param amount Amount of debt to repay.
  */
  function repayDebt(uint256 amount) public onlyOwner {
    syncDebt();

    // if a user wants to pay more than their open debt
    // we should only take the amount that's needed
    // prevents refunds etc
    uint256 openDebt = debt._openDebt;
    uint256 transferAmount = openDebt > amount ? amount : openDebt;
    require(IERC20(_stable).transferFrom(msg.sender, address(this), transferAmount), "Transfer from failed");

    IERC20(_stable).burn(transferAmount);

    //gas: transferAmount cannot be larger than debt._openDebt,
    //which is a uint128, thus can't underflow
    assert(openDebt >= transferAmount);
    unchecked {debt._openDebt -= uint128(transferAmount);}

    // if interest is calculated on a fixed rate, set interest to zero if opendebt is zero
    // todo: can be removed safely?
    if (getOpenDebt() == 0) {
      debt._yearlyInterestRate = 0;
    }

  }

  /** 
    @notice Function called to start a vault liquidation.
    @dev Requires an unhealthy vault (value / debt < liqThres).
         Starts the vault auction on the liquidator contract.
         Increases the life of the vault to indicate a liquidation has happened.
         Sets debtInfo todo: needed?
         Transfers ownership of the proxy vault to the liquidator!
  */
  function liquidateVault(address liquidationKeeper, address liquidator) public onlyFactory returns (bool success) {
    //gas: 35 gas cheaper to not take debt into memory
    uint256 totalValue = getValue(debt._numeraire);
    uint256 leftHand;
    uint256 rightHand;

    unchecked {
      //gas: cannot overflow unless totalValue is
      //higher than 1.15 * 10**57 * 10**18 decimals
      leftHand = totalValue * 100;
      //gas: cannot overflow: uint8 * uint128 << uint256
      rightHand = uint256(debt._liqThres) * uint256(debt._openDebt); //yes, double cast is cheaper than no cast (and equal to one cast)
    }

    require(leftHand < rightHand, "This vault is healthy");

    
    require(ILiquidator(liquidator).startAuction(address(this), life, liquidationKeeper, owner, debt._openDebt, debt._liqThres), "Failed to start auction!");

    //gas: good luck overflowing this
    unchecked {++life;}

    debt._openDebt = 0;
    debt._lastBlock = 0;

    return true;
    }

  function onERC721Received(address, address, uint256, bytes calldata ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) public pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

}
/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

contract VaultPaperTrading is Vault {
  using FixedPointMathLib for uint256;

  address public _tokenShop;

  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any address other than the tokenshop
   *  only added for the paper trading competition
   */
  modifier onlyTokenShop() {
    require(msg.sender == _tokenShop, "Not tokenshop");
    _;
  }

  function initialize(address, address, address, address, address) external payable override {
   revert('Not Allowed');
  }

  /** 
    @notice Initiates the variables of the vault
    @dev A proxy will be used to interact with the vault logic.
         Therefore everything is initialised through an init function.
         This function will only be called (once) in the same transaction as the proxy vault creation through the factory.
         Costly function (156k gas)
    @param _owner The tx.origin: the sender of the 'createVault' on the factory
    @param registryAddress The 'beacon' contract to which should be looked at for external logic.
    @param stable The contract address of the stablecoin of Arcadia Finance
    @param stakeContract The stake contract in which stablecoin can be staked. 
                         Used when syncing debt: interest in stable is minted to stakecontract.
    @param irmAddress The contract address of the InterestRateModule, which calculates the going interest rate
                      for a credit line, based on the underlying assets.
    @param tokenShop The contract with the mocked token shop, added for the paper trading competition
  */
  function initialize(address _owner, address registryAddress, address stable, address stakeContract, address irmAddress, address tokenShop) external payable {
    require(initialized == false);
    _registryAddress = registryAddress;
    owner = _owner;
    debt._collThres = 150;
    debt._liqThres = 110;
    _stable = stable;
    _stakeContract = stakeContract;
    _irmAddress = irmAddress;
    _tokenShop = tokenShop; //Variable only added for the paper trading competition

    initialized = true;

    //Following logic added only for the paper trading competition
    //All new vaults are initiated with $1.000.000
    address[] memory addressArr = new address[](1);
    uint256[] memory idArr = new uint256[](1);
    uint256[] memory amountArr = new uint256[](1);

    addressArr[0] = _stable;
    idArr[0] = 0;
    amountArr[0] = FixedPointMathLib.WAD;

    uint256 rateStableToUsd = IRegistry(_registryAddress).getTotalValue(addressArr, idArr, amountArr, 0);
    uint256 stableAmount = FixedPointMathLib.mulDivUp(1000000 * FixedPointMathLib.WAD, FixedPointMathLib.WAD, rateStableToUsd);
    IERC20(_stable).mint(address(this), stableAmount);
    super._depositERC20(address(this), _stable, stableAmount);
  }

  /** 
    @notice The function used to deposit assets into the proxy vault by the proxy vault owner.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get deposited. If multiple asset IDs of the same contract address
         are deposited, the assetAddress must be repeated in assetAddresses.
         The ERC20 get deposited by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner to avoid attacks where malicous actors can deposit 1 wei assets,
         increasing gas costs upon credit issuance and withrawals.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be deposited one address,
                          even if multiple assets of the same contract address are deposited.
    @param assetIds The asset IDs that will be deposited for ERC721 & ERC1155. 
                    When depositing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be deposited. 
    @param assetTypes The types of the assets to be deposited.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
  function deposit(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external payable override onlyTokenShop {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");
    

    require(IRegistry(_registryAddress).batchIsWhiteListed(assetAddresses, assetIds), "Not all assets are whitelisted!");

    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        super._depositERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        super._depositERC721(msg.sender, assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        super._depositERC1155(msg.sender, assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

  }

  /** 
    @notice Processes withdrawals of assets by and to the owner of the proxy vault.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get withdrawn. If multiple asset IDs of the same contract address
         are to be withdrawn, the assetAddress must be repeated in assetAddresses.
         The ERC20 get withdrawn by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner.
         Will fail if balance on proxy vault is not sufficient for one of the withdrawals.
         Will fail if "the value after withdrawal / open debt (including unrealised debt) > collateral threshold".
         If no debt is taken yet on this proxy vault, users are free to withraw any asset at any time.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be withdrawn one address,
                          even if multiple assets of the same contract address are withdrawn.
    @param assetIds The asset IDs that will be withdrawn for ERC721 & ERC1155. 
                    When withdrawing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be withdrawn. 
    @param assetTypes The types of the assets to be withdrawn.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
  function withdraw(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) external payable override onlyTokenShop {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");

    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        super._withdrawERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        super._withdrawERC721(msg.sender, assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        super._withdrawERC1155(msg.sender, assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

    uint256 openDebt = getOpenDebt();
    if (openDebt != 0) {
      require((getValue(debt._numeraire) * 100 / openDebt) > debt._collThres , "Cannot withdraw since the collateral value would become too low!" );
    }

  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract ERC20Mock is ERC20 {

  constructor(string memory name, string memory symbol, uint8 _decimalsInput) ERC20(name, symbol, _decimalsInput) {
  }

  function mint(address to, uint256 amount) public virtual {
      _mint(to, amount);
  }

  function burn(uint256 amount) public {
      _burn(msg.sender, amount);
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



interface IFactory {
  function isVault(address vaultAddress) external view returns (bool);
  function safeTransferFrom(address from, address to, uint256 id) external;
  function liquidate(address vault) external returns (bool);
  function vaultIndex(address vaultAddress) external view returns (uint256);
  function getCurrentRegistry() view external returns (address);
  function addNumeraire(uint256 numeraire, address stable) external;
  function numeraireCounter() external returns (uint256);
}

contract Stable is ERC20 {

  address public liquidator;
  address public owner;
  address public factory;

  modifier onlyOwner {
      require(msg.sender == owner, "You are not the owner");
      _;
  }

  modifier onlyVault {
      require(IFactory(factory).isVault(msg.sender), "Only a vault can mint!");
      _;
  }

  constructor(string memory name, string memory symbol, uint8 _decimalsInput, address liquidatorAddress, address _factory) ERC20(name, symbol, _decimalsInput) {
      liquidator = liquidatorAddress;
      owner = msg.sender;
      factory = _factory;
  }

  function setFactory(address _factory) public onlyOwner {
      factory = _factory;
  }

  function mint(address to, uint256 amount) public onlyVault {
      _mint(to, amount);
  }

  function setLiquidator(address liq) public onlyOwner {
      liquidator = liq;
  }

  function burn(uint256 amount) public {
      _burn(msg.sender, amount);
  }
function safeBurn(address from, uint256 amount) public returns (bool) {
    require(msg.sender == from || msg.sender == liquidator);
    _burn(from, amount);

    return true;
  }

}

contract StablePaperTrading is Stable {

  constructor(string memory name, string memory symbol, uint8 _decimalsInput, address liquidatorAddress, address _factory) Stable(name, symbol, _decimalsInput, liquidatorAddress, _factory) {}

  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    if (from == to) {
      return true; 
    } else {
      return super.transferFrom(from, to, amount);
    }
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IChainLinkData {
    function latestRoundData()
            external
            view
            returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
            );
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.




interface IOraclesHub {
  function getRate(address[] memory, uint256) external view returns (uint256, uint256);
  function checkOracleSequence (address[] memory oracleAdresses) external view;
}




interface ISubRegistry {
  function isAssetAddressWhiteListed(address) external view returns (bool);
  struct GetValueInput {
    address assetAddress;
    uint256 assetId;
    uint256 assetAmount;
    uint256 numeraire;
  }
  
  function isWhiteListed(address, uint256) external view returns (bool);
  function getValue(GetValueInput memory) external view returns (uint256, uint256);
}

/** 
  * @title Main Asset registry
  * @author Arcadia Finance
  * @notice The Main-registry stores basic information for each token that can, or could at some point, be deposited in the vaults
  * @dev No end-user should directly interact with the Main-registry, only vaults, Sub-Registries or the contract owner
 */ 
contract MainRegistry is Ownable {
  using FixedPointMathLib for uint256;

  bool public assetsUpdatable = true;

  uint256 public constant CREDIT_RATING_CATOGERIES = 10;

  address[] private subRegistries;
  address[] public assetsInMainRegistry;

  mapping (address => bool) public inMainRegistry;
  mapping (address => bool) public isSubRegistry;
  mapping (address => address) public assetToSubRegistry;

  address public factoryAddress;

  struct NumeraireInformation {
    uint64 numeraireToUsdOracleUnit;
    uint64 numeraireUnit;
    address assetAddress;
    address numeraireToUsdOracle;
    address stableAddress;
    string numeraireLabel;
  }

  uint256 public numeraireCounter;
  mapping (uint256 => NumeraireInformation) public numeraireToInformation;

  mapping (address => mapping (uint256 => uint256)) public assetToNumeraireToCreditRating;

  /**
   * @dev Only Sub-registries can call functions marked by this modifier.
   **/
  modifier onlySubRegistry {
    require(isSubRegistry[msg.sender], 'Caller is not a sub-registry.');
    _;
  }

  /**
   * @notice The Main Registry must always be initialised with at least one Numeraire: USD
   * @dev If the Numeraire has no native token, numeraireDecimals should be set to 0 and assetAddress to the null address
   * @param _numeraireInformation A Struct with information about the Numeraire USD
   */
  constructor (NumeraireInformation memory _numeraireInformation) {
    //Main registry must be initialised with usd
    numeraireToInformation[numeraireCounter] = _numeraireInformation;
    unchecked {++numeraireCounter;}
  }

  /**
   * @notice Sets the new Factory address
   * @dev The factory can only be set on the Main Registry AFTER the Main registry is set in the Factory.
   *  This ensures that the allowed Numeraires and corresponding stable contracts in both are equal.
   * @param _factoryAddress The address of the Factory
   */
  function setFactory(address _factoryAddress) external onlyOwner {
    require(IFactory(_factoryAddress).getCurrentRegistry() == address(this), "MR_AA: MR not set in factory");
    factoryAddress = _factoryAddress;

    uint256 factoryNumeraireCounter = IFactory(_factoryAddress).numeraireCounter();
    if (numeraireCounter > factoryNumeraireCounter) {
      for (uint256 i = factoryNumeraireCounter; i < numeraireCounter;) {
        IFactory(factoryAddress).addNumeraire(i, numeraireToInformation[i].stableAddress);
        unchecked {++i;}
      }
    }
  }

  /**
   * @notice Checks for a list of tokens and a list of corresponding IDs if all tokens are white-listed
   * @param _assetAddresses The list of token addresses that needs to be checked 
   * @param _assetIds The list of corresponding token Ids that needs to be checked
   * @dev For each token address, a corresponding id at the same index should be present,
   *  for tokens without Id (ERC20 for instance), the Id should be set to 0
   * @return A boolean, indicating of all assets passed as input are whitelisted
   */
  function batchIsWhiteListed(
    address[] calldata _assetAddresses, 
    uint256[] calldata _assetIds
  ) public view returns (bool) {

    //Check if all ERC721 tokens are whitelisted
    uint256 addressesLength = _assetAddresses.length;
    require(addressesLength == _assetIds.length, "LENGTH_MISMATCH");

    address assetAddress;
    for (uint256 i; i < addressesLength;) {
      assetAddress = _assetAddresses[i];
      if (!inMainRegistry[assetAddress]) {
        return false;
      } else if (!ISubRegistry(assetToSubRegistry[assetAddress]).isWhiteListed(assetAddress, _assetIds[i])) {
        return false;
      }
      unchecked {++i;}
    }

    return true;

  }

  /**
   * @notice returns a list of all white-listed token addresses
   * @dev Function is not gas-optimsed and not intended to be called by other smart contracts
   * @return A list of all white listed token Adresses
   */
  function getWhiteList() external view returns (address[] memory) {
    uint256 maxLength = assetsInMainRegistry.length;
    address[] memory whiteList = new address[](maxLength);

    uint256 counter = 0;
    for (uint256 i; i < maxLength;) {
      address assetAddress = assetsInMainRegistry[i];
      if (ISubRegistry(assetToSubRegistry[assetAddress]).isAssetAddressWhiteListed(assetAddress)) {
        whiteList[counter] = assetAddress;
        unchecked {++counter;}
      }
      unchecked {++i;}
    }

    return whiteList;
  }

  /**
   * @notice Add a Sub-registry Address to the list of Sub-Registries
   * @param subAssetRegistryAddress Address of the Sub-Registry
   */
  function addSubRegistry(address subAssetRegistryAddress) external onlyOwner {
    require(!isSubRegistry[subAssetRegistryAddress], 'Sub-Registry already exists');
    isSubRegistry[subAssetRegistryAddress] = true;
    subRegistries.push(subAssetRegistryAddress);
  }

  /**
   * @notice Add a new asset to the Main Registry, or overwrite an existing one (if assetsUpdatable is True)
   * @param assetAddress The address of the asset
   * @param assetCreditRatings The List of Credit Rating Categories for the asset for the different Numeraires
   * @dev The list of Credit Ratings should or be as long as the number of numeraires added to the Main Registry,
   *  or the list must have lenth 0. If the list has length zero, the credit ratings of the asset for all numeraires is
   *  is initiated as credit rating with index 0 by default (worst credit rating).
   *  Each Credit Rating Category is labeled with an integer, Category 0 (the default) is for the most risky assets.
   *  Category from 1 to 10 will be used to label groups of assets with similart risk profiles
   *  (Comparable to ratings like AAA, A-, B... for debtors in traditional finance).
   */
  function addAsset(address assetAddress, uint256[] memory assetCreditRatings) external onlySubRegistry {
    if (inMainRegistry[assetAddress]) {
      require(assetsUpdatable, 'MR_AA: already known');
    } else {
      inMainRegistry[assetAddress] = true;
      assetsInMainRegistry.push(assetAddress);
    }
    assetToSubRegistry[assetAddress] = msg.sender;

    uint256 assetCreditRatingsLength = assetCreditRatings.length;
    require(assetCreditRatingsLength == numeraireCounter || assetCreditRatingsLength == 0, 'MR_AA: LENGTH_MISMATCH');
    for (uint256 i; i < assetCreditRatingsLength;) {
      require(assetCreditRatings[i] < CREDIT_RATING_CATOGERIES, "MR_AA: non-existing");
      assetToNumeraireToCreditRating[assetAddress][i] = assetCreditRatings[i];
      unchecked {++i;}
    }
  }

  /**
   * @notice Change the Credit Rating Category for one or more assets for one or more numeraires
   * @param assets The List of addresses of the assets
   * @param numeraires The corresponding List of Numeraires
   * @param newCreditRating The corresponding List of new Credit Ratings
   * @dev The function loops over all indexes, and changes for each index the Credit Rating Category of the combination of asset and numeraire.
   *  In case multiple numeraires for the same assets need to be changed, the address must be repeated in the assets.
   *  Each Credit Rating Category is labeled with an integer, Category 0 (the default) is for the most risky assets.
   *  Category from 1 to 10 will be used to label groups of assets with similart risk profiles
   *  (Comparable to ratings like AAA, A-, B... for debtors in traditional finance).
   */
  function batchSetCreditRating(address[] calldata assets, uint256[] calldata numeraires, uint256[] calldata newCreditRating) external onlyOwner {
    uint256 assetsLength = assets.length;
    require(assetsLength == numeraires.length && assetsLength == newCreditRating.length, "MR_BSCR: LENGTH_MISMATCH");

    for (uint256 i; i < assetsLength;) {
      require(newCreditRating[i] < CREDIT_RATING_CATOGERIES, "MR_BSCR: non-existing creditRat");
      assetToNumeraireToCreditRating[assets[i]][numeraires[i]] = newCreditRating[i];
      unchecked {++i;}
    }
  }

  /**
   * @notice Disables the updatability of assets. In the disabled states, asset properties become immutable
   **/
  function setAssetsToNonUpdatable() external onlyOwner {
    assetsUpdatable = false;
  }

  /**
   * @notice Add a new numeraire to the Main Registry, or overwrite an existing one
   * @param numeraireInformation A Struct with information about the Numeraire
   * @param assetCreditRatings The List of the Credit Rating Categories of the numeraire, for all the different assets in the Main registry
   * @dev The list of Credit Rating Categories should or be as long as the number of assets added to the Main Registry,
   *  or the list must have lenth 0. If the list has length zero, the credit ratings of the numeraire for all assets is
   *  is initiated as credit rating with index 0 by default (worst credit rating).
   *  Each Credit Rating Category is labeled with an integer, Category 0 (the default) is for the most risky assets.
   *  Category from 1 to 10 will be used to label groups of assets with similart risk profiles
   *  (Comparable to ratings like AAA, A-, B... for debtors in traditional finance).
   *  ToDo: Add tests that existing numeraire cannot be entered second time?
   *  ToDo: check if assetCreditRating can be put in a struct
   */
  function addNumeraire(NumeraireInformation calldata numeraireInformation, uint256[] calldata assetCreditRatings) external onlyOwner {
    numeraireToInformation[numeraireCounter] = numeraireInformation;

    uint256 assetCreditRatingsLength = assetCreditRatings.length;
    require(assetCreditRatingsLength == assetsInMainRegistry.length || assetCreditRatingsLength == 0, 'MR_AN: lenght');
    for (uint256 i; i < assetCreditRatingsLength;) {
      require(assetCreditRatings[i] < CREDIT_RATING_CATOGERIES, "MR_AN: non existing credRat");
      assetToNumeraireToCreditRating[assetsInMainRegistry[i]][numeraireCounter] = assetCreditRatings[i];
      unchecked {++i;}
    }

    if (factoryAddress != address(0)) {
      IFactory(factoryAddress).addNumeraire(numeraireCounter, numeraireInformation.stableAddress);
    }
    unchecked {++numeraireCounter;}
  }

  /**
   * @notice Calculate the total value of a list of assets denominated in a given Numeraire
   * @param _assetAddresses The List of token addresses of the assets
   * @param _assetIds The list of corresponding token Ids that needs to be checked
   * @dev For each token address, a corresponding id at the same index should be present,
   *  for tokens without Id (ERC20 for instance), the Id should be set to 0
   * @param _assetAmounts The list of corresponding amounts of each Token-Id combination
   * @param numeraire An identifier (uint256) of the Numeraire
   * @return valueInNumeraire The total value of the list of assets denominated in Numeraire
   * @dev Todo: Not yet tested for Over-and underflow
  *       ToDo: value sum unchecked. Cannot overflow on 1e18 decimals
   */
  function getTotalValue(
                        address[] calldata _assetAddresses, 
                        uint256[] calldata _assetIds,
                        uint256[] calldata _assetAmounts,
                        uint256 numeraire
                      ) public view returns (uint256 valueInNumeraire) {
    uint256 valueInUsd;

    require(numeraire <= numeraireCounter - 1, "MR_GTV: Unknown Numeraire");

    uint256 assetAddressesLength = _assetAddresses.length;
    require(assetAddressesLength == _assetIds.length && assetAddressesLength == _assetAmounts.length, "MR_GTV: LENGTH_MISMATCH");
    ISubRegistry.GetValueInput memory getValueInput;
    getValueInput.numeraire = numeraire;

    for (uint256 i; i < assetAddressesLength;) {
      address assetAddress = _assetAddresses[i];
      require(inMainRegistry[assetAddress], "MR_GTV: Unknown asset");

      getValueInput.assetAddress = assetAddress;
      getValueInput.assetId = _assetIds[i];
      getValueInput.assetAmount = _assetAmounts[i];

      if (assetAddress == numeraireToInformation[numeraire].assetAddress) { //Should only be allowed if the numeraire is ETH, not for stablecoins or wrapped tokens
        valueInNumeraire = valueInNumeraire + _assetAmounts[i].mulDivDown(FixedPointMathLib.WAD, numeraireToInformation[numeraire].numeraireUnit); //_assetAmounts must be a with 18 decimals precision
      } else {
          //Calculate value of the next asset and add it to the total value of the vault
          (uint256 tempValueInUsd, uint256 tempValueInNumeraire) = ISubRegistry(assetToSubRegistry[assetAddress]).getValue(getValueInput);
          valueInUsd = valueInUsd + tempValueInUsd;
          valueInNumeraire = valueInNumeraire + tempValueInNumeraire;
      }
      unchecked {++i;}
    }
    if (numeraire == 0) { //Check if numeraire is USD
      return valueInUsd;
    } else if (valueInUsd > 0) {
      //Get the Numeraire-USD rate
      (,int256 rate,,,) = IChainLinkData(numeraireToInformation[numeraire].numeraireToUsdOracle).latestRoundData();
      //Add valueInUsd to valueInNumeraire, to check if conversion from int to uint can always be done
      valueInNumeraire = valueInNumeraire + valueInUsd.mulDivDown(numeraireToInformation[numeraire].numeraireToUsdOracleUnit, uint256(rate));
    }

  }

  /**
   * @notice Calculate the value per asset of a list of assets denominated in a given Numeraire
   * @param _assetAddresses The List of token addresses of the assets
   * @param _assetIds The list of corresponding token Ids that needs to be checked
   * @dev For each token address, a corresponding id at the same index should be present,
   *      for tokens without Id (ERC20 for instance), the Id should be set to 0
   * @param _assetAmounts The list of corresponding amounts of each Token-Id combination
   * @param numeraire An identifier (uint256) of the Numeraire
   * @return valuesPerAsset sThe list of values per assets denominated in Numeraire
   * @dev Todo: Not yet tested for Over-and underflow
   */
  function getListOfValuesPerAsset(
    address[] calldata _assetAddresses, 
    uint256[] calldata _assetIds,
    uint256[] calldata _assetAmounts,
    uint256 numeraire
  ) public view returns (uint256[] memory valuesPerAsset) {
    
    valuesPerAsset = new uint256[](_assetAddresses.length);

    require(numeraire <= numeraireCounter - 1, "MR_GLV: Unknown Numeraire");

    uint256 assetAddressesLength = _assetAddresses.length;
    require(assetAddressesLength == _assetIds.length && assetAddressesLength == _assetAmounts.length, "MR_GLV: LENGTH_MISMATCH");
    ISubRegistry.GetValueInput memory getValueInput;
    getValueInput.numeraire = numeraire;

    int256 rateNumeraireToUsd;

    for (uint256 i; i < assetAddressesLength;) {
      address assetAddress = _assetAddresses[i];
      require(inMainRegistry[assetAddress], "MR_GLV: Unknown asset");

      getValueInput.assetAddress = assetAddress;
      getValueInput.assetId = _assetIds[i];
      getValueInput.assetAmount = _assetAmounts[i];

      if (assetAddress == numeraireToInformation[numeraire].assetAddress) { //Should only be allowed if the numeraire is ETH, not for stablecoins or wrapped tokens
        valuesPerAsset[i] = _assetAmounts[i].mulDivDown(FixedPointMathLib.WAD, numeraireToInformation[numeraire].numeraireUnit); //_assetAmounts must be a with 18 decimals precision
      } else {
        //Calculate value of the next asset and add it to the total value of the vault
        (uint256 valueInUsd, uint256 valueInNumeraire) = ISubRegistry(assetToSubRegistry[assetAddress]).getValue(getValueInput);
        if (numeraire == 0) { //Check if numeraire is USD
          valuesPerAsset[i] = valueInUsd;
        } else if (valueInNumeraire > 0) {
            valuesPerAsset[i] = valueInNumeraire;
        } else {
          //Check if the Numeraire-USD rate is already fetched
          if (rateNumeraireToUsd == 0) {
            //Get the Numeraire-USD rate ToDo: Ask via the OracleHub?
            (,rateNumeraireToUsd,,,) = IChainLinkData(numeraireToInformation[numeraire].numeraireToUsdOracle).latestRoundData();  
          }
          valuesPerAsset[i] = valueInUsd.mulDivDown(numeraireToInformation[numeraire].numeraireToUsdOracleUnit, uint256(rateNumeraireToUsd));
        }
      }
      unchecked {++i;}
    }
    return valuesPerAsset;
  }

  /**
   * @notice Calculate the value per Credit Rating Category of a list of assets denominated in a given Numeraire
   * @param _assetAddresses The List of token addresses of the assets
   * @param _assetIds The list of corresponding token Ids that needs to be checked
   * @dev For each token address, a corresponding id at the same index should be present,
   *  for tokens without Id (ERC20 for instance), the Id should be set to 0
   * @param _assetAmounts The list of corresponding amounts of each Token-Id combination
   * @param numeraire An identifier (uint256) of the Numeraire
   * @return valuesPerCreditRating The list of values per Credit Rating Category denominated in Numeraire
   * @dev Todo: Not yet tested for Over-and underflow
   */
 function getListOfValuesPerCreditRating(
    address[] calldata _assetAddresses, 
    uint256[] calldata _assetIds,
    uint256[] calldata _assetAmounts,
    uint256 numeraire
  ) public view returns (uint256[] memory valuesPerCreditRating) {

    valuesPerCreditRating = new uint256[](CREDIT_RATING_CATOGERIES);
    uint256[] memory valuesPerAsset = getListOfValuesPerAsset(_assetAddresses, _assetIds, _assetAmounts, numeraire);

    uint256 valuesPerAssetLength = valuesPerAsset.length;
    for (uint256 i; i < valuesPerAssetLength;) {
      address assetAdress = _assetAddresses[i];
      valuesPerCreditRating[assetToNumeraireToCreditRating[assetAdress][numeraire]] += valuesPerAsset[i];
      unchecked {++i;}
    }

    return valuesPerCreditRating;
  }

}
contract ERC20PaperTrading is ERC20Mock {

  address private tokenShop;

  /**
   * @dev Throws if called by any address other than the tokenshop
   *  only added for the paper trading competition
   */
  modifier onlyTokenShop() {
    require(msg.sender == tokenShop, "Not tokenshop");
    _;
  }

  constructor(string memory name, string memory symbol, uint8 _decimalsInput, address _tokenShop) ERC20Mock(name, symbol, _decimalsInput) {
    tokenShop =_tokenShop;
  }

  function mint(address to, uint256 amount) public override onlyTokenShop {
    _mint(to, amount);
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.



// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.








/** 
  * @title Abstract Sub-registry
  * @author Arcadia Finance
  * @notice Sub-Registries store pricing logic and basic information for tokens that can, or could at some point, be deposited in the vaults
  * @dev No end-user should directly interact with the Main-registry, only the Main-registry, Oracle-Hub or the contract owner
 */ 
abstract contract SubRegistry is Ownable {
  using FixedPointMathLib for uint256;
  
  address public _mainRegistry;
  address public _oracleHub;
  address[] public assetsInSubRegistry;
  mapping (address => bool) public inSubRegistry;
  mapping (address => bool) public isAssetAddressWhiteListed;

  struct GetValueInput {
    address assetAddress;
    uint256 assetId;
    uint256 assetAmount;
    uint256 numeraire;
  }

  /**
   * @notice A Sub-Registry must always be initialised with the address of the Main-Registry and of the Oracle-Hub
   * @param mainRegistry The address of the Main-registry
   * @param oracleHub The address of the Oracle-Hub 
   */
  constructor (address mainRegistry, address oracleHub) {
    //owner = msg.sender;
    _mainRegistry = mainRegistry;
    _oracleHub = oracleHub; //ToDo Not the best place to store oraclehub address in sub-registries. Redundant + lot's of tx required of oraclehub is ever changes
  }

  /**
   * @notice Checks for a token address and the corresponding Id if it is white-listed
   * @return A boolean, indicating if the asset passed as input is whitelisted
   */
  function isWhiteListed(address, uint256) external view virtual returns (bool) {
    return false;
  }

  /**
   * @notice Removes an asset from the white-list
   * @param assetAddress The token address of the asset that needs to be removed from the white-list
   */
  function removeFromWhiteList(address assetAddress) external onlyOwner {
    require(inSubRegistry[assetAddress], 'Asset not known in Sub-Registry');
    isAssetAddressWhiteListed[assetAddress] = false;
  }

  /**
   * @notice Adds an asset to the white-list
   * @param assetAddress The token address of the asset that needs to be added to the white-list
   */
  function addToWhiteList(address assetAddress) external onlyOwner {
    require(inSubRegistry[assetAddress], 'Asset not known in Sub-Registry');
    isAssetAddressWhiteListed[assetAddress] = true;
  }

  /**
   * @notice Returns the value of a certain asset, denominated in USD or in another Numeraire
   */
  function getValue(GetValueInput memory) public view virtual returns (uint256, uint256) {
    
  }

}


/** 
  * @title Sub-registry for Standard ERC20 tokens
  * @author Arcadia Finance
  * @notice The StandardERC20Registry stores pricing logic and basic information for ERC20 tokens for which a direct price feeds exists
  * @dev No end-user should directly interact with the Main-registry, only the Main-registry, Oracle-Hub or the contract owner
 */
contract StandardERC20Registry is SubRegistry {
  using FixedPointMathLib for uint256;

  struct AssetInformation {
    uint64 assetUnit;
    address assetAddress;
    address[] oracleAddresses;
  }

  mapping (address => AssetInformation) public assetToInformation;

  /**
   * @notice A Sub-Registry must always be initialised with the address of the Main-Registry and of the Oracle-Hub
   * @param mainRegistry The address of the Main-registry
   * @param oracleHub The address of the Oracle-Hub 
   */
  constructor (address mainRegistry, address oracleHub) SubRegistry(mainRegistry, oracleHub) {
    //owner = msg.sender;
    _mainRegistry = mainRegistry;
    _oracleHub = oracleHub; //Not the best place to store oraclehub address in sub-registries. Redundant + lot's of tx required of oraclehub is ever changes
  }

  /**
   * @notice Add a new asset to the StandardERC20Registry, or overwrite an existing one
   * @param assetInformation A Struct with information about the asset 
   * @param assetCreditRatings The List of Credit Ratings for the asset for the different Numeraires
   * @dev The list of Credit Ratings should or be as long as the number of numeraires added to the Main Registry,
   *  or the list must have lenth 0. If the list has length zero, the credit ratings of the asset for all numeraires is
   *  is initiated as credit rating with index 0 by default (worst credit rating)
   * @dev The asset needs to be added/overwritten in the Main-Registry as well
   */
  function setAssetInformation(AssetInformation calldata assetInformation, uint256[] calldata assetCreditRatings) external onlyOwner {
    
    IOraclesHub(_oracleHub).checkOracleSequence(assetInformation.oracleAddresses);

    address assetAddress = assetInformation.assetAddress;
    require(assetInformation.assetUnit <= 10**18, 'Asset can have maximal 18 decimals');
    if (!inSubRegistry[assetAddress]) {
      inSubRegistry[assetAddress] = true;
      assetsInSubRegistry.push(assetAddress);
    }
    assetToInformation[assetAddress] = assetInformation;
    isAssetAddressWhiteListed[assetAddress] = true;
    IMainRegistry(_mainRegistry).addAsset(assetAddress, assetCreditRatings);
  }

  /**
   * @notice Returns the information that is stored in the Sub-registry for a given asset
   * @dev struct is not taken into memory; saves 6613 gas
   * @param asset The Token address of the asset
   * @return assetDecimals The number of decimals of the asset
   * @return assetAddress The Token address of the asset
   * @return oracleAddresses The list of addresses of the oracles to get the exchange rate of the asset in USD
   */
  function getAssetInformation(address asset) public view returns (uint64, address, address[] memory) {
    return (assetToInformation[asset].assetUnit, assetToInformation[asset].assetAddress, assetToInformation[asset].oracleAddresses);
  }

  /**
   * @notice Checks for a token address and the corresponding Id if it is white-listed
   * @param assetAddress The address of the asset
   * @dev For each token address, a corresponding id at the same index should be present,
   *      for tokens without Id (ERC20 for instance), the Id should be set to 0
   * @return A boolean, indicating if the asset passed as input is whitelisted
   */
  function isWhiteListed(address assetAddress, uint256) external override view returns (bool) {
    if (isAssetAddressWhiteListed[assetAddress]) {
      return true;
    }

    return false;
  }

  /**
   * @notice Returns the value of a certain asset, denominated in USD or in another Numeraire
   * @param getValueInput A Struct with all the information neccessary to get the value of an asset denominated in USD or
   *  denominated in a given Numeraire different from USD
   * @return valueInUsd The value of the asset denominated in USD with 18 Decimals precision
   * @return valueInNumeraire The value of the asset denominated in Numeraire different from USD with 18 Decimals precision
   * @dev The value of an asset will be denominated in a Numeraire different from USD if and only if
   *      the given Numeraire is different from USD and one of the intermediate oracles to price the asset has
   *      the given numeraire as base-asset.
   *      Only one of the two values can be different from 0.
   *      Function will overflow when assetAmount * Rate * 10**(18 - rateDecimals) > MAXUINT256
   */
  function getValue(GetValueInput memory getValueInput) public view override returns (uint256, uint256) {
    uint256 value;
    uint256 rateInUsd;
    uint256 rateInNumeraire;

    //Will return empty struct when asset is not first added to subregisrty -> still return a value without error
    //In reality however call will always pass via mainregistry, that already does the check
    //ToDo

    (rateInUsd, rateInNumeraire) = IOraclesHub(_oracleHub).getRate(assetToInformation[getValueInput.assetAddress].oracleAddresses, getValueInput.numeraire);

    if (rateInNumeraire > 0) {
      value = (getValueInput.assetAmount).mulDivDown(rateInNumeraire, assetToInformation[getValueInput.assetAddress].assetUnit);
      return (0, value);
    } else {
      value = (getValueInput.assetAmount).mulDivDown(rateInUsd, assetToInformation[getValueInput.assetAddress].assetUnit);
      return (value, 0);
    }
        
  }

}
contract ERC721Mock is ERC721 {
    using Strings for uint256;

    string baseURI;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        owner = msg.sender;
    }


    function mint(address to, uint256 id) public virtual {
        _mint(to, id);
    }

    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(
            ownerOf[tokenId] != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
            : "";
    }
}

contract ERC721PaperTrading is ERC721Mock {

  address private tokenShop;

  /**
   * @dev Throws if called by any address other than the tokenshop
   *  only added for the paper trading competition
   */
  modifier onlyTokenShop() {
    require(msg.sender == tokenShop, "Not tokenshop");
    _;
  }

  constructor(string memory name, string memory symbol, address _tokenShop) ERC721Mock(name, symbol) {
    tokenShop =_tokenShop;
  }

  function mint(address to, uint256 id) public override onlyTokenShop {
    _mint(to, id);
  }


  function burn(uint256 id) public {
      require(msg.sender == ownerOf[id], "You are not the owner");
      _burn(id);
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





/** 
  * @title Sub-registry for ERC721 tokens for which a oracle exists for the floor price of the collection
  * @author Arcadia Finance
  * @notice The FloorERC721SubRegistry stores pricing logic and basic information for ERC721 tokens for which a direct price feeds exists
  *         for the floor price of the collection
  * @dev No end-user should directly interact with the Main-registry, only the Main-registry, Oracle-Hub or the contract owner
 */
contract FloorERC721SubRegistry is SubRegistry {

  struct AssetInformation {
    uint256 idRangeStart;
    uint256 idRangeEnd;
    address assetAddress;
    address[] oracleAddresses;
  }

  mapping (address => AssetInformation) public assetToInformation;

  /**
   * @notice A Sub-Registry must always be initialised with the address of the Main-Registry and of the Oracle-Hub
   * @param mainRegistry The address of the Main-registry
   * @param oracleHub The address of the Oracle-Hub 
   */
  constructor(address mainRegistry, address oracleHub) SubRegistry(mainRegistry, oracleHub) {
    //owner = msg.sender;
    _mainRegistry = mainRegistry;
    _oracleHub = oracleHub; //Not the best place to store oraclehub address in sub-registries. Redundant + lot's of tx required of oraclehub is ever changes
  }
  
  /**
   * @notice Add a new asset to the FloorERC721SubRegistry, or overwrite an existing one
   * @param assetInformation A Struct with information about the asset 
   * @param assetCreditRatings The List of Credit Ratings for the asset for the different Numeraires
   * @dev The list of Credit Ratings should or be as long as the number of numeraires added to the Main Registry,
   *      or the list must have lenth 0. If the list has length zero, the credit ratings of the asset for all numeraires is
   *      is initiated as credit rating with index 0 by default (worst credit rating)
   * @dev The asset needs to be added/overwritten in the Main-Registry as well
   */ 
  function setAssetInformation(AssetInformation calldata assetInformation, uint256[] calldata assetCreditRatings) external onlyOwner {

    IOraclesHub(_oracleHub).checkOracleSequence(assetInformation.oracleAddresses);
    
    address assetAddress = assetInformation.assetAddress;
    //require(!inSubRegistry[assetAddress], 'Asset already known in Sub-Registry');
    if (!inSubRegistry[assetAddress]) {
      inSubRegistry[assetAddress] = true;
      assetsInSubRegistry.push(assetAddress);
    }
    assetToInformation[assetAddress] = assetInformation;
    isAssetAddressWhiteListed[assetAddress] = true;
    IMainRegistry(_mainRegistry).addAsset(assetAddress, assetCreditRatings);
  }

  /**
   * @notice Checks for a token address and the corresponding Id if it is white-listed
   * @param assetAddress The address of the asset
   * @param assetId The Id of the asset
   * @return A boolean, indicating if the asset passed as input is whitelisted
   */
  function isWhiteListed(address assetAddress, uint256 assetId) external override view returns (bool) {
    if (isAssetAddressWhiteListed[assetAddress]) {
      if (isIdInRange(assetAddress, assetId)) {
        return true;
      }
    }

    return false;
  }

  /**
   * @notice Checks if the Id for a given token is in the range for which there exists a price feed
   * @param assetAddress The address of the asset
   * @param assetId The Id of the asset
   * @return A boolean, indicating if the Id of the given asset is whitelisted
   */
  function isIdInRange(address assetAddress, uint256 assetId) private view returns (bool) {
    if (assetId >= assetToInformation[assetAddress].idRangeStart && assetId <= assetToInformation[assetAddress].idRangeEnd) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice Returns the value of a certain asset, denominated in USD or in another Numeraire
   * @param getValueInput A Struct with all the information neccessary to get the value of an asset denominated in USD or
   *                      denominated in a given Numeraire different from USD
   * @return valueInUsd The value of the asset denominated in USD with 18 Decimals precision
   * @return valueInNumeraire The value of the asset denominated in Numeraire different from USD with 18 Decimals precision
   * @dev The value of an asset will be denominated in a Numeraire different from USD if and only if
   *      the given Numeraire is different from USD and one of the intermediate oracles to price the asset has
   *      the given numeraire as base-asset.
   *      Only one of the two values can be different from 0.
   */
  function getValue(GetValueInput memory getValueInput) public view override returns (uint256 valueInUsd, uint256 valueInNumeraire) {
 
    (valueInUsd, valueInNumeraire) = IOraclesHub(_oracleHub).getRate(assetToInformation[getValueInput.assetAddress].oracleAddresses, getValueInput.numeraire);
  }
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





/** 
  * @title Interest Rate Module
  * @author Arcadia Finance
  * @notice The Interest Rate Module manages the base interest rate and the collateral specific interest rates
  * @dev No end-user should directly interact with the Interest Rate Module, only the Main-registry or the contract owner
 */
contract InterestRateModule is Ownable {

  uint256 public baseInterestRate;

  mapping (uint256 => uint256) public creditRatingToInterestRate;

  /**
   * @notice Constructor
   */
  constructor() {
  }

  /**
   * @notice Sets the base interest rate (cost of capital)
   * @param _baseInterestRate The new base interest rate (yearly APY)
   * @dev The base interest rate is standard initialized as 0
   *  the base interest rate is the relative compounded interest after one year, it is an integer with 18 decimals
   *  Example: For a yearly base interest rate of 2% APY, _baseInterestRate must equal 20 000 000 000 000 000
   */
	function setBaseInterestRate(uint64 _baseInterestRate) external onlyOwner {
		baseInterestRate = _baseInterestRate;
	}

  /**
   * @notice Sets interest rate for Credit Rating Categories (risk associated with collateral)
   * @param creditRatings The list of indices of the Credit Rating Categories for which the Interest Rate needs to be changed
   * @param interestRates The list of new interest rates (yearly APY) for the corresponding Credit Rating Categories
   * @dev The Credit Rating Categories are standard initialized with 0
   *  the interest rates are relative compounded interests after one year, it are integers with 18 decimals
   *  Example: For a yearly interest rate of 2% APY, _baseInterestRate must equal 20 000 000 000 000 000
   *  Each Credit Rating Category is labeled with an integer, Category 0 (the default) is for the most risky assets
   *  hence it will have the highest interest rate. Each Category from 1 to 10 will be used to label groups of assets
   *  with similart risk profiles (Comparable to ratings like AAA, A-, B... for debtors in traditional finance).
   */
  function batchSetCollateralInterestRates(uint256[] calldata creditRatings, uint256[] calldata interestRates) external onlyOwner {
    uint256 creditRatingsLength = creditRatings.length;
    require(creditRatingsLength == interestRates.length, 'IRM: LENGTH_MISMATCH');
    for (uint256 i; i < creditRatingsLength;) {
      creditRatingToInterestRate[creditRatings[i]] = interestRates[i];
      unchecked {++i;}
    }
  }

  /**
   * @notice Returns the weighted interest rate of a basket of different assets depending on their Credit rating category
   * @param valuesPerCreditRating A list of the values (denominated in a single Numeraire) of assets per Credit Rating Category
   * @param minCollValue The minimal collaterisation value (denominated in the same Numeraire)
   * @return collateralInterestRate The weighted asset specific interest rate of a basket of assets
   * @dev Since each Credit Rating Category has its own specific interest rate, the interest rate for a basket of collateral
   *  is calculated as the weighted interest rate over the different Credit Rating Categories.
   *  The function will start from the highest quality Credit Rating Category (labeled as 1) check if the value of Category 1 exceeds
   *  a certain treshhold, the minimal collaterisation value. If not it goes to the second best category(labeled as 2) and so forth.
   *  If the treshhold is not reached after category 10, the remainder of value to meet the minimal collaterisation value is
   *  assumed to be of the worst category (labeled as 0).
   */
  function calculateWeightedCollateralInterestrate(uint256[] memory valuesPerCreditRating, uint256 minCollValue) internal view returns (uint256) {
    if (minCollValue == 0) {
      return 0;
    } else {
      uint256 collateralInterestRate;
      uint256 totalValue;
      uint256 value;
      uint256 valuesPerCreditRatingLength = valuesPerCreditRating.length;
      for (uint256 i = 1; i < valuesPerCreditRatingLength;) {
        value = valuesPerCreditRating[i];
        if (totalValue + value < minCollValue) {
          collateralInterestRate += creditRatingToInterestRate[i] * value / minCollValue;
          totalValue += value;
        } else {
          value = minCollValue - totalValue;
          collateralInterestRate += creditRatingToInterestRate[i] * value / minCollValue;
          return collateralInterestRate;
        }
        unchecked {++i;}
      }
      //Loop ended without returning -> use lowest credit rating (at index 0) for remaining collateral
      value = minCollValue - totalValue;
      collateralInterestRate += creditRatingToInterestRate[0] * value / minCollValue;

      return collateralInterestRate;
    }
  }

  /**
   * @notice Returns the interest rate of a basket of different assets
   * @param valuesPerCreditRating A list of the values (denominated in a single Numeraire) of assets per Credit Rating Category
   * @param minCollValue The minimal collaterisation value (denominated in the same Numeraire)
   * @return yearlyInterestRate The total yearly compounded interest rate of of a basket of assets
   * @dev The yearly interest rate exists out of a base rate (cost of capital) and a collatereal specific rate (price risks of collateral)
   *  The interest rate is the relative compounded interest after one year, it is an integer with 18 decimals
   *  Example: For a yearly interest rate of 2% APY, yearlyInterestRate will equal 20 000 000 000 000 000
   */
	function getYearlyInterestRate(uint256[] calldata valuesPerCreditRating, uint256 minCollValue) external view returns (uint64 yearlyInterestRate) {
    //ToDo: checks on min and max length to implement
		yearlyInterestRate =  uint64(baseInterestRate) + uint64(calculateWeightedCollateralInterestrate(valuesPerCreditRating, minCollValue));
	}
  
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.







interface IStable {
  function safeBurn(address from, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}




contract Liquidator {

  address public factoryAddress;
  address public owner;
  uint8 public numeraireOfDebt;
  address public registryAddress;
  address public stable;
  address public reserveFund;

  uint256 constant public hourlyBlocks = 300;
  uint256 public auctionDuration = 6; //hours

  claimRatios public claimRatio;

  struct claimRatios {
    uint64 protocol;
    uint64 originalOwner;
    uint64 liquidator;
    uint64 reserveFund;
  }

  struct auctionInformation {
    uint128 openDebt;
    uint128 startBlock;
    uint8 liqThres;
    uint128 stablePaid;
    address liquidator;
    address originalOwner;
  }

  mapping (address => mapping (uint256 => auctionInformation)) public auctionInfo;
  mapping (address => uint256) public claimableBitmap;

  constructor(address newFactory, address newRegAddr, address stableAddr) {
    factoryAddress = newFactory;
    owner = msg.sender;
    numeraireOfDebt = 0;
    registryAddress = newRegAddr;
    stable = stableAddr;
    claimRatio = claimRatios({protocol: 20, originalOwner: 60, liquidator: 10, reserveFund: 10});
  }

  modifier elevated() {
    require(IFactory(factoryAddress).isVault(msg.sender), "This can only be called by a vault");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
  }

  function setFactory(address newFactory) external onlyOwner {
    factoryAddress = newFactory;
  }

  //function startAuction() modifier = only by vault
  //  sets time start to now()
  //  stores the liquidator
  // 

  function startAuction(address vaultAddress, uint256 life, address liquidator, address originalOwner, uint128 openDebt, uint8 liqThres) public elevated returns (bool) {

    require(auctionInfo[vaultAddress][life].startBlock == 0, "Liquidation already ongoing");

    auctionInfo[vaultAddress][life].startBlock = uint128(block.number);
    auctionInfo[vaultAddress][life].liquidator = liquidator;
    auctionInfo[vaultAddress][life].originalOwner = originalOwner;
    auctionInfo[vaultAddress][life].openDebt = openDebt;
    auctionInfo[vaultAddress][life].liqThres = liqThres;

    return true;
  }

  //function getPrice(assets) view
  // gets the price of assets, equals to oracle price + factor depending on time
   /** 
    @notice Function to check what the value of the items in the vault is.
    @dev 
    @param assetAddresses the vaultAddress 
    @param assetIds the vaultAddress 
    @param assetAmounts the vaultAddress 
  */
  function getPriceOfAssets(address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) public view returns (uint256) {
    uint256 totalValue = IMainRegistry(registryAddress).getTotalValue(assetAddresses, assetIds, assetAmounts, numeraireOfDebt);
    return totalValue;
  }

  // gets the price of assets, equals to oracle price + factor depending on time
   /** 
    @notice Function to buy only a certain asset of a vault in the liquidation process
    @dev 
    @param assetAddresses the vaultAddress 
    @param assetIds the vaultAddress 
    @param assetAmounts the vaultAddress 
  */
  function buyPart(address[] memory assetAddresses, uint256[] memory assetIds, uint256[] memory assetAmounts) public {

  }
   /** 
    @notice Function to check what the current price of the vault being auctioned of is.
    @dev 
    @param vaultAddress the vaultAddress 
  */
  function getPriceOfVault(address vaultAddress, uint256 life) public view returns (uint256, bool) {
    // it's cheaper to look up the struct in the mapping than to take it into memory
    //auctionInformation memory auction = auctionInfo[vaultAddress][life];
    uint256 startPrice = auctionInfo[vaultAddress][life].openDebt * auctionInfo[vaultAddress][life].liqThres / 100;
    uint256 surplusPrice = auctionInfo[vaultAddress][life].openDebt * (auctionInfo[vaultAddress][life].liqThres-100) / 100;
    uint256 priceDecrease = surplusPrice * (block.number - auctionInfo[vaultAddress][life].startBlock) / (hourlyBlocks * auctionDuration);

    if (startPrice < priceDecrease) {
      return (0, false);
    }

    uint256 totalPrice = startPrice - priceDecrease; 
    bool forSale = block.number - auctionInfo[vaultAddress][life].startBlock <= hourlyBlocks * auctionDuration ? true : false;
    return (totalPrice, forSale);
  }
    /** 
    @notice Function a user calls to buy the vault during the auction process. This ends the auction process
    @dev 
    @param vaultAddress the vaultAddress of the vault the user want to buy.
  */

  function buyVault(address vaultAddress, uint256 life) public {
    // it's 3683 gas cheaper to look up the struct 6x in the mapping than to take it into memory
    (uint256 priceOfVault, bool forSale) = getPriceOfVault(vaultAddress, life);

    require(forSale, "Too much time has passed: this vault is not for sale");
    require(auctionInfo[vaultAddress][life].stablePaid < auctionInfo[vaultAddress][life].openDebt, "This vaults debt has already been paid in full!");

    uint256 surplus = priceOfVault - auctionInfo[vaultAddress][life].openDebt;

    require(IStable(stable).safeBurn(msg.sender, auctionInfo[vaultAddress][life].openDebt), "Cannot burn sufficient stable debt");
    require(IStable(stable).transferFrom(msg.sender, address(this), surplus), "Surplus transfer failed");

    auctionInfo[vaultAddress][life].stablePaid = uint128(priceOfVault);
    
    //TODO: fetch vault id.
    IFactory(factoryAddress).safeTransferFrom(address(this), msg.sender, IFactory(factoryAddress).vaultIndex(vaultAddress));
  }
    /** 
    @notice Function a a user can call to check who is eligbile to claim what from an auction vault.
    @dev 
    @param auction the auction
    @param vaultAddress the vaultAddress of the vault the user want to buy.
    @param life the lifeIndex of vault, the keeper wants to claim their reward from
  */
  function claimable(auctionInformation memory auction, address vaultAddress, uint256 life) public view returns (uint256[] memory, address[] memory) {
    claimRatios memory ratios = claimRatio;
    uint256[] memory claimables = new uint256[](4);
    address[] memory claimableBy = new address[](4);
    uint256 claimableBitmapMem = claimableBitmap[vaultAddress];

    uint256 surplus = auction.stablePaid - auction.openDebt;

    claimables[0] = claimableBitmapMem & (1 << 4*life + 0) == 0 ? surplus * ratios.protocol / 100: 0;
    claimables[1] = claimableBitmapMem & (1 << 4*life + 1) == 0 ? surplus * ratios.originalOwner / 100: 0;
    claimables[2] = claimableBitmapMem & (1 << 4*life + 2) == 0 ? surplus * ratios.liquidator / 100: 0;
    claimables[3] = claimableBitmapMem & (1 << 4*life + 3) == 0 ? surplus * ratios.reserveFund / 100: 0;

    claimableBy[0] = address(this);
    claimableBy[1] = auction.originalOwner;
    claimableBy[2] = auction.liquidator;
    claimableBy[3] = reserveFund;

    return (claimables, claimableBy);
  }
    /** 
    @notice Function a eligeble claimer can call to claim the proceeds of the vault they are entitled to.
    @dev 
    @param vaultAddresses vaultAddresses the caller want to claim the proceeds from.
    */
  function claimProceeds(address[] calldata vaultAddresses, uint256[] calldata lives) public {
    uint256 len = vaultAddresses.length;
    require(len == lives.length, "Arrays must be of same length");

    uint256 totalClaimable;
    uint256 claimableBitmapMem;

    uint256[] memory claimables;
    address[] memory claimableBy;
    for (uint256 i; i < len;) {
      address vaultAddress = vaultAddresses[i];
      uint256 life = lives[i];
      auctionInformation memory auction = auctionInfo[vaultAddress][life];
      (claimables, claimableBy) = claimable(auction, vaultAddress, life);
      claimableBitmapMem = claimableBitmap[vaultAddress];

      if (msg.sender == claimableBy[0]) {
        totalClaimable += claimables[0];
        claimableBitmapMem = claimableBitmapMem | (1 << (4*life + 0));
      }
      if (msg.sender == claimableBy[1]) {
        totalClaimable += claimables[1];
        claimableBitmapMem = claimableBitmapMem | (1 << (4*life + 1));
      }
      if (msg.sender == claimableBy[2]) {
        totalClaimable += claimables[2];
        claimableBitmapMem = claimableBitmapMem | (1 << (4*life + 2));
      }
      if (msg.sender == claimableBy[3]) {
        totalClaimable += claimables[3];
        claimableBitmapMem = claimableBitmapMem | (1 << (4*life + 3));
      }

      claimableBitmap[vaultAddress] = claimableBitmapMem;

      unchecked {++i;}
    }

    require(IStable(stable).transferFrom(address(this), msg.sender, totalClaimable));
  }

  //function buy(assets, amounts, ids) payable
  //  fetches price of first provided
  //  if buy-price is >= open debt, close auction & take fees (how?)
  //  (if all assets are bought, transfer vault)
  //  (for purchase that ends auction, give discount?)


}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.






library Printing {
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {

    return string(abi.encodePacked(a, b, c,d, e));

}

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }

function makeString(bytes memory byteCode) internal pure returns(string memory stringData)
{
    uint256 blank = 0; //blank 32 byte value
    uint256 length = byteCode.length;

    uint cycles = byteCode.length / 0x20;
    uint requiredAlloc = length;

    if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
    {
        cycles++;
        requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
    }

    stringData = new string(requiredAlloc);

    //copy data in 32 byte blocks
    assembly {
        let cycle := 0

        for
        {
            let mc := add(stringData, 0x20) //pointer into bytes we're writing to
            let cc := add(byteCode, 0x20)   //pointer to where we're reading from
        } lt(cycle, cycles) {
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
            cycle := add(cycle, 0x01)
        } {
            mstore(mc, mload(cc))
        }
    }

    //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
    if (length % 0x20 > 0)
    {
        uint offsetStart = 0x20 + length;
        assembly
        {
            let mc := add(stringData, offsetStart)
            mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back so the returned object is the correct size
            mstore(stringData, length)
        }
    }
}
}


/** 
  * @title Oracle Hub
  * @author Arcadia Finance
  * @notice The Oracle Hub stores the adressesses and other necessary information of the Oracles
  * @dev No end-user should directly interact with the Main-registry, only the Main Registry, Sub-Registries or the contract owner
 */ 
contract OracleHub is Ownable {
  using FixedPointMathLib for uint256;

  struct OracleInformation {
    uint64 oracleUnit;
    uint8 baseAssetNumeraire;
    bool baseAssetIsNumeraire;
    string quoteAsset;
    string baseAsset;
    address oracleAddress;
    address quoteAssetAddress;
  }
  
  mapping (address => bool) public inOracleHub;
  mapping (address => OracleInformation) public oracleToOracleInformation;

  /**
   * @notice Constructor
   */
  constructor () {}

  /**
   * @notice Add a new oracle to the Oracle Hub
   * @param oracleInformation A Struct with information about the new Oracle
   * @dev It is not possible to overwrite the information of an existing Oracle in the Oracle Hub
   */
  function addOracle(OracleInformation calldata oracleInformation) external onlyOwner { //Need separate function to edit existing oracles?
    address oracleAddress = oracleInformation.oracleAddress;
    require(!inOracleHub[oracleAddress], 'Oracle already in oracle-hub');
    require(oracleInformation.oracleUnit <= 1000000000000000000, 'Oracle can have maximal 18 decimals');
    inOracleHub[oracleAddress] = true;
    oracleToOracleInformation[oracleAddress] = oracleInformation;
  }

  /**
   * @notice Checks if two input strings are identical, if so returns true
   * @param a The first string to be compared
   * @param b The second string to be compared
   * @return stringsMatch Boolean that returns true if both input strings are equal, and false if both strings are different
   */
  function compareStrings(string memory a, string memory b) internal pure returns (bool stringsMatch) {
      if(bytes(a).length != bytes(b).length) {
          return false;
      } else {
          stringsMatch = keccak256(bytes(a)) == keccak256(bytes(b));
      }
  }

  /**
   * @notice Checks if a series of oracles , if so returns true
   * @param oracleAdresses An array of addresses of oracle contracts
   * @dev Function will do nothing if all checks pass, but reverts if at least one check fails.
   *      The following checks are performed:
   *      The oracle-address must be previously added to the Oracle-Hub.
   *      The last oracle in the series must have USD as base-asset.
   *      The Base-asset of all oracles must be equal to the quote-asset of the next oracle (except for the last oracle in the series).
   */
  function checkOracleSequence (address[] memory oracleAdresses) external view {
    uint256 oracleAdressesLength = oracleAdresses.length;
    require(oracleAdressesLength <= 3, "Oracle seq. cant be longer than 3");
    for (uint256 i; i < oracleAdressesLength;) {
      require(inOracleHub[oracleAdresses[i]], "Unknown oracle");
      //Add test that in all other cases, the quote asset of next oracle matches base asset of previous oracle
      if (i > 0) {
        require(compareStrings(oracleToOracleInformation[oracleAdresses[i-1]].baseAsset, oracleToOracleInformation[oracleAdresses[i]].quoteAsset), "qAsset doesnt match with bAsset of prev oracle");
      }
      //Add test that base asset of last oracle is USD
      if (i == oracleAdressesLength-1) {
        require(compareStrings(oracleToOracleInformation[oracleAdresses[i]].baseAsset, "USD"), "Last oracle does not have USD as bAsset");
      }
      unchecked {++i;} 
    }

  }

  /**
   * @notice Returns the exchange rate of a certain asset, denominated in USD or in another Numeraire
   * @param oracleAdresses An array of addresses of oracle contracts
   * @param numeraire The Numeraire (base-asset) in which the exchange rate is ideally expressed
   * @return rateInUsd The exchange rate of the asset denominated in USD with 18 Decimals precision
   * @return rateInNumeraire The exchange rate of the asset denominated in a Numeraire different from USD with 18 Decimals precision
   * @dev The Function will loop over all oracles-addresses and find the total exchange rate of the asset by
   *      multiplying the intermediate exchangerates (max 3) with eachother. Exchange rates can be with any Decimals precision, but smaller than 18.
   *      All intermediate exchange rates are calculated with a precision of 18 decimals and rounded down.
   *      Todo: check precision when multiplying multiple small rates -> go to 27 decimals precision??
   *      The exchange rate of an asset will be denominated in a Numeraire different from USD if and only if
   *      the given Numeraire is different from USD and one of the intermediate oracles to price the asset has
   *      the given numeraire as base-asset
   *      Function will overflow if any of the intermediate or the final exchange rate overflows
   *      Example of 3 oracles with R1 the first exchange rate with D1 decimals and R2 the second exchange rate with D2 decimals R3...
   *        First intermediate rate will overflow when R1 * 10**18 > MAXUINT256
   *        Second rate will overflow when R1 * R2 * 10**(18 - D1) > MAXUINT256
   *        Third and final exchange rate will overflow when R1 * R2 * R3 * 10**(18 - D1 - D2) > MAXUINT256
   */
  function getRate(address[] memory oracleAdresses, uint256 numeraire) public view returns (uint256, uint256) {

    //Scalar 1 with 18 decimals
    uint256 rate = FixedPointMathLib.WAD;
    int256 tempRate;

    uint256 oraclesLength = oracleAdresses.length;

    //taking into memory, saves 209 gas
    address oracleAddressAtIndex;
    for (uint256 i; i < oraclesLength;) {
      oracleAddressAtIndex = oracleAdresses[i];
      (, tempRate,,,) = IChainLinkData(oracleToOracleInformation[oracleAddressAtIndex].oracleAddress).latestRoundData();
      require(tempRate >= 0, "Negative oracle price");

      rate = rate.mulDivDown(uint256(tempRate), oracleToOracleInformation[oracleAddressAtIndex].oracleUnit);

      if (oracleToOracleInformation[oracleAddressAtIndex].baseAssetIsNumeraire && oracleToOracleInformation[oracleAddressAtIndex].baseAssetNumeraire == 0) {
        //If rate is expressed in USD, break loop and return rate expressed in numeraire
        return (rate, 0);
      } else if (oracleToOracleInformation[oracleAddressAtIndex].baseAssetIsNumeraire && oracleToOracleInformation[oracleAddressAtIndex].baseAssetNumeraire == numeraire) {
        //If rate is expressed in numeraire, break loop and return rate expressed in numeraire
        return (0, rate);
      }
      unchecked {++i;}
    }
    revert('No oracle with USD or numeraire as bAsset');
  }

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.




library Constants {
    // Math
    uint256 internal constant UsdNumeraire = 0;
    uint256 internal constant EthNumeraire = 1;
    uint256 internal constant SafemoonNumeraire = 2;

    uint256 internal constant ethDecimals = 12;
    uint256 internal constant ethCreditRatingUsd = 2;
    uint256 internal constant ethCreditRatingBtc = 0;
    uint256 internal constant ethCreditRatingEth = 1;
    uint256 internal constant snxDecimals = 14;
    uint256 internal constant snxCreditRatingUsd = 0;
    uint256 internal constant snxCreditRatingEth = 0;
    uint256 internal constant linkDecimals = 4;
    uint256 internal constant linkCreditRatingUsd = 2;
    uint256 internal constant linkCreditRatingEth = 2;
    uint256 internal constant safemoonDecimals = 18;
    uint256 internal constant safemoonCreditRatingUsd = 0;
    uint256 internal constant safemoonCreditRatingEth = 0;
    uint256 internal constant baycCreditRatingUsd = 4;
    uint256 internal constant baycCreditRatingEth = 3;
    uint256 internal constant maycCreditRatingUsd = 0;
    uint256 internal constant maycCreditRatingEth = 0;
    uint256 internal constant dickButsCreditRatingUsd = 0;
    uint256 internal constant dickButsCreditRatingEth = 0;
    uint256 internal constant interleaveCreditRatingUsd = 0;
    uint256 internal constant interleaveCreditRatingEth = 0;
    uint256 internal constant wbaycDecimals = 16;
    uint256 internal constant wmaycDecimals = 14;

    uint256 internal constant oracleEthToUsdDecimals = 8;
    uint256 internal constant oracleLinkToUsdDecimals = 8;
    uint256 internal constant oracleSnxToEthDecimals = 18;
    uint256 internal constant oracleWbaycToEthDecimals = 18;
    uint256 internal constant oracleWmaycToUsdDecimals = 8;
    uint256 internal constant oracleInterleaveToEthDecimals = 10;
    uint256 internal constant oracleStableToUsdDecimals = 12;
    uint256 internal constant oracleStableEthToEthDecimals = 14;

    uint256 internal constant oracleEthToUsdUnit = 10**oracleEthToUsdDecimals;
    uint256 internal constant oracleLinkToUsdUnit = 10**oracleLinkToUsdDecimals;
    uint256 internal constant oracleSnxToEthUnit = 10**oracleSnxToEthDecimals;
    uint256 internal constant oracleWbaycToEthUnit = 10**oracleWbaycToEthDecimals;
    uint256 internal constant oracleWmaycToUsdUnit = 10**oracleWmaycToUsdDecimals;
    uint256 internal constant oracleInterleaveToEthUnit = 10**oracleInterleaveToEthDecimals;
    uint256 internal constant oracleStableToUsdUnit = 10**oracleStableToUsdDecimals;
    uint256 internal constant oracleStableEthToEthUnit = 10**oracleStableEthToEthDecimals;

    uint256 internal constant usdDecimals = 14;
    uint256 internal constant stableDecimals = 18;
    uint256 internal constant stableEthDecimals = 18;

    uint256 internal constant WAD = 1e18;
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





contract StableOracle is Ownable {

	uint80 private roundId;
	int256 private answer;
	uint256 private startedAt;
	uint256 private updatedAt;
	uint80 private answeredInRound;

  uint8 public decimals;
  string public description;

  constructor (uint8 _decimals, string memory _description) {
		decimals = _decimals;
		description = _description;
		answer = int256(10 ** _decimals);
  }

  function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
    return (roundId, answer, startedAt, updatedAt, answeredInRound);
  }
  
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





contract SimplifiedChainlinkOracle is Ownable {

	uint80 private roundId;
	int256 private answer;
	uint256 private startedAt;
	uint256 private updatedAt;
	uint80 private answeredInRound;

  uint8 public decimals;
  string public description;

  constructor (uint8 _decimals, string memory _description) {
		decimals = _decimals;
		description = _description;
  }

  function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
    return (roundId, answer, startedAt, updatedAt, answeredInRound);
  }

	function setAnswer(int256 _answer) external onlyOwner {
		answer = _answer;
	}
  
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.




// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





interface IERC20PaperTrading is IERC20 {

}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





interface IERC721PaperTrading is IERC721 {
  function mint(address to, uint256 id) external;
  function burn(uint256 id) external;
}
// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





interface IERC1155PaperTrading is IERC1155 {
  function mint(address to, uint256 id, uint256 amount) external;
  function burn(uint256 id, uint256 amount) external;
  }

// This is a private, unpublished repository.
// All rights reserved to Arcadia Finance.
// Any modification, publication, reproduction, commercialisation, incorporation, sharing or any other kind of use of any part of this code or derivatives thereof is not allowed.





interface IFactoryPaperTrading is IFactory {
  function getVaultAddress(uint256 id) external view returns(address);
}





/** 
  * @title Token Shop
  * @author Arcadia Finance
  * @notice Mocked Exchange for the Arcadia Paper Trading Game
  * @dev For testnet purposes only
 */ 

contract TokenShop is Ownable {
  using FixedPointMathLib for uint256;

  address public factory;
  address public mainRegistry;

  struct SwapInput {
    address[] tokensIn;
    uint256[] idsIn;
    uint256[] amountsIn;
    uint256[] assetTypesIn;
    address[] tokensOut;
    uint256[] idsOut;
    uint256[] amountsOut;
    uint256[] assetTypesOut;
    uint256 vaultId;
  }

  constructor (address _mainRegistry) {
    mainRegistry = _mainRegistry;
  }

  /**
   * @dev Sets the new Factory address
   * @param _factory The address of the Factory
   */
  function setFactory(address _factory) public {
    factory = _factory;
  }

  function swapExactTokensForTokens(SwapInput calldata swapInput) external {
    require(msg.sender == IERC721(factory).ownerOf(swapInput.vaultId), "You are not the owner");
    address vault = IFactoryPaperTrading(factory).getVaultAddress(swapInput.vaultId);
    (,,,,,uint8 numeraire) = IVaultPaperTrading(vault).debt();

    uint256 totalValueIn = IMainRegistry(mainRegistry).getTotalValue(swapInput.tokensIn, swapInput.idsIn, swapInput.amountsIn, numeraire);
    uint256 totalValueOut = IMainRegistry(mainRegistry).getTotalValue(swapInput.tokensOut, swapInput.idsOut, swapInput.amountsOut, numeraire);
    require (totalValueIn >= totalValueOut, "Not enough funds");

    IVaultPaperTrading(vault).withdraw(swapInput.tokensIn, swapInput.idsIn, swapInput.amountsIn, swapInput.assetTypesIn);
    _burn(swapInput.tokensIn, swapInput.idsIn, swapInput.amountsIn, swapInput.assetTypesIn);
    _mint(swapInput.tokensOut, swapInput.idsOut, swapInput.amountsOut, swapInput.assetTypesOut);
    IVaultPaperTrading(vault).deposit(swapInput.tokensOut, swapInput.idsOut, swapInput.amountsOut, swapInput.assetTypesOut);

    if (totalValueIn > totalValueOut) {
      uint256 amountNumeraire = totalValueIn - totalValueOut;
      address stable = IVaultPaperTrading(vault)._stable();
      _mintERC20(stable, amountNumeraire);

      address[] memory stableArr = new address[](1);
      uint256[] memory stableIdArr = new uint256[](1);
      uint256[] memory stableAmountArr = new uint256[](1);
      uint256[] memory stableTypeArr = new uint256[](1);

      stableArr[0] = stable;
      stableIdArr[0] = 0; //can delete
      stableAmountArr[0] = amountNumeraire;
      stableTypeArr[0] = 0; //can delete

      IVaultPaperTrading(vault).deposit(stableArr, stableIdArr, stableAmountArr, stableTypeArr);
    }

  }

  function _mint(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) internal {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");
    
    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        _mintERC20(assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        _mintERC721(assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        _mintERC1155(assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

  }

  function _burn(address[] calldata assetAddresses, uint256[] calldata assetIds, uint256[] calldata assetAmounts, uint256[] calldata assetTypes) internal {
    uint256 assetAddressesLength = assetAddresses.length;

    require(assetAddressesLength == assetIds.length &&
             assetAddressesLength == assetAmounts.length &&
             assetAddressesLength == assetTypes.length, "Length mismatch");
    
    for (uint256 i; i < assetAddressesLength;) {
      if (assetTypes[i] == 0) {
        _burnERC20(assetAddresses[i], assetAmounts[i]);
      }
      else if (assetTypes[i] == 1) {
        _burnERC721(assetAddresses[i], assetIds[i]);
      }
      else if (assetTypes[i] == 2) {
        _burnERC1155(assetAddresses[i], assetIds[i], assetAmounts[i]);
      }
      else {
        require(false, "Unknown asset type");
      }
      unchecked {++i;}
    }

  }

  function _mintERC20(address tokenAddress, uint256 tokenAmount) internal {
    IERC20PaperTrading(tokenAddress).mint(address(this), tokenAmount);
  }

  function _mintERC721(address tokenAddress, uint256 tokenId) internal {
    IERC721PaperTrading(tokenAddress).mint(address(this), tokenId);
  }

  function _mintERC1155(address tokenAddress, uint256 tokenId, uint256 tokenAmount) internal {
    IERC1155PaperTrading(tokenAddress).mint(address(this), tokenId, tokenAmount);
  }

  function _burnERC20(address tokenAddress, uint256 tokenAmount) internal {
    IERC20PaperTrading(tokenAddress).burn(tokenAmount);
  }

  function _burnERC721(address tokenAddress, uint256 tokenId) internal {
    IERC721PaperTrading(tokenAddress).burn(tokenId);
  }

  function _burnERC1155(address tokenAddress, uint256 tokenId, uint256 tokenAmount) internal {
    IERC1155PaperTrading(tokenAddress).burn(tokenId, tokenAmount);
  }

}


contract DeployContracts  {

  FactoryPaperTrading public factory;
  VaultPaperTrading public vault;
  VaultPaperTrading public proxy;
  address public proxyAddr;
  
  OracleHub public oracleHub;
  MainRegistry public mainRegistry;
  StandardERC20Registry public standardERC20Registry;
  FloorERC721SubRegistry public floorERC721Registry;
  InterestRateModule public interestRateModule;
  StablePaperTrading public stableUsd;
  StablePaperTrading public stableEth;
  StableOracle public oracleStableUsdToUsd;
  StableOracle public oracleStableEthToEth;
  Liquidator public liquidator;
  TokenShop public tokenShop;

  ERC20PaperTrading public weth;

  SimplifiedChainlinkOracle public oracleEthToUsd;

  address private creatorAddress = address(1);
  address private tokenCreatorAddress = address(2);
  address private oracleOwner = address(3);
  address private unprivilegedAddress = address(4);
  address private stakeContract = address(5);
  address private vaultOwner = address(6);

  uint256 rateEthToUsd = 3000 * 10 ** Constants.oracleEthToUsdDecimals;

  address[] public oracleEthToUsdArr = new address[](1);
  address[] public oracleStableToUsdArr = new address[](1);

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
  }

  //this is a before
  constructor() {
    owner = msg.sender;
    factory = new FactoryPaperTrading();
    factory.setBaseURI("ipfs://");

    stableUsd = new StablePaperTrading("Arcadia USD Stable Mock", "masUSD", uint8(Constants.stableDecimals), 0x0000000000000000000000000000000000000000, address(factory));
    stableEth = new StablePaperTrading("Arcadia ETH Stable Mock", "masETH", uint8(Constants.stableEthDecimals), 0x0000000000000000000000000000000000000000, address(factory));

    oracleEthToUsd = new SimplifiedChainlinkOracle(uint8(Constants.oracleEthToUsdDecimals), "ETH / USD");
    oracleEthToUsd.setAnswer(int256(rateEthToUsd));

    // stableUsd.setFactory(address(factory));
    // stableEth.setFactory(address(factory));

    oracleStableUsdToUsd = new StableOracle(uint8(Constants.oracleStableToUsdDecimals), "masUSD / USD");
    oracleStableEthToEth = new StableOracle(uint8(Constants.oracleStableEthToEthUnit), "masEth / Eth");

    mainRegistry = new MainRegistry(MainRegistry.NumeraireInformation({numeraireToUsdOracleUnit:0, assetAddress:0x0000000000000000000000000000000000000000, numeraireToUsdOracle:0x0000000000000000000000000000000000000000, stableAddress:address(stableUsd), numeraireLabel:'USD', numeraireUnit:1}));

    liquidator = new Liquidator(address(factory), address(mainRegistry), address(stableUsd));
    stableUsd.setLiquidator(address(liquidator));
    stableEth.setLiquidator(address(liquidator));

    tokenShop = new TokenShop(address(mainRegistry));
    weth = new ERC20PaperTrading("ETH Mock", "mETH", uint8(Constants.ethDecimals), address(tokenShop));

    oracleHub = new OracleHub();

    standardERC20Registry = new StandardERC20Registry(address(mainRegistry), address(oracleHub));
    mainRegistry.addSubRegistry(address(standardERC20Registry));

    floorERC721Registry = new FloorERC721SubRegistry(address(mainRegistry), address(oracleHub));
    mainRegistry.addSubRegistry(address(floorERC721Registry));


    oracleEthToUsdArr[0] = address(oracleEthToUsd);
    oracleStableToUsdArr[0] = address(oracleStableUsdToUsd);

    interestRateModule = new InterestRateModule();
    interestRateModule.setBaseInterestRate(5 * 10 ** 16);

    vault = new VaultPaperTrading();
    factory.setNewVaultInfo(address(mainRegistry), address(vault), stakeContract, address(interestRateModule));
    factory.confirmNewVaultInfo();
    factory.setLiquidator(address(liquidator));
    liquidator.setFactory(address(factory));
    mainRegistry.setFactory(address(factory));


  }

  function createVault() public onlyOwner {
    proxyAddr = factory.createVault(uint256(keccak256(abi.encodeWithSignature("doRandom(uint256,uint256,bytes32)", block.timestamp, block.number, blockhash(block.number)))), 0);
    proxy = VaultPaperTrading(proxyAddr);
  }


  struct assetInfo {
    string desc;
    string symbol;
    uint8 decimals;
    uint8 oracleDecimals;
    uint128 rate;
    string quoteAsset;
    address oracleAddr;
    address assetAddr;
  }

  assetInfo[] public assets;
  function storeStructs() public onlyOwner {
    assets.push(assetInfo({desc: "Wrapped Ether - Mock", symbol: "mwETH", decimals: uint8(Constants.ethDecimals), rate: uint128(rateEthToUsd), oracleDecimals: uint8(Constants.oracleEthToUsdDecimals), quoteAsset: "ETH", oracleAddr: address(oracleEthToUsd), assetAddr: address(weth)}));
    
    assets.push(assetInfo({desc: "Wrapped BTC - Mock", symbol: "mwBTC", decimals: 8, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "BTC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "USD Coin - Mock", symbol: "mUSDC", decimals: 6, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "USDC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "SHIBA INU - Mock", symbol: "mSHIB", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "SHIB", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Matic Token - Mock", symbol: "mMATIC", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "MATIC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Cronos Coin - Mock", symbol: "mCRO", decimals: 8, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CRO", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Uniswap - Mock", symbol: "mUNI", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "UNI", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "ChainLink Token - Mock", symbol: "mLINK", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "LINK", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "FTX Token - Mock", symbol: "mFTT", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "FTT", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "ApeCoin - Mock", symbol: "mAPE", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "APE", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "The Sandbox - Mock", symbol: "mSAND", decimals: 8, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "SAND", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Decentraland - Mock", symbol: "mMANA", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "MANA", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Axie Infinity - Mock", symbol: "mAXS", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "AXS", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Aave - Mock", symbol: "mAAVE", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "AAVE", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Fantom - Mock", symbol: "mFTM", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "FTM", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "KuCoin Token  - Mock", symbol: "mKCS", decimals: 6, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "KCS", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Maker - Mock", symbol: "mMKR", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "MKR", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Dai - Mock", symbol: "mDAI", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "DAI", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Convex Finance - Mock", symbol: "mCVX", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CVX", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Curve DAO Token - Mock", symbol: "mCRV", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CRV", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Loopring - Mock", symbol: "mLRC", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "LRC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "BAT - Mock", symbol: "mBAT", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "BAT", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Amp - Mock", symbol: "mAMP", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "AMP", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Compound - Mock", symbol: "mCOMP", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "COMP", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "1INCH Token - Mock", symbol: "m1INCH", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "1INCH", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Gnosis - Mock", symbol: "mGNO", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "GNO", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "OMG Network - Mock", symbol: "mOMG", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "OMG", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Bancor - Mock", symbol: "mBNT", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "BNT", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Celsius Network - Mock", symbol: "mCEL", decimals: 4, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CEL", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Ankr Network - Mock", symbol: "mANKR", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "ANKR", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Frax Share  - Mock", symbol: "mFXS", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "FXS", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Immutable X - Mock", symbol: "mIMX", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "IMX", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Ethereum Name Service  - Mock", symbol: "mENS", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "ENS", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "SushiToken - Mock", symbol: "mSUSHI", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "SUSHI", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "dYdX - Mock", symbol: "mDYDX", decimals: 18, rate:  uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "DYDX", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "CelerToken - Mock", symbol: "mCELR", decimals: 18, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CEL", oracleAddr: address(0), assetAddr: address(0)}));
  
    assets.push(assetInfo({desc: "CRYPTOPUNKS - Mock", symbol: "mC", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "PUNK", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "BoredApeYachtClub - Mock", symbol: "mBAYC", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "BAYC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "MutantApeYachtClub - Mock", symbol: "mMAYC", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "MAYC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "CloneX - Mock", symbol: "mCloneX", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "CloneX", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Loot - Mock", symbol: "mLOOT", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "LOOT", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Sandbox's LANDs - Mock", symbol: "mLAND", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "LAND", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Cool Cats - Mock", symbol: "mCOOL", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "COOL", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Azuki - Mock", symbol: "mAZUKI", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "AZUKI", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Doodles - Mock", symbol: "mDOODLE", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "DOODLE", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Meebits - Mock", symbol: "mMEEBIT", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "MEEBIT", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "CyberKongz - Mock", symbol: "mKONGZ", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "KONGZ", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "BoredApeKennelClub - Mock", symbol: "mBAKC", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "BAKC", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Decentraland LAND - Mock", symbol: "mLAND", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "LAND", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Timeless - Mock", symbol: "mTMLS", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "TMLS", oracleAddr: address(0), assetAddr: address(0)}));
    assets.push(assetInfo({desc: "Treeverse - Mock", symbol: "mTRV", decimals: 0, rate: uint128(rateEthToUsd), oracleDecimals: 8, quoteAsset: "TRV", oracleAddr: address(0), assetAddr: address(0)}));
  }

  function deployERC20Contracts() public onlyOwner {
    address newContr;
    assetInfo memory asset;
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      if (asset.decimals == 0) { }
      else {
        newContr = address(new ERC20PaperTrading(asset.desc, asset.symbol, asset.decimals, address(tokenShop)));
        assets[i].assetAddr = newContr;
       }
      
    }
  }

  function deployERC721Contracts() public onlyOwner {
    address newContr;
    assetInfo memory asset;
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      if (asset.decimals == 0) {
        newContr = address(new ERC721PaperTrading(asset.desc, asset.symbol, address(tokenShop)));
        assets[i].assetAddr = newContr;
      }
      else { }
      
    }
  }

  function deployOracles() public onlyOwner {
    address newContr;
    assetInfo memory asset;
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      newContr = address(new SimplifiedChainlinkOracle(asset.oracleDecimals, string(abi.encodePacked(asset.quoteAsset, " / USD"))));
      assets[i].oracleAddr = newContr;
    }

    uint256[] memory emptyList = new uint256[](0);
    mainRegistry.addNumeraire(MainRegistry.NumeraireInformation({numeraireToUsdOracleUnit:uint64(10**Constants.oracleEthToUsdDecimals), assetAddress:address(weth), numeraireToUsdOracle:address(oracleEthToUsd), stableAddress:address(stableUsd), numeraireLabel:'ETH', numeraireUnit:uint64(10**Constants.ethDecimals)}), emptyList);

  }

  function setOracleAnswers() public onlyOwner {
    assetInfo memory asset;
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      SimplifiedChainlinkOracle(asset.oracleAddr).setAnswer(int256(uint256(asset.rate)));
    }
  }

  function addOracles() public onlyOwner {
    assetInfo memory asset;
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit: uint64(10**asset.oracleDecimals), baseAssetNumeraire: 0, quoteAsset: asset.quoteAsset, baseAsset: "USD", oracleAddress: asset.oracleAddr, quoteAssetAddress: asset.assetAddr, baseAssetIsNumeraire: true}));
    }

    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit: uint64(10**18), baseAssetNumeraire: 0, quoteAsset: "STABLE", baseAsset: "USD", oracleAddress: address(oracleStableUsdToUsd), quoteAssetAddress: address(0), baseAssetIsNumeraire: true}));

  }

  function setAssetInformation() public onlyOwner {
    assetInfo memory asset;
    uint256[] memory emptyList = new uint256[](0);
    address[] memory genOracleArr = new address[](1);
    for (uint i; i < assets.length; ++i) {
      asset = assets[i];
      genOracleArr[0] = asset.oracleAddr;
      if (asset.decimals == 0) {
        floorERC721Registry.setAssetInformation(FloorERC721SubRegistry.AssetInformation({oracleAddresses: genOracleArr, idRangeStart:0, idRangeEnd:type(uint256).max, assetAddress: asset.assetAddr}), emptyList);
      }
      else {
        standardERC20Registry.setAssetInformation(StandardERC20Registry.AssetInformation({oracleAddresses: genOracleArr, assetUnit: uint64(10**asset.decimals), assetAddress: asset.assetAddr}), emptyList);
        }
    }

    // genOracleArr[0] = address(oracleStableToUsd);
    // standardERC20Registry.setAssetInformation(StandardERC20Registry.AssetInformation({oracleAddresses: genOracleArr, assetUnit: uint64(10**Constants.stableDecimals), assetAddress: address(stableUsd)}), emptyList);

  }

  function returnAssets() public view returns (assetInfo[] memory) {
    return assets;
  }

  function verify() public returns (bool) {
    storeStructs();
    deployERC20Contracts();
    deployERC721Contracts();
    deployOracles();
    setOracleAnswers();
    addOracles();
    setAssetInformation();

    require(checkAddressesInit(), "Verification: addresses not inited");
    require(checkFactory(), "Verification: factory not set");
    require(checkStables(), "Verification: Stables not set");
    require(checkTokenShop(), "Verification: tokenShop not set");
    require(checkLiquidator(), "Verification: Liquidator not set");
    require(checkSubregs(), "Verification: Subregs not set");

    return true;
  }

  function checkMainreg() public view returns (bool) {
    require(mainRegistry.isSubRegistry(address(standardERC20Registry)), "MR: ERC20SR not set");
    require(mainRegistry.isSubRegistry(address(floorERC721Registry)), "MR: ERC721SR not set");
    require(mainRegistry.factoryAddress() == address(factory), "MR: fact not set");

    uint64 numeraireToUsdOracleUnit;
    uint64 numeraireUnit;
    address assetAddress;
    address numeraireToUsdOracle;
    address stableAddress;
    string memory numeraireLabel;

    uint256 numCounter = mainRegistry.numeraireCounter();
    require(numCounter > 0);
    for (uint i; i < numCounter; ++i) {
      (numeraireToUsdOracleUnit, numeraireUnit, assetAddress, numeraireToUsdOracle, stableAddress, numeraireLabel) = mainRegistry.numeraireToInformation(0);
      require(numeraireToUsdOracleUnit != 0 && 
              numeraireUnit != 0 && 
              assetAddress != address(0) && 
              numeraireToUsdOracle != address(0) && 
              stableAddress != address(0) && 
              bytes(numeraireLabel).length != 0, "MR: num 0 not set");
    }

    return true;
  }

  function checkSubregs() public view returns (bool) {
    require(standardERC20Registry._mainRegistry() == address(mainRegistry), "ERC20SR: mainreg not set");
    require(floorERC721Registry._mainRegistry() == address(mainRegistry), "ERC721SR: mainreg not set");
    require(standardERC20Registry._oracleHub() == address(oracleHub), "ERC20SR: OH not set");
    require(floorERC721Registry._oracleHub() == address(oracleHub), "ERC721SR: OH not set");

    return true;
  }

  function checkLiquidator() public view returns (bool) {
    require(liquidator.registryAddress() == address(mainRegistry), "Liq: mainreg not set");
    require(liquidator.factoryAddress() == address(factory), "Liq: fact not set");
    require(liquidator.stable() == address(stableUsd), "Liq: stable not set");

    return true;
  }

  function checkTokenShop() public view returns (bool) {
    require(tokenShop.mainRegistry() == address(mainRegistry), "TokenShop: mainreg not set");

    return true;
  }

  function checkStables() public view returns (bool) {
    require(stableUsd.liquidator() == address(liquidator), "StableUSD: liq not set");
    require(stableUsd.factory() == address(factory), "StableUSD: fact not set");
    require(stableEth.liquidator() == address(liquidator), "StableETH: liq not set");
    require(stableEth.factory() == address(factory), "StableETH: fact not set");

    return true;
  }

  function checkFactory() public view returns (bool) {
    require(bytes(factory.baseURI()).length != 0, "FTRY: baseURI not set");
    uint256 numCountFact = factory.numeraireCounter();
    require(numCountFact == mainRegistry.numeraireCounter(), "FTRY: numCountFact != numCountMR");
    require(factory.liquidatorAddress() != address(0), "FTRY: LiqAddr not set");
    require(factory.newVaultInfoSet() == false, "FTRY: newVaultInfo still set");
    require(factory.getCurrentRegistry() == address(mainRegistry), "FTRY: mainreg not set");
    (, address factLogic, address factStake, address factIRM) = factory.vaultDetails(factory.currentVaultVersion());
    require(factLogic == address(vault), "FTRY: vaultLogic not set");
    require(factStake == address(stakeContract), "FTRY: stakeContr not set");
    require(factIRM == address(interestRateModule), "FTRY: IRM not set");
    for (uint256 i; i < numCountFact; ++i) {
      require(factory.numeraireToStable(i) != address(0), string(abi.encodePacked("FTRY: numToStable not set for", Strings.toString(i))));
    }

    return true;
  }

  error AddressNotInitialised();
  function checkAddressesInit() public view returns (bool) {
    require(owner != address(0), "AddrCheck: owner not set");
    require(address(factory) != address(0), "AddrCheck: factory not set");
    require(address(vault) != address(0), "AddrCheck: vault not set");
    require(address(oracleHub) != address(0), "AddrCheck: oracleHub not set");
    require(address(mainRegistry) != address(0), "AddrCheck: mainRegistry not set");
    require(address(standardERC20Registry) != address(0), "AddrCheck: standardERC20Registry not set");
    require(address(floorERC721Registry) != address(0), "AddrCheck: floorERC721Registry not set");
    require(address(interestRateModule) != address(0), "AddrCheck: interestRateModule not set");
    require(address(stableUsd) != address(0), "AddrCheck: stableUsd not set");
    require(address(stableEth) != address(0), "AddrCheck: stableEth not set");
    require(address(oracleStableUsdToUsd) != address(0), "AddrCheck: oracleStableUsdToUsd not set");
    require(address(oracleStableEthToEth) != address(0), "AddrCheck: oracleStableEthToEth not set");
    require(address(liquidator) != address(0), "AddrCheck: liquidator not set");
    require(address(tokenShop) != address(0), "AddrCheck: tokenShop not set");
    require(address(weth) != address(0), "AddrCheck: weth not set");
    require(address(oracleEthToUsd) != address(0), "AddrCheck: oracleEthToUsd not set");

    return true;
  }

}

