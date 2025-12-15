Authors: Andres Castro, Dennie Yuen, Gregory Moore

Login Information (username: password):
Admin: password 
rep1: password
rep2: password
user1: password
user2:password

File Descriptors:

admin_dashboard.jsp – Main page for administrators to view system summaries, manage users, auctions, and customer reps.

AppDB.java - Connects to MySQL server, ensures it is working.

api_history.jsp - Creates working JSON files for items.

auctions.jsp – Displays all active auctions and allows users to browse items and open individual auction pages.

autoBidEngine.jsp – Executes automatic bidding logic, calculating counter-bids between competing auto-bidders.

bid.jsp – Bid submission page to perform bidding.

cancelAuction.jsp – Allows a seller or admin to cancel an auction and mark it inactive.

cancelBid.jsp – Allows a seller or admin to cancel a specific bid from a buyer.

cr_helpdesk.jsp – Customer Representative helpdesk interface to assist users, view reports, or manage complaints.

createAccount.jsp – Registration page allowing users to create new accounts.

createListing.jsp – Form for sellers to enter vehicle details and create a new auction listing.

deleteUser.jsp – Backend logic to soft-delete (anonymize) a user account while preserving their transaction history.

enableAutoBid.jsp – Saves or removes user auto-bid settings and triggers the auto-bid engine.

getAdminUserStats.jsp – AJAX helper that fetches and displays user details and auction history for the admin dashboard.

getUserStats.jsp – AJAX helper that retrieves participation and win statistics for a user profile

globalNotification.jsp - Handles notification logic and format.

index.jsp – Login page where users authenticate to enter the system.

manageAlerts.jsp – JSON API to retrieve or delete user-defined alerts.

notification_service.jsp – Background service that checks for auction updates, winner notifications, and alerts.

processPayment.jsp – Handles logic behind payments for a product.

qa.jsp - Allows users to contribute towards an interactive question and answer forum.

staff_login.jsp – Dedicated login portal for Administrators and Customer Representatives.

submitAuction.jsp – Processes submitted listing data and inserts vehicle, subtype, and auction records into the database.

submitBid.jsp – Validates and inserts manual bids and updates the auction’s current highest bid.

submitCreateAlert.jsp – Processes user-defined alerts.

updateAccount.jsp – Processes updates to user profile information such as name, email, and address.

updateVisibility.jsp – Toggles the visibility (public/private) of an auction listing.

viewAuction.jsp – Displays full auction details, bid history, bidding options, auto-bid settings, and seller controls.
