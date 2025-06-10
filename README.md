# SmartAuction
practica tp2 EthKipu

Contrato Inteligente SmartAuctionEste repositorio contiene el código Solidity para un contrato inteligente de subasta (SmartAuction) diseñado para la blockchain de Ethereum.

Permite a múltiples participantes ofertar por un artículo, maneja los depósitos de Ether, aplica comisiones específicas y facilita el reembolso de fondos.

📝 Descripción

El contrato SmartAuction implementa una subasta descentralizada donde los usuarios pueden ofertar por un artículo específico.

La subasta tiene una duración definida que puede extenderse si se realizan ofertas en los últimos minutos.

El contrato gestiona la oferta más alta, los fondos depositados por cada participante y el proceso de reembolso al finalizar la subasta.

✨ Funcionalidades Principales

Constructor: Inicializa la subasta con un nombre de artículo, duración y porcentaje de incremento mínimo para las ofertas.

El desplegador se convierte en el propietario del contrato.

Función para ofertar (bid):Permite a los participantes realizar ofertas enviando Ether al contrato.

Una oferta es válida si es al menos un 5% más alta que la oferta actual más alta.

Si una oferta válida se realiza en los últimos 10 minutos de la subasta, el plazo de la subasta se extiende automáticamente por otros 10 minutos.

Los fondos de cada oferta se depositan en el contrato y se asocian a la dirección del oferente.

Mostrar ganador (getWinner): Devuelve la dirección del oferente ganador y el monto de la oferta ganadora una vez que la subasta ha finalizado.

Mostrar ofertas (getBids): Proporciona una lista de todos los participantes y sus respectivas últimas ofertas válidas.

Devolver depósitos / Finalizar subasta (endAuction):Solo puede ser llamado por el propietario una vez que la subasta ha terminado.

El ganador NO paga comisión: El monto total de la oferta ganadora se transfiere al propietario del contrato.

Los perdedores pagan un 2% de comisión: A los oferentes no ganadores se les devuelve su depósito, pero se les descuenta una comisión del 2%, que se transfiere al propietario.

Reembolso parcial (partialRefund): Durante la subasta, los participantes pueden retirar el importe por encima de su última oferta válida.

Esto les permite liberar fondos que ya no están activamente en juego.

Retiro de depósitos para no ganadores (withdrawNonWinningBids): Permite a los oferentes no ganadores retirar sus fondos (con el 2% de comisión) después de que la subasta haya terminado, si no lo hicieron a través de la función endAuction.

💸 Lógica de Comisiones

La estructura de comisiones está diseñada de la siguiente manera:

Oferente Ganador: El highestBid completo es transferido al owner del contrato sin aplicar ninguna comisión al ganador.

Oferentes No Ganadores: Al momento de devolver los depósitos (ya sea a través de endAuction o withdrawNonWinningBids), se descuenta una comisión del 2% sobre el monto a reembolsar.
Esta comisión se transfiere al owner del contrato, y el monto restante se devuelve al oferente.

📢 Eventos Emitidos

Para facilitar la interacción con aplicaciones externas y el seguimiento de los cambios de estado:

NewBid(address indexed bidder, uint256 amount): Se emite cuando se realiza una nueva oferta válida.

AuctionEnded(address indexed winner, uint256 amount): Se emite cuando la subasta es finalizada por el propietario.

FundsWithdrawn(address indexed bidder, uint256 amount): Se emite cuando se retiran fondos del contrato (reembolso parcial o finalización de la subasta).

PartialRefund(address indexed bidder, uint256 amount): Se emite específicamente cuando se realiza un reembolso parcial.

🚀 Despliegue y Uso

Despliegue

Puedes desplegar este contrato utilizando herramientas como Remix Ethereum IDE o Hardhat.

Remix (Recomendado para principiantes):

Abre Remix.Crea un nuevo archivo .sol y pega el código del contrato.

Compila el contrato (versión ^0.8.0 de Solidity).

En la pestaña "Deploy & Run Transactions", selecciona "Injected Provider - MetaMask" y conéctate a la red deseada (ej., Sepolia Testnet).

Ingresa los parámetros del constructor (_itemName, _biddingDurationInMinutes, _minBidIncrementPercentage) y haz clic en "Deploy".

Hardhat (Recomendado para desarrollo profesional):

Configura un proyecto Hardhat (instala hardhat, @nomicfoundation/hardhat-ethers, dotenv).

Crea un script de despliegue (scripts/deploy.js) que instancie y despliegue el contrato con los parámetros deseados.

Configura tu hardhat.config.js con las credenciales de la red (usando variables de entorno para las claves privadas).

Ejecuta npx hardhat run scripts/deploy.js --network <your_network_name> en tu terminal.

Interacción (Uso)Una vez desplegado, puedes interactuar con el contrato:bid(): Envía una transacción a esta función con Ether para realizar tu oferta.

partialRefund(): Llama a esta función para retirar fondos no comprometidos durante la subasta.

endAuction(): El propietario del contrato llama a esta función para finalizar la subasta y distribuir los fondos.

getWinner(): Consulta esta función (función view) para ver quién ganó y por cuánto.

getBids(): Consulta esta función para ver un historial de ofertas de todos los participantes.

withdrawNonWinningBids(): Los oferentes no ganadores pueden usar esta función para reclamar sus fondos restantes después de la subasta.

🔒 Consideraciones de Seguridad

Validaciones Robustas: El contrato utiliza extensivamente require() para validar todas las entradas y condiciones de estado, previniendo errores lógicos y comportamientos inesperados.

Transferencia de Ether Segura: Las transferencias de Ether a direcciones externas se realizan utilizando el patrón call{value: amount}(""), considerado el método más seguro para transferir Ether, minimizando el riesgo de ataques de reentrada.

Control de Acceso: Modificadores como onlyOwner aseguran que solo las entidades autorizadas puedan ejecutar funciones críticas.

📄 LicenciaEste proyecto está bajo la licencia MIT. 

Consulta el archivo LICENSE para más detalles.
