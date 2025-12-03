<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    AppDB db = new AppDB();
    Connection con = db.getConnection();
    PreparedStatement ps = null;
    ResultSet rs = null;

    String sql =
        "SELECT a.auction_id, a.start_price, a.min_price, a.current_highest_bid, " +
        "a.end_time, a.bid_increment, a.current_highest_bidder, " +
        "v.vehicle_id, v.make, v.model, v.year, v.type, " +
        "c.body_style, c.num_doors, " +
        "t.num_wheels, t.axle_config, " +
        "m.has_sidecar, m.handlebar_style " +
        "FROM auctions a " +
        "JOIN vehicles v ON a.vehicle_id = v.vehicle_id " +
        "LEFT JOIN cars c ON v.vehicle_id = c.vehicle_id " +
        "LEFT JOIN trucks t ON v.vehicle_id = t.vehicle_id " +
        "LEFT JOIN motorcycles m ON v.vehicle_id = m.vehicle_id " +
        "WHERE a.is_active = 1 " +
        "ORDER BY a.end_time ASC";

    ps = con.prepareStatement(sql);
    rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
<title>Active Auctions</title>
<style>
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; }
th { background-color: #eee; }
</style>
</head>
<body>

<h1>Active Auctions</h1>

<a href="createListing.jsp">Create New Auction</a>
<br><br>

<table>
<tr>
    <th>Make</th>
    <th>Model</th>
    <th>Year</th>
    <th>Type</th>
    <th>Subtype</th>
    <th>Current Bid</th>
    <th>Ends</th>
    <th>Action</th>
</tr>

<%
while (rs.next()) {

    double highest = rs.getDouble("current_highest_bid");
    if (rs.wasNull()) {
        highest = rs.getDouble("start_price");
    }

    String type = rs.getString("type");
    String subtype = "";

    if ("car".equalsIgnoreCase(type)) {
        subtype = "Body: " + rs.getString("body_style") +
                  ", Doors: " + rs.getInt("num_doors");
    } else if ("truck".equalsIgnoreCase(type)) {
        subtype = "Wheels: " + rs.getInt("num_wheels") +
                  ", Axle: " + rs.getString("axle_config");
    } else if ("motorcycle".equalsIgnoreCase(type)) {
        String sc = rs.getInt("has_sidecar") == 1 ? "Yes" : "No";
        subtype = "Sidecar: " + sc +
                  ", Handlebar: " + rs.getString("handlebar_style");
    }
%>

<tr>
    <td><%= rs.getString("make") %></td>
    <td><%= rs.getString("model") %></td>
    <td><%= rs.getInt("year") %></td>
    <td><%= type %></td>
    <td><%= subtype %></td>
    <td>$<%= highest %></td>
    <td><%= rs.getTimestamp("end_time") %></td>

    <td>
        <form action="viewAuction.jsp" method="GET">
            <input type="hidden" name="auction_id"
                   value="<%= rs.getInt("auction_id") %>" />
            <button type="submit">View</button>
        </form>
    </td>
</tr>

<%
}
rs.close();
ps.close();
con.close();
%>

</table>
</body>
</html>