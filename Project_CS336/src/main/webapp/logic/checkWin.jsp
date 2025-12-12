<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    // Prevent browser caching so it always checks the latest status
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    
    Integer userId = (Integer) session.getAttribute("user_id");

    if (userId == null) {
        out.print("{\"found\": false}");
        return;
    }

    AppDB db = new AppDB();
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = db.getConnection();
        
        // CHECK: Ensure your table has 'status', 'end_time', 'current_highest_bidder', 'min_price'
        String sql = "SELECT auction_id, current_highest_bid " +
                     "FROM auctions " +
                     "WHERE end_time < NOW() " +
                     "AND current_highest_bidder = ? " +
                     "AND current_highest_bid >= min_price " +
                     "AND (status IS NULL OR status != 'closed') " + 
                     "LIMIT 1";

        ps = con.prepareStatement(sql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            int id = rs.getInt("auction_id");
            double amount = rs.getDouble("current_highest_bid");
            // Manual JSON construction
            out.print("{\"found\": true, \"auction_id\": " + id + ", \"amount\": " + amount + "}");
        } else {
            out.print("{\"found\": false}");
        }
    } catch (Exception e) {
        // Log error to server console, return false to client
        e.printStackTrace();
        out.print("{\"found\": false, \"error\": \"Server error\"}");
    } finally {
        if (rs != null) rs.close();
        if (ps != null) ps.close();
        if (con != null) con.close();
    }
%>