<%@ page import="java.sql.*, com.cs336_project.pkg.AppDB" %>
<%
    // 1. Security Check
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    AppDB db = new AppDB();
    Connection con = db.getConnection();
    String message = "";
    
    // --- CAPTURE SEARCH KEYWORD ---
    String searchQuery = request.getParameter("search");

    // 2. Handle POST Requests (New Question OR New Answer)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        if ("post_question".equals(action)) {
            String topic = request.getParameter("topic");
            String content = request.getParameter("content");
            PreparedStatement ps = con.prepareStatement("INSERT INTO questions (user_id, topic, content) VALUES (?, ?, ?)");
            ps.setInt(1, userId);
            ps.setString(2, topic);
            ps.setString(3, content);
            ps.executeUpdate();
            message = "Question posted successfully!";
            
        } else if ("post_answer".equals(action)) {
            int qId = Integer.parseInt(request.getParameter("question_id"));
            String content = request.getParameter("content");
            PreparedStatement ps = con.prepareStatement("INSERT INTO answers (question_id, user_id, content) VALUES (?, ?, ?)");
            ps.setInt(1, qId);
            ps.setInt(2, userId);
            ps.setString(3, content);
            ps.executeUpdate();
            message = "Answer added!";
        }
    }

    // 3. Fetch Questions (Newest first) with OPTIONAL SEARCH FILTER
    // *** UPDATED: Changed u.username to u.user_name ***
    StringBuilder queryBuilder = new StringBuilder();
    queryBuilder.append("SELECT q.*, u.user_name FROM questions q JOIN users u ON q.user_id = u.user_id ");
    
    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
        queryBuilder.append("WHERE q.topic LIKE ? OR q.content LIKE ? ");
    }
    
    queryBuilder.append("ORDER BY q.created_at DESC");
    
    PreparedStatement psQuestions = con.prepareStatement(queryBuilder.toString());
    
    // Set search parameters if they exist
    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
        String likePattern = "%" + searchQuery + "%";
        psQuestions.setString(1, likePattern);
        psQuestions.setString(2, likePattern);
    }
    
    ResultSet rsQuestions = psQuestions.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Q/A Forum</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f4f7f6; padding: 40px; }
        .container { max-width: 900px; margin: 0 auto; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .btn { background-color: #3498db; color: white; padding: 8px 15px; border: none; border-radius: 4px; cursor: pointer; }
        .btn-submit { background-color: #27ae60; }
        input, textarea { width: 100%; padding: 10px; margin-bottom: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        
        /* Search Bar Styles */
        .search-box { display: flex; gap: 10px; margin-bottom: 20px; }
        .search-input { flex-grow: 1; margin-bottom: 0; }
        
        /* Message Styling */
        .q-header { border-bottom: 1px solid #eee; padding-bottom: 10px; margin-bottom: 15px; }
        .q-topic { font-size: 1.2rem; font-weight: bold; color: #2c3e50; }
        .q-meta { font-size: 0.85rem; color: #7f8c8d; }
        
        /* Answer Styling */
        .answer-box { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 10px; border-left: 3px solid #ccc; }
        .rep-answer { background-color: #e8f6fd; border-left: 3px solid #3498db; }
        .rep-badge { background-color: #3498db; color: white; font-size: 0.7rem; padding: 2px 6px; border-radius: 4px; margin-left: 5px; }
                /* Style for the back link */
        .back-link {
            display: inline-block;
            margin-bottom: 15px;
            color: #6c757d;
            text-decoration: none;
            font-weight: bold;
        }
        .back-link:hover {
            color: #333;
            text-decoration: underline;
        }
    </style>
</head>
<body>

<div class="container">

    <a href="auctions.jsp" class="back-link">&larr; Back to Auctions</a>

    <h1>Community Q&A</h1>
    
    <% if (!message.isEmpty()) { %>
        <div style="background: #d4edda; color: #155724; padding: 10px; border-radius: 4px; margin-bottom: 20px;">
            <%= message %>
        </div>
    <% } %>

    <form action="qa.jsp" method="GET" class="search-box">
        <input type="text" name="search" class="search-input" 
               placeholder="Search questions by keyword..." 
               value="<%= (searchQuery != null) ? searchQuery : "" %>">
        <button type="submit" class="btn">Search</button>
    </form>

    <div class="card" style="background-color: #eaf2f8; border: 1px solid #d6eaf8;">
        <h3>Ask a Question</h3>
        <form action="qa.jsp" method="POST">
            <input type="hidden" name="action" value="post_question">
            <input type="text" name="topic" placeholder="Subject (e.g., Shipping Policy, Item 402 condition)" required>
            <textarea name="content" rows="3" placeholder="What would you like to know?" required></textarea>
            <button type="submit" class="btn btn-submit">Post Question</button>
        </form>
    </div>

    <% 
    boolean hasQuestions = false;
    while (rsQuestions.next()) { 
        hasQuestions = true;
        int qId = rsQuestions.getInt("question_id");
    %>
        <div class="card">
            <div class="q-header">
                <div class="q-topic"><%= rsQuestions.getString("topic") %></div>
                <div class="q-meta">
                    Asked by <strong><%= rsQuestions.getString("user_name") %></strong> 
                    on <%= rsQuestions.getTimestamp("created_at") %>
                </div>
                <p style="margin-top: 10px;"><%= rsQuestions.getString("content") %></p>
            </div>

            <h4>Answers:</h4>
            <%
                // *** UPDATED: Changed u.username to u.user_name ***
                String aSql = 
                    "SELECT a.*, u.user_name, r.user_id AS rep_user_id " +
                    "FROM answers a " + 
                    "JOIN users u ON a.user_id = u.user_id " + 
                    "LEFT JOIN customer_reps r ON u.user_id = r.user_id " +
                    "WHERE question_id = ? ORDER BY created_at ASC";
                    
                PreparedStatement psAns = con.prepareStatement(aSql);
                psAns.setInt(1, qId);
                ResultSet rsAns = psAns.executeQuery();

                while(rsAns.next()) {
                    rsAns.getInt("rep_user_id"); 
                    boolean isRep = !rsAns.wasNull();
                    
                    String cssClass = isRep ? "answer-box rep-answer" : "answer-box";
            %>
                <div class="<%= cssClass %>">
                    <strong><%= rsAns.getString("user_name") %></strong>
                    <% if (isRep) { %> <span class="rep-badge">Customer Rep</span> <% } %>
                    <span style="color: #999; font-size: 0.8rem;"> - <%= rsAns.getTimestamp("created_at") %></span>
                    <p style="margin: 5px 0 0 0;"><%= rsAns.getString("content") %></p>
                </div>
            <% 
                } 
                rsAns.close();
            %>

            <form action="qa.jsp" method="POST" style="margin-top: 15px;">
                <input type="hidden" name="action" value="post_answer">
                <input type="hidden" name="question_id" value="<%= qId %>">
                <div style="display: flex; gap: 10px;">
                    <input type="text" name="content" placeholder="Write an answer..." required style="margin-bottom: 0;">
                    <button type="submit" class="btn">Reply</button>
                </div>
            </form>
        </div>
    <% 
    } 
    
    if (!hasQuestions) {
    %>
        <div style="text-align: center; color: #777; margin-top: 40px;">
            <p>No questions found matching your search.</p>
        </div>
    <%
    }
    
    rsQuestions.close();
    con.close();
    %>

</div>

<%@ include file="globalNotification.jsp" %>
</body>
</html>