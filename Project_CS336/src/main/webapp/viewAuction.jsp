<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>

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
    double currentBid = rs.getDouble("current_highest_bid");
    boolean hadBid = !rs.wasNull();
    if (!hadBid) currentBid = startPrice;

    double increment = rs.getDouble("bid_increment");
    Timestamp endTime = rs.getTimestamp("end_time");

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
        table { border-collapse: collapse; width: 70%; }
        th, td { border: 1px solid #ccc; padding: 8px; }
        th { background: #eee; }
        .section { margin-top: 20px; }
        .error { color: red; }
        .success { color: green; }
    </style>
</head>
<body>

<h1>Auction #<%= auctionId %> - <%= make %> <%= model %> (<%= year %>)</h1>

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
<tr><th>Type</th><td><%= type %></td></tr>

<tr><th>Subtype</th><td>
<%
    if (type.equals("car")) {
        out.print("Body Style: " + bodyStyle + ", Doors: " + numDoors);
    }
    else if (type.equals("truck")) {
        out.print("Wheels: " + numWheels + ", Axle: " + axleConfig);
    }
    else if (type.equals("motorcycle")) {
        out.print("Sidecar: " + (("1".equals(hasSidecar)) ? "Yes" : "No") +
                  ", Handlebar: " + handlebarStyle);
    }
    else {
        out.print("-");
    }
%>
</td></tr>

<tr><th>Start Price</th><td>$<%= startPrice %></td></tr>
<tr><th>Current Highest Bid</th><td>$<%= currentBid %></td></tr>
<tr><th>Bid Increment</th><td>$<%= increment %></td></tr>
<tr><th>Ends At</th><td><%= endTime %></td></tr>
</table>

<div class="section">
    <h2>Place a Bid</h2>
    <form action="submitBid.jsp" method="POST">
        <input type="hidden" name="auction_id" value="<%= auctionId %>">
        <label>Your Bid:</label>
        <input type="number" step="0.01" name="bid_amount" required>
        <button type="submit">Submit Bid</button>
    </form>
</div>

<div class="section">
    <h2>Automatic Bidding</h2>
    <form action="enableAutoBid.jsp" method="POST">
        <input type="hidden" name="auction_id" value="<%= auctionId %>">

        <label>Enable Auto-Bid:</label><br><br>

        Max Bid:
        <input type="number" name="max_bid" step="0.01"><br><br>

        Increment:
        <input type="number" name="increment" step="0.01"><br><br>

        <button type="submit" name="action" value="save">Save Auto-Bid</button>
        <button type="submit" name="action" value="disable">Disable Auto-Bid</button>
    </form>
</div>

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
    <td>$<%= amt %></td>
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
<div class="section">
    <h2>Seller Options</h2>
    <form action="cancelAuction.jsp" method="POST">
        <input type="hidden" name="auction_id" value="<%= auctionId %>">
        <button type="submit" style="color:red;">Cancel Auction</button>
    </form>
</div>
<%
    }
%>

</body>
</html>