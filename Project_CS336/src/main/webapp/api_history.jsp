<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>

<%
    Integer userId = (Integer) session.getAttribute("user_id");
    
    // Return empty array if not logged in
    if (userId == null) {
        out.print("[]");
        return;
    }

    AppDB db = new AppDB();
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = db.getConnection();
        
        // 1. The Query
        String sql = "SELECT DISTINCT a.auction_id, a.start_price, a.current_highest_bid, " +
                     "v.make, v.model, v.year, a.end_time " +
                     "FROM bids b " +
                     "JOIN auctions a ON b.auction_id = a.auction_id " +
                     "JOIN vehicles v ON a.vehicle_id = v.vehicle_id " +
                     "WHERE b.bidder_id = ? " +
                     "ORDER BY a.end_time DESC";

        ps = con.prepareStatement(sql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        // 2. Build JSON Manually
        StringBuilder json = new StringBuilder("[");
        boolean first = true;

        while (rs.next()) {
            if (!first) { json.append(","); }
            first = false;

            // Determine display price
            double price = rs.getObject("current_highest_bid") != null ? 
                           rs.getDouble("current_highest_bid") : 
                           rs.getDouble("start_price");

            // Construct valid JSON string for this item
            // Example: {"id":1, "item":"2020 Toyota Camry", "price":5000.00, "endTime":"..."}
            json.append("{");
            json.append("\"id\":").append(rs.getInt("auction_id")).append(",");
            json.append("\"item\":\"").append(rs.getInt("year")).append(" ")
                .append(rs.getString("make")).append(" ")
                .append(rs.getString("model")).append("\",");
            json.append("\"price\":\"").append(String.format(Locale.US, "%.2f", price)).append("\",");
            json.append("\"endTime\":\"").append(rs.getTimestamp("end_time")).append("\"");
            json.append("}");
        }

        json.append("]");
        out.print(json.toString());

    } catch (Exception e) {
        // Return empty array on error so the popup doesn't break
        out.print("[]");
        e.printStackTrace(); 
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignore) {}
        if (ps != null) try { ps.close(); } catch (SQLException ignore) {}
        if (con != null) try { con.close(); } catch (SQLException ignore) {}
    }
%>