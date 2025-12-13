Authors: Andres Castro, Dennie Yuen, Gregory Moore

Admin Login Information:



File Descriptors:

admin_dashboard.jsp – Main page for administrators to view system summaries, manage users, auctions, and customer reps.

AppDB.java - Connects to MySQL server, ensures it is working.

api_history.jsp - Creates working JSON files for items.

auctions.jsp – Displays all active auctions and allows users to browse items and open individual auction pages.

autoBidEngine.jsp – Executes automatic bidding logic, calculating counter-bids between competing auto-bidders.

bid.jsp – Bid submission page to perform bidding.

cancelAuction.jsp – Allows a seller or admin to cancel an auction and mark it inactive.

cancelBid.jsp – Allows a seller or admin to cancel a specific bid from a buyer.

checkWin.jsp - Handles logic for who wins a bid.

cr_helpdesk.jsp – Customer Representative helpdesk interface to assist users, view reports, or manage complaints.

createAccount.jsp – Registration page allowing users to create new accounts.

createListing.jsp – Form for sellers to enter vehicle details and create a new auction listing.

enableAutoBid.jsp – Saves or removes user auto-bid settings and triggers the auto-bid engine.

globalNotification.jsp - Handles notification logic and format.

index.jsp – Login page where users authenticate to enter the system.

logged_in.jsp – Simple landing page confirming a successful login.

processPayment.jsp - Handles logic behind payments for a product.

qa.jsp - Allows users to contribute towards an interactive question and answer forum.

show_log_in.jsp – Login status display page.

submitAuction.jsp – Processes submitted listing data and inserts vehicle, subtype, and auction records into the database.

submitBid.jsp – Validates and inserts manual bids and updates the auction’s current highest bid.

submitCreateAlert.jsp – Processes user-defined alerts.

viewAuction.jsp – Displays full auction details, bid history, bidding options, auto-bid settings, and seller controls.

viewitem.jsp – Item-view page, usually pre–auction redesign, previously displaying item details.
