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
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f7f6;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
        }
        .container {
            background-color: #ffffff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 500px;
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 20px;
        }
        h2 {
            color: #555;
            font-size: 1.2em;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
            margin-top: 20px;
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #666;
            font-weight: bold;
        }
        input[type="text"],
        input[type="number"],
        input[type="datetime-local"],
        select {
            width: 100%;
            padding: 10px;
            margin-bottom: 15px;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box; 
            font-size: 14px;
        }
        input[type="submit"] {
            width: 100%;
            background-color: #007bff;
            color: white;
            padding: 12px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 10px;
            transition: background-color 0.3s;
        }
        input[type="submit"]:hover {
            background-color: #0056b3;
        }
        .subsection {
            background-color: #f9f9f9;
            padding: 15px;
            border-left: 4px solid #007bff;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .message {
            text-align: center;
            padding: 10px;
            margin-bottom: 15px;
            border-radius: 4px;
        }
    </style>

    <script>
        // --- DATA LISTS ---
        const carMakes = [
            "Toyota", "Ford", "Chevrolet", "Honda", "Nissan", 
            "Jeep", "Hyundai", "Kia", "Subaru", "Ram", 
            "GMC", "Volkswagen", "BMW", "Mercedes-Benz", "Mazda", 
            "Lexus", "Dodge", "Audi", "Tesla", "Volvo"
        ];

        const truckMakes = [
            "Ford", "Chevrolet", "Ram", "GMC", "Toyota", 
            "Nissan", "Jeep", "Rivian", "Kenworth", "Peterbilt", 
            "Mack", "Volvo Trucks", "Freightliner", "International", "Western Star", 
            "Isuzu", "Hino", "Mitsubishi Fuso", "Tesla (Cybertruck)", "Hummer EV"
        ];

        const motorcycleMakes = [
            "Harley-Davidson", "Honda", "Yamaha", "Kawasaki", "Suzuki", 
            "BMW", "Ducati", "Triumph", "KTM", "Royal Enfield", 
            "Indian", "Aprilia", "Husqvarna", "Moto Guzzi", "MV Agusta", 
            "Zero", "Can-Am", "Polaris", "Vespa", "Piaggio"
        ];

        // Map Wheels -> Compatible Axle Configurations 
        const axleCompatibility = {
            "4": ["4x2", "4x4"], // Standard Pickup
            "6": ["4x2", "4x4"], // Dually Pickup (Still 2 axles)
            "10": ["6x2", "6x4", "6x6"], // Standard 3-axle truck
            "12": ["8x4", "8x6"], // 4-axle truck
            "18": ["6x4"] // Standard Semi-Tractor (usually 6x4 pulling a trailer)
        };

        // --- FUNCTIONS ---

        function updateSubtype() {
            var t = document.getElementById("type").value;
            var makeSelect = document.getElementById("makeSelect");
            
            // 1. Logic to show/hide specific fields
            document.getElementById("carFields").style.display = (t === "car") ? "block" : "none";
            document.getElementById("truckFields").style.display = (t === "truck") ? "block" : "none";
            document.getElementById("motorcycleFields").style.display = (t === "motorcycle") ? "block" : "none";

            // 2. Logic to populate the Make dropdown
            makeSelect.innerHTML = ""; 

            var selectedList = [];
            if (t === "car") {
                selectedList = carMakes;
            } else if (t === "truck") {
                selectedList = truckMakes;
                updateAxleConfig(); // Trigger axle update immediately if switching to truck
            } else if (t === "motorcycle") {
                selectedList = motorcycleMakes;
            } else {
                var option = document.createElement("option");
                option.text = "Select Vehicle Type First";
                option.value = "";
                makeSelect.add(option);
                return;
            }

            for (var i = 0; i < selectedList.length; i++) {
                var option = document.createElement("option");
                option.text = selectedList[i];
                option.value = selectedList[i];
                makeSelect.add(option);
            }
        }

        function updateAxleConfig() {
            var numWheels = document.getElementById("numWheels").value;
            var axleSelect = document.getElementById("axleConfig");
            
            // Clear current options
            axleSelect.innerHTML = "";

            // Get valid options based on wheel count
            var validConfigs = axleCompatibility[numWheels];

            if (validConfigs) {
                for (var i = 0; i < validConfigs.length; i++) {
                    var option = document.createElement("option");
                    option.text = validConfigs[i];
                    option.value = validConfigs[i];
                    axleSelect.add(option);
                }
            } else {
                // Fallback
                var option = document.createElement("option");
                option.text = "Select Wheels First";
                axleSelect.add(option);
            }
        }
    </script>
