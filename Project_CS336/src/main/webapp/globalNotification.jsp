

<style>
    /* The Modal Background - covers entire screen, blocks clicks */
    #paymentModalOverlay {
        display: none; /* Hidden by default */
        position: fixed;
        z-index: 9999;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        overflow: auto;
        background-color: rgba(0,0,0,0.9); /* Dark background */
        backdrop-filter: blur(5px);
    }

    /* The Modal Content */
    .payment-modal-content {
        background-color: #fefefe;
        margin: 10% auto;
        padding: 20px;
        border: 1px solid #888;
        width: 80%;
        max-width: 400px;
        border-radius: 10px;
        text-align: center;
        box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
        font-family: 'Segoe UI', sans-serif;
    }

    .payment-title {
        color: #28a745;
        font-size: 24px;
        margin-bottom: 10px;
    }

    .payment-amount {
        font-size: 30px;
        font-weight: bold;
        color: #333;
        margin: 20px 0;
    }

    .payment-input {
        width: 100%;
        padding: 12px;
        margin: 10px 0;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-sizing: border-box;
        font-size: 16px;
    }

    .pay-btn {
        background-color: #007bff;
        color: white;
        padding: 14px 20px;
        margin: 8px 0;
        border: none;
        cursor: pointer;
        width: 100%;
        font-size: 18px;
        border-radius: 4px;
    }

    .pay-btn:hover {
        background-color: #0056b3;
    }
</style>

<div id="paymentModalOverlay">
    <div class="payment-modal-content">
        <h2 class="payment-title">🎉 You Won!</h2>
        <p>This auction has ended and you are the winner.</p>
        <p>To continue using the site, you must complete the payment now.</p>
        
        <div class="payment-amount" id="displayAmount">$0.00</div>

        <form action="${pageContext.request.contextPath}/logic/processPayment.jsp" method="POST">
            <input type="hidden" id="payAuctionId" name="auction_id" value="">
            
            <label style="text-align:left; display:block; font-weight:bold;">Card Number (16 digits)</label>
            <input type="text" class="payment-input" name="card_number" 
                   pattern="\d{16}" title="Enter 16 digit card number" 
                   placeholder="1234 5678 1234 5678" required>

            <button type="submit" class="pay-btn">Pay Now</button>
        </form>
    </div>
</div>

<script>
    // Poll the server every 5 seconds to check if I won anything
    setInterval(checkWinStatus, 5000);

    function checkWinStatus() {
        // We assume your checkWin.jsp is inside the 'logic' folder
        fetch('logic/checkWin.jsp')
            .then(response => response.json())
            .then(data => {
                if (data.found === true) {
                    showPaymentModal(data.auction_id, data.amount);
                }
            })
            .catch(error => console.error('Error checking win status:', error));
    }

    function showPaymentModal(id, amount) {
        var modal = document.getElementById("paymentModalOverlay");
        var amountDiv = document.getElementById("displayAmount");
        var inputId = document.getElementById("payAuctionId");

        // Set the values
        amountDiv.innerText = "$" + amount.toFixed(2);
        inputId.value = id;

        // Show the modal
        modal.style.display = "block";
        
        // Disable scrolling on the main body to force focus
        document.body.style.overflow = "hidden";
    }
</script>