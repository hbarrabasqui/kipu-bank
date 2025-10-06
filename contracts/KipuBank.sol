// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title KipuBank
/// @author Horacio Barrabasqui
/// @notice Contrato bancario simple con límite global y límite por transacción
/// @dev Trabajo Práctico 2

contract KipuBank {
    // ====================
    // ====== ERRORS ======
    // ====================
    error KipuBank_DepositoFueraDeLimite();
    error KipuBank_BancoSinCapacidad();
    error KipuBank_SaldoInsuficiente();
    error KipuBank_MontoMayorAlLimite();

    // ====================
    // ===== VARIABLES ====
    // ====================
    uint256 public immutable i_limitePorTransaccion; // límite de retiro por operación
    uint256 public immutable i_bankCap;             // límite global de depósitos permitido

    uint256 public s_totalDepositos;   // monto total depositado en el banco
    uint256 public s_cantidadDepositos; 
    uint256 public s_cantidadRetiros;

    mapping(address => uint256) private s_saldos;

    // ====================
    // ===== EVENTOS ======
    // ====================
    event KipuBank_Deposito(address indexed usuario, uint256 monto);
    event KipuBank_Retiro(address indexed usuario, uint256 monto);

    // ====================
    // ===== CONSTRUCTOR ==
    // ====================
    /// @param _limitePorTx límite máximo que puede retirarse en una transacción
    /// @param _bankCap límite global de depósitos del banco
    constructor(uint256 _limitePorTx, uint256 _bankCap) {
        i_limitePorTransaccion = _limitePorTx;
        i_bankCap = _bankCap;
    }

    // ====================
    // ===== MODIFIERS ====
    // ====================
    modifier montoMayorQueCero(uint256 _monto) {
        if (_monto == 0) revert KipuBank_DepositoFueraDeLimite();
        _;
    }

    // ====================
    // ===== FUNCIONES ====
    // ====================

    /// @notice Depositar fondos en la bóveda personal
    function depositar() external payable montoMayorQueCero(msg.value) {
        if (s_totalDepositos + msg.value > i_bankCap) {
            revert KipuBank_BancoSinCapacidad();
        }

        s_saldos[msg.sender] += msg.value;
        s_totalDepositos += msg.value;
        s_cantidadDepositos++;

        emit KipuBank_Deposito(msg.sender, msg.value);
    }

    /// @notice Retirar fondos con límite por transacción
    /// @param _monto monto a retirar
    function retirar(uint256 _monto) external montoMayorQueCero(_monto) {
        if (_monto > i_limitePorTransaccion) {
            revert KipuBank_MontoMayorAlLimite();
        }
        if (_monto > s_saldos[msg.sender]) {
            revert KipuBank_SaldoInsuficiente();
        }

        // checks-effects-interactions
        s_saldos[msg.sender] -= _monto;
        s_totalDepositos -= _monto;
        s_cantidadRetiros++;

        (bool ok, ) = msg.sender.call{value: _monto}("");
        require(ok, "Fallo transferencia");

        emit KipuBank_Retiro(msg.sender, _monto);
    }

    /// @notice Consultar saldo de un usuario
    /// @param _usuario dirección a consultar
    /// @return saldo disponible de ese usuario
    function saldoDe(address _usuario) external view returns (uint256) {
        return s_saldos[_usuario];
    }

    /// @notice Función privada de utilidad (ejemplo pedido en consigna)
    /// @dev Devuelve true si se superó la capacidad del banco
    function _superoCapacidad(uint256 _monto) private view returns (bool) {
        return (s_totalDepositos + _monto > i_bankCap);
    }
}

