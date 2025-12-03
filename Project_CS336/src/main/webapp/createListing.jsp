<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Create Auction Listing</title>
    <style>
        body { font-family: Arial; }
        label { display: block; margin-top: 10px; }
        input, select { width: 250px; }
        .subsection { margin-left: 20px; margin-top: 10px; }
    </style>

    <script>
        function updateSubtype() {
            var t = document.getElementById("type").value;
            document.getElementById("carFields").style.display =
                (t === "car") ? "block" : "none";
            document.getElementById("truckFields").style.display =
                (t === "truck") ? "block" : "none";
            document.getElementById("motorcycleFields").style.display =
                (t === "motorcycle") ? "block" : "none";
        }
    </script>
</head>

<body>
<h1>Create Auction Listing</h1>

<%
    String error = (String) session.getAttribute("createError");
    if (error != null) {
        out.println("<div style='color:red;'>" + error + "</div>");
        session.removeAttribute("createError");
    }

    String success = (String) session.getAttribute("createOK");
    if (success != null) {
        out.println("<div style='color:green;'>" + success + "</div>");
        session.removeAttribute("createOK");
    }
%>

<form action="submitAuction.jsp" method="POST">

    <h2>Vehicle Information</h2>

    <label>Make</label>
    <input type="text" name="make" required>

    <label>Model</label>
    <input type="text" name="model" required>

    <label>Year</label>
    <input type="number" name="year" min="1900" max="2100" required>

    <label>Vehicle Type</label>
    <select id="type" name="type" onchange="updateSubtype()" required>
        <option value="">Select</option>
        <option value="car">Car</option>
        <option value="truck">Truck</option>
        <option value="motorcycle">Motorcycle</option>
    </select>

    <!-- Car Fields -->
    <div id="carFields" class="subsection" style="display:none;">
        <label>Body Style</label>
        <input type="text" name="body_style">

        <label>Number of Doors</label>
        <input type="number" name="num_doors" min="1" max="5">
    </div>

    <!-- Truck Fields -->
    <div id="truckFields" class="subsection" style="display:none;">
        <label>Number of Wheels</label>
        <input type="number" name="num_wheels" min="2" max="18">

        <label>Axle Configuration</label>
        <input type="text" name="axle_config">
    </div>

    <!-- Motorcycle Fields -->
    <div id="motorcycleFields" class="subsection" style="display:none;">
        <label>Has Sidecar (0 or 1)</label>
        <input type="number" name="has_sidecar" min="0" max="1">

        <label>Handlebar Style</label>
        <input type="text" name="handlebar_style">
    </div>

    <h2>Auction Settings</h2>

    <label>Start Price</label>
    <input type="number" name="start_price" step="0.01" required>

    <label>Minimum Price</label>
    <input type="number" name="min_price" step="0.01" required>

    <label>Bid Increment</label>
    <input type="number" name="bid_increment" step="0.01" required>

    <label>Reserve Price (optional)</label>
    <input type="number" name="reserve_price" step="0.01">

    <label>Auction End Time</label>
    <input type="datetime-local" name="end_time" required>

    <br><br>
    <input type="submit" value="Create Auction">

</form>

</body>
</html>