<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String auctionIdStr = request.getParameter("auction_id");
    String maxStr = request.getParameter("max_bid");
    String incStr = request.getParameter("increment");
    String action = request.getParameter("action");

    if (auctionIdStr == null) {
        session.setAttribute("bidError", "Missing auction ID.");
        response.sendRedirect("../auctions.jsp");
        return;
    }

    int auctionId = Integer.parseInt(auctionIdStr);

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        if ("disable".equals(action)) {
            // Remove auto-bid entry
            ps = con.prepareStatement("DELETE FROM auto_bids WHERE auction_id = ? AND bidder_id = ?");
            ps.setInt(1, auctionId);
            ps.setInt(2, userId);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
            return;
        }

        double maxBid = Double.parseDouble(maxStr);
        double inc = Double.parseDouble(incStr);

        // Check if user already has auto-bid set
        ps = con.prepareStatement(
            "SELECT 1 FROM auto_bids WHERE auction_id = ? AND bidder_id = ?"
        );
        ps.setInt(1, auctionId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();
        boolean exists = rs.next();
        rs.close();
        ps.close();

        if (exists) {
            ps = con.prepareStatement(
                "UPDATE auto_bids SET max_bid = ?, increment = ? WHERE auction_id = ? AND bidder_id = ?"
            );
            ps.setDouble(1, maxBid);
            ps.setDouble(2, inc);
            ps.setInt(3, auctionId);
            ps.setInt(4, userId);
            ps.executeUpdate();
            ps.close();
        } else {
            ps = con.prepareStatement(
                "INSERT INTO auto_bids (auction_id, bidder_id, max_bid, increment) VALUES (?, ?, ?, ?)"
            );
            ps.setInt(1, auctionId);
            ps.setInt(2, userId);
            ps.setDouble(3, maxBid);
            ps.setDouble(4, inc);
            ps.executeUpdate();
            ps.close();
        }

        // Place initial minimal bid required
        ps = con.prepareStatement(
            "SELECT start_price, bid_increment, current_highest_bid FROM auctions WHERE auction_id = ?"
        );
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        double start = 0;
        double incReq = 0;
        Double current = null;

        if (rs.next()) {
            start = rs.getDouble("start_price");
            incReq = rs.getDouble("bid_increment");
            current = (rs.getObject("current_highest_bid") == null)
                        ? null
                        : rs.getDouble("current_highest_bid");
        }
        rs.close();
        ps.close();

        double minNeeded = (current == null) ? start : (current + incReq);

        if (maxBid >= minNeeded) {
            ps = con.prepareStatement(
                "INSERT INTO bids (auction_id, bidder_id, bid_amount, max_auto_bid) VALUES (?, ?, ?, ?)"
            );
            ps.setInt(1, auctionId);
            ps.setInt(2, userId);
            ps.setDouble(3, minNeeded);
            ps.setDouble(4, maxBid);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "UPDATE auctions SET current_highest_bid = ?, current_highest_bidder = ? WHERE auction_id = ?"
            );
            ps.setDouble(1, minNeeded);
            ps.setInt(2, userId);
            ps.setInt(3, auctionId);
            ps.executeUpdate();
            ps.close();
        }

        // TRIGGER AUTO-BID ENGINE
        response.sendRedirect("../autoBidEngine.jsp?auction_id=" + auctionId);
        return;

    } catch (Exception e) {
        session.setAttribute("bidError", "Error saving auto-bid: " + e.getMessage());
        response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
        return;

    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>