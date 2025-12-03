<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<!DOCTYPE html>
<html>
<head>
    <title>View Item / Bid</title>
    <style>
        table { border-collapse: collapse; width: 60%; margin-bottom: 20px; }
        th, td { padding: 8px; border: 1px solid #ccc; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>

<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    int itemId = Integer.parseInt(request.getParameter("item_id"));

    AppDB db = new AppDB();
    Connection con = db.getConnection();

    // 1. Get item auction details + vehicle info + subtype info
    String sql =
        "SELECT i.*, u.username AS seller_username, " +
        "       v.make, v.model, v.year, v.type, " +
        "       c.body_style, c.num_doors, " +
        "       t.num_wheels, t.axle_config, " +
        "       m.has_sidecar, m.handlebar_style, " +
        "       (SELECT MAX(bid_amount) FROM bids WHERE item_id = i.id) AS highest_bid " +
        "FROM items i " +
        "JOIN users u ON i.seller_id = u.id " +
        "JOIN vehicles v ON i.vehicle_id = v.vehicle_id " +
        "LEFT JOIN cars c ON v.vehicle_id = c.vehicle_id " +
        "LEFT JOIN trucks t ON v.vehicle_id = t.vehicle_id " +
        "LEFT JOIN motorcycles m ON v.vehicle_id = m.vehicle_id " +
        "WHERE i.id = ?";

    PreparedStatement ps = con.prepareStatement(sql);
    ps.setInt(1, itemId);
    ResultSet rs = ps.executeQuery();

    if (!rs.next()) {
        out.println("<h3>Invalid item.</h3>");
        return;
    }

    String type = rs.getString("type");

    double highestBid = rs.getDouble("highest_bid");
    if (rs.wasNull()) {
        highestBid = rs.getDouble("start_price");
    }

    boolean isSeller = (rs.getInt("seller_id") == userId);
%>

<h1>Auction: <%= rs.getString("make") %> <%= rs.getString("model") %> (<%= rs.getInt("year") %>)</h1>

<h3>Vehicle Details</h3>
<table>
    <tr><th>Make</th><td><%= rs.getString("make") %></td></tr>
    <tr><th>Model</th><td><%= rs.getString("model") %></td></tr>
    <tr><th>Year</th><td><%= rs.getInt("year") %></td></tr>
    <tr><th>Type</th><td><%= type %></td></tr>

<% if ("car".equals(type)) { %>
    <tr><th>Body Style</th><td><%= rs.getString("body_style") %></td></tr>
    <tr><th>Doors</th><td><%= rs.getInt("num_doors") %></td></tr>
<% } else if ("truck".equals(type)) { %>
    <tr><th>Wheels</th><td><%= rs.getInt("num_wheels") %></td></tr>
    <tr><th>Axle Config</th><td><%= rs.getString("axle_config") %></td></tr>
<% } else if ("motorcycle".equals(type)) { %>
    <tr><th>Sidecar</th><td><%= rs.getBoolean("has_sidecar") ? "Yes" : "No" %></td></tr>
    <tr><th>Handlebar Style</th><td><%= rs.getString("handlebar_style") %></td></tr>
<% } %>
</table>

<h3>Auction Details</h3>
<table>
    <tr><th>Seller</th><td><%= rs.getString("seller_username") %></td></tr>
    <tr><th>Start Price</th><td>$<%= rs.getDouble("start_price") %></td></tr>
    <tr><th>Minimum Price</th><td>$<%= rs.getDouble("min_price") %></td></tr>
    <tr><th>Bid Increment</th><td>$<%= rs.getDouble("bid_increment") %></td></tr>
    <tr><th>Current Highest Bid</th><td>$<%= highestBid %></td></tr>
    <tr><th>Auction Ends</th><td><%= rs.getTimestamp("end_time") %></td></tr>
</table>

<% if (isSeller) { %>
    <p style="color:red;"><b>You CANNOT bid on your own item.</b></p>
<% } else { %>

<h3>Place a Bid</h3>
<form action="submitBid.jsp" method="POST">
    <input type="hidden" name="item_id" value="<%= itemId %>">

    Your Bid: <input type="number" name="bid_amount" step="0.01" required><br><br>

    Maximum Auto-Bid (optional): 
    <input type="number" name="max_auto_bid" step="0.01"><br><br>

    <button type="submit">Submit Bid</button>
</form>

<% } %>

<h3>Bidding History</h3>

<%
    String sql2 =
        "SELECT b.bid_amount, b.max_auto_bid, b.bid_time, u.username " +
        "FROM bids b JOIN users u ON b.bidder_id = u.id " +
        "WHERE b.item_id = ? ORDER BY b.bid_time DESC";

    PreparedStatement ps2 = con.prepareStatement(sql2);
    ps2.setInt(1, itemId);
    ResultSet rs2 = ps2.executeQuery();
%>

<table>
    <tr><th>Bidder</th><th>Bid</th><th>Auto Max</th><th>Time</th></tr>

<%
    while (rs2.next()) {
%>
    <tr>
        <td><%= rs2.getString("username") %></td>
        <td>$<%= rs2.getDouble("bid_amount") %></td>
        <td><%= rs2.getString("max_auto_bid") == null ? "-" : "$" + rs2.getDouble("max_auto_bid") %></td>
        <td><%= rs2.getTimestamp("bid_time") %></td>
    </tr>
<%
    }
%>

</table>

</body>
</html>
