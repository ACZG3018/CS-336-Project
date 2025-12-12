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

    String auctionIdStr = request.getParameter("auction_id");
    if (auctionIdStr == null) {
        out.println("Missing auction_id.");
        return;
    }
    int auctionId = Integer.parseInt(auctionIdStr);

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    AppDB db = new AppDB();
    con = db.getConnection();
    String sql =
        "SELECT a.*, v.make, v.model, v.year, v.type, " +
        "c.body_style, c.num_doors, " +
        "t.num_wheels, t.axle_config, " +
        "m.has_sidecar, m.handlebar_style " +
        "FROM auctions a " +
        "JOIN vehicles v ON a.vehicle_id = v.vehicle_id " +
        "LEFT JOIN cars c ON v.vehicle_id = c.vehicle_id " +
        "LEFT JOIN trucks t ON v.vehicle_id = t.vehicle_id " +
        "LEFT JOIN motorcycles m ON v.vehicle_id = m.vehicle_id " +
        "WHERE a.auction_id = ?";
    ps = con.prepareStatement(sql);
    ps.setInt(1, auctionId);
    rs = ps.executeQuery();

    if (!rs.next()) {
        out.println("Auction not found.");
        return;
    }

    int sellerId = rs.getInt("seller_id");
    String make = rs.getString("make");
    String model = rs.getString("model");
    int year = rs.getInt("year");
    String type = rs.getString("type");

    double startPrice = rs.getDouble("start_price");
    double increment = rs.getDouble("bid_increment");
    Timestamp endTime = rs.getTimestamp("end_time");

    // --- BID LOGIC ---
    double dbCurrentBid = rs.getDouble("current_highest_bid");
    boolean hasBids = !rs.wasNull();
    double displayBid = hasBids ? dbCurrentBid : 0.0;
    double minNextBid = hasBids ? (dbCurrentBid + increment) : startPrice;

    // --- STATUS LOGIC ---
    // 1. Get status from DB (default to active if missing)
    String dbStatus = "active";
    try { dbStatus = rs.getString("status"); } catch(Exception e) {} // Safe failover if column missing
    if (dbStatus == null) dbStatus = "active";

    // 2. Check if time has passed
    boolean isTimeUp = endTime.before(new java.sql.Timestamp(System.currentTimeMillis()));

    // 3. Determine Display Status
    String displayStatus = "ACTIVE";
    String statusColorClass = "status-active";
    boolean isBiddingOpen = true;

    if ("closed".equalsIgnoreCase(dbStatus)) {
        displayStatus = "CLOSED (SOLD)";
        statusColorClass = "status-closed";
        isBiddingOpen = false;
    } else if (isTimeUp) {
        displayStatus = "PENDING PAYMENT"; // Time up, but not marked closed/paid yet
        statusColorClass = "status-pending";
        isBiddingOpen = false;
    } else {
        // Normal active state
        displayStatus = "ACTIVE";
        statusColorClass = "status-active";
        isBiddingOpen = true;
    }

    String bodyStyle = rs.getString("body_style");
    String numDoors = rs.getString("num_doors");
    String numWheels = rs.getString("num_wheels");
    String axleConfig = rs.getString("axle_config");
    String hasSidecar = rs.getString("has_sidecar");
    String handlebarStyle = rs.getString("handlebar_style");
    rs.close();
    ps.close();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Auction Details</title>
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
            max-width: 800px;
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 5px; /* Reduced to fit status below */
        }
        
        /* --- STATUS BADGE STYLES --- */
        .status-badge {
            text-align: center;
            padding: 8px;
            margin-bottom: 20px;
            font-weight: bold;
            color: white;
            border-radius: 4px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-size: 0.9em;
        }
        .status-active { background-color: #28a745; }
        .status-pending { background-color: #ffc107; color: #444; }
        .status-closed { background-color: #dc3545; }
        /* -------------------------- */

        h2 {
            color: #555;
            font-size: 1.2em;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
            margin-top: 30px;
            margin-bottom: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            color: #555;
            font-weight: 600;
            width: 30%;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .section {
            margin-top: 20px;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 6px;
            border: 1px solid #e0e0e0;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #666;
            font-weight: bold;
        }
        input[type="number"], input[type="text"] {
            width: 100%;
            padding: 10px;
            margin-bottom: 15px;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.3s;
            margin-right: 10px;
        }
        button:hover {
            background-color: #0056b3;
        }
        button.secondary {
            background-color: #6c757d;
        }
        button.secondary:hover {
            background-color: #5a6268;
        }
        button.danger {
            background-color: #dc3545;
        }
        button.danger:hover {
            background-color: #c82333;
        }
        button.quick-bid {
            background-color: #28a745;
            width: 100%;
            margin-top: 10px;
            font-size: 16px;
            padding: 12px;
        }
        button.quick-bid:hover {
            background-color: #218838;
        }
        .error {
            color: #721c24;
            background-color: #f8d7da;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 15px;
            text-align: center;
        }
        .success {
            color: #155724;
            background-color: #d4edda;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 15px;
            text-align: center;
        }
        .bid-forms-container {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .bid-box {
            flex: 1;
            min-width: 250px;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 15px;
            color: #6c757d;
            text-decoration: none;
            font-weight: bold;
        }
        .back-link:hover {
            color: #333;
            text-decoration: underline;
        }
    </style>
</head>
<body>

<div class="container">
    
    <a href="auctions.jsp" class="back-link">&larr; Back to Auctions</a>

    <h1>Auction #<%= auctionId %>: <%= make %> <%= model %></h1>

    <div class="status-badge <%= statusColorClass %>">
        <%= displayStatus %>
    </div>

    <%
        String err = (String) session.getAttribute("bidError");
        if (err != null) {
            out.println("<div class='error'>" + err + "</div>");
            session.removeAttribute("bidError");
        }
        String ok = (String) session.getAttribute("bidOK");
        if (ok != null) {
            out.println("<div class='success'>" + ok + "</div>");
            session.removeAttribute("bidOK");
        }
    %>

    <h2>Vehicle Details</h2>
    <table>
        <tr><th>Make</th><td><%= make %></td></tr>
        <tr><th>Model</th><td><%= model %></td></tr>
        <tr><th>Year</th><td><%= year %></td></tr>
        <tr><th>Type</th><td><%= type.substring(0, 1).toUpperCase() + type.substring(1) %></td></tr>
        
        <tr><th>Specifics</th><td>
        <%
            if (type.equals("car")) {
                out.print("Body Style: " + (bodyStyle != null ? bodyStyle : "-") + ", Doors: " + (numDoors != null ? numDoors : "-"));
            }
            else if (type.equals("truck")) {
                out.print("Wheels: " + (numWheels != null ? numWheels : "-") + ", Axle: " + (axleConfig != null ? axleConfig : "-"));
            }
            else if (type.equals("motorcycle")) {
                String sidecarStr = "1".equals(hasSidecar) ? "Yes" : "No";
                out.print("Sidecar: " + sidecarStr + ", Handlebar: " + (handlebarStyle != null ? handlebarStyle : "-"));
            }
            else {
                out.print("-");
            }
        %>
        </td></tr>

        <tr><th>Start Price</th><td>$<%= String.format("%.2f", startPrice) %></td></tr>
        <tr><th>Current Highest Bid</th><td><strong style="color: #28a745; font-size: 1.1em;">$<%= String.format("%.2f", displayBid) %></strong></td></tr>
        <tr><th>Bid Increment</th><td>$<%= String.format("%.2f", increment) %></td></tr>
        <tr><th>Ends At</th><td><%= endTime %></td></tr>
    </table>

    <%
        // LOGIC: Hide Bid Section if (User is Seller) OR (Bidding is NOT open)
        if (userId != sellerId && isBiddingOpen) {
    %>
    <div class="section">
        <h2>Place a Bid</h2>
        <div class="bid-forms-container">
            
            <div class="bid-box">
                <form action="logic/submitBid.jsp" method="POST">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">
                    <input type="hidden" name="bid_amount" value="<%= minNextBid %>">
                    
                    <label>Quick Bid (Minimum)</label>
                    <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">
                        <%= hasBids ? "Bid standard increment" : "Be the first to bid!" %>
                    </div>
                    
                    <button type="submit" class="quick-bid">
                        Bid $<%= String.format("%.2f", minNextBid) %>
                    </button>
                </form>
            </div>

            <div class="bid-box">
                <form action="logic/submitBid.jsp" method="POST">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">
                    <label>Custom Bid Amount:</label>
                    <input type="number" step="0.01" name="bid_amount" placeholder="Enter amount..." required>
                    <button type="submit" style="width: 100%;">Submit Custom Bid</button>
                </form>
            </div>
        </div>
    </div>

    <div class="section">
        <h2>Automatic Bidding</h2>
        <form action="logic/enableAutoBid.jsp" method="POST">
            <input type="hidden" name="auction_id" value="<%= auctionId %>">

            <label>Max Bid (Secret Limit):</label>
            <input type="number" name="max_bid" step="0.01" placeholder="Maximum you are willing to pay">

            <label>Increment Limit (Optional):</label>
            <input type="number" name="increment" step="0.01" placeholder="Leave empty for default">

            <div style="margin-top: 10px;">
                <button type="submit" name="action" value="save">Enable Auto-Bid</button>
                <button type="submit" name="action" value="disable" class="secondary">Disable Auto-Bid</button>
            </div>
        </form>
    </div>
    <%
        } // END BIDDING SECTION
    %>

    <div class="section">
        <h2>Bid History</h2>

        <%
            ps = con.prepareStatement(
                "SELECT b.bid_amount, b.bid_time, b.max_auto_bid, u.user_name " +
                "FROM bids b JOIN users u ON b.bidder_id = u.user_id " +
                "WHERE b.auction_id = ? AND b.retracted = 0 AND b.cancelled_by_seller = 0 " +
                "ORDER BY b.bid_time DESC"
            );
            ps.setInt(1, auctionId);
            rs = ps.executeQuery();
        %>

        <table>
            <tr><th>Bidder</th><th>Amount</th><th>Auto Max</th><th>Time</th></tr>

            <%
                while (rs.next()) {
                    String bidder = rs.getString("user_name");
                    double amt = rs.getDouble("bid_amount");
                    Object mxObj = rs.getObject("max_auto_bid");
                    String mx = (mxObj == null ? "-" : ("$" + rs.getDouble("max_auto_bid")));
            %>

            <tr>
                <td><%= bidder %></td>
                <td>$<%= String.format("%.2f", amt) %></td>
                <td><%= mx %></td>
                <td><%= rs.getTimestamp("bid_time") %></td>
            </tr>

            <%
                }
                rs.close();
                ps.close();
            %>

        </table>
    </div>

    <%
        // Only seller sees this
        if (userId == sellerId) {
    %>
    <div class="section" style="border-color: #dc3545;">
        <h2 style="color: #dc3545; border-color: #f5c6cb;">Seller Options</h2>
        
        <% if(isBiddingOpen) { %>
            <form action="logic/cancelAuction.jsp" method="POST">
                <input type="hidden" name="auction_id" value="<%= auctionId %>">
                <p style="color: #721c24; margin-bottom: 10px;">Warning: Canceling an auction cannot be undone.</p>
                <button type="submit" class="danger">Cancel Auction</button>
            </form>
        <% } else { %>
            <p style="color: #666; font-style: italic;">This auction has ended. You cannot cancel it now.</p>
        <% } %>
        
    </div>
    <%
        }
    %>

</div>

<%@ include file="globalNotification.jsp" %>
</body>
</html>