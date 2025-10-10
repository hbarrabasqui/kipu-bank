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
    /// @notice Error cuando el depósito es cero o fuera de los límites
    error KipuBank_DepositoFueraDeLimite();
    /// @notice Error cuando el banco ha alcanzado su capacidad máxima
    error KipuBank_BancoSinCapacidad();
    /// @notice Error cuando el usuario no tiene saldo suficiente
    error KipuBank_SaldoInsuficiente();
    /// @notice Error cuando el monto excede el límite por transacción
    error KipuBank_MontoMayorAlLimite();
    /// @notice Error cuando falla la transferencia de ether
    error KipuBank_TransferenciaFallida();
    /// @notice Error cuando se detecta reentrancia
    error KipuBank_ReentranciaDetectada();

    // ====================
    // ===== VARIABLES ====
    // ====================
    /// @notice Límite máximo por transacción de retiro
    uint256 public immutable i_limitePorTransaccion;
    /// @notice Capacidad máxima total de depósitos del banco
    uint256 public immutable i_bankCap;
    /// @notice Total de depósitos en el banco
    uint256 public s_totalDepositos;
    /// @notice Cantidad total de depósitos realizados
    uint256 public s_cantidadDepositos;
    /// @notice Cantidad total de retiros realizados
    uint256 public s_cantidadRetiros;
    /// @notice Mapeo de saldos por dirección de usuario
    mapping(address => uint256) private s_saldos;
    /// @notice Variable para control de reentrancia
    bool private s_reentranciaLock;

    // ====================
    // ===== EVENTOS ======
    // ====================
    /// @notice Emitido cuando un usuario realiza un depósito
    /// @param usuario Dirección del usuario que depositó
    /// @param monto Monto depositado en wei
    event KipuBank_Deposito(address indexed usuario, uint256 monto);
    /// @notice Emitido cuando un usuario realiza un retiro
    /// @param usuario Dirección del usuario que retiró
    /// @param monto Monto retirado en wei
    event KipuBank_Retiro(address indexed usuario, uint256 monto);
    /// @notice Emitido cuando se reciben ether sin función específica
    /// @param remitente Dirección que envió los fondos
    /// @param monto Monto recibido en wei
    event KipuBank_Recepcion(address indexed remitente, uint256 monto);

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
    /// @notice Modificador que verifica que el monto sea mayor a cero
    /// @param _monto Monto a verificar
    modifier montoMayorQueCero(uint256 _monto) {
        if (_monto == 0) revert KipuBank_DepositoFueraDeLimite();
        _;
    }

    /// @notice Modificador para prevenir ataques de reentrancia
    modifier nonReentrant() {
        if (s_reentranciaLock) revert KipuBank_ReentranciaDetectada();
        s_reentranciaLock = true;
        _;
        s_reentranciaLock = false;
    }

    // ====================
    // ===== FUNCIONES ====
    // ====================

    /// @notice Depositar fondos en la bóveda personal
    function depositar() external payable montoMayorQueCero(msg.value) {
        // Usamos la función _superoCapacidad para verificar capacidad
        if (_superoCapacidad(msg.value)) {
            revert KipuBank_BancoSinCapacidad();
        }

        s_saldos[msg.sender] += msg.value;
        s_totalDepositos += msg.value;
        s_cantidadDepositos++;

        emit KipuBank_Deposito(msg.sender, msg.value);
    }

    /// @notice Retirar fondos con límite por transacción
    /// @param _monto monto a retirar
    function retirar(uint256 _monto) 
        external 
        montoMayorQueCero(_monto) 
        nonReentrant 
    {
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
        if (!ok) revert KipuBank_TransferenciaFallida();

        emit KipuBank_Retiro(msg.sender, _monto);
    }

    /// @notice Consultar saldo de un usuario
    /// @param _usuario dirección a consultar
    /// @return saldo disponible de ese usuario
    function saldoDe(address _usuario) external view returns (uint256) {
        return s_saldos[_usuario];
    }

    /// @notice Función receive para recibir ether directamente
    receive() external payable {
        // Cuando se envía ether directamente al contrato sin data
        // Se considera como un depósito automático
        if (_superoCapacidad(msg.value)) {
            revert KipuBank_BancoSinCapacidad();
        }

        s_saldos[msg.sender] += msg.value;
        s_totalDepositos += msg.value;
        s_cantidadDepositos++;

        emit KipuBank_Recepcion(msg.sender, msg.value);
        emit KipuBank_Deposito(msg.sender, msg.value);
    }

    /// @notice Función fallback para manejar llamadas no reconocidas
    fallback() external payable {
        // Si se envía ether con data no reconocida, se rechaza
        if (msg.value > 0) {
            revert KipuBank_DepositoFueraDeLimite();
        }
    }

    /// @notice Función privada de utilidad para verificar capacidad
    /// @dev Devuelve true si se superó la capacidad del banco
    /// @param _monto Monto a verificar
    /// @return True si supera la capacidad, false en caso contrario
    function _superoCapacidad(uint256 _monto) private view returns (bool) {
        return (s_totalDepositos + _monto > i_bankCap);
    }
}
