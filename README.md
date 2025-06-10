# SmartAuction
practica tp2 EthKipu

Contrato Inteligente SmartAuctionEste repositorio contiene el código Solidity para un contrato inteligente de subasta (SmartAuction) diseñado para la blockchain de Ethereum. Su propósito es facilitar un proceso de subasta descentralizado donde los participantes pueden ofertar por un artículo, gestionar sus depósitos de Ether, y asegurar la aplicación de comisiones específicas al finalizar la subasta.

📝 Descripción Detallada

El contrato SmartAuction implementa una subasta con reglas claras para la participación y la finalización.

Permite a los usuarios realizar ofertas, con mecanismos para extender el plazo de la subasta si la actividad es alta en los momentos finales.

Gestiona automáticamente la oferta más alta y los fondos depositados por cada participante.

Al concluir, el contrato determina el ganador y maneja el proceso de reembolso para los oferentes no ganadores, aplicando la lógica de comisiones definida.

🛠️ Variables de Estado del Contrato

Estas variables almacenan información crucial sobre el estado de la subasta en la blockchain:

owner (address payable): La dirección de la billetera que desplegó este contrato.

Este owner tiene permisos especiales, como la capacidad de finalizar la subasta.

auctionEndTime (uint256): Un timestamp Unix que representa la fecha y hora exacta en la que la subasta está programada para finalizar.

Se actualiza si la subasta se extiende.

highestBid (uint256): El monto actual de la oferta más alta en la subasta.

Se inicializa en 0.

highestBidder (address payable): La dirección de la billetera del oferente que actualmente ha realizado la highestBid.

itemName (string): El nombre del artículo que se está subastando, especificado al crear el contrato.

minBidIncrementPercentage (uint256): Un porcentaje (ej., 5 para 5%) que define cuánto debe ser mayor una nueva oferta respecto a la highestBid actual para ser considerada válida.

bids (mapping(address => uint256)): Un mapeo que asocia la dirección de cada oferente con el valor de su última oferta válida.

Esto es diferente de depositedFunds.

depositedFunds (mapping(address => uint256)): Un mapeo que asocia la dirección de cada oferente con el total de Ether que ha enviado al contrato a lo largo de todas sus ofertas.

Es crucial para el reembolso parcial.

auctionEnded (bool): Un indicador booleano que es true si la subasta ha sido oficialmente finalizada (es decir, se ha llamado a endAuction) y false en caso contrario.

participants (address[] private): Un array que guarda las direcciones de todos los usuarios que han realizado al menos una oferta en la subasta. 

Es una lista auxiliar para facilitar los reembolsos.

isParticipant (mapping(address => bool) private): Un mapeo auxiliar que permite verificar rápidamente si una dirección ya está incluida en la lista participants.

✨ Funcionalidades y sus Funciones

El contrato ofrece las siguientes funciones públicas para interactuar con la subasta:

constructor(string memory _itemName, uint256 _biddingDurationInMinutes, uint256 _minBidIncrementPercentage)

Propósito: Esta función especial se ejecuta una única vez cuando el contrato se despliega en la blockchain.

Parámetros:

_itemName: El nombre del artículo a subastar (ej., "Colección de sellos antiguos").

_biddingDurationInMinutes: La duración inicial de la subasta en minutos (ej., 60 para una hora).

_minBidIncrementPercentage: El incremento mínimo porcentual para las ofertas (ej., 5 para 5%).

Acción: Inicializa las variables de estado owner, itemName, auctionEndTime, highestBid, y minBidIncrementPercentage.

bid() public payable auctionNotEnded

Propósito: Permite a cualquier participante realizar una oferta de Ether por el artículo.

Comportamiento:

Requiere que el monto de Ether enviado (msg.value) sea mayor que cero.

La nueva oferta debe ser al menos un 5% más alta (o el porcentaje definido por minBidIncrementPercentage) que la highestBid actual.

Extensión de la Subasta: Si la oferta se realiza en los últimos 10 minutos del auctionEndTime, la subasta se extiende automáticamente por 10 minutos adicionales.

Los msg.value se suman a depositedFunds[msg.sender] (total depositado) y bids[msg.sender] se actualiza a la última oferta válida del usuario.

Actualiza highestBid y highestBidder si la oferta es la nueva más alta.

Eventos emitidos: NewBid.

partialRefund() public

Propósito: Permite a los participantes recuperar el Ether que han depositado en exceso por encima de su última oferta válida.

Comportamiento: Si un usuario hizo una oferta de 1 ETH, luego alguien más ofertó 2 ETH, y luego el usuario ofertó 3 ETH (enviando 2 ETH adicionales), esta función le permitiría reclamar el 1 ETH de su primera oferta que ya no está en juego.

Restricciones: No puede ser llamada por el highestBidder (ya que su oferta está comprometida) ni después de que la subasta haya finalizado.

Eventos emitidos: PartialRefund.

endAuction() public onlyOwner auctionHasEnded

Propósito: Finaliza oficialmente la subasta y distribuye los fondos.

Comportamiento:

Solo puede ser llamada por el owner del contrato.

Solo puede ser llamada después de que el auctionEndTime haya pasado y si la subasta no ha sido finalizada previamente.

Comisión del Ganador: El monto total de la highestBid se transfiere al owner del contrato, sin ninguna deducción de comisión al ganador.

Comisión de los Perdedores: Para cada oferente no ganador, se devuelve su depositedFunds menos una comisión del 2%, que se transfiere al owner.

Eventos emitidos: AuctionEnded, FundsWithdrawn (por cada perdedor reembolsado).

getWinner() public view returns (address winner, uint256 winningBid)

Propósito: Permite consultar la dirección del oferente ganador y el monto de su oferta.

