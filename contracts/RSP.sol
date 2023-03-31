pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";

contract RSP {
    // Maximun deposit on balance
    // 1 billion ETH
    uint public balance_maxDeposit = 1000000000 ether;

    // Maximum one pay deposit (without fee extracted)
    // 1 million ETH
    uint public balance_maxOnePayDeposit = 1000000 ether;

    // Minimum one pay deposit (without fee extracted)
    // 100 WEI
    uint public balance_minOnePayDeposit = 100 wei;

    // For every balance_extractDepositFeePerWei wei in deposit fee will be extracted
    uint public balance_extractDepositFeePerWei = 100 wei;

    // Fee per balance_extractDepositFeePerWei wei in deposit
    // 1 WEI
    uint public balance_depositFeePerWei = 1 wei;

    // Minimum fee for every deposit
    // 10 WEI
    uint public balance_depositMinFee = 10 wei;

    // Maximum rooms for player at one time
    // 10
    uint public rooms_playerMaxOwnRoomsCount = 10;

    // Maximum rooms for player at one time
    // 10
    uint public rooms_playerMaxParticipatedRoomsCount = 10;

    // Maximum amount of bet for game room
    // 1 million ETH
    uint public room_maxBet = 1000000 ether;

    enum GameState {
        free,
        waitingForSecondPlayer,
        committing,
        revealing,
        ended
    }

    enum GameResult {
        draw,
        firstPlayerWon,
        secondPlayerWon
    }

    struct PlayerInRoom {
        address player;
        bytes32 commit;
        uint choice;
    }

    struct Room {
        PlayerInRoom firstPlayer;
        PlayerInRoom secondPlayer;

        uint bet;

        GameState gameState;
        GameResult gameResult;
    }

    struct PlayerRoomsInfo {
        uint[] ownRoomsIds;
        uint[] participatedRoomsIds;
    }

    address private _owner;
    uint private _accumulatedFee;

    mapping (address => uint) private _balances;

    mapping (uint => Room) private _rooms;
    uint[] private _waitingRoomsIds;
    mapping (address => PlayerRoomsInfo) private _playersRoomsInfos;

    constructor() {
        _owner = msg.sender;
    }

    function getAccumulatedFee() external view isOwner returns (uint) {
        return _accumulatedFee;
    }

    function withdrawAccumulatedFee(uint _amount) external isOwner {
        require (_accumulatedFee >= _amount, "Accumulated fee is lower than amount");
        _accumulatedFee -= _amount;
        _transfer(_owner, _amount);
    }

    function getBalance() external view returns (uint) {
        return _balances[msg.sender];
    }

    function deposit() external payable {
        require (msg.value >= balance_minOnePayDeposit, "Deposit is lower than one pay minimum");
        require (msg.value <= balance_maxOnePayDeposit, "Deposit is greater than one pay maximum");

        uint balance = _balances[msg.sender] + _collectFee(msg.value);
        require(balance <= balance_maxDeposit, "This deposit will overflow max deposit value, reverting");
        _balances[msg.sender] += balance;
    }

    function withdraw(uint _amount) external requireBalance(_amount) {
        _balances[msg.sender] -= _amount;
        _transfer(msg.sender, _amount);
    }

    function getWaitingRoomsIds() external view returns (uint[] memory) {
        return _waitingRoomsIds;
    }

    function getRoomState(uint _roomId) external view returns (GameState) {
        return _rooms[_roomId].gameState;
    }

    function getOwnRoomsIds() external view returns (uint[] memory) {
        return _playersRoomsInfos[msg.sender].ownRoomsIds;
    }

    function getParticipatedRoomsIds() external view returns (uint[] memory) {
        return _playersRoomsInfos[msg.sender].participatedRoomsIds;
    }

    function isRoomFree(uint _roomId) external view
    requireRoomState(_roomId, GameState.free) returns (bool)
    {
        return true;
    }

    function createRoom(uint _bet, uint _roomId) external
    requireBalance(_bet) requireRoomState(_roomId, GameState.free)
    {
        PlayerRoomsInfo storage roomsInfo = _playersRoomsInfos[msg.sender];
        require (
            roomsInfo.ownRoomsIds.length < rooms_playerMaxOwnRoomsCount,
            "Max own rooms count reached"
        );
        _balances[msg.sender] -= _bet;

        Room memory room = Room({
            firstPlayer: _createPlayerInRoom(msg.sender),
            secondPlayer: _createPlayerInRoom(address(0x0)),
            bet: _bet,
            gameState: GameState.waitingForSecondPlayer,
            gameResult: GameResult.draw
        });

        _rooms[_roomId] = room;
        roomsInfo.ownRoomsIds.push(_roomId);
        _waitingRoomsIds.push(_roomId);
    }

    function participateInRoom(uint _roomId) external
    requireRoomState(_roomId, GameState.waitingForSecondPlayer) requireBalance(_rooms[_roomId].bet)
    {
        PlayerRoomsInfo storage roomsInfo = _playersRoomsInfos[msg.sender];
        require (
            roomsInfo.participatedRoomsIds.length < rooms_playerMaxParticipatedRoomsCount,
            "Max participated rooms count reached"
        );

        Room storage room = _rooms[_roomId];
        require (room.firstPlayer.player != msg.sender, "Can't participate in room created by yourself");
        room.secondPlayer.player = msg.sender;
        room.gameState = GameState.committing;
        _balances[msg.sender] -= room.bet;

        roomsInfo.participatedRoomsIds.push(_roomId);
        _removeFromArray(_waitingRoomsIds, _roomId);
    }

    function commit(uint _roomId, bytes32 _commit) external isPlayer(_roomId)
    {
        (Room storage room, PlayerInRoom storage player) = _getRoomAndPlayer(_roomId, GameState.committing);

        require (player.commit == 0, "Already committed");
        player.commit = _commit;

        if (room.firstPlayer.commit != 0 && room.secondPlayer.commit != 0) {
            room.gameState = GameState.revealing;
        }
    }

    // 1 - Rock, 2 - Scissors, 3 - Paper
    function reveal(uint _roomId, uint _choice, string calldata _salt) external isPlayer(_roomId)
    {
        (Room storage room, PlayerInRoom storage player) = _getRoomAndPlayer(_roomId, GameState.revealing);

        require (player.choice == 0, "Already revealed");
        _verifyReveal(player.commit, _choice, _salt);
        player.choice = _choice;

        _tryEndGame(room);
    }

    function endGame(uint _roomId) external requireRoomState(_roomId, GameState.ended) {
        Room storage room = _rooms[_roomId];

        if (room.gameResult == GameResult.firstPlayerWon) {
            _balances[room.firstPlayer.player] += room.bet * 2;
        } else if (room.gameResult == GameResult.secondPlayerWon) {
            _balances[room.secondPlayer.player] += room.bet * 2;
        } else if (room.gameResult == GameResult.draw) {
            _balances[room.firstPlayer.player] += room.bet;
            _balances[room.secondPlayer.player] += room.bet;
        }

        _removeFromArray(_playersRoomsInfos[room.firstPlayer.player].ownRoomsIds, _roomId);
        _removeFromArray(_playersRoomsInfos[room.secondPlayer.player].participatedRoomsIds, _roomId);
        delete _rooms[_roomId];
    }

    function concede(uint _roomId) external isPlayer(_roomId)
    {
        (Room storage room, PlayerInRoom storage player) = _getRoomAndPlayer(_roomId, GameState.revealing);

        require (player.choice == 0, "Already revealed");
        player.choice = 100;

        _tryEndGame(room);
    }

    function _removeFromArray(uint[] storage _array, uint _element) private {
        uint index = 0;
        bool found = false;
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _element) {
                index = i;
                found = true;
                break;
            }
        }
        if (!found) {
            return;
        }
        _array[index] = _array[_array.length - 1];
        _array.pop();
    }

    function _createPlayerInRoom(address _player) private pure returns(PlayerInRoom memory) {
        return PlayerInRoom({
        player: _player,
        commit: 0,
        choice: 0
        });
    }

    function _getRoomAndPlayer(uint _roomId, GameState requiredState) private view
    requireRoomState(_roomId, requiredState) returns (Room storage, PlayerInRoom storage)
    {
        Room storage room = _rooms[_roomId];
        PlayerInRoom storage player = msg.sender == room.firstPlayer.player
        ? room.firstPlayer
        : room.secondPlayer;

        return (room, player);
    }

    function _verifyReveal(bytes32 committedHash, uint _choice, string calldata _salt) private pure {
        bytes32 hash = keccak256(abi.encodePacked(_choice, _salt));
        require (committedHash == hash, "Incorrect choice or salt");
    }

    function _tryEndGame(Room storage _room) private {
        require (_room.gameState != GameState.ended, "Game is already ended");
        PlayerInRoom storage firstPlayer = _room.firstPlayer;
        PlayerInRoom storage secondPlayer = _room.secondPlayer;
        if (firstPlayer.choice == 0 || secondPlayer.choice == 0) {
            return;
        }
        _room.gameState = GameState.ended;
        if (firstPlayer.choice == secondPlayer.choice) {
            _room.gameResult = GameResult.draw;
            return;
        }

        if (firstPlayer.choice == 100) {
            _room.gameResult = GameResult.secondPlayerWon;
            return;
        }
        if (secondPlayer.choice == 100) {
            _room.gameResult = GameResult.firstPlayerWon;
            return;
        }

        uint gameReusltValue = (3 + secondPlayer.choice - firstPlayer.choice) % 3;
        _room.gameResult = GameResult(gameReusltValue);
    }

    function _transfer(address _address, uint _amount) private {
        (bool success, ) = payable(_address).call{value: _amount}("");
        require(success, "Trasnfering failed");
    }

    modifier isOwner() {
        require (msg.sender == _owner, "Not an owner");
        _;
    }

    modifier isPlayer(uint _roomId) {
        Room storage room = _rooms[_roomId];
        require (room.firstPlayer.player == msg.sender
            || room.secondPlayer.player == msg.sender, "Not a player");
        _;
    }

    modifier requireBalance(uint _balance) {
        require (_balances[msg.sender] >= _balance, "Balance is lower than required balance");
        _;
    }

    modifier requireRoomState(uint _roomId, GameState state) {
        require (_rooms[_roomId].gameState == state, "Room is incorrect state");
        _;
    }

    function _collectFee(uint _value) private returns (uint) {
        uint fee = _value / balance_extractDepositFeePerWei * balance_depositFeePerWei;
        if (fee < balance_depositMinFee) {
            fee = balance_depositMinFee;
        }
        _accumulatedFee += fee;
        return _value - fee;
    }

    // TEST ONLY. Коммит надо генерировать из клиента Веб3 или на других ресурсах
    function getCommit(uint _choice, string calldata _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_choice, _salt));
    }
}