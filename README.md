# KipuBank - Trabajo Práctico 2

## 📌 Descripción
KipuBank es un contrato bancario simple escrito en Solidity.  
Permite a los usuarios:
- Depositar ETH en su bóveda personal.
- Retirar ETH con un límite máximo por transacción.
- Opera con un límite global de depósitos (`bankCap`).

Incluye:
- Variables `immutable` y de almacenamiento.
- Mapping de saldos por usuario.
- Eventos para depósitos y retiros.
- Errores personalizados para mayor eficiencia.
- Constructor, modifier y funciones con distintos niveles de visibilidad (`external payable`, `external view`, `private`).

---

## 🚀 Instrucciones de despliegue
1. Abrir [Remix IDE](https://remix.ethereum.org/).
2. Crear un archivo en `/contracts` llamado `KipuBank.sol` y pegar el contrato.
3. Compilar con versión de Solidity **0.8.26**.
4. En la sección **Deploy & Run**:
   - Seleccionar una testnet (ejemplo: Sepolia) conectada con **MetaMask**.
   - Indicar los parámetros del constructor:
     - `_limitePorTx`: límite máximo de retiro por transacción (ej. `1000000000000000000` para 1 ETH).
     - `_bankCap`: límite global del banco (ej. `100000000000000000000` para 100 ETH).
   - Presionar **Deploy**.
5. Verificar el contrato en el block explorer de la testnet (ejemplo: [Sepolia Etherscan](https://sepolia.etherscan.io)).

---

## 🛠 Cómo interactuar con el contrato
- **depositar()** → Función `external payable`. Enviá ETH con la transacción y quedará guardado en tu saldo.
- **retirar(uint256 monto)** → Retira fondos siempre que:
  - Tengas saldo suficiente.
  - El monto no supere el límite por transacción.
- **saldoDe(address usuario)** → Consulta el saldo de cualquier dirección.
- **Eventos**:
  - `KipuBank_Deposito(address usuario, uint256 monto)`
  - `KipuBank_Retiro(address usuario, uint256 monto)`

