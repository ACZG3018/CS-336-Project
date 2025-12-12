<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>

<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String searchKeyword = request.getParameter("keyword");
    AppDB db = new AppDB();
    Connection con = db.getConnection();
    
    // --- QUERY CONSTRUCTION ---
    StringBuilder sqlBuilder = new StringBuilder();
    sqlBuilder.append("SELECT a.auction_id, a.seller_id, a.start_price, a.min_price, a.current_highest_bid, "); 
    sqlBuilder.append("a.end_time, a.bid_increment, a.current_highest_bidder, ");
    sqlBuilder.append("v.vehicle_id, v.make, v.model, v.year, v.type, ");
    sqlBuilder.append("c.body_style, c.num_doors, ");
    sqlBuilder.append("t.num_wheels, t.axle_config, ");
    sqlBuilder.append("m.has_sidecar, m.handlebar_style ");
    sqlBuilder.append("FROM auctions a ");
    sqlBuilder.append("JOIN vehicles v ON a.vehicle_id = v.vehicle_id ");
    sqlBuilder.append("LEFT JOIN cars c ON v.vehicle_id = c.vehicle_id ");
    sqlBuilder.append("LEFT JOIN trucks t ON v.vehicle_id = t.vehicle_id ");
    sqlBuilder.append("LEFT JOIN motorcycles m ON v.vehicle_id = m.vehicle_id ");
    sqlBuilder.append("WHERE a.status = 'active' ");
    
    if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
        sqlBuilder.append("AND (v.make LIKE ? OR v.model LIKE ?) ");
    }
    sqlBuilder.append("ORDER BY a.end_time ASC");

    PreparedStatement ps = con.prepareStatement(sqlBuilder.toString());
    if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
        String likePattern = "%" + searchKeyword + "%";
        ps.setString(1, likePattern);
        ps.setString(2, likePattern);
    }
    
    ResultSet rs = ps.executeQuery();
    
    // --- STRICT SEPARATION OF DATA ---
    List<Map<String, Object>> marketplaceAuctions = new ArrayList<>(); // ONLY other people's stuff
    List<Map<String, Object>> myListings = new ArrayList<>();          // ONLY my stuff
    
    while(rs.next()) {
        Map<String, Object> row = new HashMap<>();
        row.put("auction_id", rs.getInt("auction_id"));
        row.put("make", rs.getString("make"));
        row.put("model", rs.getString("model"));
        row.put("year", rs.getInt("year"));
        row.put("type", rs.getString("type"));
        row.put("end_time", rs.getTimestamp("end_time"));
        
        double highest = rs.getDouble("current_highest_bid");
        if (rs.wasNull()) highest = rs.getDouble("start_price");
        row.put("price", highest);

        // Subtype Logic
        String type = rs.getString("type");
        String subtype = "";
        if ("car".equalsIgnoreCase(type)) {
            subtype = "Body: " + rs.getString("body_style") + ", Doors: " + rs.getInt("num_doors");
        } else if ("truck".equalsIgnoreCase(type)) {
            subtype = "Wheels: " + rs.getInt("num_wheels") + ", Axle: " + rs.getString("axle_config");
        } else if ("motorcycle".equalsIgnoreCase(type)) {
            subtype = "Sidecar: " + (rs.getInt("has_sidecar")==1?"Yes":"No") + ", Handle: " + rs.getString("handlebar_style");
        }
        row.put("subtype", subtype);
        
        // --- LOGIC CHANGE: STRICT SEPARATION ---
        if (rs.getInt("seller_id") == userId) {
            myListings.add(row);
        } else {
            marketplaceAuctions.add(row);
        }
    }
    
    rs.close();
    con.close();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Active Auctions</title>
    <style>
        /* --- GENERAL LAYOUT --- */
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f7f6;
            color: #333;
            margin: 0;
            padding: 40px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        h1 { color: #2c3e50; margin-bottom: 20px; font-weight: 600; }

        /* --- RULES BOX --- */
        .rules-box {
            background-color: #fff3cd;
            border: 1px solid #ffeeba;
            color: #856404;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 8px;
            width: 100%;
            max-width: 1200px;
            box-sizing: border-box;
        }
        .rules-box h3 { margin-top: 0; margin-bottom: 10px; font-size: 1.2rem; }
        .rules-box ul { margin: 0; padding-left: 20px; }
        .rules-box li { margin-bottom: 5px; }

        /* --- TOP BUTTONS --- */
        .top-buttons { margin-bottom: 30px; display: flex; gap: 15px; }
        .btn-link {
            display: inline-block; padding: 10px 20px;
            text-decoration: none; border-radius: 5px;
            font-weight: bold; color: white; border: none;
            cursor: pointer; font-size: 1rem;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .btn-green { background-color: #27ae60; }
        .btn-purple { background-color: #8e44ad; }
        .btn-blue { background-color: #2980b9; }

        /* --- SEARCH BAR --- */
        .search-container {
            background: white; padding: 20px;
            border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            margin-bottom: 30px; display: flex; gap: 10px;
            align-items: center; width: 100%; max-width: 1200px;
            box-sizing: border-box;
        }
        .search-input { flex-grow: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 1rem; }
        .search-btn { background-color: #34495e; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }

        /* --- TAB CONTAINER --- */
        .tab-container {
            width: 100%;
            max-width: 1200px;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
        }

        .tab-header {
            background-color: #4361ee;
            padding: 10px 20px 0 20px;
            display: flex;
            gap: 5px;
        }

        .tab-btn {
            background-color: rgba(255, 255, 255, 0.5);
            color: white;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 12px 24px;
            transition: 0.3s;
            font-size: 1rem;
            font-weight: 600;
            border-top-left-radius: 8px;
            border-top-right-radius: 8px;
            margin-bottom: 0;
        }

        .tab-btn:hover {
            background-color: rgba(255, 255, 255, 0.8);
            color: #4361ee;
        }

        .tab-btn.active {
            background-color: white;
            color: #4361ee;
            border-bottom: 2px solid white;
        }

        .tab-content {
            display: none;
            padding: 0;
            border-top: none;
            animation: fadeEffect 0.5s;
        }

        @keyframes fadeEffect {
            from {opacity: 0;}
            to {opacity: 1;}
        }

        /* --- TABLE STYLES --- */
        table { border-collapse: collapse; width: 100%; }
        th, td { padding: 15px 20px; text-align: left; }
        th { background-color: #f8f9fa; color: #333; font-weight: 700; border-bottom: 2px solid #ddd; }
        tr { border-bottom: 1px solid #eee; }
        tr:hover { background-color: #f1f1f1; }
        td:nth-child(6) { font-weight: bold; color: #27ae60; }

        .view-btn {
            background-color: #3498db; color: white; border: none;
            padding: 6px 12px; border-radius: 4px; cursor: pointer;
        }

        /* --- MODAL STYLES --- */
        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); }
        .modal-content { background-color: #fefefe; margin: 5% auto; padding: 20px; width: 80%; max-width: 800px; border-radius: 8px; }
        .close { float: right; font-size: 28px; font-weight: bold; cursor: pointer; }
    </style>
</head>
<body>

<h1>Auction Dashboard</h1>

<div class="rules-box">
    <h3>⚠ Auction Rules</h3>
    <ul>
        <li><strong>1. Information Integrity:</strong> Sellers must state the complete and correct information.</li>
        <li><strong>2. Accuracy Penalty:</strong> Incorrect info results in immediate auction elimination.</li>
        <li><strong>3. Bidding Increments:</strong> Bids must meet the minimum increment.</li>
        <li><strong>4. Seller Obligation:</strong> Sellers must sell if reserve is met.</li>
    </ul>
</div>

<div class="top-buttons">
    <a href="createListing.jsp" class="btn-link btn-green">+ Create Listing</a>
    <a href="qa.jsp" class="btn-link btn-purple">💬 Q/A Forum</a>
    <button onclick="openHistory()" class="btn-link btn-blue">📜 My Bidding History</button>
</div>

<form class="search-container" action="auctions.jsp" method="GET">
    <input type="text" name="keyword" class="search-input" 
           placeholder="Search Make or Model..." 
           value="<%= (searchKeyword != null) ? searchKeyword : "" %>">
    <button type="submit" class="search-btn">Search</button>
</form>

<div class="tab-container">
    <div class="tab-header">
        <button class="tab-btn active" onclick="openTab(event, 'Marketplace')">Marketplace</button>
        <button class="tab-btn" onclick="openTab(event, 'MyListings')">My Listings</button>
    </div>

    <div id="Marketplace" class="tab-content" style="display: block;">
        <table>
            <thead>
                <tr>
                    <th>Make</th><th>Model</th><th>Year</th><th>Type</th><th>Subtype</th><th>Current Bid</th><th>Ends</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% if (marketplaceAuctions.isEmpty()) { %>
                <tr><td colspan="8" style="text-align:center; padding:30px;">No other active auctions found.</td></tr>
            <% } else { 
                for (Map<String, Object> item : marketplaceAuctions) { %>
                <tr>
                    <td><%= item.get("make") %></td>
                    <td><%= item.get("model") %></td>
                    <td><%= item.get("year") %></td>
                    <td><%= item.get("type") %></td>
                    <td><%= item.get("subtype") %></td>
                    <td>$<%= String.format("%.2f", item.get("price")) %></td>
                    <td><%= item.get("end_time") %></td>
                    <td>
                        <form action="viewAuction.jsp" method="GET" style="margin:0;">
                            <input type="hidden" name="auction_id" value="<%= item.get("auction_id") %>" />
                            <button type="submit" class="view-btn">View</button>
                        </form>
                    </td>
                </tr>
            <% } } %>
            </tbody>
        </table>
    </div>

    <div id="MyListings" class="tab-content">
        <table>
            <thead>
                <tr>
                    <th>Make</th><th>Model</th><th>Year</th><th>Type</th><th>Subtype</th><th>Current Price</th><th>Ends</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% if (myListings.isEmpty()) { %>
                <tr><td colspan="8" style="text-align:center; padding:30px; color:#777;">You have not posted any auctions yet.</td></tr>
            <% } else { 
                for (Map<String, Object> item : myListings) { %>
                <tr>
                    <td><%= item.get("make") %></td>
                    <td><%= item.get("model") %></td>
                    <td><%= item.get("year") %></td>
                    <td><%= item.get("type") %></td>
                    <td><%= item.get("subtype") %></td>
                    <td>$<%= String.format("%.2f", item.get("price")) %></td>
                    <td><%= item.get("end_time") %></td>
                    <td>
                        <form action="viewAuction.jsp" method="GET" style="margin:0;">
                            <input type="hidden" name="auction_id" value="<%= item.get("auction_id") %>" />
                            <button type="submit" class="view-btn">Manage</button>
                        </form>
                    </td>
                </tr>
            <% } } %>
            </tbody>
        </table>
    </div>
</div>

<div id="historyModal" class="modal">
    <div class="modal-content">
        <span class="close" onclick="closeHistory()">&times;</span>
        <h2>My Bidding History</h2>
        <table style="margin-top:20px;">
            <thead><tr><th>Vehicle</th><th>Price</th><th>End Time</th><th>Action</th></tr></thead>
            <tbody id="historyTableBody"><tr><td colspan="4">Loading...</td></tr></tbody>
        </table>
    </div>
</div>

<script>
    // --- TAB LOGIC ---
    function openTab(evt, tabName) {
        var i, tabcontent, tablinks;
        
        // Hide all tab content
        tabcontent = document.getElementsByClassName("tab-content");
        for (i = 0; i < tabcontent.length; i++) {
            tabcontent[i].style.display = "none";
        }
        
        // Remove "active" class from all buttons
        tablinks = document.getElementsByClassName("tab-btn");
        for (i = 0; i < tablinks.length; i++) {
            tablinks[i].className = tablinks[i].className.replace(" active", "");
        }
        
        // Show the specific tab and add "active" to the button clicked
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.className += " active";
    }

    // --- MODAL LOGIC ---
function openHistory() {
        document.getElementById("historyModal").style.display = "block";
        const tbody = document.getElementById("historyTableBody");
        tbody.innerHTML = "<tr><td colspan='4' style='text-align:center;'>Loading...</td></tr>";

        // Fetch data from the fixed api_history.jsp
        fetch('api_history.jsp')
            .then(res => {
                // Check if response is OK
                if (!res.ok) { throw new Error("Server Error"); }
                return res.json();
            })
            .then(data => {
                tbody.innerHTML = "";
                if(data.length === 0) { 
                    tbody.innerHTML = "<tr><td colspan='4' style='text-align:center;'>No bids found.</td></tr>"; 
                    return; 
                }
                
                data.forEach(a => {
                    // Create rows using the JSON data (id, item, price, endTime)
                    tbody.innerHTML += `
                        <tr>
                            <td>\${a.item}</td>
                            <td style="color:#27ae60; font-weight:bold;">$\${a.price}</td>
                            <td>\${a.endTime}</td>
                            <td>
                                <form action='viewAuction.jsp' method='GET' style='margin:0;'>
                                    <input type='hidden' name='auction_id' value='\${a.id}'>
                                    <button class='view-btn'>View</button>
                                </form>
                            </td>
                        </tr>`;
                });
            })
            .catch(err => {
                console.error(err);
                tbody.innerHTML = "<tr><td colspan='4' style='color:red; text-align:center;'>Error loading history.</td></tr>";
            });
    }

    function closeHistory() { 
        document.getElementById("historyModal").style.display = "none"; 
    }
    
    // Close modal if user clicks outside of it
    window.onclick = function(e) { 
        if(e.target == document.getElementById("historyModal")) {
            closeHistory(); 
        }
    }
</script>

<%@ include file="globalNotification.jsp" %>
</body>
</html>