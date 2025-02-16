// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    
    // 주소별 잔액
    mapping(address => uint256) public balanceOf;
    // 주소별 allowance
    mapping(address => mapping(address => uint256)) public allowance;
    // EIP-2612용 nonce: 주소별로 관리해야 함
    mapping(address => uint256) public nonces;

    // Pausable 관련
    bool public paused;
    address public owner;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        totalSupply = 1000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;

        // 오너 설정
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!paused, "PAUSED");
        require(balanceOf[msg.sender] >= _value, "INSUFFICIENT_BALANCE");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!paused, "PAUSED");
        require(balanceOf[_from] >= _value, "INSUFFICIENT_BALANCE");
        require(allowance[_from][msg.sender] >= _value, "INSUFFICIENT_ALLOWANCE");
        
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!paused, "PAUSED");
        allowance[msg.sender][_spender] += _value;
        return true;
    }

    function pause() public {
        require(msg.sender == owner, "NOT_OWNER");
        paused = true;
    }

    // EIP-712 Typed Data Hash
    // 여기서 도메인 구분자는 제외했음
    function _toTypedDataHash(bytes32 structHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", structHash));
    }

    // EIP-2612 Permit
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // 만료시간 체크
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");

        // 현재 owner_의 nonce
        uint256 currentNonce = nonces[owner_];

        // EIP-712 structHash
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner_,
                spender,
                value,
                currentNonce,
                deadline
            )
        );

        bytes32 hash = _toTypedDataHash(structHash);

        // ecrecover로 서명자 복원
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner_, "INVALID_SIGNER");

        // nonce 사용 후 1 증가
        nonces[owner_] = currentNonce + 1;

        // approve
        _approve(owner_, spender, value);
    }

    function _approve(address owner_, address spender, uint256 value) internal {
        allowance[owner_][spender] = value;
    }

}