Comportamiento: Esta función solo devolverá datos válidos después de que la subasta haya terminado (es decir, se ha llamado a endAuction).

Tipo: Es una función view, lo que significa que no modifica el estado de la blockchain y no cuesta gas al ser llamada.

getBids() public view returns (address[] memory biddersList, uint256[] memory amountsList)

Propósito: Proporciona un resumen de todas las ofertas realizadas por los participantes.

Comportamiento: Devuelve dos arrays:

biddersList: Un array con las direcciones de todos los oferentes que han participado.

amountsList: Un array correspondiente con las últimas ofertas válidas de cada oferente.

Tipo: Es una función view, lo que significa que no modifica el estado de la blockchain y no cuesta gas al ser llamada.

withdrawNonWinningBids() public auctionHasEnded

Propósito: Permite a los oferentes no ganadores reclamar manualmente sus fondos restantes después de que la subasta haya terminado.

Comportamiento: Es una alternativa para que los perdedores retiren sus fondos si endAuction aún no se ha llamado o si desean retirarlos individualmente.A estos retiros también se les aplica una comisión del 2%, que se envía al owner.

Eventos emitidos: FundsWithdrawn.

📢 Eventos Emitidos (Clarificación)

Los eventos son una forma eficiente y económica para que los contratos inteligentes "registren" cambios en la blockchain. Las aplicaciones externas (como interfaces de usuario o servidores) pueden "escuchar" estos eventos y reaccionar a ellos en tiempo real, sin tener que leer el estado del contrato constantemente.

NewBid(address indexed bidder, uint256 amount)

Cuándo se emite: Cada vez que se realiza una nueva oferta válida a través de la función bid().

Datos que contiene:

bidder (indexado): La dirección de la persona que hizo la nueva oferta. indexed significa que se puede buscar por esta dirección.

amount: El monto exacto de la nueva oferta.

AuctionEnded(address indexed winner, uint256 amount)

Cuándo se emite: Cuando el propietario llama a la función endAuction() y la subasta es oficialmente finalizada.

Datos que contiene:

winner (indexado): La dirección del oferente que ganó la subasta.

amount: El monto final de la oferta ganadora.

FundsWithdrawn(address indexed bidder, uint256 amount)

Cuándo se emite: Cada vez que fondos son retirados del contrato, ya sea como parte de un reembolso parcial, o cuando un oferente no ganador reclama sus fondos al finalizar la subasta.

Datos que contiene:

bidder (indexado): La dirección de la persona que retiró los fondos.

amount: El monto de Ether que fue retirado/reembolsado (después de aplicar comisiones si aplica).

PartialRefund(address indexed bidder, uint256 amount)

Cuándo se emite: Específicamente cuando un participante utiliza la función partialRefund() para retirar el exceso de sus depósitos durante la subasta.

Datos que contiene:

bidder (indexado): La dirección del oferente que recibió el reembolso parcial.

amount: El monto de Ether que le fue reembolsado parcialmente.

💸 Lógica de Comisiones

La estructura de comisiones está diseñada de la siguiente manera:

Oferente Ganador: El highestBid completo es transferido al owner del contrato sin aplicar ninguna comisión al ganador. El ganador recibe el artículo subastado.

Oferentes No Ganadores: Al momento de devolver los depósitos (ya sea a través de la función endAuction o withdrawNonWinningBids), se descuenta una comisión del 2% sobre el monto a reembolsar. Esta comisión se transfiere al owner del contrato, y el monto restante se devuelve al oferente.

🚀 Despliegue y Uso

Despliegue

Puedes desplegar este contrato utilizando herramientas como Remix Ethereum IDE o Hardhat.

Remix (Recomendado para principiantes):

Abre Remix.

Crea un nuevo archivo .sol y pega el código del contrato.

Compila el contrato (versión ^0.8.0 de Solidity).

En la pestaña "Deploy & Run Transactions", selecciona "Injected Provider - MetaMask" y conéctate a la red deseada (ej., Sepolia Testnet).

Ingresa los parámetros del constructor (_itemName, _biddingDurationInMinutes, _minBidIncrementPercentage) y haz clic en "Deploy".

Hardhat (Recomendado para desarrollo profesional):

Configura un proyecto Hardhat (instala hardhat, @nomicfoundation/hardhat-ethers, dotenv).

Crea un script de despliegue (scripts/deploy.js) que instancie y despliegue el contrato con los parámetros deseados.

Configura tu hardhat.config.js con las credenciales de la red (usando variables de entorno para las claves privadas).

Ejecuta npx hardhat run scripts/deploy.js --network <your_network_name> en tu terminal.

Interacción (Uso)

Una vez desplegado, puedes interactuar con el contrato:

bid(): Envía una transacción a esta función con Ether para realizar tu oferta.

partialRefund(): Llama a esta función para retirar fondos no comprometidos durante la subasta.

endAuction(): El propietario del contrato llama a esta función para finalizar la subasta y distribuir los fondos.

getWinner(): Consulta esta función (función view) para ver quién ganó y por cuánto.

getBids(): Consulta esta función para ver un historial de ofertas de todos los participantes.

withdrawNonWinningBids(): Los oferentes no ganadores pueden usar esta función para reclamar sus fondos restantes después de la subasta.

🔒 Consideraciones de Seguridad

Validaciones Robustas: El contrato utiliza extensivamente require() para validar todas las entradas y condiciones de estado, previniendo errores lógicos y comportamientos inesperados.

Transferencia de Ether Segura: Las transferencias de Ether a direcciones externas se realizan utilizando el patrón call{value: amount}(""), considerado el método más seguro para transferir Ether, minimizando el riesgo de ataques de reentrada.

Control de Acceso: Modificadores como onlyOwner aseguran que solo las entidades autorizadas puedan ejecutar funciones críticas.

📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.
