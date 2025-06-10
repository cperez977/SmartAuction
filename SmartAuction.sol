/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SmartAuction
 * @dev Contrato inteligente que gestiona una subasta.
 * Permite a los participantes ofertar por un artículo, maneja los depósitos,
 * aplica comisiones y reembolsa los fondos a los oferentes no ganadores.
 */
contract SmartAuction {
    // --- Variables de Estado ---
    address payable public owner; // Dirección del propietario del contrato, quien desplegó el contrato.
    uint256 public auctionEndTime; // Timestamp Unix en el que la subasta está programada para finalizar.
    uint256 public highestBid; // El monto de la oferta más alta actual.
    address payable public highestBidder; // La dirección del oferente que ha realizado la oferta más alta.
    string public itemName; // El nombre del artículo que se está subastando.
    uint256 public minBidIncrementPercentage; // El porcentaje mínimo en que una nueva oferta debe superar la oferta actual (ej., 5 para 5%).

    // --- Mapeos ---
    // bids[address] = Almacena la última oferta válida individual de cada participante.
    mapping(address => uint256) public bids;
    // depositedFunds[address] = Rastrea el total acumulado de fondos (Ether) depositados por cada oferente en el contrato.
    mapping(address => uint256) public depositedFunds;

    bool public auctionEnded; // Indica si la subasta ha sido oficialmente finalizada por el propietario.

    // --- Listas de Participantes ---
    address[] private participants; // Un array para mantener un registro de todas las direcciones que han ofertado.
    mapping(address => bool) private isParticipant; // Un mapeo para verificar rápidamente si una dirección ya está en el array `participants`.

    // --- Eventos ---
    /**
     * @dev Se emite cuando se realiza y acepta una nueva oferta válida.
     * @param bidder La dirección del oferente que realizó la oferta.
     * @param amount El monto de la oferta realizada.
     */
    event NewBid(address indexed bidder, uint256 amount);

    /**
     * @dev Se emite cuando la subasta finaliza y se determina el ganador.
     * @param winner La dirección del oferente ganador.
     * @param amount El monto de la oferta ganadora.
     */
    event AuctionEnded(address indexed winner, uint256 amount);

    /**
     * @dev Se emite cuando se retiran fondos del contrato, ya sea un reembolso parcial
     * o la devolución de depósitos a oferentes no ganadores.
     * @param bidder La dirección del oferente cuyos fondos fueron retirados.
     * @param amount El monto que se retiró/reembolsó.
     */
    event FundsWithdrawn(address indexed bidder, uint256 amount);

    /**
     * @dev Se emite cuando un participante retira el importe por encima de su última oferta válida.
     * @param bidder La dirección del oferente que recibió el reembolso parcial.
     * @param amount El monto del reembolso parcial.
     */
    event PartialRefund(address indexed bidder, uint256 amount);

    // --- Modificadores ---
    /**
     * @dev Restringe la ejecución de una función solo al propietario del contrato.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede llamar a esta funcion.");
        _; // Continúa con la ejecución de la función.
    }

    /**
     * @dev Permite la ejecución de una función solo si la subasta aún no ha terminado.
     */
    modifier auctionNotEnded() {
        require(block.timestamp < auctionEndTime, "La subasta ya ha terminado.");
        _;
    }

    /**
     * @dev Permite la ejecución de una función solo si la subasta ha terminado (por tiempo)
     * pero aún no ha sido oficialmente finalizada por el propietario.
     */
    modifier auctionHasEnded() {
        require(block.timestamp >= auctionEndTime && !auctionEnded, "La subasta no ha terminado o ya se finalizo.");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Constructor del contrato SmartAuction.
     * Se ejecuta una vez al desplegar el contrato e inicializa los parámetros de la subasta.
     * @param _itemName El nombre del artículo que se va a subastar.
     * @param _biddingDurationInMinutes La duración inicial de la subasta en minutos.
     * @param _minBidIncrementPercentage El porcentaje mínimo de incremento que una nueva oferta debe tener.
     */
    constructor(string memory _itemName, uint256 _biddingDurationInMinutes, uint256 _minBidIncrementPercentage) {
        owner = payable(msg.sender); // El desplegador del contrato se convierte en el propietario.
        itemName = _itemName;
        auctionEndTime = block.timestamp + (_biddingDurationInMinutes * 1 minutes); // Calcula el tiempo de finalización.
        highestBid = 0; // La oferta inicial es cero.
        minBidIncrementPercentage = _minBidIncrementPercentage;
        auctionEnded = false; // La subasta no ha terminado al inicio.
    }

    // --- Funciones Principales ---
    /**
     * @dev Permite a los participantes realizar una oferta por el artículo.
     * La oferta debe ser mayor que cero y al menos un 5% más alta que la oferta actual.
     * Si la oferta se realiza en los últimos 10 minutos, extiende la subasta 10 minutos.
     */
    function bid() public payable auctionNotEnded {
        require(msg.value > 0, "El monto de la oferta debe ser mayor que cero.");

        uint256 requiredBid = highestBid + (highestBid * minBidIncrementPercentage / 100);
        // Si no hay oferta actual, la primera oferta puede ser cualquier monto > 0.
        if (highestBid == 0) {
            requiredBid = 1; // Un mínimo para asegurar que msg.value sea al menos 1 wei.
        }

        // Se ha modificado el mensaje de error para eliminar la dependencia de la librería Strings.
        require(msg.value >= requiredBid, "La nueva oferta debe ser mayor que la oferta actual en el porcentaje minimo de incremento.");

        // Si la oferta se realiza en los últimos 10 minutos de la subasta, se extiende 10 minutos más.
        if (block.timestamp < auctionEndTime && auctionEndTime - block.timestamp < 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        depositedFunds[msg.sender] += msg.value; // Acumula todos los fondos enviados por el oferente.
        bids[msg.sender] = msg.value; // Registra la última oferta válida de este oferente.
        _recordParticipant(msg.sender); // Añade al oferente a la lista de participantes si es nuevo.

        // Si la oferta actual es la más alta, actualiza el estado de la subasta.
        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = payable(msg.sender);
        }

        emit NewBid(msg.sender, msg.value); // Emite el evento de nueva oferta.
    }

    /**
     * @dev Permite a los participantes retirar el importe que exceda su última oferta válida.
     * Esto es útil si un participante ha ofertado múltiples veces y quiere liberar fondos no comprometidos.
     */
    function partialRefund() public {
        require(bids[msg.sender] < depositedFunds[msg.sender], "No hay fondos en exceso para reembolsar.");
        require(msg.sender != highestBidder, "El oferente mas alto no puede solicitar un reembolso parcial.");
        require(block.timestamp < auctionEndTime, "No se permiten reembolsos parciales despues de que la subasta ha terminado.");

        uint256 refundableAmount = depositedFunds[msg.sender] - bids[msg.sender]; // Calcula el monto a reembolsar.
        depositedFunds[msg.sender] = bids[msg.sender]; // Actualiza los fondos depositados al valor de la última oferta válida.

        // Transfiere los fondos al oferente.
        (bool success, ) = payable(msg.sender).call{value: refundableAmount}("");
        require(success, "Fallo el reembolso parcial.");

        emit PartialRefund(msg.sender, refundableAmount); // Emite el evento de reembolso parcial.
    }

    /**
     * @dev Finaliza la subasta, transfiere el monto ganador al propietario y reembolsa a los perdedores.
     * Solo el propietario puede llamar a esta función una vez que la subasta ha terminado.
     * El ganador no paga comisión. Los perdedores pagan un 2% de comisión sobre su reembolso.
     */
    function endAuction() public onlyOwner auctionHasEnded {
        require(!auctionEnded, "La subasta ya ha sido finalizada.");

        auctionEnded = true; // Marca la subasta como finalizada para evitar llamadas múltiples.

        if (highestBidder != address(0)) {
            // El monto total de la oferta ganadora se transfiere al propietario (sin comision para el ganador).
            (bool successWinnerTransfer, ) = payable(owner).call{value: highestBid}("");
            require(successWinnerTransfer, "Fallo la transferencia al propietario.");

            // Itera sobre todos los participantes para reembolsar a los no ganadores con un descuento del 2%.
            for (uint i = 0; i < participants.length; i++) {
                address participant = participants[i];
                // Solo reembolsa si el participante no es el ganador y tiene fondos depositados.
                if (participant != highestBidder && depositedFunds[participant] > 0) {
                    uint256 amountToRefund = depositedFunds[participant];
                    uint256 commission = amountToRefund * 2 / 100; // Calcula la comisión del 2% para los perdedores.
                    uint256 netRefundAmount = amountToRefund - commission; // Monto neto a reembolsar.

                    depositedFunds[participant] = 0; // Reinicia los fondos depositados.

                    // Transfiere la comisión al propietario.
                    (bool successCommission, ) = payable(owner).call{value: commission}("");
                    require(successCommission, "Fallo la transferencia de comision al propietario.");

                    // Transfiere el monto neto al participante.
                    (bool successRefund, ) = payable(participant).call{value: netRefundAmount}("");
                    require(successRefund, "Fallo el reembolso neto a un participante.");

                    emit FundsWithdrawn(participant, netRefundAmount); // Emite el evento de fondos retirados.
                }
            }
        }
        emit AuctionEnded(highestBidder, highestBid); // Emite el evento de subasta finalizada.
    }

    // --- Funciones de Consulta (View) ---
    /**
     * @dev Devuelve la dirección del oferente ganador y el valor de la oferta ganadora.
     * Solo se puede llamar una vez que la subasta ha terminado.
     * @return winner La dirección del oferente que ganó la subasta.
     * @return winningBid El monto de la oferta ganadora.
     */
    function getWinner() public view returns (address winner, uint256 winningBid) {
        require(auctionEnded, "La subasta no ha terminado todavia.");
        return (highestBidder, highestBid);
    }

    /**
     * @dev Devuelve la lista de todos los oferentes que han participado y sus respectivos montos ofrecidos.
     * @return biddersList Un array con las direcciones de todos los oferentes.
     * @return amountsList Un array con los montos de las últimas ofertas válidas de cada oferente.
     */
    function getBids() public view returns (address[] memory biddersList, uint256[] memory amountsList) {
        biddersList = new address[](participants.length);
        amountsList = new uint256[](participants.length);

        for (uint i = 0; i < participants.length; i++) {
            biddersList[i] = participants[i];
            amountsList[i] = bids[participants[i]];
        }
        return (biddersList, amountsList);
    }

    /**
     * @dev Permite a los oferentes no ganadores retirar sus depósitos una vez que la subasta ha finalizado.
     * A los fondos retirados se les aplica una comisión del 2%, que va al propietario del contrato.
     */
    function withdrawNonWinningBids() public auctionHasEnded {
        require(msg.sender != highestBidder, "El ganador no puede retirar de esta manera.");
        require(depositedFunds[msg.sender] > 0, "No hay fondos para retirar.");

        uint256 amountToRefund = depositedFunds[msg.sender];
        uint256 commission = amountToRefund * 2 / 100; // Calcula la comisión del 2% para este retiro.
        uint256 netRefundAmount = amountToRefund - commission; // Monto neto a reembolsar.

        depositedFunds[msg.sender] = 0; // Reinicia los fondos depositados.

        // Transfiere la comisión al propietario.
        (bool successCommission, ) = payable(owner).call{value: commission}("");
        require(successCommission, "Fallo la transferencia de comision al propietario.");

        // Transfiere el monto neto al oferente.
        (bool success, ) = payable(msg.sender).call{value: netRefundAmount}("");
        require(success, "Fallo el retiro de fondos.");
        emit FundsWithdrawn(msg.sender, netRefundAmount); // Emite el evento de fondos retirados.
    }

    // --- Funciones Auxiliares Internas ---
    /**
     * @dev Función interna para registrar un participante en el array `participants`
     * si aún no está presente, para facilitar el reembolso al final de la subasta.
     * @param _participant La dirección del participante a registrar.
     */
    function _recordParticipant(address _participant) internal {
        if (!isParticipant[_participant]) {
            participants.push(_participant);
            isParticipant[_participant] = true;
        }
    }
}
