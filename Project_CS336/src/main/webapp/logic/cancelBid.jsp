<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.cs336_project.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="jakarta.servlet.http.*,jakarta.servlet.*" %>
<%
    // User must be logged in
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    // Get parameters
    String bidIdStr = request.getParameter("bid_id");
    String auctionIdStr = request.getParameter("auction_id");

    if (bidIdStr == null || auctionIdStr == null) {
        session.setAttribute("bidError", "Invalid bid cancellation request.");
        response.sendRedirect("../auctions.jsp");
        return;
    }

    int bidId = Integer.parseInt(bidIdStr);
    int auctionId = Integer.parseInt(auctionIdStr);

    AppDB db = new AppDB();
    Connection con = db.getConnection();
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        // First confirm this user is the seller for this auction
        ps = con.prepareStatement(
            "SELECT seller_id FROM auctions WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (!rs.next()) {
            session.setAttribute("bidError", "Auction not found.");
            response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
            return;
        }

        int sellerId = rs.getInt("seller_id");
        rs.close();
        ps.close();

        // Make sure only seller can cancel
        if (sellerId != userId) {
            session.setAttribute("bidError", "You are not the seller and cannot cancel bids.");
            response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
            return;
        }

        // Mark bid as cancelled_by_seller
        ps = con.prepareStatement(
            "UPDATE bids SET cancelled_by_seller = 1 WHERE bid_id = ?"
        );
        ps.setInt(1, bidId);
        ps.executeUpdate();
        ps.close();

        // Notify seller that cancellation succeeded
        session.setAttribute("alertOK", "Bid has been cancelled.");

        // Redirect back to auction
        response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
        return;

    } catch (Exception e) {
        session.setAttribute("bidError", "Error cancelling bid: " + e.getMessage());
        response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
        return;

    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>