</head>

<body>
<div class="container">
    <h1>Create Auction Listing</h1>

    <%
        String error = (String) session.getAttribute("createError");
        if (error != null) {
            out.println("<div class='message' style='background-color: #f8d7da; color: #721c24;'>" + error + "</div>");
            session.removeAttribute("createError");
        }

        String success = (String) session.getAttribute("createOK");
        if (success != null) {
            out.println("<div class='message' style='background-color: #d4edda; color: #155724;'>" + success + "</div>");
            session.removeAttribute("createOK");
        }
    %>

    <form action="logic/submitAuction.jsp" method="POST">

        <h2>Vehicle Information</h2>

        <label>Vehicle Type</label>
        <select id="type" name="type" onchange="updateSubtype()" required>
            <option value="">Select Type...</option>
            <option value="car">Car</option>
            <option value="truck">Truck</option>
            <option value="motorcycle">Motorcycle</option>
        </select>

        <label>Make</label>
        <select id="makeSelect" name="make" required>
            <option value="">Select Vehicle Type First</option>
        </select>

        <label>Model</label>
        <input type="text" name="model" placeholder="e.g. Camry, F-150, Ninja" required>

        <label>Year</label>
        <input type="number" name="year" min="1900" max="2100" placeholder="e.g. 2024" required>

        <div id="carFields" class="subsection" style="display:none;">
            <label>Body Style</label>
            <input type="text" name="body_style" placeholder="e.g. Sedan, SUV">

            <label>Number of Doors</label>
            <input type="number" name="num_doors" min="1" max="5">
        </div>

        <div id="truckFields" class="subsection" style="display:none;">
            <label>Number of Wheels</label>
            <select id="numWheels" name="num_wheels" onchange="updateAxleConfig()">
                <option value="4">4 Wheels</option>
                <option value="6">6 Wheels (Dually)</option>
                <option value="10">10 Wheels</option>
                <option value="12">12 Wheels</option>
                <option value="18">18 Wheels (Semi)</option>
            </select>

            <label>Axle Configuration</label>
            <select id="axleConfig" name="axle_config">
                </select>
        </div>

        <div id="motorcycleFields" class="subsection" style="display:none;">
            <label>Has Sidecar</label>
            <select name="has_sidecar">
                <option value="0">No</option>
                <option value="1">Yes</option>
            </select>

            <label>Handlebar Style</label>
            <select name="handlebar_style">
                <option value="Stock / Standard">Stock / Standard</option>
                <option value="Clip-on">Clip-on</option>
                <option value="Ape Hangers">Ape Hangers</option>
                <option value="Drag Bars">Drag Bars</option>
                <option value="Clubman">Clubman</option>
                <option value="Beach Bars">Beach Bars</option>
                <option value="Motocross / Dirt">Motocross / Dirt</option>
                <option value="Z-Bar">Z-Bar</option>
                <option value="T-Bar">T-Bar</option>
                <option value="Buckhorn">Buckhorn</option>
                <option value="Other / Modified">Other / Modified</option>
            </select>
        </div>

        <h2>Auction Settings</h2>

        <label>Start Price</label>
        <input type="number" name="start_price" step="0.01" required>

        <label>Minimum Price</label>
        <input type="number" name="min_price" step="0.01" required>

        <label>Bid Increment</label>
        <input type="number" name="bid_increment" step="0.01" required>

        <label>Auction End Time</label>
        <input type="datetime-local" name="end_time" required>

        <input type="submit" value="Create Auction">

    </form>
</div>
<%@ include file="globalNotification.jsp" %>
</body>
</html>