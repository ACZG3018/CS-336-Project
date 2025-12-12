<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String auctionIdStr = request.getParameter("auction_id");
    String amountStr = request.getParameter("bid_amount");

    if (auctionIdStr == null || amountStr == null) {
        session.setAttribute("bidError", "Missing bid fields.");
        response.sendRedirect("../auctions.jsp");
        return;
    }

    int auctionId = Integer.parseInt(auctionIdStr);
    double bidAmount = Double.parseDouble(amountStr);

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        AppDB db = new AppDB();
        con = db.getConnection();

        // Load auction data
        ps = con.prepareStatement("SELECT start_price, bid_increment, current_highest_bid FROM auctions WHERE auction_id = ?");
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (!rs.next()) {
            session.setAttribute("bidError", "Auction not found.");
            response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
            return;
        }

        double startPrice = rs.getDouble("start_price");
        double increment = rs.getDouble("bid_increment");
        Double current = (rs.getObject("current_highest_bid") == null)
                           ? null
                           : rs.getDouble("current_highest_bid");
        rs.close();
        ps.close();

        double minRequired = (current == null) ? startPrice : (current + increment);

        if (bidAmount < minRequired) {
            session.setAttribute("bidError", "Bid too low. Minimum required: " + minRequired);
            response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
            return;
        }

        // Insert bid
        ps = con.prepareStatement(
            "INSERT INTO bids (auction_id, bidder_id, bid_amount, max_auto_bid) VALUES (?, ?, ?, NULL)"
        );
        ps.setInt(1, auctionId);
        ps.setInt(2, userId);
        ps.setDouble(3, bidAmount);
        ps.executeUpdate();
        ps.close();

        // Update auction highest bid
        ps = con.prepareStatement(
            "UPDATE auctions SET current_highest_bid = ?, current_highest_bidder = ? WHERE auction_id = ?"
        );
        ps.setDouble(1, bidAmount);
        ps.setInt(2, userId);
        ps.setInt(3, auctionId);
        ps.executeUpdate();
        ps.close();

        // TRIGGER AUTO-BID ENGINE
        response.sendRedirect("autoBidEngine.jsp?auction_id=" + auctionId);
        return;

    } catch (Exception e) {
        session.setAttribute("bidError", "Error placing bid: " + e.getMessage());
        response.sendRedirect("../viewAuction.jsp?auction_id=" + auctionId);
        return;

    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>