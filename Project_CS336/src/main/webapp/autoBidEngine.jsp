<%@ page import="java.sql.*, java.util.*, com.cs336_project.pkg.AppDB" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String auctionIdStr = request.getParameter("auction_id");
    if (auctionIdStr == null) {
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

        con.setAutoCommit(false);

        ps = con.prepareStatement(
            "SELECT auction_id, start_price, bid_increment, " +
            "current_highest_bid, current_highest_bidder, end_time, is_active " +
            "FROM auctions WHERE auction_id = ? FOR UPDATE"
        );
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (!rs.next()) {
            rs.close();
            ps.close();
            con.commit();
            response.sendRedirect("auctions.jsp");
            return;
        }

        double startPrice = rs.getDouble("start_price");
        double bidIncrement = rs.getDouble("bid_increment");

        Double currentBid = (rs.getObject("current_highest_bid") == null)
                            ? null
                            : rs.getDouble("current_highest_bid");
        int currentWinner = rs.getInt("current_highest_bidder");

        Timestamp endTime = rs.getTimestamp("end_time");
        int active = rs.getInt("is_active");

        rs.close();
        ps.close();

        java.util.Date now = new java.util.Date();
        if (active != 1 || (endTime != null && now.after(endTime))) {
            con.commit();
            response.sendRedirect("viewAuction.jsp?auction_id=" + auctionId);
            return;
        }


        while (true) {
            ps = con.prepareStatement(
                "SELECT auctionbid_id, bidder_id, max_bid, increment " +
                "FROM auto_bids WHERE auction_id = ? ORDER BY max_bid DESC, auctionbid_id ASC"
            );
            ps.setInt(1, auctionId);
            rs = ps.executeQuery();

            List<Map<String, Object>> autoList = new ArrayList<Map<String, Object>>();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<String, Object>();
                row.put("auctionbid_id", rs.getInt("auctionbid_id"));
                row.put("bidder_id", rs.getInt("bidder_id"));
                row.put("max_bid", rs.getDouble("max_bid"));
                row.put("increment", rs.getDouble("increment"));
                autoList.add(row);
            }
            rs.close();
            ps.close();

            if (autoList.size() == 0) break;

            double display = (currentBid == null) ? startPrice : currentBid;

            // CASE A: no current bid yet -> top auto bidder places initial bid
            if (currentBid == null) {
                Map<String, Object> top = autoList.get(0);
                int bidder = (Integer) top.get("bidder_id");
                double max = (Double) top.get("max_bid");
                double place = Math.min(max, startPrice);
                if (place < startPrice) place = startPrice;

                // insert initial auto bid
                PreparedStatement ins = null;
                try {
                    ins = con.prepareStatement(
                        "INSERT INTO bids (auction_id, bidder_id, bid_amount, max_auto_bid, bid_time) " +
                        "VALUES (?, ?, ?, ?, NOW())"
                    );
                    ins.setInt(1, auctionId);
                    ins.setInt(2, bidder);
                    ins.setDouble(3, place);
                    ins.setDouble(4, max);
                    ins.executeUpdate();
                } finally {
                    try { if (ins != null) ins.close(); } catch (Exception ex) {}
                }

                PreparedStatement up = null;
                try {
                    up = con.prepareStatement(
                        "UPDATE auctions SET current_highest_bid = ?, current_highest_bidder = ? WHERE auction_id = ?"
                    );
                    up.setDouble(1, place);
                    up.setInt(2, bidder);
                    up.setInt(3, auctionId);
                    up.executeUpdate();
                } finally {
                    try { if (up != null) up.close(); } catch (Exception ex) {}
                }

                currentBid = place;
                currentWinner = bidder;
                // loop again to let others counter
                continue;
            }

            // CASE B: there is a current winner
            // find highest auto bidder that is NOT the current winner (challenger)
            Map<String, Object> challenger = null;
            for (Map<String,Object> row : autoList) {
                if (((Integer) row.get("bidder_id")) != currentWinner) {
                    challenger = row;
                    break;
                }
            }

            if (challenger == null) {
                // no challengers remain
                break;
            }

            int chalUser = (Integer) challenger.get("bidder_id");
            double chalMax = (Double) challenger.get("max_bid");
            double chalInc = (Double) challenger.get("increment");

            double minNext = currentBid + bidIncrement;
            // challenger attempts minimal necessary increase, but cannot exceed their max
            double chalBid = Math.min(chalMax, minNext);
            if (chalBid < minNext) {
                // challenger can't reach the minimal required amount
                break;
            }

            // place challenger bid
            PreparedStatement ins2 = null;
            try {
                ins2 = con.prepareStatement(
                    "INSERT INTO bids (auction_id, bidder_id, bid_amount, max_auto_bid, bid_time) " +
                    "VALUES (?, ?, ?, ?, NOW())"
                );
                ins2.setInt(1, auctionId);
                ins2.setInt(2, chalUser);
                ins2.setDouble(3, chalBid);
                ins2.setDouble(4, chalMax);
                ins2.executeUpdate();
            } finally {
                try { if (ins2 != null) ins2.close(); } catch (Exception ex) {}
            }

            PreparedStatement up2 = null;
            try {
                up2 = con.prepareStatement(
                    "UPDATE auctions SET current_highest_bid = ?, current_highest_bidder = ? WHERE auction_id = ?"
                );
                up2.setDouble(1, chalBid);
                up2.setInt(2, chalUser);
                up2.setInt(3, auctionId);
                up2.executeUpdate();
            } finally {
                try { if (up2 != null) up2.close(); } catch (Exception ex) {}
            }

            currentBid = chalBid;
            currentWinner = chalUser;
            // loop again to let top (previous winner or others) counter
            continue;
        } // end while

        con.commit();
        response.sendRedirect("viewAuction.jsp?auction_id=" + auctionId);
        return;

    } catch (Exception e) {
        try { if (con != null) con.rollback(); } catch (Exception ex) {}
        e.printStackTrace();
        session.setAttribute("bidError", "Auto-bid error: " + e.getMessage());
        response.sendRedirect("viewAuction.jsp?auction_id=" + auctionId);
        return;
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) { con.setAutoCommit(true); con.close(); } } catch (Exception ex) {}
    }
%>