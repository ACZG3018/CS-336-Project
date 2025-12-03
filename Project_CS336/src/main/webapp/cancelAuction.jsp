<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>

<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");

    String auctionIdStr = request.getParameter("auction_id");
    if (auctionIdStr == null) {
        session.setAttribute("auctionError", "Missing auction ID.");
        response.sendRedirect("auctions.jsp");
        return;
    }

    int auctionId = Integer.parseInt(auctionIdStr);

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        // Verify seller owns this auction
        ps = con.prepareStatement(
            "SELECT seller_id FROM auctions WHERE auction_id = ? AND is_active = 1"
        );
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (!rs.next()) {
            session.setAttribute("auctionError",
                "Auction not found or it is already inactive.");
            response.sendRedirect("auctions.jsp");
            return;
        }

        int sellerId = rs.getInt("seller_id");
        rs.close();
        ps.close();

        if (sellerId != userId) {
            session.setAttribute("auctionError",
                "You can only cancel auctions you created.");
            response.sendRedirect("auctions.jsp");
            return;
        }

        // Cancel the auction
        ps = con.prepareStatement(
            "UPDATE auctions SET is_active = 0 WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        ps.executeUpdate();
        ps.close();

        // Mark bids as cancelled_by_seller = 1
        ps = con.prepareStatement(
            "UPDATE bids SET cancelled_by_seller = 1 WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        ps.executeUpdate();
        ps.close();

        // Optional: remove auto-bid settings
        ps = con.prepareStatement(
            "DELETE FROM auto_bids WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        ps.executeUpdate();
        ps.close();

        session.setAttribute("auctionOK",
            "Auction #" + auctionId + " has been cancelled.");
        response.sendRedirect("auctions.jsp");
        return;

    } catch (Exception e) {
        session.setAttribute("auctionError",
            "Error cancelling auction: " + e.getMessage());
        response.sendRedirect("auctions.jsp");
        return;

    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>